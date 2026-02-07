set -euxo pipefail
shopt -s nullglob

installs=(
  05-rpmostree.install
  50-dracut.install
)

cd /usr/lib/kernel/install.d
for install in "${installs[@]}"; do
  printf '%s\n' '#!/bin/sh' 'exit 0' > "$install"
done
chmod +x "${installs[@]}"
cd -

packages=(
  kernel-cachyos-lto
  kernel-cachyos-lto-devel-matched
)

for pkg in kernel kernel-core kernel-modules kernel-modules-core; do
  rpm --erase $pkg --nodeps
done
rm -rf "/usr/lib/modules/$(ls /usr/lib/modules | head -n1)"
rm -rf /boot/*

dnf5 -y install "${packages[@]}"
dnf5 versionlock add "${packages[@]}"

dnf5 -y distro-sync
