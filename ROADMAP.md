# Roadmap: blue-zirconium (BlueBuild edition)

**Build:** BlueBuild (Containerfile via recipe.yml)
**Base:** `ghcr.io/ublue-os/bluefin-dx:latest`
**Desktop:** niri + DankMaterialShell
**DM:** greetd + DMS greeter

---

## Why this approach

The previous mkosi-based roadmap required 33 files, 2 submodules, lifecycle scripts, and a fragile fetch-filter pattern to replicate bluefin-dx packages. A BlueBuild approach is simpler:

| Problem | mkosi approach | BlueBuild approach |
|---------|---------------|-------------------|
| DX parity | Fetch 04-packages.sh + 00-dx.sh from GitHub, strip GNOME at build time | Inherit everything from `bluefin-dx:latest` — zero fetch, zero filter |
| Submodules | `zirconium/` + `bluefin/` + nested submodules | None. Config files copied once, owned by this repo |
| Lifecycle | `prepare.chroot` + `postinst.chroot` + validation scripts | Modules in recipe.yml — DNF removes GNOME, DNF installs niri/DMS, files copy configs |
| CI pipeline | Custom mkosi workflow with skopeo version detection | Existing `blue-build/github-action` — just update recipe path |
| File count | ~33 files | ~12 files |
| Complexity | 7 phases | 4 phases |

### What you get from `bluefin-dx`

Everything. Docker, VS Code, Cockpit, libvirt, ROCm, brew, flathub, tailscale, fish/zsh, starship, just, fastfetch, rclone, restic, samba, wireguard-tools, input-remapper, ddcutil, nerd-fonts, xdg-terminal-exec — all inherited from the base image with zero additional config.

The only change: GNOME is removed and replaced with niri + DMS.

### What you need from Zirconium

~10 config files (greetd, niri, DMS, systemd presets, PAM, tmpfiles) and 3 COPR repo files. All copied once as reference — no submodule dependency.

---

## Architecture

```
                      ┌──────────────────────────────┐
                      │  ghcr.io/ublue-os/bluefin-dx  │
                      │  (Fedora Silverblue +         │
                      │   Docker, VS Code, Cockpit,   │
                      │   brew, tailscale, flathub,   │
                      │   fish/zsh, just, ROCm, ...)  │
                      └──────────────┬───────────────┘
                                     │ FROM
                      ┌──────────────▼───────────────┐
                      │     BlueBuild recipe.yml       │
                      │                                │
                      │  1. Remove GNOME packages      │
                      │  2. Install niri + DMS +       │
                      │     greetd + foot (from COPRs) │
                      │  3. Copy system configs        │
                      │     (greetd, niri, DMS,        │
                      │      systemd presets, PAM)     │
                      │  4. Set systemd presets        │
                      │  5. Validate                   │
                      └──────────────┬───────────────┘
                                     │ push to GHCR
                      ┌──────────────▼───────────────┐
                      │  ghcr.io/felipecabelloe/      │
                      │  blue-zirconium:latest         │
                      │  (bootc-swappable OCI image)   │
                      └──────────────────────────────┘
```

---

## Phase 0 — Repository restructure

### New structure

```
blue-zirconium/
├── recipes/
│   └── recipe.yml              # BlueBuild recipe (the whole build definition)
├── files/
│   ├── copr-repos/
│   │   ├── yalter-niri-git.repo          # enabled=0, COPR for niri
│   │   ├── avengemedia-dms-git.repo      # enabled=0, COPR for DMS + danklinux dep
│   │   └── avengemedia-danklinux.repo    # enabled=0, COPR for danklinux
│   └── system/
│       └── usr/
│           ├── lib/systemd/system-preset/
│           │   └── 01-blue-zirconium.preset   # System services
│           ├── lib/systemd/user-preset/
│           │   └── 01-blue-zirconium.preset   # User services
│           ├── lib/pam.d/
│           │   └── greetd-spawn               # PAM for greetd
│           ├── lib/tmpfiles.d/
│           │   └── 99-blue-zirconium.conf      # Factory defaults
│           └── share/
│               ├── greetd/
│               │   └── config.toml             # DMS greeter session
│               └── niri/
│                   ├── config.kdl              # Default niri config
│                   └── local.kdl               # System-wide overrides (empty)
├── cosign.pub
├── .github/workflows/build.yml # Already works — minor updates
├── AGENTS.md
├── README.md
└── ROADMAP.md
```

### Housekeeping

