# mkosi Build Lifecycle

## Root Config (`mkosi.conf`)

Key settings merged by the build system:

| Field | Value | Notes |
|---|---|---|
| `Distribution` | fedora | |
| `Release` | 44 | Overridden by `CI_MKOSI_RELEASE` in rawhide CI |
| `Profiles` | base-desktop,fedora-bootc-ostree | `bootc-ostree` added at build time |
| `SecureBoot` | no | Only sysupdate profile enables it |
| `ToolsTree` | default | mkosi manages its own build container |
| `Incremental` | yes | Reuses cached layers on rebuild |
| `Output` | `%i_%v_%a` | Expands to ImageId_Version_Architecture |

## Profile Config Files

### `mkosi.profiles/base-desktop/mkosi.conf`

Matched by `Profiles=base-desktop`. Hardware support layer:
- NetworkManager (including VPN, team, wifi, wwan)
- Firmware: alsa-firmware, alsa-sof-firmware, intel/atheros/brcm/realtek wifi/bt firmware
- PipeWire, WirePlumber, CUPS, fwupd, fprintd, tuned, Plymouth
- `kernel-modules-extra`, `zram-generator-defaults`, `irqbalance`
- x86-64 only: `libva-intel-media-driver`, `powerstat`, `thermald`, `virtualbox-guest-additions`

### `mkosi.profiles/fedora-bootc-ostree/mkosi.conf`

Mirrors `quay.io/fedora/fedora-bootc`. Includes:
- `bootloader.conf`: grub2-common, shim, grub2-tools-minimal, bootupd
- `bootloader-x64.conf` (x86-64): grub2-efi-x64, grub2-pc, grub2-pc-modules
- `firmware.conf` (x86-64): microcode_ctl, amd-ucode-firmware, cirrus/intel audio/gpu firmware
- `goodies.conf`: dnf5, dracut-network, dracut-squash, efibootmgr, flatpak-session-helper, irqbalance, man-db, nfs-utils, p11-kit-server
- `others.conf`: kernel, podman, cryptsetup, lvm2, firewalld, openssh, selinux-policy, tpm2-tools, etc.
- `rhel-edge.conf`: packages from CentOS bootc edge manifest
- Post-install in profile config: automatic updates timer (7d), staging mode, rootless podman setup

### `mkosi.profiles/bootc-ostree/mkosi.conf`

OCI container image format + ostree:
- `Format=oci`, `KernelCommandLine=empty`, `Bootable=no` (dracut handled by bootc/ostree)
- OCI labels: `containers.bootc=1`
- Dracut: `hostonly=no`, modules include kernel-modules + dracut-systemd + systemd-initrd + base + ostree
- Creates ostree symlink structure (`/var/home`, `/var/opt`, etc.)
- Configures composefs + readonly sysroot
- `zram-size = min(ram, 8192)`
- Includes `rechunker-group-fix` service

### `mkosi.profiles/nvidia/mkosi.conf`

