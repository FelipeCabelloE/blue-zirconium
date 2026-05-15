# Local Development Workflow

## Prerequisites

- `sudo` access (required for mkosi and most Justfile commands)
- `podman` installed
- `just` installed (CI uses `extractions/setup-just`; install via `dnf install just` or cargo)
- Git submodules checked out: `git submodule update --init --recursive`

## Full Pipeline

```
just build                    # Build image with mkosi (incremental)
sudo just load                # Load newest artifact into podman
sudo just lint                # bootc container lint on loaded image
sudo just ostree-rechunk      # Re-layer via centos-bootc (optional for testing)
sudo env BUILD_BASE_DIR=/tmp just disk-image  # Create 20G bootable disk image
vmbuddy -f /tmp/bootable.img  # Boot in VM
```

The default `just` recipe runs all steps sequentially.

## Build

```
just build
```

Equivalent to: `mkosi -B --debug --profile=bootc-ostree`

For a full rebuild (no incremental cache): `mkosi -B -ff --debug --profile=bootc-ostree`

## Load

```
sudo just load
```

Finds the newest directory matching `mkosi.output/_*` (mkosi creates timestamped output dirs), loads it into podman with `podman load`, and tags it as `localhost/zirconium:latest`.

If you need a different tag: `sudo env IMAGE_FULL=localhost/mytag:test just load`

## Lint

```
sudo just lint
```

Runs `bootc container lint` inside the loaded image. Validates:
- bootc compatibility
- OSTree layer structure
- Required files exist

## Rechunk

```
sudo just ostree-rechunk
```

Uses `quay.io/centos-bootc/centos-bootc:stream10` in a privileged container to re-layer the image. This splits the monolithic image into up to 120 layers for efficient OCI distribution.

Only needed on default branch pushes in CI. For local testing, you can skip it.

Alternative: `just rechunk` uses `quay.io/jlebon/chunkah` (experimental).

## Disk Image

```
sudo env BUILD_BASE_DIR=/tmp just disk-image
```

Creates a 20G loopback disk image using `bootc install to-disk` with:
- Generic image mode (works on any hardware)
- GRUB bootloader
- BTRFS filesystem (default, override with `BUILD_FILESYSTEM=ext4` or `xfs`)
- Wipes existing content

The image is written to `${BUILD_BASE_DIR:-.}/bootable.img`.

## Boot in VM

`vmbuddy` is the preferred VM tool. After disk image:
```
vmbuddy -f /tmp/bootable.img
```

## Cache Management

mkosi maintains caches for incremental builds:

| Directory | Purpose | Safe to delete? |
|---|---|---|
| `mkosi.cache/` | Package RPMs, metadata | Yes (slows next build) |
| `mkosi.output/` | Built images | Yes |
| `mkosi.tools/` | mkosi build container | Yes |
| `cache/` in `SRCDIR` | crane binary, homebrew tarball, flathub repo | Yes (re-downloaded on next prepare) |

`sudo just clean` removes `mkosi.output/`, `mkosi.cache/`, and `mkosi.tools/`.

## Inspecting the Built Image

Check what's in the loaded image:
```
just bootc image info
```

List layers:
```
podman images localhost/zirconium:latest
```

Enter the image for inspection:
```
podman run --rm -it localhost/zirconium:latest bash
```

## Environment Variables

| Variable | Default | Used by |
|---|---|---|
| `IMAGE_FULL` | `localhost/zirconium:latest` | load, lint, ostree-rechunk, bootc, disk-image, rechunk |
| `BUILD_FILESYSTEM` | `btrfs` | disk-image (ext4, xfs also valid) |
| `BUILD_BASE_DIR` | `.` (cwd) | disk-image, bootc |

## CI Workflow for Reference

The CI runs on ubuntu-24.04 runners and does:
1. Git checkout with submodules
2. Install deps: bubblewrap, python3-{gpg,hawkey,libcomps,unbound}
3. Clone mkosi from git to `/usr/src/mkosi`
4. `sudo mkosi -B -ff --debug --profile=bootc-ostree,${CI_MKOSI_PROFILES} ${RELEASE_ARGUMENTS}`
5. `sudo just load`
6. `sudo just ostree-rechunk`
7. `sudo just lint`
8. Push to GHCR (twice), sign with cosign
9. Merge per-platform images into multi-arch manifest
