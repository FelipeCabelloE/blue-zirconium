# mkosi Quickstart & Cheat Sheet

---

## Minimal Image Builds

```bash
# Fedora disk image (auto-detects distro from host if available)
mkosi --distribution fedora --release 41

# Minimal Debian image
mkosi --distribution debian --release trixie

# Minimal Arch Linux image
mkosi --distribution arch

# Ubuntu image
mkosi --distribution ubuntu --release noble

# openSUSE image
mkosi --distribution opensuse --release tumbleweed
```

## Output Format Examples

```bash
# Bootable GPT disk image
mkosi -t disk --distribution fedora --release 41 --bootable yes

# Tarball
mkosi -t tar --distribution fedora --release 41

# Initrd (CPIO)
mkosi -t cpio --distribution fedora --release 41 --make-initrd yes

# Unified Kernel Image
mkosi -t uki --distribution fedora --release 41

# OCI container image
mkosi -t oci --distribution fedora --release 41

# systemd-sysext extension
mkosi -t sysext --distribution fedora --release 41

# Portable service image
mkosi -t portable --distribution fedora --release 41
```

## Config File Examples

### Simple `mkosi.conf`
```ini
[Distribution]
Distribution=fedora
Release=41

[Output]
Format=disk
ImageId=my-custom-image
Compression=zstd

[Content]
Packages=systemd, kernel, openssh-clients, vim
Bootable=yes
Autologin=yes

[Runtime]
VM=qemu
Firmware=uefi
RAM=2G
```

### Conditional Config Drop-in (`mkosi.conf.d/developer.conf`)
```ini
[Match]
Distribution=fedora

[Content]
Packages=
    gcc, make, git, strace, gdb
```

### Multi-Image Build (`mkosi.images/`)
```bash
# Directory structure:
# mkosi.images/
# ├── base/mkosi.conf
# └── with-db/mkosi.conf
```

`mkosi.images/base/mkosi.conf`:
```ini
[Output]
ImageId=base-image
ImageVersion=1.0

[Content]
Packages=systemd, kernel
Bootable=yes
```

`mkosi.images/with-db/mkosi.conf`:
```ini
[Config]
Dependencies=base

[Content]
Packages=postgresql, postgresql-server
```

Build all: `mkosi`
Build specific: `mkosi --image with-db`

### Profile Variants (`mkosi.profiles/`)
```bash
# Directory structure:
# mkosi.profiles/
# ├── minimal/mkosi.conf
# └── full/mkosi.conf
```

`mkosi.profiles/minimal/mkosi.conf`:
```ini
[Content]
Packages=systemd, kernel
```

`mkosi.profiles/full/mkosi.conf`:
```ini
[Content]
Packages=systemd, kernel, vim, git, curl, tmux
```

Use: `mkosi --profile minimal`

## Build Scripts

### Prepare script (`mkosi.prepare/01-configure.sh`)
```bash
#!/bin/bash
echo "Running inside image root before cache"
echo "custom-config" > /etc/my-config
```

### Build script (`mkosi.build/01-compile.sh`)
```bash
#!/bin/bash
echo "Running with build dependencies available"
make -C /build/src
make install DESTDIR=/dest
```

### Post-installation script (`mkosi.postinst/01-cleanup.sh`)
```bash
#!/bin/bash
rm -rf /var/cache/dnf
useradd -m myuser
```

## Interacting with Built Images

```bash
# Boot via systemd-nspawn
mkosi boot

# Boot in QEMU VM
mkosi vm

# Boot in QEMU with specific firmware
mkosi vm --firmware bios

# Boot with debug output
mkosi vm --debug

# Open shell in image
mkosi shell

# SSH into running VM (requires vsock)
mkosi ssh

# Run command in image directly
mkosi shell /usr/bin/uname -a
```

## Debugging

```bash
# Show full build configuration
mkosi summary

# Show config as JSON
mkosi summary --json

# Show all loaded configuration files
mkosi cat-config

# Verbose build
mkosi --debug

# Spawn shell on chroot failure
mkosi --debug-shell

# Keep workspace on failure (for inspection)
mkosi --debug-workspace

# Inspect journal
mkosi journalctl

# Look for coredumps
mkosi coredumpctl
```

## Advanced Features

### Custom Initrd
```bash
# Build custom initrd
mkosi -t cpio --distribution fedora --release 41 --make-initrd yes \
  --initrd-packages "systemd, udev, bash, lvm2" \
  --initrd-profiles "lvm, network"
```

### Persistent Journal
```bash
# Run VM with persistent journal
mkosi vm --runtime-journal

# Run VM with scratch runtime
mkosi vm --runtime-scratch=yes
```

### UKI with SecureBoot
```bash
# Generate keys first
mkosi genkey

# Build UKI with SecureBoot
mkosi -t uki --distribution fedora --release 41 \
  --secure-boot yes --secure-boot-auto-enroll yes
```

### Reproducible Builds
```bash
# Set seed for deterministic partition UUIDs
echo "my-build-seed" > mkosi.seed

# Set SOURCE_DATE_EPOCH
mkosi --source-date-epoch 1714521600
```

## Container/OCI Usage

```bash
# Build OCI image
mkosi -t oci --distribution fedora --release 41

# Run with podman
podman run -it localhost/$(cat mkosi.output 2>/dev/null || echo "image"):latest

# Or use the output directory directly
podman run -it oci-defs:latest
```

## System Update Integration

```bash
# Configure sysupdate definitions in mkosi.sysupdate/
# Then run:
mkosi sysupdate
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `MKOSI_CONFIG` | Path to loaded config file |
| `MKOSI_IMAGE_VERSION` | Current image version |
| `MKOSI_IMAGE_ID` | Current image ID |
| `MKOSI_OUTPUT` | Path to output image |
| `SOURCE_DATE_EPOCH` | Reproducible build timestamp |
| `XDG_CACHE_HOME` | Controls cache directory location |
| `SYSTEMD_LOG_LEVEL` | systemd tool log level (debug, info, etc.) |
