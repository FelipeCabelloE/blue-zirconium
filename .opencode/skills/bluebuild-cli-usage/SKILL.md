---
name: bluebuild-cli-usage
description: |-
  Help users install, configure, and use the BlueBuild CLI tool to build custom ostree-based container images from recipe.yml files.
  Covers installation (cargo, podman/docker installer, script, Nix flake, distrobox), all subcommands (build, generate, switch, validate,
  generate-iso, login, new/init, prune, bug-report, completions), recipe YAML format, build drivers (docker/podman/buildah/chunked-oci/rechunk),
  multi-platform builds, cosign signing, ISO generation, secrets management, and CI integration (GitHub Actions, GitLab CI).

  Use proactively when the user asks about building custom atomic/ostree images, needs help with recipe.yml syntax,
  needs to install bluebuild, or encounters build errors.

  Examples:
  - user: "How do I build a custom Fedora atomic image?" -> walk through installation, recipe creation, and bluebuild build
  - user: "What's the recipe.yml format?" -> explain name, base-image, image-version, modules, stages, alt-tags, labels
  - user: "My build fails with a driver error" -> check Docker/Podman/Buildah versions, verify build driver selection
  - user: "How do I sign my images?" -> configure cosign signing with -S sigstore flag and COSIGN_PRIVATE_KEY
  - user: "Can I build for ARM64 too?" -> add platforms to recipe and use --platform flag for multi-arch builds
  - user: "How do I generate an ISO from my image?" -> use bluebuild generate-iso with image or recipe source
  - user: "What build drivers are supported?" -> explain docker, podman, buildah with -B flag, chunked-oci, rechunk features
  - user: "How do I add secrets to my builds?" -> use secrets field in modules with env/file/exec mount types
  - user: "Help setting up CI for bluebuild" -> reference blue-build/github-action or GitLab CI template
---
# BlueBuild CLI

CLI tool that builds custom Containerfile templates and container images for ostree-based atomic distros (Fedora Atomic, Bluefin, Bazzite, etc.) from YAML recipe files.

## Installation

```bash
# Cargo (recommended for local dev)
cargo install --locked blue-build

# Container installer (extracts binary to /usr/local/bin)
podman run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash
docker run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash

# Direct script
bash <(curl -s https://raw.githubusercontent.com/blue-build/cli/main/install.sh)

# Nix Flake
nix profile install https://flakehub.com/f/blue-build/cli/*.tar.gz#bluebuild

# Distrobox (rootless, no rebase)
git clone https://github.com/blue-build/cli.git
cd cli
distrobox assemble create
```

**Requirements:** Docker v23+, Podman v4+, or Buildah v1.29+.

## Subcommands

| Command | Aliases | Purpose |
|---|---|---|
| `build` | | Build an image from a recipe |
| `generate` | `template` | Generate a Containerfile from a recipe (stdout) |
| `switch` | `update`, `upgrade`, `rebase` | Build + rebase local OS onto oci-archive image |
| `generate-iso` | | Generate an ISO from an image or recipe |
| `validate` | | Validate recipe YAML syntax and module references |
| `new` | | Scaffold a new bluebuild project from template |
| `init` | | Initialize bluebuild in existing directory |
| `login` | | Login to container registries |
| `prune` | | Clean build caches and images |
| `bug-report` | | Generate pre-populated GitHub issue |
| `completions` | | Generate shell completions (bash/zsh/fish/powershell/nushell/elvish) |

## Recipe Format

A `recipe.yml` defines the image. Schemas available at `https://schema.blue-build.org/`:

```yaml
# yaml-language-server: $schema=https://schema.blue-build.org/recipe-v1.json
name: my-custom-image
description: My personal OS image
base-image: quay.io/fedora/fedora-bootc
image-version: latest

# Optional fields
blue-build-tag: none               # Set bluebuild version, "none" to skip install
cosign-version: none               # Set cosign version, "none" to skip install
alt-tags: [stable, v1]             # Override default "latest" and timestamp tags
nushell-version: none               # Set nushell version, "none" to disable
platforms: [linux/amd64]           # Target platforms for multi-arch builds
labels:                            # Custom OCI labels
  org.opencontainers.image.title: My Image

stages:                            # Multi-stage build dependencies
  - from-file: stages.yml          # Stages can reference external files

modules:                           # Build modules (required)
  - from-file: common.yml          # Module lists can reference external files
```

### Module Types

Modules run in order during build. Each module has a `type` field.

| Type | Purpose | Key Config |
|---|---|---|
| `script` | Run shell scripts | `snippets`, `scripts`, `env`, `secrets` |
| `dnf` | Install/remove RPM packages | `install.packages`, `remove.packages`, `repos` |
| `apt` | Debian/Ubuntu package management | `install.packages`, `remove.packages` |
| `apk` | Alpine package management | `install.packages` |
| `pacman` | Arch package management | `install.packages`, `remove.packages` |
| `zypper` | openSUSE package management | `install.packages` |
| `containerfile` | Inject raw Containerfile instructions | `snippets`, `containerfiles` |
| `copy` | Copy files from a stage | `from`, `src`, `dest` |
| `files` | Copy local files into image | `files` (list of source/destination) |
| `signing` | Verify image signatures | (no extra config) |
| `akmods` | Install akmod RPMs | `install`, `base`, `nvidia` (open/proprietary) |
| `default-flatpaks` | Install Flatpaks | `system.install`, `user.install`, `notify` |

Modules can use `source: local` to reference modules in the `modules/` directory instead of pre-built images.

