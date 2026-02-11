set -euxo pipefail
shopt -s nullglob

packages=(
  # wireless
  @networkmanager-submodules
  NetworkManager-wifi
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

  # system 
  glibc-langpack-en
  audit
  audispd-plugins
  cifs-utils
  firewalld
  fuse
  fuse-devel
  man-pages
  systemd-container
  unzip
  whois
  inotify-tools
  cups
  gutenprint-cups
  system-config-printer
  tailscale
  htop
  stow

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
  swaybg
  alacritty

  # battery/perf
  tlp-rdw
  tlp
  thermald
  ksmtuned
  cachyos-ksm-settings
  cachyos-settings
  scx-scheds-git
  scx-tools-git
  scx-manager
  scxctl

  # graphics
  glx-utils
  mesa*
  *vulkan*

  # storage
  jmtpfs
  gvfs-mtp
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
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome

   # theming
  papirus-icon-theme
  kvantum
  qt5-qtgraphicaleffects
  qt5-qtquickcontrols2
  qt5-qtsvg

  # packages
  flatpak
  toolbox
  podman
)

dnf5 -y install "${packages[@]}" --exclude=usbmuxd

packages=(
  console-login-helper-messages
)

dnf5 -y remove "${packages[@]}"

dconf update

flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

cd /usr/share/fonts
mkdir -p JetBrainsMonoNerdFont
cd JetBrainsMonoNerdFont

curl -L -o JetBrainsMono.tar.xz \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz

tar -xJf JetBrainsMono.tar.xz --strip-components=0
rm JetBrainsMono.tar.xz

# Rebuild font cache
fc-cache -fv

