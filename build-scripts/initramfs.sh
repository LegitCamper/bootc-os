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
SB_KEY=/run/secrets/sb_key
SB_CERT=/run/secrets/sb_cert

if [ -f "$SB_KEY" ] && [ -f "$SB_CERT" ]; then
  echo "Signing kernel for Secure Boot: $KIMAGE"
  sbsign \
    --key "$SB_KEY" \
    --cert "$SB_CERT" \
    --output "$KIMAGE" \
    "$KIMAGE"

  # Ship the public cert in the image for first-boot MOK enrollment
  install -dm755 /etc/pki/sb-certs
  # DER format required by mokutil --import
  openssl x509 -in "$SB_CERT" -outform DER -out /etc/pki/sb-certs/bootc-os-sb.cer
  # PEM kept alongside for human inspection / re-use
  install -m644 "$SB_CERT" /etc/pki/sb-certs/bootc-os-sb.pem

  echo "Kernel signed successfully"
else
  echo "WARNING: No Secure Boot signing key provided — kernel will not be signed"
fi