| Action | Files |
|--------|-------|
| **Remove** submodule checkouts | `zirconium/`, `bluefin/` (directories, not tracked as submodules) |
| **Remove** mkosi-era stubs | `modules/`, `files/scripts/example.sh` |
| **Adapt** `recipes/recipe.yml` | Full rewrite (see Phase 1) |
| **Keep** | `cosign.pub`, `.github/workflows/build.yml`, `LICENSE`, `.gitignore` |

---

## Phase 1 — Recipe

### `recipes/recipe.yml`

```yaml
name: blue-zirconium
description: Bluefin DX with Niri + DankMaterialShell
base-image: ghcr.io/ublue-os/bluefin-dx
image-version: latest

modules:
  # Step 1: Copy COPR repos into the image early so DNF can use them
  - type: containerfile
    snippets:
      - COPY files/copr-repos/yalter-niri-git.repo /etc/yum.repos.d/
      - COPY files/copr-repos/avengemedia-dms-git.repo /etc/yum.repos.d/
      - COPY files/copr-repos/avengemedia-danklinux.repo /etc/yum.repos.d/

  # Step 2: Remove GNOME desktop components
  - type: dnf
    remove:
      packages:
        - gnome-shell
        - gdm
        - gnome-session
        - gnome-initial-setup
        - gnome-software
        - gnome-tweaks
        - gnome-console
        - gnome-text-editor
        - evince
        - eog
        - totem
        - gnome-calculator
        - gnome-calendar
        - gnome-clocks
        - gnome-logs
        - gnome-characters
        - gnome-font-viewer
        - gnome-connections
        - snapshot
        - baobab
        - file-roller
        - loupe
        - adw-gtk3-theme
        - gnome-browser-connector
        - gnome-tour

  # Step 3: Install niri + DMS stack from COPRs
  - type: dnf
    install:
      packages:
        - niri
        - xwayland-satellite
        - dms
        - dms-cli
        - dms-greeter
        - dgop
        - dsearch
        - greetd
        - greetd-selinux
        - foot
        - wl-clipboard
        - wtype
        - waypipe
        - brightnessctl
        - iio-niri
        - satty
        - fcitx5
        - fcitx5-mozc
        - qt6ct
        - breeze-qt6
        - qt6-qtimageformats
        - playerctl
        - cava
        - udiskie
        - xdg-desktop-portal-gtk

  # Step 4: Copy system config files
  - type: files
    files:
      - source: system
        destination: /

  # Step 5: Enable systemd presets
  - type: script
    snippets:
      - systemctl preset greetd.service
      - systemctl preset docker.socket
      - systemctl preset podman.socket
      - systemctl preset foot-server.socket

  # Step 6: Validate
  - type: script
    snippets:
      - stat /usr/bin/niri
      - stat /usr/bin/dms
      - stat /usr/bin/greetd
      - stat /usr/bin/foot
      - '! test -f /usr/bin/gnome-shell || { echo "GNOME still present!"; exit 1; }'

  # Step 7: Default Flatpaks
  - type: default-flatpaks
    notify: true
    system:
      install:
        - org.mozilla.firefox
```

### Fedora version alignment

Start with `image-version: latest` to track bluefin-dx's rolling releases. When bluefin-dx rebases to a new Fedora major version:

1. The COPR repo files use `$releasever` which matches whatever Fedora the base image runs
2. No recipe changes needed — just rebuild

If this proves unreliable, pin to `image-version: 42` and bump manually.

### COPR isolation

All COPR `.repo` files use `enabled=0`. The `containerfile` module copies them into the image, and the DNF module references them for the install transaction. After the build, they remain `enabled=0` in the image — matching bluefin's validated-repos security policy.

---

## Phase 2 — System files & configuration

### Source: Zirconium reference

All config files are adapted from the `zirconium/` directory (kept locally for reference, not as a submodule). After initial setup, these files are owned by this repo and can diverge from upstream.

