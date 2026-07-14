#!/bin/bash
set -euo pipefail

CERT=/etc/pki/sb-certs/bootc-os-sb.cer

# If already enrolled, nothing to do
if mokutil --test-key "$CERT" 2>/dev/null | grep -q "is already enrolled"; then
  exit 0
fi

# Not enrolled — log clear guidance to the journal
{
  echo "======================================================"
  echo "Secure Boot: Machine Owner Key not yet enrolled."
  echo "To enable Secure Boot, run:"
  echo "  sudo mokutil --import $CERT"
  echo "Then reboot and confirm enrollment in the MokManager UI."
  echo "This only needs to be done once. All future image"
  echo "updates are signed with the same key automatically."
  echo "======================================================"
} | systemd-cat -t enroll-mok -p warning
