set -euxo pipefail
shopt -s nullglob

KVER=$(ls /usr/lib/modules | head -n1)
KIMAGE="/usr/lib/modules/$KVER/vmlinuz"

echo "Building initramfs for kernel version: $KVER"

if [ ! -d "/usr/lib/modules/$KVER" ]; then
  echo "Error: modules missing for kernel $KVER"
  exit 1
fi

depmod -a "$KVER"
export DRACUT_NO_XATTR=1
/usr/bin/dracut \
  --no-hostonly \
  --kver "$KVER" \
  --reproducible \
  --zstd -v \
  --add ostree --add fido2 --add tpm2-tss \
  -f "/usr/lib/modules/$KVER/initramfs.img"

chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

# Sign kernel for Secure Boot if signing key is available (injected via build secret)
#
# Key management:
#   Generate / rotate key pair:
#     openssl req -newkey rsa:2048 -nodes -keyout sb_key.pem \
#       -new -x509 -sha256 -days 3650 \
#       -subj "/CN=bootc-os Secure Boot/" -out sb_cert.pem
#
#   Encode for GitHub Actions secrets (multiline PEM breaks secret injection):
#     base64 -w0 sb_key.pem && echo   # -> SECURE_BOOT_KEY (repo secret, private key only)
#   Delete sb_key.pem locally after storing.
#   sb_cert.pem is public — commit it to system-files/etc/pki/sb-certs/bootc-os-sb.cer
#
#   First-boot MOK enrollment (once per machine):
#     sudo mokutil --import /etc/pki/sb-certs/bootc-os-sb.cer
#     reboot -> confirm in MokManager UI
#     mokutil --test-key /etc/pki/sb-certs/bootc-os-sb.cer  # verify enrollment
#
SB_KEY=/run/secrets/sb_key
# cert is committed to the repo and copied into the image via system-files/
SB_CERT=/etc/pki/sb-certs/bootc-os-sb.pem

if [ -f "$SB_KEY" ] && [ -f "$SB_CERT" ]; then
  echo "Signing kernel for Secure Boot: $KIMAGE"

  # Private key is stored base64-encoded in GitHub secrets to avoid
  # newline corruption when injected through Docker build secrets.
  SBTMP=$(mktemp -d)
  trap 'rm -rf "$SBTMP"' EXIT
  base64 -d "$SB_KEY" > "$SBTMP/sb_key.pem"

  sbsign \
    --key  "$SBTMP/sb_key.pem" \
    --cert "$SB_CERT" \
    --output "$KIMAGE" \
    "$KIMAGE"

  # Generate DER format needed by mokutil --import
  openssl x509 -in "$SB_CERT" -outform DER \
    -out /etc/pki/sb-certs/bootc-os-sb.cer

  echo "Kernel signed successfully"
else
  echo "WARNING: No Secure Boot signing key provided — kernel will not be signed"
fi

