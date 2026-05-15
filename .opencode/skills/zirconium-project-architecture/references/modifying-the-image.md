# Modifying the Image

## Adding a Package

1. Determine which variant or profile needs the package
2. Edit the appropriate config file's `[Content] Packages=` section:
   - Core image packages (most packages): `mkosi.conf.d/theme.conf`
   - Terra packages: `mkosi.conf.d/terra.conf`
   - Niri git builds: `mkosi.conf.d/niri-git.conf`
   - DMS packages: `mkosi.conf.d/avengemedia-danklinux.conf`
   - NVIDIA-specific: `mkosi.profiles/nvidia/mkosi.conf`
   - Hardware support: `mkosi.profiles/base-desktop/mkosi.conf`
   - Edge OS packages: `mkosi.profiles/fedora-bootc-ostree/mkosi.conf`
3. If a package is available in a third-party repo not yet configured, add the repo first (see below)
4. Build locally with `just build` to verify installation

**Format for adding packages:**
```
[Content]
Packages=
    existing-package
    new-package
```

Note: some files use the format `Packages=existing-package\n    new-package` (single-line with continuation). Check the specific file's style before editing.

## Adding a Third-Party DNF Repository

1. Create a `.repo` file in `repos/` following standard DNF/YUM repo format:
   ```ini
   [repo-name]
   name=My Repository
   baseurl=https://example.com/repo/fedora/$releasever/$basearch/
   enabled=1
   gpgcheck=1
   gpgkey=https://example.com/repo/RPM-GPG-KEY
   ```
2. Create a corresponding `mkosi.conf.d/repo-name.conf` to enable it and optionally list packages:
   ```
   [Content]
   Repositories=repos/repo-name.repo
   Packages=
       package-from-repo
   ```

Existing repo files in `repos/`: terra, yalter-niri-git, avengemedia-danklinux, avengemedia-dms-git, negativo-17-nvidia, nvidia-container-toolkit, terra-extras.

## Adding a Systemd Service

### System Services (root)

1. Place unit file: `mkosi.extra/usr/lib/systemd/system/my-service.service`
2. Enable via preset: add to `mkosi.extra/usr/lib/systemd/system-preset/01-zirconium.preset`:
   ```
   enable my-service.service
   ```
3. If timer-based, add `my-service.timer` alongside the `.service` file, and enable the timer in presets

### User Services

1. Place unit file: `mkosi.extra/usr/lib/systemd/user/my-service.service`
2. Enable via preset: add to `mkosi.extra/usr/lib/systemd/user-preset/01-zirconium.preset`

### Existing services for reference:

System: `flatpak-add-flathub-repos.service`, `flatpak-preinstall.service`, `bootc-fetch-apply-updates.service`, `brew-setup.service`, `uupd.service`, `nvctk-cdi.service` (nvidia)
User: `chezmoi-init.service`, `chezmoi-update.service`, `dms.service`, `fcitx5.service`, `udiskie.service`, `iio-niri.service`

## Adding a Script or Binary

Place executable scripts in `mkosi.extra/usr/bin/`. The `mkosi.postinst.chroot` script validates critical files with `stat` — if the file is essential for the image to function, add a `stat` check there.

Project-specific data goes in `mkosi.extra/usr/share/zirconium/`.

### Existing scripts for reference:

| Script | Location | Purpose |
|---|---|---|
| `zjust` | `mkosi.extra/usr/bin/zjust` | Wrapper: `just -f /usr/share/zirconium/just/00-start.just "$@"` |
| `zocr` | `mkosi.extra/usr/bin/zocr` | OCR screenshot via tesseract |
| `zmotd` | `mkosi.extra/usr/bin/zmotd` | Message-of-the-day banner |
| `zfetch` / `glorpfetch` | `mkosi.extra/usr/bin/` | Fastfetch wrappers |
| `luks-tpm2-autounlock` | `mkosi.extra/usr/bin/` | Interactive TPM2 LUKS setup |

## Modifying the In-Image Justfile

Edit: `mkosi.extra/usr/share/zirconium/just/00-start.just`

Key recipes: `update-dotfiles`, `reset-niri`, `toggle-user-motd`, `toggle-autorotation`, `toggle-updates`, `toggle-tpm2`, `toggle-fcitx5`, `check-local-overrides`, `generate-bug-report`.

After modifying, completions for `zjust` are auto-generated in `mkosi.postinst.chroot`. No separate completion update needed.

## Adding a Custom Configuration File

Place in `mkosi.extra/usr/` under the appropriate path (e.g., `mkosi.extra/etc/` for `/etc` files, `mkosi.extra/usr/share/` for package-data files).

For files that should ship as defaults but allow user overrides, place in `/usr/share/factory/etc/` (systemd-tmpfiles will copy to `/etc/` on first boot if not present).

## Adding Flatpaks

1. Add the flatpak ref to the preinstall list: `mkosi.extra/usr/share/flatpak/preinstall.d/zirconium.preinstall`
2. On first boot, `flatpak-add-flathub-repos.service` replaces Fedora flatpak repos with Flathub
3. `flatpak-preinstall.service` runs `flatpak preinstall -y`

Current preinstalled flatpaks: `io.github.flattool.Ignition`, `org.gnome.TextEditor`, `io.github.kolunmi.Bazaar`

## Updating Submodules

Three submodules need periodic updates:

```
git submodule update --remote assets
git submodule update --remote mkosi.extra/usr/share/zirconium/zdots
git submodule update --remote subprojects/ublue-brew
```

Or update all: `git submodule update --remote --recursive`

Renovate bot is configured for automatic submodule updates (`enabled: true` in `.github/renovate.json5`), so CI often handles this.

## Validation Rules

`mkosi.postinst.chroot` validates critical files exist. If you add something essential, add a `stat` line there. The build will fail with an explicit error message pointing to the failing line if a `stat` fails.

Current validation checks:
- `policy.json` references `ghcr.io/zirconium-dev`
- `flathub.flatpakrepo` is a valid flatpak repo file
- Public keys exist: `zirconium.pub`, `jackrabbit.pub`
- Scripts and binaries: `luks*tpm*`, `uupd`, `brew-setup`
- Systemd units: `uupd.service`, `uupd.timer`
- Brew tarball and tmpfiles config

The os-release patching block at the bottom is also critical — if this fails, the image identifies as Fedora instead of Zirconium.
