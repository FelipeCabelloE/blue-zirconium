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
| File count | ~33 files | ~13 files |
| Complexity | 7 phases | 4 phases |

### What you get from `bluefin-dx`

Everything. Docker, VS Code, Cockpit, libvirt, ROCm, brew, flathub, tailscale, fish/zsh, starship, just, fastfetch, rclone, restic, samba, wireguard-tools, input-remapper, ddcutil, nerd-fonts, xdg-terminal-exec — all inherited from the base image with zero additional config.

The only change: GNOME is removed and replaced with niri + DMS.

### What you need from Zirconium

~10 config files (greetd, niri, DMS, systemd presets, PAM, tmpfiles) and 3 COPR repo files. All copied once as reference — no submodule dependency.

### GNOME removal: auto-detected at build time

A script (`files/scripts/detect-gnome-removals.sh`) runs during the build and identifies GNOME packages to remove:

1. **Primary filter**: `rpm -qa | grep '^gnome-'` — catches all packages with the gnome-* prefix. This is safe because shared system infrastructure (NetworkManager, mesa, gvfs, etc.) doesn't use the gnome- prefix.
2. **KEEP list** — 3 packages (gnome-keyring, gnome-keyring-pam, gnome-disk-utility) that start with gnome- but provide system-wide services
3. **Targeted list** — System packages that don't use the gnome- prefix but are GNOME-specific: `gdm` and `ptyxis`
4. **EXTRA list** — GNOME packages added by bluefin that don't start with `gnome-`: `adw-gtk3-theme`, `nautilus-gsconnect`, `firewall-config` (`gnome-tweaks` is caught by the primary filter)
5. **Comps XML** (supplementary only) — Fetched for dry-run reporting to show what @gnome-desktop packages are intentionally left alone (system infrastructure)

When bluefin-dx rebases to a new Fedora version, the gnome-* filter is version-agnostic — no manual updates needed.

**DMS replaces every `gnome-settings-daemon` plugin:**

