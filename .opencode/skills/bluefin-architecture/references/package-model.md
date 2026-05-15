# Package Security Model

## Why two arrays?

COPR repositories can ship packages with the same name as Fedora packages. If a COPR is globally enabled and a user runs `dnf install fedora-package`, the COPR's version may be installed instead — potentially a malicious fork.

Bluefin prevents this by **never leaving COPR repos enabled**.

## FEDORA_PACKAGES

Array in `04-packages.sh` and `00-dx.sh`:

```bash
FEDORA_PACKAGES=(
    fish
    just
    tmux
    ...
)
```

Installed in a single `dnf -y install "${FEDORA_PACKAGES[@]}"` command. These come from official Fedora repos only — safe from injection.

## COPR_PACKAGES

Packages from third-party COPR repos. Installed individually via `copr_install_isolated()`:

```bash
copr_install_isolated "ublue-os/packages" "uupd"
copr_install_isolated "che/nerd-fonts" "nerd-fonts"
```

### copr_install_isolated() internals

Defined in `build_files/shared/copr-helpers.sh`:

```bash
copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")
    repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

    dnf5 -y copr enable "$copr_name"          # Step 1: enable
    dnf5 -y copr disable "$copr_name"         # Step 2: immediately disable
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"  # Step 3: install with explicit repo
}
```

This ensures the COPR repo is only active for the specific package install command.

## Third-party repos (non-COPR)

Handled manually with the same enable→disable pattern:

```bash
# Tailscale
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

# Docker (dx only)
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install --enablerepo=docker-ce-stable containerd.io docker-ce ...

# VS Code (dx only)
tee /etc/yum.repos.d/vscode.repo <<'EOF'
...
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
dnf -y install --enablerepo=code code
```

## FWUPD override

```bash
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging fwupd fwupd
```

Uses the same pattern to swap the Fedora `fwupd` with the `ublue-os/staging` version (fixes hardware detection).

## Validated repos policy

After all packages are installed, `validate-repos.sh` iterates every `.repo` file and checks for `enabled=1`. If any enabled repo is found, the build **fails**. This is a security gate — no YUM repo may remain active on the shipped image.

Known allowed exceptions:
- `fedora-updates-testing.repo` enabled only when `UBLUE_IMAGE_TAG=beta`
- Standard `fedora.repo`, `fedora-updates.repo` (these are always enabled and are the expected Fedora base)

## Package exclusions

```bash
EXCLUDED_PACKAGES=(
    cosign
    fedora-bookmarks
    fedora-chromium-config
    firefox
    gnome-software
    podman-docker
    ...
)
```

Unwanted packages are removed if present. `rpm -qa --queryformat='%{NAME}\n'` checks for installed state before removal (prevents errors for already-absent packages).
