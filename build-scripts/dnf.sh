set -euxo pipefail
shopt -s nullglob

dnf5 -y install dnf5-plugins
printf "\nmax_parallel_downloads=20\nfastestmirror=True" >> /etc/dnf/dnf.conf

coprs=(
  bieszczaders/kernel-cachyos-lto
  bieszczaders/kernel-cachyos-addons

  ublue-os/packages

  yalter/niri
  ulysg/xwayland-satellite

  che/nerd-fonts
)

for copr in "${coprs[@]}"; do
  echo "Enabling copr: $copr"
  dnf5 -y copr enable "$copr"
done

echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo
echo "priority=2" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ulysg:xwayland-satellite.repo
dnf5 -y config-manager setopt "*fedora*".exclude="kernel-core-* kernel-modules-* kernel-uki-virt-*"

