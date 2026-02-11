#!/usr/bin/env bash

packages=(
  com.bitwarden.desktop
  org.qutebrowser.qutebrowser
  com.vivaldi.Vivaldi
  com.discordapp.Discord
  org.gnome.Firmware
  com.github.iwalton3.jellyfin-media-player
  io.missioncenter.MissionCenter
  org.onlyoffice.desktopeditors
  com.github.tchx84.Flatseal
)

for package in "${packages[@]}"; do
  flatpak install --user -y --noninteractive flathub "$package"
done

flatpak update --user -y --noninteractive

