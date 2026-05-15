---
name: image-builder-cli
description: |-
  Use image-builder-cli (osbuild) to build OS images (qcow2, ami, iso, raw, vmdk, wsl, etc.)
  for Fedora, CentOS, RHEL from CLI or container. Covers build, list, manifest, describe,
  upload, and version subcommands; blueprint customizations; bootc container-based images;
  cross-arch building; SBOM/rpmlist export; cloud uploads; filtering; and progress control.
  NOT for contributing to the repo's source code or for installation — use for running the
  tool itself.
  
  Examples:
  - user: "List buildable images for centos" → `image-builder list --filter 'distro:*centos*'`
  - user: "Build a qcow2 image for fedora-43" → `sudo image-builder build qcow2 --distro fedora-43`
  - user: "Build with a blueprint" → `sudo image-builder build qcow2 --blueprint config.toml --distro centos-9`
  - user: "Check what version is installed" → `image-builder version --format=json`
  - user: "Cross-build for riscv64" → `sudo image-builder build --arch=riscv64 minimal-raw --distro fedora-43`
  - user: "Build a bootc-based image" → `sudo image-builder build qcow2 --bootc-ref quay.io/...`
---
# image-builder-cli — Using the Tool

## CLI Subcommands

| Subcommand | Description |
|---|---|
| `list` | List buildable images (use `--filter`, `--format=json`) |
| `build <image-type>` | Build an image (e.g. `qcow2`, `ami`, `iso`, `anaconda-iso`, `minimal-raw`, `vmdk`, `wsl`, `iot-raw-image`, `iot-qcow2`, `edge-raw-image`, `edge-qcow2`) |
| `manifest <image-type>` | Generate osbuild manifest JSON to stdout |
| `describe <image-type>` | Print image-type metadata |
| `upload <image-path>` | Upload a built image to cloud |
| `version` | Show version info (`--format=yaml` default, or `json`) |

## Key Flags (applied to `build`, `manifest`)

**Distro / arch:**
- `--distro <name>` — e.g. `fedora-43`, `centos-9`, `rhel-10.0`
- `--arch <name>` — e.g. `x86_64`, `aarch64`, `riscv64` (needs `qemu-user-static`)

**Blueprints / customization:**
- `--blueprint <file>` — TOML or JSON file with customizations (users, packages, services, etc.)
- `--registrations <file>` — JSON file with Red Hat subscription details

**Repositories:**
- `--force-repo-dir <dir>` — override data dir with custom `<dir>/repositories/<distro>.json`
- `--extra-repo <url>` — add extra repo during build (not in final image)
- `--force-repo <url>` — replace all base repos during build

**OSTree / Bootc:**
- `--ostree-ref`, `--ostree-parent`, `--ostree-url`
- `--bootc-ref <container-image>` — build disk image from a bootc container
- `--bootc-build-ref <container-image>` — override build container for bootc
- `--bootc-installer-payload-ref <container-image>` — payload for installer images
- `--bootc-default-fs <fstype>` — e.g. `ext4`
- `--bootc-no-default-kernel-args`

**Output / exports:**
- `--output-dir <dir>`, `--output-name <name>`
- `--with-manifest` — export osbuild manifest JSON
- `--with-sbom` — export SPDX SBOM document
- `--with-buildlog` — export osbuild build log
- `--with-metrics` — print timing info after build
- `--cache <dir>` — osbuild artifact cache dir (default `/var/cache/image-builder/store`)

**Other:**
- `--filter "type:qcow2"`, `--filter "distro:*centos*"`, `--filter "arch:x86*"` — filter list results
- `--format=text|json` — output format for list/version
- `--progress auto|verbose|term`
- `--in-vm` — run osbuild pipeline inside a VM
- `--ignore-warnings` — skip warnings during manifest gen
- `--verbose` / `-v` — verbose mode

## Container Usage

The CLI is published as `ghcr.io/osbuild/image-builder-cli:latest`. Run with `--privileged`:

```bash
sudo podman run --privileged \
  -v ./output:/output \
  ghcr.io/osbuild/image-builder-cli:latest \
  build qcow2 --distro fedora-43
```

For bootc mode, the binary also acts as `bootc-image-builder` (multi-call entrypoint via symlink or argv[0]).

**Important:** Builds require root (osbuild needs privileges). Cross-arch builds require `qemu-user-static`.

## Fetching Up-to-Date Information

| Source | Command / URL |
|---|---|
| CLI version | `image-builder version` (or `--format=json`) |
| Buildable images | `image-builder list` |
| COPR snapshots (dev) | `dnf copr enable @osbuild/image-builder` then `dnf info image-builder` |
| GitHub releases | `https://github.com/osbuild/image-builder-cli/releases` |
| Container images | `skopeo list-tags docker://ghcr.io/osbuild/image-builder-cli` |
| Bug tracker | `https://github.com/osbuild/image-builder-cli/issues` |
| Discussions | `https://github.com/orgs/osbuild/discussions` |
| Matrix chat | `#image-builder:fedoraproject.org` |

## Usage Patterns

**Build an image:**
```bash
sudo image-builder build qcow2 --distro centos-9
```

**Build with customization blueprint:**
```bash
sudo image-builder build qcow2 --blueprint ./config.toml --distro fedora-43
```

**Build and upload to cloud:**
```bash
sudo image-builder build ami --distro centos-9 \
  --aws-region us-east-1 --aws-bucket example-bucket --aws-ami-name my-image-1
```

**Build a bootc container disk image:**
```bash
sudo image-builder build qcow2 --bootc-ref quay.io/example/my-app:latest
```

**Cross-arch build (experimental):**
```bash
sudo image-builder build --arch=riscv64 minimal-raw --distro fedora-43
```

**Filter available images:**
```bash
image-builder list --filter "type:qcow2" --filter "distro:*centos*" --format=json
```