### Secrets

Modules support secrets via the `secrets` field:

```yaml
- type: script
  secrets:
    - type: env        # Load from environment variable
      name: MY_SECRET
      mount:
        type: env      # Expose as env var during build
        name: MY_SECRET
    - type: file       # Load from local file
      source: ./secrets/key.txt
      mount:
        type: file
        destination: /tmp/key
    - type: exec       # Load from command output
      command: cat
      args: [./token.txt]
      mount:
        type: env
        name: TOKEN
```

### Stages

Multi-stage builds compile software outside the final image:

```yaml
stages:
  - name: builder
    from: docker.io/library/rust
    platform: linux/amd64
    shell: ["/bin/bash", "-c"]    # optional custom shell
    modules:
      - type: script
        snippets:
          - cargo build --release
```

Stages can be split into standalone files referenced by `from-file: stages.yml`.

## Build Drivers

Select with `-B` / `--build-driver`:

| Driver | Flag | Notes |
|---|---|---|
| Docker | `-B docker` | Default, requires Docker v23+ |
| Podman | `-B podman` | Podman v4+ |
| Buildah | `-B buildah` | Buildah v1.29+ |

### Advanced Build Flags

| Flag | Purpose |
|---|---|
| `--build-chunked-oci` | Split final image into chunked OCI layers (max 128 by default, set with `BB_BUILD_CHUNKED_OCI_MAX_LAYERS`) |
| `--rechunk` | Reorganize layers from the cache for optimal layer sharing |
| `--rechunk-clear-plan` | Clear rechunk plan cache and rebuild from scratch |
| `--remove-base-image` | Strip base image layers from the output (used with chunked-oci) |
| `--squash` | Squash all layers into one |
| `--platform` | Target specific platform (e.g., `linux/arm64`) |
| `--retry-push` | Retry pushing on transient registry failures |
| `-S sigstore` | Enable cosign signing |

### Signing

```bash
COSIGN_PRIVATE_KEY=$(cat cosign.key) bluebuild build -S sigstore recipes/recipe.yml
```

Cosign OIDC (GitHub Actions):
```yaml
- name: Build Custom Image
  uses: blue-build/github-action@v1
  with:
    recipe: recipe.yml
    cosign_private_key: ${{ secrets.SIGNING_SECRET }}
    registry_token: ${{ github.token }}
```

### Multi-Platform

Recipe-level platforms field OR `--platform` flag:
```bash
bluebuild build --platform linux/amd64,linux/arm64 recipes/recipe.yml
```

## ISO Generation

```bash
# From a pre-built image
bluebuild generate-iso image ghcr.io/my-org/my-image:latest

# From a recipe (builds first)
bluebuild generate-iso recipe recipes/recipe.yml

# With web UI
bluebuild generate-iso --web-ui image ghcr.io/my-org/my-image:latest

# Flags
--output-dir DIR       # Output directory (default: temp dir)
--web-ui              # Include interactive web-based installer UI
```

Uses `ghcr.io/jasonn3/build-container-installer:v1.4.0` under the hood.

## Environment Variables

| Variable | Purpose |
|---|---|
| `BB_BUILD_DRIVER` | Override build driver |
| `BB_BUILD_PUSH` | Enable push (boolean) |
| `BB_BUILD_RETRY_PUSH` | Retry push on failure |
| `BB_BUILD_NO_SIGN` | Disable signing |
| `BB_BUILD_SQUASH` | Squash layers |
| `BB_BUILD_CHUNKED_OCI` | Enable chunked OCI layers |
| `BB_BUILD_RECHUNK` | Enable layer rechunking |
| `BB_CACHE_LAYERS` | Cache layer reuse |
| `BB_REGISTRY` | Container registry |
| `BB_REGISTRY_NAMESPACE` | Registry namespace/org |
| `BB_USERNAME` | Registry username |
| `BB_PASSWORD` | Registry password/token |
| `BB_SKIP_VALIDATION` | Skip recipe validation |
| `BB_GENISO_ENROLLMENT_PASSWORD` | Secure boot enrollment password for ISO |
| `COSIGN_PRIVATE_KEY` | Cosign signing key |
| `COSIGN_PASSWORD` | Cosign key password |
| `GH_TOKEN` | GitHub token for OIDC signing |

## CI Integration

### GitHub Actions

Uses reusable action `blue-build/github-action@v1`:

```yaml
- name: Build Custom Image
  uses: blue-build/github-action@v1
  with:
    recipe: recipe.yml
    cosign_private_key: ${{ secrets.SIGNING_SECRET }}
    registry_token: ${{ github.token }}
    pr_event_number: ${{ github.event.number }}
```

### GitLab CI

```yaml
build-image:
  image: ghcr.io/blue-build/cli
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: /certs
  before_script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
    - export COSIGN_PRIVATE_KEY=$(cat .secure_files/cosign.key)
  script:
    - bluebuild build --push ./recipes/recipe.yml
```

## Quick Start

```bash
# 1. Install bluebuild
cargo install --locked blue-build

# 2. Create a new project
bluebuild new my-image --org-name my-org --registry ghcr.io --ci-provider github

# 3. Edit recipes/recipe.yml with your base image and modules

# 4. Validate
bluebuild validate recipes/recipe.yml

# 5. Generate Containerfile (inspect before building)
bluebuild generate -o Containerfile recipes/recipe.yml

# 6. Build
bluebuild build recipes/recipe.yml

# 7. Generate ISO from built image
bluebuild generate-iso image ghcr.io/my-org/my-image:latest
```
