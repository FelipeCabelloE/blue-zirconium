---
name: mkosi
description: |-
  Build OS images (disk, tar, cpio, UKI, OCI, sysext, portable) with mkosi from the systemd project.
  Covers image building workflows, config files, danger points, and how to find up-to-date info.
  Use proactively when user asks about building/customizing OS images, creating bootable disks,
  initrds, system extensions, portable services, or when "mkosi" appears in context.

  Examples:
  - user: "Build a Fedora 41 disk image for testing" → configure Distribution=Fedora, Release=41, Format=disk
  - user: "How do I use mkosi to create a custom initrd?" → use Format=cpio with MakeInitrd=yes
  - user: "What's the difference between UKI and disk images?" → UKI=unified kernel PE binary, disk=full GPT
  - user: "This image won't boot, what's wrong?" → check bootloader, kernel modules, SecureBoot settings
  - user: "Create a systemd-sysext extension image" → use Format=sysext with appropriate config
  - user: "Build a portable service image" → use Format=portable
  - user: "mkosi burn destroyed my disk!" → warn: burn writes directly to block devices
  - user: "How do I configure mkosi?" → explain mkosi.conf INI format and parsing order
---
# mkosi — OS Image Builder

Build OS images using distribution package managers (dnf, apt, pacman, zypper, apk) via `--installroot`. From the [systemd project](https://github.com/systemd/mkosi).

## Quick Start

```bash
# Build a Fedora disk image with defaults
mkosi --distribution fedora --release 41

# Boot it in a VM
mkosi vm

# Open a shell inside the built image
mkosi shell

# See what will be built
mkosi summary
```

## Output Formats

| Format | Description |
|--------|-------------|
| `directory` | Plain OS tree |
| `tar` | Tarball |
| `cpio` | CPIO archive (for initrds) |
| `disk` | GPT disk image (via systemd-repart) |
| `esp` | ESP-only disk image |
| `uki` | Unified Kernel Image (single PE binary) |
| `oci` | OCI container image directory |
| `sysext` | systemd-sysext extension |
| `confext` | systemd-confext configuration extension |
| `portable` | Portable service image |
| `addon` | PE addon for extending UKIs |
| `none` | Build scripts only |

## Supported Distributions

Fedora, Debian, Ubuntu, Kali, Arch Linux, openSUSE, Mageia, CentOS, RHEL, RHEL-UBI, Rocky Linux, AlmaLinux, Azure Linux, PostmarketOS, openMandriva, `custom`.

Package managers: `dnf`/`dnf5` (RPM), `apt` (Debian), `pacman` (Arch), `zypper` (openSUSE), `apk` (Alpine).

---

## Core Concepts

### Configuration System

INI format in `mkosi.conf`. Sections:

| Section | Purpose |
|---------|---------|
| `[Match]` | Conditional config inclusion (AND semantics) |
| `[TriggerMatch]` | Conditional config inclusion (OR semantics) |
| `[Assert]` / `[TriggerAssert]` | Like Match but fails if not satisfied |
| `[Config]` | Profiles, Dependencies, MinimumVersion, ConfigureScripts |
| `[Distribution]` | Distribution, Release, Architecture, Mirror, Repositories |
| `[Output]` | Format, Output, ImageVersion, ImageId, Compression |
| `[Content]` | Packages, BuildPackages, Trees, Scripts, Bootable, KernelCommandLine |
| `[Validation]` | SecureBoot, Verity, SignExpectedPcr, Checksum, Passphrase |
| `[Build]` | ToolsTree, Incremental, CacheDirectory, BuildDirectory |
| `[Runtime]` | NSpawnSettings, VMM, Firmware, RAM, CPUs, VSock, TPM, Console |

**Config parsing order** (last wins for scalars, appends for collections):
1. CLI arguments
2. `mkosi.local.conf` / `mkosi.local/`
3. Default paths for options
4. `mkosi.conf` (or `mkosi/mkosi.conf`)
5. `mkosi.conf.d/*.conf` (alphanumeric order)
6. `mkosi.profiles/*/mkosi.conf`
7. `mkosi.images/*/mkosi.conf`

**Special files:**

| File | Purpose |
|------|---------|
| `mkosi.version` | Image version (can be executable script) |
| `mkosi.seed` | UUID for reproducible partition builds |
| `mkosi.rootpw` | Root password (can be executable script) |
| `mkosi.machine-id` | Machine ID UUID |
| `mkosi.bump` | Custom version bump logic (executable) |

**Special directories:**

| Directory | Purpose |
|-----------|---------|
| `mkosi.extra/` | Files copied into image root (post-install) |
| `mkosi.skeleton/` | Files copied before package installation |
| `mkosi.sandbox/` | Files copied into build sandbox |
| `mkosi.repart/` | systemd-repart partition definitions |
| `mkosi.packages/` | Extra RPM/deb packages |
| `mkosi.uki-profiles/` | UKI profile configs |
| `mkosi.credentials/` | User/group definitions |
| `mkosi.sysupdate/` | systemd-sysupdate transfer definitions |
| `mkosi.nspawn` | systemd-nspawn settings file |

### Script Lifecycle

Scripts are executed in order during the build. Place executables in these directories or reference them via config keys:

| Script Type | Config Key | When It Runs |
|-------------|-----------|-------------|
| Configure | `ConfigureScripts=` | Before build, receives/sets config as JSON |
| Sync | `SyncScripts=` | Before build (e.g., git operations) |
| Prepare | `PrepareScripts=` | Inside image, before caching |
| Build | `BuildScripts=` | Inside build overlay with build deps |
| Post-install | `PostInstallationScripts=` | After packages, before finalization |
| Finalize | `FinalizeScripts=` | Outside image (on staging directory) |
| Post-output | `PostOutputScripts=` | After final image is assembled |
| Clean | `CleanScripts=` | When `mkosi clean` runs |

**Key details:**
- Scripts suffixed with `.chroot` run via `systemd-nspawn` inside the image (not in the sandbox)
- Environment variables like `MKOSI_CONFIG`, `MKOSI_IMAGE_VERSION`, `MKOSI_OUTPUT` are available in scripts
- Configure scripts receive the current config as JSON on stdin and must output modified config as JSON on stdout

### Tools Tree

A self-contained build environment with pinned tool versions. Built from `mkosi.tools.conf/`. Enables reproducible builds by decoupling build tools from the host system. Set `ToolsTree=` to `tools` (default) or a custom path.

### Incremental Builds

`--incremental` / `Incremental=yes` caches intermediate images to speed up rebuilds:
- Only re-runs build scripts when sources change
- Cache invalidated when config or referenced files change
- Use `-ff` to force a full rebuild from scratch
- Cache stored in `--cache-directory` (default: `$XDG_CACHE_HOME/mkosi`)

### Multiple Image Builds

Place subimage configs in `mkosi.images/<name>/mkosi.conf` to build families of related images in a single run. Each subimage can override parent config. Use `Dependencies=` to specify build order.

### Profiles

Place variant configs in `mkosi.profiles/<name>/mkosi.conf`. Activate with `Profiles=<name>` in `[Config]` section or `--profile` CLI flag.

---

## Common Workflows

### Build an Image

```bash
# Minimal: auto-detect distro from host
mkosi

# Explicit config
mkosi --distribution fedora --release 41 --format disk

# With force overwrite
mkosi -f

# Incremental build
mkosi -i
```

### Inspect

```bash
mkosi summary          # Show full config
mkosi summary --json   # As JSON
mkosi cat-config       # All loaded config files
```

### Interact with Image

```bash
mkosi shell              # Spawn shell via nspawn
mkosi boot               # Boot systemd in nspawn
mkosi vm                 # Boot in VM (qemu or systemd-vmspawn)
mkosi ssh                # SSH into running VM (requires vsock)
```

### Manage Outputs

```bash
mkosi clean              # Remove build artifacts
mkosi clean -f           # Also remove incremental cache
mkosi clean -ff          # Also remove package cache
mkosi burn /dev/sdX      # Write image to device (DESTRUCTIVE!)
mkosi bump               # Bump version in mkosi.version
mkosi serve              # Serve output dir on port 8081
```

### Security & Signing

```bash
mkosi genkey             # Generate SecureBoot signing keys
```

### Diagnostics

```bash
mkosi journalctl         # Inspect image journal
mkosi coredumpctl        # Look for coredumps inside image
mkosi dependencies       # List packages needed to use mkosi
mkosi box                # Run commands in sandbox
```

### Documentation

```bash
mkosi documentation          # Show man page
mkosi documentation mkosi    # Same
mkosi documentation news     # Show changelog
mkosi completion bash        # Generate bash completions
```

---

## Danger Points

**CRITICAL: Read `references/danger-points.md` for full details.**

| Risk | Description |
|------|-------------|
| `mkosi burn` | Writes image **directly to a block device**. Can destroy data. |
| `mkosi clean -ff` | Removes ALL caches including package cache. Forces slow rebuild. |
| `mkosi -f` | Overwrites existing output artifacts. Lose prior build. |
| `mkosi genkey` | Creates SecureBoot signing keys that control boot path trust. |
| `RootPassword=` | Can be an executable script — stdout is read. Code injection risk. |
| `ConfigureScripts=` | Can modify any config setting via JSON. Full build control. |
| Architecture mismatch | Building for foreign arch requires registered QEMU emulation. |
| Incremental cache staleness | May produce stale images. Use `-ff` for clean builds. |
| Running as root | mkosi does NOT drop privileges. Scripts run as root in sandbox. |
| Sandbox escapes | mkosi-sandbox vulnerabilities could let scripts escape isolation. |
| `Overlay=yes` | Requires `BaseTrees=`. Fails silently without it. |

---

## Getting Up-to-Date Information

| Resource | Access |
|----------|--------|
| GitHub repo | <https://github.com/systemd/mkosi> |
| Man page | `mkosi documentation` or `mkosi man` |
| Changelog | `mkosi documentation news` or `NEWS.md` in repo |
| Matrix chat | `#mkosi:matrix.org` |
| Blog intro | <https://0pointer.net/blog/a-re-introduction-to-mkosi-a-tool-for-generating-os-images.html> |
| Distro packages | <https://software.opensuse.org//download.html?project=system%3Asystemd&package=mkosi> |

---

## CLI Verbs Reference

| Verb | Description |
|------|-------------|
| `build` | Build the image (default verb) |
| `shell` | Interactive shell in image via nspawn |
| `boot` | Boot systemd in image via nspawn |
| `vm` | Boot in VM (qemu or systemd-vmspawn) |
| `ssh` | SSH into running VM |
| `summary` | Show build configuration |
| `cat-config` | Show all loaded configuration files |
| `clean` | Remove build artifacts |
| `burn <device>` | Write image to block device |
| `bump` | Bump version in mkosi.version |
| `genkey` | Generate SecureBoot keys |
| `journalctl` | Inspect image journal |
| `coredumpctl` | Look for coredumps |
| `sysupdate` | Run systemd-sysupdate |
| `box` | Run commands in sandboxed env |
| `dependencies` | List host packages needed |
| `completion <shell>` | Generate shell completions |
| `documentation [topic]` | Show documentation |
| `serve` | HTTP serve output on :8081 |
| `init` | One-time tmpfiles.d setup |
| `latest-snapshot` | Latest mirror snapshot |
| `help` | Brief usage |

### Key CLI Flags

| Short | Long | Description |
|-------|------|-------------|
| `-f` | `--force` | Force overwrite |
| `-C` | `--directory` | Change to directory |
| | `--debug` | Debug output |
| | `--debug-shell` | Shell on chroot failure |
| | `--debug-workspace` | Keep workspace on failure |
| `-d` | `--distribution` | Distribution |
| `-r` | `--release` | Release version |
| `-t` | `--format` | Output format |
| `-o` | `--output` | Output filename |
| `-O` | `--output-directory` | Output directory |
| `-p` | `--package` | Additional packages |
| `-i` | `--incremental` | Incremental builds |
| `-E` | `--environment` | Set env vars |
| `-a` | `--autologin` | Root autologin |
| `-B` | `--auto-bump` | Bump version after build |
| `-w` | `--wipe-build-dir` | Wipe build dir |
| `-R` | `--rerun-build-scripts` | Rerun build scripts |
| `-I` | `--include` | Include config file |
| `-T` | `--with-tests` | Control test execution |
| `-m` | `--mirror` | Distribution mirror |

---

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "No space left on device" | Output partition too small | Increase `RootSize=` or disk image size |
| Image won't boot | Missing bootloader or kernel | Set `Bootable=yes`, check `Bootloader=` |
| VM shows no display | Missing firmware or GPU | Set `Firmware=` or add `Firmware=Bios` |
| `mkosi vm` fails | Missing QEMU | Install qemu-kvm, qemu-img packages |
| Incremental build wrong | Stale cache | Use `mkosi clean -f` then rebuild |
| "Failed to find kernel" | No kernel package | Add `kernel` to `Packages=` |
| Permission denied | Running rootless without namespace support | Check user namespace support on host |
| Architecture mismatch | Cross-building without emulation | Register binfmt for QEMU user mode |

## kernel-install Integration

mkosi provides kernel-install plugins:
- `50-mkosi.install` — Builds initrd/UKI on kernel install when `initrd_generator=mkosi-initrd` or `layout=uki`
- `51-mkosi-addon.install` — Builds PE addon from `/etc/mkosi-addon/` config

Standalone tools:
- `mkosi-initrd` — Build initrds from CLI
- `mkosi-addon` — Build PE addons from CLI
