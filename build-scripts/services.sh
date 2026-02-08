set -euxo pipefail
shopt -s nullglob

system_services=(
  podman.socket
  greetd.service
  chronyd.service
  thermald.service
  tlp.service
  firewalld.service
  podman-tcp.service
  flatpak-theme.service
  systemd-resolved.service
  bootc-fetch-apply-updates.service
)

user_services=(
  podman.socket
  flathub-setup.service
  gnome-keyring-daemon.socket
  gnome-keyring-daemon.service
)

mask_services=(
  logrotate.timer
  logrotate.service
  akmods-keygen.target
  rpm-ostree-countme.timer
  rpm-ostree-countme.service
  systemd-remount-fs.service
  flatpak-add-fedora-repos.service
  NetworkManager-wait-online.service
  akmods-keygen@akmods-keygen.service
)

systemctl enable "${system_services[@]}"
systemctl mask "${mask_services[@]}"
systemctl --global enable "${user_services[@]}"

preset_file="/usr/lib/systemd/system-preset/01-bootc-os.preset"
touch "$preset_file"

for service in "${system_services[@]}"; do
  echo "enable $service" >> "$preset_file"
done

mkdir -p "/etc/systemd/user-preset/"
preset_file="/etc/systemd/user-preset/01-bootc-os.preset"
touch "$preset_file"

for service in "${user_services[@]}"; do
  echo "enable $service" >> "$preset_file"
done

systemctl --global preset-all