Only added for `zirconium-nvidia` images:
- Packages: dkms, nvidia-driver, nvidia-driver-cuda, nvidia-modprobe, nvidia-persistenced, nvidia-settings, libnvidia-fbc, libva-nvidia-driver
- Also: nvidia-container-toolkit (from nvidia's own repo)
- Post-install: install `dkms-nvidia`, run `dkms install`, force nvidia driver load in dracut
- Kernel args: `rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1`
- Enables `nvctk-cdi.service`, disables `akmods-keygen` services

### `mkosi.profiles/sysupdate/mkosi.conf`

Experimental (not in CI): disk-image format with UKI, SecureBoot=yes, full repart.d partitioning.

## Config Snippets (`mkosi.conf.d/`)

| File | Content |
|---|---|
| `theme.conf` | Core image packages: greetd, just, fastfetch, flatpak, git-core, gnome-keyring, foot, fcitx5, tailscale, nautilus, distrobox, chezmoi, qt6ct, xwayland-satellite, ykman, etc. Removes: alacritty, fuzzel, mako, PackageKit, swayidle, swaylock, waybar, ibus-panel |
| `terra.conf` | Terra repository: iio-niri, maple-fonts, satty, valent, uupd |
| `niri-git.conf` | yalter/niri-git COPR — `niri` (git builds) |
| `avengemedia-danklinux.conf` | avengemedia/danklinux + dms-git COPRs — dms, dms-cli, dms-greeter, dgop, dsearch, quickshell-git |
| `subprojects.conf` | Layers `subprojects/ublue-brew/system_files/` into image |
| `non-rawhide.conf` | Enables `updates-testing` repo (excluded for rawhide) |

## Lifecycle Hooks

### `mkosi.prepare.chroot`

Runs before package installation:
1. Downloads latest `crane` binary from GitHub releases (cached once)
2. Uses crane to export `ghcr.io/ublue-os/brew:latest`, extracts `homebrew.tar.zst`
3. Downloads `flathub.flatpakrepo` from `https://dl.flathub.org/repo/flathub.flatpakrepo`
4. All artifacts cached in `${SRCDIR}/cache/`

Cache key insight: if cache files exist, they are NOT re-downloaded. Delete `mkosi.cache/` to force fresh downloads.

### `mkosi.postinst.chroot`

Runs after all packages installed. Errors are fatal (`set -xeuo pipefail`):

1. **Downloads → image**: copies cached `homebrew.tar.zst` and `flathub.flatpakrepo` into image
2. **Validation**: verifies niri is a git build (`niri --version | grep ".*\.git\..*"`)
3. **Patches bootc service**: `ExecStart=/usr/bin/bootc update --quiet`
4. **PAM fix**: installs DMS PAM configs, patches greetd PAM for fingerprint auth speed
5. **Shell config**: adds `pure.bash` to `/etc/bashrc`
6. **Completions**: generates `zjust` completions for bash/zsh/fish (renamed from `just`)
7. **Fonts**: runs `fc-cache --force --really-force --system-only`
8. **Validation gates**: uses `stat` + `grep` to verify critical files exist:
   - `policy.json` references ghcr.io/zirconium-dev
   - flathub.flatpakrepo is correct
   - Public keys: `zirconium.pub`, `jackrabbit.pub`
   - Scripts: `luks*tpm*`, `uupd`, `brew-setup`
   - Systemd units: `uupd.service`, `uupd.timer`, `brew-setup.service`
   - Brew tarball and tmpfiles config
9. **os-release patching**: rewrites NAME=Zirconium, VERSION_CODENAME=Pibble, removes Red Hat specific fields

**Failure mode**: any `stat` or `grep` failure aborts the build. If the image is missing a critical file, the build fails at postinst with the specific `stat` line number.

## Versioning

- `mkosi.bump` script: `date -u +%Y%m%d%H%M%S` (e.g., `20250514120000`)
- CI also produces date-based tags: `latest.YYYYMMDD`, `release.YYYYMMDD`
- CI date tag format: `{{date 'YYYYMMDD'}}` via docker/metadata-action

## CI vs Local Build Differences

| Aspect | CI | Local |
|---|---|---|
| mkosi invocation | `sudo mkosi -B -ff --debug --profile=bootc-ostree,${CI_MKOSI_PROFILES}` | `just build` = `mkosi -B --debug --profile=bootc-ostree` |
| Force flag | `-ff` (force-full rebuild) | No force (incremental) |
| Release override | `--release=$CI_MKOSI_RELEASE` (rawhide) | From mkosi.conf |
| Environment | ubuntu-24.04 runner | Host Fedora |
| mkosi source | Cloned from git (latest) | System-installed |
| Caching | CI cache action for `mkosi.cache/` | Local disk cache |
| Rechunk | Always on push | Must run manually |
| Push/Sign | GHCR + cosign | Not applicable |