| GSD plugin | DMS replacement |
|---|---|
| `gsd-power` (backlight, idle, suspend) | DMS idle/power management + brightness IPC |
| `gsd-media-keys` (volume, media) | `dms ipc call audio increment/decrement/mute` |
| `gsd-color` (night light) | DMS night mode / gamma control |
| `gsd-background` (wallpaper) | DMS wallpaper manager |
| `gsd-sound` (system sounds) | DMS Qt multimedia feedback |
| `gsd-clipboard` | DMS clipboard history |
| `gsd-keyboard` (layout sync) | niri `config.kdl` |

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
                       │  2. Guard GNOME user hooks     │
                       │  3. Install niri + DMS +       │
                       │     greetd + foot (from COPRs) │
                       │  4. Copy system configs        │
                       │     (greetd, niri, portals,    │
                       │      systemd presets, PAM)     │
                       │  5. Fix PAM for greetd         │
                       │  6. Set systemd presets        │
                       │  7. Validate                   │
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
│   ├── scripts/
│   │   └── detect-gnome-removals.sh      # Auto-detects GNOME packages from Fedora comps
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
│   └── share/
│               ├── greetd/
│               │   └── config.toml             # DMS greeter session
│               ├── niri/
│               │   ├── config.kdl              # Default niri config
│               │   └── local.kdl               # System-wide overrides (empty)
│               └── xdg-desktop-portal/
│                   └── portals.conf            # Portal backend: gtk;gnome
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
  # Auto-detected from Fedora comps XML at build time.
  # Also removes orphaned GNOME Shell extensions post-removal.
  # See files/scripts/detect-gnome-removals.sh for the detection logic.
  - type: script
    scripts:
      - files/scripts/detect-gnome-removals.sh

  # Step 3: Guard bluefin's GNOME-specific user-setup hooks
  # 10-theming.sh writes dconf keys for GNOME Shell extensions — harmless
  # but noisy on niri. Disable it; GDK scale setting is handled by DMS.
  - type: script
    snippets:
      - |
        if [ -f /usr/share/ublue-os/user-setup.hooks.d/10-theming.sh ]; then
          mv /usr/share/ublue-os/user-setup.hooks.d/10-theming.sh{,.disabled}
        fi

  # Step 4: Install niri + DMS stack from COPRs
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

  # Step 5: Copy system config files
  # Includes: niri config, greetd config, PAM, tmpfiles, presets, portals.conf
  - type: files
    files:
      - source: system
        destination: /

  # Step 6: Fix PAM for greetd + DMS
  # greetd RPM installs /etc/pam.d/greetd with gnome_keyring.so on wrong
  # auth/session lines. Fix the ordering and install DMS fingerprint-auth PAM.
  - type: script
    snippets:
      - |
        sed -i '/gnome_keyring.so/ s/-auth/auth/; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
        cp /usr/share/quickshell/dms/assets/pam/* /usr/lib/pam.d/

  # Step 7: Enable systemd presets
  - type: script
    snippets:
      - systemctl preset greetd.service
      - systemctl preset docker.socket
      - systemctl preset podman.socket
      - systemctl preset foot-server.socket

  # Step 8: Validate
  - type: script
    snippets:
      - stat /usr/bin/niri
      - stat /usr/bin/dms
      - stat /usr/bin/greetd
      - stat /usr/bin/foot
      - |
        # Verify GNOME is fully removed
        for pkg in gnome-shell gnome-settings-daemon gdm; do
          ! rpm -q "$pkg" >/dev/null 2>&1 || { echo "$pkg still present!"; exit 1; }
        done
      - |
        # Verify GNOME infrastructure we need is still there
        for pkg in gnome-keyring nautilus xdg-desktop-portal-gnome; do
          rpm -q "$pkg" >/dev/null 2>&1 || { echo "$pkg missing!"; exit 1; }
        done

  # Step 9: Default Flatpaks
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

### Detection script: `files/scripts/detect-gnome-removals.sh`

Runs during the build and identifies GNOME packages via naming convention:

**Strategy rationale:**
The `@gnome-desktop` comps group contains ~85 packages, but only ~40 are actually GNOME. The other ~45 are shared system infrastructure (NetworkManager, mesa, gvfs, librsvg2, toolbox, etc.) that happen to be grouped there. Removing them would break networking, graphics, and file system access.

The script takes a safer approach: **remove by naming convention** (`gnome-*` prefix) rather than by comps group membership. This catches all GNOME-specific packages while leaving system infrastructure untouched.

**Flow:**
```
Query RPM database for installed gnome-* packages
    │
    ▼
Subtract KEEP_LIST (3 packages: keyring, disk-utility)
    │
    ▼
Add targeted non-gnome- packages (gdm, ptyxis)
    │
    ▼
Add bluefin extras (adw-gtk3-theme, gnome-tweaks, …)
    │
    ▼
Fetch comps XML (supplementary — for dry-run reporting only)
    → Shows what @gnome-desktop packages are being left alone
    │
    ▼
dnf remove
     ↑
   DRY_RUN=true   → preview only, no changes
   DEBUG=true     → enable bash command tracing
```

**Keep list rationale:** These gnome-* packages provide system-wide services that non-GNOME apps need.

| Package | Why kept |
|---------|----------|
| `gnome-keyring` / `gnome-keyring-pam` | Secret Service — SSH agent, password storage |
| `gnome-disk-utility` | Disk management GUI — useful, not GNOME-shell-dependent |

**Post-removal cleanup** (built into the script):
- Removes orphaned GNOME Shell extensions at `/usr/share/gnome-shell/extensions/*`

**Guard bluefin's GNOME-specific user hooks:**
bluefin-dx ships `10-theming.sh` that writes dconf keys for GNOME Shell extensions and GDK scale. On niri, these writes are harmless but noisy. The recipe disables this hook; DMS handles theming and GDK scaling natively.

**PAM fix for greetd + gnome-keyring:**
The `greetd` RPM installs `/etc/pam.d/greetd` with `gnome_keyring.so` on the wrong auth/session lines (`-auth` instead of `auth`). Without the fix, the keyring fails to auto-unlock at login. Zirconium's postinst includes this fix — the recipe replicates it. Additionally, DMS provides optimized PAM files for fingerprint auth that are copied from its assets.

**Portal backend configuration:**
`xdg-desktop-portal` auto-selects backends based on `$XDG_CURRENT_DESKTOP`. On niri (unregistered desktop), the selection may fall back incorrectly. The shipped `portals.conf` explicitly sets `[preferred] default=gtk;gnome` to ensure the GTK file-chooser portal is primary, with GNOME screencast/screenshot portal as fallback.

**Packages intentionally NOT removed** (system infrastructure from @gnome-desktop groups):
`NetworkManager*`, `mesa-*`, `gvfs-*`, `librsvg2`, `glib-networking`, `avahi`, `toolbox`, `xdg-desktop-portal`, `polkit`, `dconf`, `nautilus`, `xdg-desktop-portal-gnome`, `xdg-desktop-portal-gtk`, `fprintd-pam`, `systemd-oomd-defaults`, and others.

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
| `system/usr/share/xdg-desktop-portal/portals.conf` | N/A | Set `[preferred] default=gtk;gnome` for portal backends |

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
| GNOME detection | `files/scripts/detect-gnome-removals.sh` | Written from scratch |
| COPR repos | 3 `.repo` files | Copied from Zirconium, verbatim |
| System configs | 6 files (presets, PAM, tmpfiles, greetd, niri) | Adapted from Zirconium |
| CI | `.github/workflows/build.yml` | Already exists, trivial update |
| Auth/certs | `cosign.pub` | Already exists |
| Docs | `README.md`, `AGENTS.md`, `ROADMAP.md` | Updated or written |
| **Total** | **~13 files** | |

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
