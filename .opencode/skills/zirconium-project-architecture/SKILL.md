---
name: zirconium-project-architecture
description: |-
  Understand how the Zirconium OS image is constructed, configured, built, and deployed.
  Covers mkosi build system, profile layering, configuration system, CI/CD pipeline,
  package/repo management, submodule dependencies, and local development workflow.
  Use proactively when modifying image content, debugging builds, adding packages/repos,
  editing mkosi config, working on CI, or understanding how the system is wired together.

  Examples:
  - user: "Add a new package" → find which mkosi.conf.d/ or profile lists it; add there
  - user: "Debug a build failure" → check lifecycle phases; postinst.chroot validations
  - user: "How does CI build work?" → walk reusable-build-bootc.yaml: build→load→rechunk→lint→push→sign→manifest
  - user: "Add a third-party repo" → create .repo in repos/ + snippet in mkosi.conf.d/
  - user: "Build and test locally" → just build → sudo just load → sudo just lint
  - user: "What profile owns this config?" → read AGENTS.md variant table + profile dirs
---
# Zirconium Project Architecture

This skill covers the deep operational knowledge for working on the Zirconium OS image. For quick-start build commands and image variants, load `AGENTS.md` (loaded automatically).

## Repository Anatomy

| Path | Role |
|---|---|
| `mkosi.conf` | Root build config — distribution, release, output, validation, profiles |
| `mkosi.conf.d/*.conf` | Config snippets layered on root (theme, repos, subprojects, niri-git, nvidia) |
| `mkosi.profiles/` | Profile directories — each has own `mkosi.conf` layered in order |
| `mkosi.extra/` | Files injected into the image at build time (scripts, systemd units, configs, dotfiles) |
| `mkosi.prepare.chroot` | Pre-build: downloads crane, homebrew tarball, flathub repo |
| `mkosi.postinst.chroot` | Post-install: validates contents, patches configs, generates completions |
| `repos/` | Third-party DNF `.repo` files (Terra, COPRs, negativo17, nvidia-toolkit) |
| `Justfile` | Task runner — all build/load/lint/rechunk/disk-image commands |
| `.github/workflows/` | CI pipeline — reusable build + 3 image variants + disk/ISO build |
| `subprojects/ublue-brew` | Submodule — Homebrew for Linux (prebundled) |
| `assets/` | Submodule — ISO branding, wallpapers, logos |
| `mkosi.extra/usr/share/zirconium/zdots` | Submodule — default dotfiles (chezmoi-managed) |
| `cosign.pub` | Cosign public key for verifying image signatures |
| `iso.toml` / `iso-nvidia.toml` | `bootc-image-builder` ISO configs (kickstart + branding) |
| `.gitmodules` | 3 submodules: assets, zdots, ublue-brew |

## Config Layering

Configs merge in this order (later wins):

1. `mkosi.conf` (root — sets Distribution, Release, Profiles, SecureBoot=no)
2. `mkosi.conf.d/*.conf` (alphabetical — theme, terra, niri-git, danklinux, subprojects, non-rawhide)
3. `mkosi.profiles/base-desktop/mkosi.conf` (hardware support packages)
4. `mkosi.profiles/fedora-bootc-ostree/mkosi.conf` (edge OS packages, bootloader, firmware)
5. `mkosi.profiles/bootc-ostree/mkosi.conf` (OCI format, dracut, ostree layout, bootupd)
6. `mkosi.profiles/nvidia/mkosi.conf` (added only for nvidia variant — dkms, driver, container-toolkit)

The `sysupdate` profile is separate (disk-image format, SecureBoot=yes) and NOT used in CI.

## Build Lifecycle

```
prepare.chroot
  └─ Downloads crane (go-containerregistry)
  └─ Exports homebrew.tar.zst from ghcr.io/ublue-os/brew:latest
  └─ Downloads flathub.flatpakrepo
mkosi build phase
  └─ Installs all packages from profiles + conf.d repos
  └─ Layers mkosi.extra/ files into image
postinst.chroot
  └─ Installs cached homebrew + flathub
  └─ Verifies niri is git build
  └─ Patches bootc-fetch-apply-updates → --quiet
  └─ Fixes PAM for greetd (fingerprint auth timeout)
  └─ Generates zjust bash/zsh/fish completions
  └─ Runs fc-cache for fonts
  └─ Validates critical files exist (policy.json, flatpakrepo, pub keys, scripts)
  └─ Patches /usr/lib/os-release → NAME=Zirconium, VERSION_CODENAME=Pibble
Post-build (CI/local)
  └─ Load image into podman
  └─ Rechunk layers (centos-bootc or chunkah)
  └─ Lint with bootc container lint
  └─ Push to GHCR (twice — podman annotation bug workaround)
  └─ Sign with cosign
  └─ Merge multi-arch manifests
```

## Common Operations

**Find where a package is listed:**
Read `mkosi.conf.d/theme.conf`, `mkosi.conf.d/terra.conf`, `mkosi.conf.d/niri-git.conf`, and profile configs for the relevant image variant. Some packages are conditionally included per-architecture in `base-desktop`.

**Add a new package:**
1. Determine which profile/variant should include it
2. Add to the appropriate `mkosi.conf.d/*.conf` under `[Content] Packages=`
3. If a new repo is needed, add `.repo` to `repos/` + `mkosi.conf.d/*.conf` to enable it

**Add a systemd service:**
1. Place unit file in `mkosi.extra/usr/lib/systemd/system/` (system) or `mkosi.extra/usr/lib/systemd/user/` (user)
2. Add preset in `mkosi.extra/usr/lib/systemd/system-preset/` or `mkosi.extra/usr/lib/systemd/user-preset/`
3. If timer-based, add `.timer` file too

**Add a script/binary:**
Place in `mkosi.extra/usr/bin/` for system-wide, or `mkosi.extra/usr/share/zirconium/` for project-specific content. Must be referenced in `mkosi.postinst.chroot` validations if critical.

**Debug a build failure:**
1. Check which lifecycle phase failed (prepare, package install, postinst)
2. For postinst failures: the `set -xeuo pipefail` means any `stat` or `grep` failure causes abort
3. Run `mkosi -B --debug` locally for verbose output
4. Inspect `mkosi.output/` for built images and manifests
5. Use `just bootc <args>` to inspect the loaded image

## Reference Index

Load the relevant reference file when you need deep detail:

| Reference | Load when... |
|---|---|
| `references/mkosi-build-lifecycle.md` | Debugging mkosi builds, understanding profile layering, modifying lifecycle scripts |
| `references/local-dev-workflow.md` | Building/testing locally, using vmbuddy, caching, incremental builds |
| `references/modifying-the-image.md` | Adding packages, repos, systemd units, scripts, configs, flatpaks, submodules |
| `references/ci-deep-dive.md` | Understanding CI pipeline, multi-arch manifests, signing, ISO building |

For DMS plugin development, load the `dms-plugin-dev` skill instead — this skill focuses on the OS image construction layer only.
