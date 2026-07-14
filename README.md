# bootc-os

Personal Fedora 43 bootc image. Built and published weekly via GitHub Actions to `ghcr.io/legitcamper/bootc-os`. Images are cosign-signed.

## What it is

A [bootc](https://containers.github.io/bootc/) image — the OS is an OCI container that boots directly. Updates are atomic and staged; the running system is never modified in place.

## Stack

| Component | Details |
|---|---|
| Base | `quay.io/fedora/fedora-bootc:43` |
| Kernel | CachyOS LTO (`bieszczaders/kernel-cachyos-lto` COPR), version-locked |
| Display manager | greetd + tuigreet |
| Compositor | niri (Wayland) + xwayland-satellite |
| Audio | Pipewire (pulseaudio, ALSA, JACK compat) + wireplumber |
| Bar | waybar |
| Terminal | alacritty |
| File manager | thunar |
| Notifications | dunst |
| Theming | Catppuccin Macchiato (Kvantum), Papirus icons, Adwaita-dark GTK |
| Fonts | JetBrains Mono Nerd Font |
| Gaming | Steam + gamescope |
| Containers | Podman, Toolbox, Flatpak |
| Virtualisation | libvirt + virt-manager |
| Networking | NetworkManager, Tailscale, WireGuard, OpenVPN |
| Scheduling | scx-scheds (sched-ext) + scx-manager |
| Power | TLP + thermald |

## Repos enabled

- RPMFusion free + nonfree
- Cisco OpenH264
- COPR: `bieszczaders/kernel-cachyos-lto`, `bieszczaders/kernel-cachyos-addons`, `ublue-os/packages`, `yalter/niri`, `ulysg/xwayland-satellite`, `che/nerd-fonts`, `lionheartp/Hyprland`

## Updates

**OS:** `bootc-fetch-apply-updates.service` runs on a timer, stages the new image, applies on next reboot.

**Flatpaks:** `flatpak-update.timer` fires 5 min after boot, then every 24 h.

## Secure Boot

The CachyOS kernel is signed with a custom MOK key during the CI build. The public cert is at `/etc/pki/sb-certs/bootc-os-sb.cer` in the image. See `build-scripts/initramfs.sh` for key management notes.

## Building locally

```bash
docker buildx build --build-arg FEDORA_VERSION=43 -t bootc-os .
```

Secure Boot signing is skipped when the `SECURE_BOOT_KEY` build secret is absent.
