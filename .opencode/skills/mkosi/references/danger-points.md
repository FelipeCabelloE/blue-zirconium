# mkosi Danger Points & Safety Guide

This document covers behaviors that can damage data, compromise security, or produce surprising results.

---

## Destructive Operations

### `mkosi burn <device>` — Direct Block Device Write

**Risk:** COMPLETE AND IRREVERSIBLE DATA LOSS.

`mkosi burn` writes the output image directly to a block device using `dd` or similar. There is no confirmation prompt for the target device beyond what the OS provides. Specifying the wrong device (e.g., `/dev/sda` instead of `/dev/sdb`) destroys the target disk's contents including partition table.

**Mitigation:**
- Double-check device paths before running
- Use `lsblk` to verify device identity
- Consider writing to a file first, then manually `dd` if needed
- Use `--output-directory` to verify the image before burning

### `mkosi clean -f` / `-ff` — Cache Removal

| Flag | What Gets Removed |
|------|-------------------|
| No flag | Output artifacts only |
| `-f` | Output artifacts + incremental cache |
| `-ff` | Output artifacts + incremental cache + package cache |

**Risk:** `-ff` removes the package manager cache, requiring re-download of all packages on next build. On slow connections or with large images, this can significantly increase build time.

### `mkosi -f` (Force) — Overwrite Output

**Risk:** Silently overwrites existing output image files without confirmation. If you have a built image you want to keep, ensure it's backed up or use a different output path.

---

## Security Considerations

### SecureBoot Key Generation (`mkosi genkey`)

**Risk:** Generates signing keys that control which boot artifacts are trusted by UEFI SecureBoot. If keys are compromised, an attacker can sign malicious boot components.

**Keys generated:**
- `mkosi.secure-boot.crt` — Certificate (public key)
- `mkosi.secure-boot.key` — Private key (MUST be kept secret)

**Mitigation:**
- Store keys securely (restricted permissions)
- Do NOT commit keys to version control
- Use hardware-backed keys for production
- Revoke compromised keys via UEFI dbx update

### Root Password Handling

`RootPassword=` in config, or the `mkosi.rootpw` file, can be:
- A plaintext password
- An executable script (its stdout is read as the password)

**Risk:** If `mkosi.rootpw` is an executable script, it can contain arbitrary code that runs during the build. If the file is writable by untrusted users, they can inject malicious code.

**`mkosi.rootpw` format detection:** If the file has the executable bit set, mkosi executes it and reads its stdout. If not executable, the file content is used directly.

**Mitigation:**
- Set restrictive permissions on `mkosi.rootpw` (600)
- Use `RootPassword=` in config with a hashed password when possible
- Do NOT make the file executable unless you need script-based password generation
- Never commit password files to version control

### Configure Scripts

**Risk:** Configure scripts (set via `ConfigureScripts=`) receive the full current config as JSON on stdin and output modified config as JSON on stdout. They can change ANY build setting including packages, scripts, passwords, and signing keys.

**Mitigation:**
- Only use trusted configure scripts
- Review configure script logic carefully
- Use `mkosi summary --json` to inspect final config

### RepositoryKeyFetch (Default: Disabled)

**Risk:** When `RepositoryKeyFetch=yes`, mkosi will fetch missing GPG keys from keyservers when building on a distro that doesn't have them. This is DISABLED by default for security reasons (man-in-the-middle attacks on key fetch).

**Enable only if:** You're building RPM/Arch images on a non-RPM/Arch host and trust the keyservers. Prefer manually adding keys via the image's package manager config.

### Sandbox Security

**Risk:** All build tools run inside `mkosi-sandbox` which uses Linux namespaces (user, mount, pid, network). A vulnerability in mkosi-sandbox could allow escape from the sandbox. Additionally, if running as root, the sandbox provides less isolation.

**Mitigation:**
- Build as an unprivileged user (recommended)
- Keep mkosi updated for sandbox security fixes
- Do not run untrusted build scripts from unknown sources

### SSH Access

**Risk:** The `Ssh=yes` setting enables vsock-based SSH access into the built image. If enabled in production images, it could expose administrative access.

**Mitigation:**
- Only enable `Ssh=yes` for development/testing images
- Review SSH key configuration

---

## Build Failures & Gotchas

### Missing Kernel Modules in Initrd

**Risk:** If `KernelModulesInclude=` (or `KernelModulesInitrdInclude=`) patterns are too restrictive, the initrd may lack essential modules (storage, filesystem, network), making the image unbootable.

