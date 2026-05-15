# blue-zirconium

A custom Fedora Atomic desktop image based on Bluefin DX with niri + DankMaterialShell.

## Build Commands

```bash
bluebuild validate recipes/recipe.yml    # Validate recipe syntax
bluebuild build recipes/recipe.yml       # Build the image locally
bluebuild generate recipes/recipe.yml    # Generate Containerfile for inspection
```

Build requires Docker v23+, Podman v4+, or Buildah v1.29+.

## Justfile Commands

```bash
just validate               # Validate recipe syntax
just generate               # Generate Containerfile for inspection
just generate-iso           # Build + installer ISO from recipe
just generate-iso-image     # Installer ISO from pushed image
just vm                     # Build VM disk image (qcow2)
just test                   # Build VM + boot with qemu
```

Prerequisites for VM testing: `sudo dnf install @virtualization`

## Directory Structure

```
Justfile                        # Build/test/ISO commands (just)
recipes/recipe.yml              # BlueBuild recipe (9 modules)
files/
├── scripts/
│   └── detect-gnome-removals.sh  # Auto-detects GNOME packages to remove
└── system/
    └── usr/
        ├── lib/
        │   ├── systemd/
        │   │   ├── system-preset/01-blue-zirconium.preset
        │   │   └── user-preset/01-blue-zirconium.preset
        │   ├── pam.d/greetd-spawn
        │   └── tmpfiles.d/99-blue-zirconium.conf
        └── share/
            ├── greetd/config.toml
            ├── niri/config.kdl
            └── xdg-desktop-portal/portals.conf
.github/workflows/build.yml     # CI pipeline (scheduled + on push)
cosign.pub                      # Signing public key
```

## Recipe Modules (in order)

1. **Script** — `detect-gnome-removals.sh` removes GNOME packages
2. **Script** — Disables bluefin's `10-theming.sh` user hook
3. **DNF** — Installs niri/DMS stack from COPRs
4. **Files** — Copies `files/system/` → `/`
5. **Script** — Fixes PAM for greetd + DMS fingerprint auth
6. **Script** — `systemctl preset` for greetd, docker, podman, foot-server
7. **Script** — Validates binaries exist and GNOME is removed
8. **Default-flatpaks** — Zen Browser + Calibre (system) + Flathub user repo
9. **Signing** — Container policy setup

## Adding Packages

### From Fedora repos
Add to the DNF module's `install.packages` list in `recipes/recipe.yml`:

```yaml
- type: dnf
  install:
    packages:
      - <package-name>
```

### From COPRs
BlueBuild's `repos: copr:` shorthand handles repo setup automatically:

```yaml
- type: dnf
  repos:
    copr:
      - <user>/<project>
  install:
    packages:
      - <package-name>
```

### Active COPR dependencies
- `yalter/niri-git` — Niri compositor (git builds)
- `avengemedia/dms-git` — DankMaterialShell
- `avengemedia/danklinux` — DMS runtime dependency

## Adding System Config Files

Place files under `files/system/` mirroring the target root path:

- `files/system/usr/lib/systemd/system/foo.service` → `/usr/lib/systemd/system/foo.service`
- Enable in the appropriate preset file if it should start at boot

## Key Conventions

- All config files in `files/system/` mirror the target root filesystem
- COPR repos are documented only in `recipes/recipe.yml` (no `.repo` files in the repo)
- GNOME removal is auto-detected by naming convention, not manually listed
- The base image (`bluefin-dx:latest`) provides all non-GNOME functionality
- Tmpfiles inphase creates symlinks and directories at boot
- System presets ship as `.preset` files in the appropriate `system-preset/` or `user-preset/` directory

## Image Variants

| Tag | Base | Notes |
|-----|------|-------|
| `latest` | bluefin-dx:latest | Rolling, tracks bluefin-dx |
| `stable` | (planned) | Weekly pinned builds |

## Inherited from bluefin-dx

Docker, VS Code, Cockpit, libvirt, ROCm, Homebrew, Flathub, Tailscale, fish/zsh, starship, just, fastfetch, rclone, restic, samba, wireguard-tools, input-remapper, ddcutil, nerd-fonts, xdg-terminal-exec.

The only change: GNOME is removed and replaced with niri + DMS.

## COPR Isolation

COPR repos are specified via BlueBuild's `repos: copr:` shorthand. BlueBuild fetches and enables them during the install transaction. The `.repo` files are managed by BlueBuild and left in their default state.
