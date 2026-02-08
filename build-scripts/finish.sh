set -euxo pipefail
shopt -s nullglob

systemctl set-default graphical.target

# So it won't reboot on Update
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

sed -i '/^[[:space:]]*Defaults[[:space:]]\+timestamp_timeout[[:space:]]*=/d;$a Defaults timestamp_timeout=5' /etc/sudoers

find /etc/yum.repos.d/ -maxdepth 1 -type f -name '*.repo' ! -name 'fedora.repo' ! -name 'fedora-updates.repo' ! -name 'fedora-updates-testing.repo' -exec rm -f {} +
rm -rf /tmp/* || true
dnf5 clean all

RELEASE="$(rpm -E %fedora)"
DATE=$(date +%Y%m%d)

# branding
echo "bootc-os" | tee "/etc/hostname"
sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME=\"Bootc-os\"|
s|^ID=.*|ID=\"booc-os\"|
s|^VERSION=.*|VERSION=\"${RELEASE}.${DATE}\"|
s|^PRETTY_NAME=.*|PRETTY_NAME=\"Bootc-os${RELEASE}.${DATE}\"|
s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="boot-os"|

/^REDHAT_BUGZILLA_PRODUCT=/d
/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d
/^REDHAT_SUPPORT_PRODUCT=/d
/^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF

