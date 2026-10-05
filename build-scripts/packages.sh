set -euxo pipefail
shopt -s nullglob

packages=(
  # wireless
  @networkmanager-submodules
  NetworkManager-wifi
  linux-firmware          # already in the base image; listed to pin the intent
  wireless-regdb
  iwlegacy-firmware
  iwlwifi-dvm-firmware
  iwlwifi-mvm-firmware

  # sound
  alsa-firmware
  alsa-sof-firmware
  alsa-tools-firmware
  pipewire
  pipewire-pulseaudio
  pipewire-alsa
  pipewire-jack-audio-connection-kit
  wireplumber
  pipewire-plugin-libcamera
  pavucontrol-qt

  # system
  glibc-langpack-en
  audit
  audispd-plugins
  cifs-utils
  firewalld
  fuse
  fuse3
  man-pages
  systemd-container
  unzip
  whois
  just
  inotify-tools
  cups
  gutenprint-cups
  system-config-printer
  tailscale
  htop
  stow
  git
  lxqt-policykit
  polkit-qt
  bind-utils
  dnscrypt-proxy
  hunspell-en-US
  geoclue2
  colord

  # bluetooth
  bluez
  bluez-tools
  bluez-obexd
  blueman

  # mDNS / local service discovery
  avahi
  nss-mdns

  # firmware updates (LVFS / UEFI)
  fwupd

  # disk health monitoring
  smartmontools

  # peripherals
  ublue-os-udev-rules     # controllers (8BitDo/DualSense/Switch Pro), Framework input module, USB NICs
  bolt                    # thunderbolt dock / eGPU authorization
  usb_modeswitch          # USB LTE dongles that boot as mass storage
  iio-sensor-proxy        # accelerometer/ambient light -> niri auto-rotate
  switcheroo-control      # "launch on discrete GPU" on hybrid graphics
  libratbag-ratbagd       # gaming mouse DPI/buttons
  piper                   # ratbagd GUI
  fprintd                 # fingerprint reader
  fprintd-pam

  # TPM2 support
  tpm2-tools
  tpm2-tss

  # VPN
  NetworkManager-openvpn
  wireguard-tools

  # archive management
  p7zip
  file-roller

  # desktop
  jetbrains-mono-fonts
  niri
  waybar
  gnome-keyring
  gnome-keyring-pam
  greetd
  greetd-selinux
  tuigreet
  xwayland-satellite
  wl-clipboard
  thunar
  thunar-volman           # removable media automount
  thunar-archive-plugin   # right-click extract, pairs with file-roller
  tumbler-extras          # thumbnails for video/pdf/raw
  swaybg
  # waypaper (GUI wallpaper picker for swaybg) is not packaged in Fedora, and
  # solopasha/hyprland dropped its f43 chroot. Use `swaybg -i <file>` or the
  # flathub build. Revisit if it lands in Fedora proper.
  alacritty
  dunst
  brightnessctl
  pamixer
  network-manager-applet
  libappindicator-gtk3
  swaylock
  swayidle
  kanshi
  imv
  libva-utils

  # battery/perf
  tlp-rdw
  tlp
  thermald
  ksmtuned
  cachyos-ksm-settings
  cachyos-settings
  scx-scheds
  scx-tools
  scx-manager

  # graphics
  # explicit, not mesa*/*vulkan* globs: those matched mingw32 cross-compile libs,
  # ollama-vulkan, mesaflash (FPGA tool) and validation layers
  glx-utils
  mesa-dri-drivers
  mesa-vulkan-drivers
  mesa-va-drivers
  vulkan-loader
  vulkan-tools

  # storage
  jmtpfs
  gvfs-mtp
  gvfs-smb                # network shares in Thunar
  # no gvfs-afc: it hard-requires the usbmuxd daemon, excluded below
  gvfs-fuse               # expose gvfs mounts to non-GTK apps
  exfatprogs              # SD cards, cameras
  ntfs-3g                 # windows volumes
  libimobiledevice
  udisks2
  udiskie

  # media
  @multimedia
  ffmpeg
  gstreamer1-plugins-base
  gstreamer1-plugins-good
  gstreamer1-plugins-bad-free
  gstreamer1-plugins-bad-free-libs
  qt6-qtmultimedia
  lame-libs
  libjxl
  ffmpegthumbnailer
  glycin-libs
  glycin-gtk4-libs
  glycin-loaders
  glycin-thumbnailer
  gdk-pixbuf2
  libopenraw

  # system desktop portals
  # niri ships /usr/share/xdg-desktop-portal/niri-portals.conf (gnome;gtk) and
  # screencasts via -gnome. -wlr is not used; do not override in /etc/xdg.
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome

   # theming
  papirus-icon-theme
  kvantum                 # in F43 this is the Qt6 build (Provides: kvantum-qt6)
  kvantum-qt5
  qt5ct                   # Qt 5 platform theme configuration GUI
  qt6ct
  qt5-qtgraphicaleffects
  qt5-qtquickcontrols2
  qt5-qtsvg

  # print + scan
  hplip
  sane-airscan            # driverless network scanning
  sane-backends-drivers-scanners
  simple-scan

  # gaming
  gamemode
  gamescope
  steam
  steam-devices

  # packages
  flatpak
  toolbox
  podman
  podman-compose

  # secure boot
  sbsigntools
  mokutil

  # disk tools
  gnome-disk-utility
  mediawriter

  # virt
  @virtualization
  virt-manager
)

dnf5 -y install "${packages[@]}" --exclude=usbmuxd

mantle_version=0.3.0
mantle_rpm="mantle-${mantle_version}-1.x86_64.rpm"
mantle_path="/tmp/${mantle_rpm}"

[[ "$(rpm -E '%{_arch}')" == x86_64 ]] || {
  echo "Mantle ${mantle_version} RPM supports x86_64 only" >&2
  exit 1
}

curl --fail --location --retry 3 \
  --output "$mantle_path" \
  "https://github.com/anasgets111/mantle/releases/download/v${mantle_version}/${mantle_rpm}"
printf '%s  %s\n' \
  '7a308ab3875fa0db802957fc655fbf4c11dae545ea29d2b22c291e2e9b67d9ac' \
  "$mantle_path" | sha256sum --check --strict -
dnf5 -y install "$mantle_path"
rm -f "$mantle_path"

packages=(
  console-login-helper-messages
)

dnf5 -y remove "${packages[@]}"

dconf update

flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