**Fix:** Broaden include patterns or remove restrictive excludes. Use `lsinitrd` to inspect initrd contents.

### Architecture Mismatch

**Risk:** Building for a foreign architecture (e.g., building ARM64 on x86_64) requires:
1. QEMU user-mode emulation binaries installed
2. `binfmt` registered for the target architecture
3. Cross-compilation toolchain for build packages

**Diagnostic:** Build fails with "Exec format error" or similar.

**Fix:**
```bash
# Install QEMU user emulation
sudo dnf install qemu-user-static   # Fedora
sudo apt install qemu-user-static   # Debian/Ubuntu

# Verify binfmt registration
ls /proc/sys/fs/binfmt_misc/
```

### Incremental Cache Staleness

**Risk:** Incremental builds (`-i` / `Incremental=yes`) cache intermediate images. The cache invalidation may not detect all changes (e.g., changes to files referenced indirectly), leading to stale images.

**Symptoms:** Build succeeds but image doesn't reflect recent config changes.

**Fix:**
```bash
mkosi clean -f    # Remove incremental cache
mkosi -f          # Full rebuild
```

### `Overlay=yes` Requires `BaseTrees=`

**Risk:** Setting `Overlay=yes` without also setting `BaseTrees=` causes a build failure because mkosi has no base to overlay on.

### Portable Images + Overlay

**Risk:** `Format=portable` cannot be combined with `Overlay=yes`. The build will fail.

### Rootless Disk Image Builds

**Risk:** Some operations require root:
- Using raw disk images as `BaseTrees=`
- Building images with SELinux XFS labels
- Certain `systemd-repart` operations

**Workaround:** Build as root, or avoid these specific features.

### `--debug-shell` on CI

**Risk:** `--debug-shell` spawns an interactive shell when a chroot command fails. On CI systems with no TTY, this will hang forever.

**Mitigation:** Do not use `--debug-shell` in CI. Use `--debug` instead for verbose output.

### `--debug-workspace` Disk Usage

**Risk:** `--debug-workspace` keeps the temporary workspace on build failure. These can accumulate and consume significant disk space.

**Mitigation:** Periodically clean `/var/tmp/mkosi-*` or `$XDG_CACHE_HOME/mkosi-*`.

### Version Bump (`mkosi bump`)

**Risk:** `mkosi bump` modifies `mkosi.version` in-place. Combined with `--auto-bump` / `-B`, it bumps the version AFTER every successful build. This can produce unexpected version increments if not tracked.

### Large Output Files

**Risk:** Disk images can be very large (multiple GB). Ensure `--output-directory` has sufficient space. `--compression` can reduce size but adds build time.

### Package Cache Growth

**Risk:** The package cache (`--cache-directory`) grows over time and is NOT automatically cleaned. It's shared across builds.

**Cleanup:**
```bash
du -sh ~/.cache/mkosi   # Check size
mkosi clean -ff         # Full cache cleanup
# Or manually:
rm -rf ~/.cache/mkosi
```

---

## Configuration Pitfalls

### Config Parsing Order Confusion

Config is parsed in order: CLI > `mkosi.local.conf` > defaults > `mkosi.conf` > `mkosi.conf.d/` > profiles > images.

**Trap:** Settings in `mkosi.conf` can be silently overridden by `mkosi.conf.d/` drop-ins. Use `mkosi cat-config` to see the final merged config.

### Collection Settings vs Scalar Settings

**Collection settings** (e.g., `Packages=`, `BuildScripts=`) **append** across config files.
**Scalar settings** (e.g., `Format=`, `Distribution=`) **replace** (last wins).

**Trap:** If you set `Packages=` in a drop-in, it does NOT replace — it appends to the parent's package list. Use `Packages=` with `--force` or at the right priority level if you want to override.

### Match Section Surprises

**Trap:** `[Match]` uses AND semantics. If you specify both `Distribution=fedora` and `Release=41`, the config only applies to Fedora 41. For OR semantics, use `[TriggerMatch]`.

**Trap:** A `[Match]` section that doesn't match is silently ignored. Use `[Assert]` to fail if conditions aren't met.

### Executable Config Files

Several config files can be executable scripts:
- `mkosi.version` — stdout read as version
- `mkosi.rootpw` — stdout read as password  
- `mkosi.bump` — custom bump logic
- `mkosi.seed` — stdout read as seed UUID

**Trap:** Making any of these executable changes the semantics. A non-executable `mkosi.version` is read as a static string; an executable one runs as a script.
