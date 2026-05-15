# CI/CD Deep Dive

## Workflow Files

| File | Trigger | Image | Profiles |
|---|---|---|---|
| `build-standard.yaml` | push/PR to main, weekly Tue 1:00, merge_group, dispatch | `zirconium:latest` | (default) |
| `build-nvidia.yaml` | Same | `zirconium-nvidia:latest` | `nvidia` |
| `build-rawhide.yaml` | Same | `zirconium:rawhide` | (default, `CI_MKOSI_RELEASE=rawhide`) |
| `build-disk.yml` | Weekly + dispatch (NOT on push/PR) | ISO from published images | N/A |
| `reusable-build-bootc.yaml` | Called by other workflows | — | Parametrized |

**Concurrency**: each workflow cancels in-progress runs for the same ref.

## Reusable Build Workflow (`reusable-build-bootc.yaml`)

### Inputs

| Input | Type | Default |
|---|---|---|
| `image-name` | string (required) | — |
| `image-desc` | string | `"Opinionated niri + bootc image"` |
| `default-tag` | string | `"latest"` |
| `platforms` | string | `"amd64,arm64"` |
| `rechunk` | bool | `true` |
| `publish` | bool | `true` |
| `profiles` | string | `""` (extra profiles) |
| `release` | string | `""` (rawhide override) |

Secrets: `SIGNING_SECRET` (cosign private key)

### Per-Platform Build (`build_push` job)

Runs on `ubuntu-24.04` (amd64) or `ubuntu-24.04-arm` (arm64). 60-minute timeout.

**Steps:**

1. **BTRFS mount** (amd64 non-arm only): mounts `/var/lib/containers` with compress-force=zstd for podman storage. Only when `cleanup_action` is set.

2. **Checkout**: `actions/checkout` with `submodules: true`

3. **Setup Just**: `extractions/setup-just`

4. **Brew cache**: caches `/home/linuxbrew` per-platform. Podman from brew is needed because GH runners have an old podman that doesn't push layer annotations.

5. **mkosi cache**: caches `mkosi.cache/` per image+platform.

6. **Install deps**: `bubblewrap`, `python3-gpg`, `python3-hawkey`, `python3-libcomps`, `python3-unbound`. Clones mkosi from `github.com/systemd/mkosi.git` to `/usr/src/mkosi`.

7. **Render config**: `mkosi cat-config --debug` for debugging (dumps merged config).

8. **Build image**: `sudo mkosi -B -ff --debug --profile=bootc-ostree,${CI_MKOSI_PROFILES} ${RELEASE_ARGUMENTS}`

9. **Load image**: `sudo env IMAGE_FULL=... just load`

10. **Rechunk**: `sudo env IMAGE_FULL=... just ostree-rechunk`

11. **Lint**: `sudo env IMAGE_FULL=... just lint`

12. **Cache perms fix**: `sudo chmod 777 --recursive mkosi.cache` (avoids cache permission issues)

13. **Login to GHCR**: podman + docker login (docker for cosign)

14. **Install Podman from Brew** (on cache miss): needed because GH runner podman too old.

15. **Push to GHCR**: pushes twice (annotation bug workaround):
    ```bash
    for _ in $(seq 2); do
      for i in $(seq ${MAX_RETRIES}); do
        sudo /home/linuxbrew/.linuxbrew/bin/podman push --compression-format=zstd \
          localhost/${IMAGE_NAME}:${DEFAULT_TAG} \
          ${IMAGE_REGISTRY}/${IMAGE_NAME}:${DEFAULT_TAG}-${PLATFORM} && break
      done
    done
    ```
    Uses digestion file for manifest reference.

16. **Sign**: `cosign sign -y --key env://COSIGN_PRIVATE_KEY ...`

### Manifest Job (`manifest`)

Runs in an Alpine container (privileged) to merge per-platform images:

1. Collects digests from artifacts uploaded by per-platform builds
2. Uses `docker/metadata-action` to generate tags and OCI labels:
   - Tags: `latest`, `release`, `latest-YYYYMMDD`, `release-YYYYMMDD`, `latest-sha`, `sha`, PR ref, date-only
   - Labels: `containers.bootc=1`, ArtifactHub metadata (keywords, license, logo), OCI annotations
