# bootc-os

Personal Fedora 44 bootc image. Built and published daily via GitHub Actions to `ghcr.io/legitcamper/bootc-os`. Images are cosign-signed.

## What it is

A [bootc](https://containers.github.io/bootc/) image — the OS is an OCI container that boots directly. Updates are atomic and staged; the running system is never modified in place.

## Stack

| Component | Details |
|---|---|
| Base | `quay.io/fedora/fedora-bootc:44` |
| Kernel | CachyOS LTO (`bieszczaders/kernel-cachyos-lto` COPR), version-locked |
| Display manager | greetd + tuigreet |
| Compositor | niri (Wayland) + xwayland-satellite |
| Desktop shell | Mantle `v0.3.0` with a system fallback config; user config overrides it |
| Audio | Pipewire (pulseaudio, ALSA, JACK compat) + wireplumber |
| Terminal | alacritty |
| File manager | thunar |
| Theming | Catppuccin Macchiato (Kvantum), Papirus icons, Adwaita-dark GTK |
| Fonts | JetBrains Mono Nerd Font |
| Gaming | Steam + GameMode + gamescope; CachyOS scheduler/kernel tuning; maintained controller/uinput rules |
| DNS | `dnscrypt-proxy` DoH to `dns.sawyer.services`, fronted by `systemd-resolved` |
| Containers | Podman, Toolbox, Flatpak |
| Virtualisation | libvirt + virt-manager |
| Networking | NetworkManager, Tailscale, WireGuard, OpenVPN |
| Peripherals | Thunderbolt (bolt), sensors (iio-sensor-proxy), hybrid GPU (switcheroo-control), gaming mice (ratbagd/piper), fingerprint (fprintd), controller udev rules (ublue-os-udev-rules) |
| Print / scan | CUPS + hplip, SANE + sane-airscan, simple-scan |
| Scheduling | scx-scheds (sched-ext) + scx-manager |
| Power | TLP + thermald |

## Repos enabled

- RPMFusion free + nonfree
- Cisco OpenH264
- COPR: `bieszczaders/kernel-cachyos-lto`, `bieszczaders/kernel-cachyos-addons`, `ublue-os/packages`, `yalter/niri`, `ulysg/xwayland-satellite`
- Mantle `v0.3.0`: checksum-verified upstream `x86_64` RPM. Change version, RPM filename, and SHA-256 together when upgrading.

Mantle currently makes this image amd64/x86_64-only. Its RPM supplies the CLI and renderer, Lua metadata, PAM policy, and license. The system niri config starts Mantle with `/etc/mantle/shell.lua` as a fallback; `~/.config/mantle/shell.lua` takes precedence. Niri loads `/etc/niri/config.kdl` unless the user supplies `~/.config/niri/config.kdl`. Niri starts Xwayland Satellite on demand.

## Updates

**OS:** `bootc-fetch-apply-updates.service` runs on a timer, stages the new image, applies on next reboot.

**Flatpaks:** `flatpak-update.timer` fires 5 min after boot, then every 24 h.

## Secure Boot

The CachyOS kernel is signed with a custom MOK key during the CI build. The public cert is at `/etc/pki/sb-certs/bootc-os-sb.cer` in the image. See `build-scripts/initramfs.sh` for key management notes.

## Building locally

```bash
docker buildx build --build-arg FEDORA_VERSION=44 -t bootc-os .
```

Secure Boot signing is skipped when the `SECURE_BOOT_KEY` build secret is absent.

## Build layout

`Containerfile` runs the scripts in two layers: packages + kernel first, then
`COPY system-files /` and the services/initramfs/finish steps. Editing a
systemd unit or a dotfile therefore reuses the cached dnf layer — GHA
`cache-from` hits on most pushes.

`build-scripts/check-packages.sh` resolves every name in `packages.sh` against
the enabled repos without installing. Run it inside the build container after
`dnf.sh` to catch typos or F-version drift before a full build.

`build-scripts/check-dns.sh` decodes the pinned DNS stamp and verifies its DoH
host/path. During image builds it also asks `dnscrypt-proxy` to validate the
full configuration.
