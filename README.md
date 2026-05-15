# blue-zirconium &nbsp; [![bluebuild build badge](https://github.com/felipecabelloe/blue-zirconium/actions/workflows/build.yml/badge.svg)](https://github.com/felipecabelloe/blue-zirconium/actions/workflows/build.yml)

A custom Fedora Atomic desktop image based on [Bluefin DX](https://projectbluefin.io/), replacing GNOME with [niri](https://github.com/YaLTeR/niri) + [DankMaterialShell](https://github.com/avengemedia/DankMaterialShell).

## Features

- Inherits everything from Bluefin DX — Docker, VS Code, Cockpit, libvirt, ROCm, Homebrew, Flathub, Tailscale, fish/zsh, starship, just, and more
- Niri scrollable-tiling Wayland compositor
- DankMaterialShell for status bar, notifications, launcher, control center, and clipboard
- greetd + DMS greeter as the login manager
- All GNOME desktop components removed

## Installation

> [!WARNING]
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

From an existing Fedora Atomic system:

```bash
# First rebase to the unsigned image to get signing keys
sudo bootc switch ghcr.io/felipecabelloe/blue-zirconium:latest
```

The `latest` tag tracks Bluefin DX rolling releases. Reboot to complete the installation.

## Building

```bash
bluebuild validate recipes/recipe.yml
bluebuild build recipes/recipe.yml
```

## Relationship to Bluefin DX and Zirconium

[Zirconium](https://github.com/felipecabelloe/zirconium) is a mkosi-based niri/DMS image that builds from scratch. blue-zirconium takes a simpler approach: it layers on top of Bluefin DX using BlueBuild, inheriting everything Bluefin DX provides and only replacing GNOME with niri + DMS. This eliminates the need to replicate Bluefin's package selection, fetch-filter patterns, or lifecycle scripts.

## Default Flatpaks

Installed as system flatpaks at first boot:
- [Zen Browser](https://zen-browser.app/)
- [Calibre](https://calibre-ebook.com/)

Flathub user repo is configured for installing additional flatpaks.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running:

```bash
cosign verify --key cosign.pub ghcr.io/felipecabelloe/blue-zirconium
```

## License

MIT