| File | Source | Adaptations |
|------|--------|-------------|
| `copr-repos/yalter-niri-git.repo` | `zirconium/repos/` | Verbatim |
| `copr-repos/avengemedia-dms-git.repo` | `zirconium/repos/` | Verbatim (includes danklinux as coprdep) |
| `copr-repos/avengemedia-danklinux.repo` | `zirconium/repos/` | Verbatim |
| `system/usr/lib/systemd/system-preset/01-blue-zirconium.preset` | `zirconium/.../01-zirconium.preset` | Remove zirconium-specific (brew-setup, uupd). Add docker/podman/foot. |
| `system/usr/lib/systemd/user-preset/01-blue-zirconium.preset` | `zirconium/.../01-zirconium.preset` | Remove chezmoi. Keep dms, fcitx5, iio-niri, udiskie. |
| `system/usr/lib/pam.d/greetd-spawn` | `zirconium/.../pam.d/greetd-spawn` | Verbatim |
| `system/usr/lib/tmpfiles.d/99-blue-zirconium.conf` | `zirconium/.../99-zirconium-factory.conf` | Greetd config symlink, greetd/niri directory |
| `system/usr/share/greetd/config.toml` | `zirconium/.../greetd/config.toml` | Verbatim |
| `system/usr/share/niri/config.kdl` | N/A | Ship a minimal niri config with DMS IPC keybinds |
| `system/usr/share/niri/local.kdl` | N/A | Empty placeholder |

### Systemd presets

**`01-blue-zirconium.preset` (system):**
```
enable greetd.service
enable docker.socket
enable podman.socket
enable foot-server.socket
```

**`01-blue-zirconium.preset` (user):**
```
enable dms.service
enable fcitx5.service
enable iio-niri.service
enable udiskie.service
```

### Greetd config (`/usr/share/greetd/config.toml`):
```toml
[general]
service = "greetd-spawn"

[terminal]
vt = 1

[default_session]
command = "dms-greeter --command niri --cache-dir /var/cache/dms-greeter -C /etc/greetd/niri/config.kdl"
user = "greeter"
```

### Tmpfiles (`/usr/lib/tmpfiles.d/99-blue-zirconium.conf`):
```
L /etc/greetd/config.toml - - - - /usr/share/greetd/config.toml
d /etc/greetd/niri 0755 - - -
```

---

## Phase 3 — CI/CD

### Current workflow (`.github/workflows/build.yml`)

Already uses `blue-build/github-action@v1.11` — the only change needed is updating the recipe path. The workflow supports:
- Daily scheduled builds (6:00 UTC)
- Push and PR triggers
- Cosign signing via `SIGNING_SECRET`
- `maximize_build_space: true`

No new CI files needed.

### Future additions (post-MVP)

- **NVIDIA variant**: Add a second recipe file (`recipe-nvidia.yml`) with akmods + nvidia-container-toolkit
- **ISO generation**: `bluebuild generate-iso` from the built image
- **Multi-arch**: Add `linux/arm64` to recipe `platforms` field

---

## Phase 4 — Documentation

| File | Action |
|------|--------|
| `README.md` | Update: blue-zirconium identity, `bootc switch` instructions, relationship to bluefin-dx and zirconium |
| `AGENTS.md` | Write: build commands, file conventions, how to add packages, COPR handling |
| `ROADMAP.md` | This file — mark completed phases as done |

---

## File inventory

| Area | Files | Source |
|------|-------|--------|
| Recipe | `recipes/recipe.yml` | Written from scratch |
| COPR repos | 3 `.repo` files | Copied from Zirconium, verbatim |
| System configs | 6 files (presets, PAM, tmpfiles, greetd, niri) | Adapted from Zirconium |
| CI | `.github/workflows/build.yml` | Already exists, trivial update |
| Auth/certs | `cosign.pub` | Already exists |
| Docs | `README.md`, `AGENTS.md`, `ROADMAP.md` | Updated or written |
| **Total** | **~12 files** | |

### Removed from mkosi roadmap

- `zirconium/` submodule checkout
- `bluefin/` submodule checkout
- All planned mkosi files (mkosi.conf, mkosi.conf.d/, mkosi.profiles/, mkosi.extra/, etc.)
- `scripts/fetch-bluefin-packages.sh`
- `repos/` directory (COPR files live in `files/copr-repos/`)
- `modules/` directory stub
- `files/scripts/example.sh`

---

## Future considerations

- **NVIDIA variant**: Profile with akmods COPR + nvidia-container-toolkit. BlueBuild supports `akmods` module type natively.
- **Multi-arch**: When niri and DMS support arm64, add `platforms: [linux/amd64, linux/arm64]` to recipe.
- **ISO generation**: `bluebuild generate-iso recipe recipes/recipe.yml` for offline installers.
- **Image pruning**: If the GNOME removal doesn't reclaim enough space, consider `dnf remove` for `gtk4` and other GNOME libraries (risky — may break non-GNOME apps).
- **Pre-built COPR RPMS**: If COPR build latency is an issue, mirror packages to GHCR as OCI artifacts.