3. Creates multi-arch manifest with `podman manifest create`
4. Adds per-platform images: `podman manifest add`
5. Annotates: `podman manifest annotate --index --annotation`
6. **Push twice** (same annotation bug workaround):
   ```bash
   for _ in $(seq 2); do
     while IFS= read -r TAG; do
       podman manifest push --all=false --digestfile=/tmp/digestfile \
         "${TARGET_MANIFEST}" "${TARGET_MANIFEST}:${TAG}"
     done <<< "${TAGS}"
   done
   ```
7. Signs the merged manifest with cosign

## ISO Build (`build-disk.yml`)

Runs weekly and on dispatch (NOT on push/PR). Matrix: [amd64, arm64] x ["", "-nvidia"].

**Steps:**

1. **Free disk space**: removes unwanted software
2. **Pull image**: pulls from GHCR
3. **Extract RPM GPG keys** from the image for validation
4. **Run bootc-image-builder**:
   `quay.io/centos-bootc/bootc-image-builder:latest --type iso --rootfs btrfs`
5. **Brand the ISO**: uses lorax/mkksiso to add custom product image (from `assets/` submodule), sets `inst.resolution=1280x800`
6. **Generate CHECKSUM**: `sha256sum`
7. **Upload to S3**: via rclone (secrets: S3_ACCESS_KEY_ID, S3_ENDPOINT, S3_PROVIDER, S3_REGION, S3_SECRET_ACCESS_KEY, S3_BUCKET_NAME)
8. **Upload PR artifacts**: retention-days: 0 (default)

### ISO Config Files

- `iso.toml`: kickstart post-install → `bootc switch --mutate-in-place --transport registry ghcr.io/zirconium-dev/zirconium:latest`
- `iso-nvidia.toml`: same, but switches to `zirconium-nvidia:latest`

Anaconda modules enabled: Storage, Runtime, Network, Security, Services, Users, Timezone. Subscription disabled.

## Image Configuration and Publishing

### OCI Labels Applied

```
containers.bootc=1
io.artifacthub.package.deprecated=false
io.artifacthub.package.keywords=bootc,niri
io.artifacthub.package.license=AGPL-2.0
io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/237492973?s=400&v=4
org.opencontainers.image.created=<timestamp>
org.opencontainers.image.description=Opinionated niri + bootc image
org.opencontainers.image.source=https://github.com/.../blob/<sha>/Containerfile
org.opencontainers.image.title=<image-name>
org.opencontainers.image.vendor=<org>
org.opencontainers.image.version=latest.<date>
```

### Container Image Signing

Signing: cosign with `SIGNING_SECRET` private key. NOT keyless (no ambient OIDC).
Public key: `cosign.pub` in repo root.
Verification policy: `/usr/share/factory/etc/containers/policy.json` requires sigstore verification for `ghcr.io/zirconium-dev` using 3 public keys.
Sigstore attachment config: `registries.d/zirconium-dev.yaml` enables attachments.

## Renovate Bot

Config: `.github/renovate.json5`

- Uses `config:best-practices` preset
- Submodules enabled for auto-updates
- Auto-merges pin/pinDigest updates
- Disables digest/pin updates for container deps in workflow files

## Build Quirks Summary

- **Podman annotation bug**: `https://github.com/containers/podman/issues/27796` — images must be pushed twice for layer annotations to appear. Affects both per-platform images and manifest pushes.
- **Old podman on runners**: GH ubuntu-24.04 runners ship a podman too old for layer annotations. Workaround: install podman from Homebrew (brew cache).
- **Docker for cosign**: An old docker is needed specifically for cosign login (separate from podman).
- **Manifest job in container**: The manifest job runs in an `alpine:latest` container with `--privileged` for podman operations. Must install podman, docker, and tools from apk.
- **Cache permissions**: After build, `mkosi.cache/` permissions must be fixed (`chmod 777 -R`) to avoid CI cache restore issues.
- **Timestamp-based versions**: Date tags use UTC (`date -u`).
