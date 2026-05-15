#!/bin/bash
set -oue pipefail
[[ -n "${DEBUG:-}" ]] && set -x

DRY_RUN="${DRY_RUN:-false}"

echo "::group:: ===GNOME detection${DRY_RUN:+ (DRY RUN)}==="

# ---------------------------------------------------------------------------
# Keep list  —  gnome-* packages that provide system-wide services and
# should NOT be removed. These are not GNOME-desktop functionality.
# ---------------------------------------------------------------------------
KEEP_LIST=(
    gnome-keyring          # Secret Service provider
    gnome-keyring-pam      # PAM auto-unlock integration
    gnome-disk-utility     # Disk management GUI (system utility)
)

# ---------------------------------------------------------------------------
# Non-gnome- GNOME packages to explicitly remove
# ---------------------------------------------------------------------------
TARGET_NON_GNOME=(
    gdm                    # Login manager  →  greetd
    ptyxis                 # Terminal       →  foot
)

# ---------------------------------------------------------------------------
# GNOME packages added by bluefin  →  always remove
# ---------------------------------------------------------------------------
EXTRA_REMOVE=(
    adw-gtk3-theme         # libadwaita theme (GNOME-only, not gnome- prefix)
    nautilus-gsconnect     # KDE Connect GNOME integration (not gnome- prefix)
    firewall-config        # GNOME firewall frontend (not gnome- prefix)
)

# ---------------------------------------------------------------------------
# Step 1 — Detect Fedora version (for reporting only)
# ---------------------------------------------------------------------------
source /usr/lib/os-release
FEDORA_VERSION="${VERSION_ID%%.*}"
echo "Fedora ${FEDORA_VERSION}"

# ---------------------------------------------------------------------------
# Step 2 — Categorize installed packages
# ---------------------------------------------------------------------------

# 2a — Find all installed gnome-* packages (minus keep list)
declare -a REMOVE_GNOME_PREFIX=()

while IFS= read -r pkg; do
    skip=false
    for keep in "${KEEP_LIST[@]}"; do
        [[ "$pkg" == "$keep" ]] && { skip=true; break; }
    done
    $skip || REMOVE_GNOME_PREFIX+=("$pkg")
done < <(rpm -qa --queryformat='%{NAME}\n' | grep '^gnome-' | sort)

# 2b — Targeted non-gnome- packages
declare -a REMOVE_TARGETED=()

for pkg in "${TARGET_NON_GNOME[@]}"; do
    rpm -q "$pkg" &>/dev/null && REMOVE_TARGETED+=("$pkg")
done

# 2c — Bluefin extras
declare -a REMOVE_EXTRA=()

for pkg in "${EXTRA_REMOVE[@]}"; do
    rpm -q "$pkg" &>/dev/null && REMOVE_EXTRA+=("$pkg")
done

# 2d — Kept gnome-* packages (for reporting)
declare -a KEPT=()

for keep in "${KEEP_LIST[@]}"; do
    rpm -q "$keep" &>/dev/null && KEPT+=("$keep")
done

# ---------------------------------------------------------------------------
# Step 3 — (Optional) Compose comps XML for supplementary reporting
# ---------------------------------------------------------------------------
# Fetch comps to show what other GNOME-group packages are on the system
# that WON'T be removed (because they're system infrastructure, not gnome-
# named).  This is informative only — the removal list does NOT depend on it.

COMPS_OK=false

for MIRROR_BASE in \
    "https://mirror.math.princeton.edu/pub/fedora/linux/releases/${FEDORA_VERSION}" \
    "https://dl.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}" \
    "https://mirror.math.princeton.edu/pub/fedora/linux/development/${FEDORA_VERSION}"; do

    REPO_URL="${MIRROR_BASE}/Everything/x86_64/os"
    REPOMD_URL="${REPO_URL}/repodata/repomd.xml"

    REPOMD=$(curl -sL --max-time 15 "${REPOMD_URL}" 2>/dev/null)
    [ -z "$REPOMD" ] && continue

    COMPS_HREF=$(echo "$REPOMD" |
        grep -oP 'href="repodata/\K[^"]*-comps-Everything\.x86_64\.xml[^"]*' |
        head -1)
    [ -z "$COMPS_HREF" ] && continue

    curl -sL --max-time 60 "${REPO_URL}/repodata/${COMPS_HREF}" \
        -o /tmp/comps.zst 2>/dev/null
    [ ! -f /tmp/comps.zst ] && continue

    case "${COMPS_HREF}" in
        *.zst) zstd -d /tmp/comps.zst -o /tmp/comps.xml -q -f 2>/dev/null ;;
        *.gz)  gunzip -c /tmp/comps.zst > /tmp/comps.xml 2>/dev/null ;;
        *)     mv /tmp/comps.zst /tmp/comps.xml ;;
    esac

    if [ -f /tmp/comps.xml ] && [ -s /tmp/comps.xml ]; then
        COMPS_OK=true
        break
    fi
done

if [ "$COMPS_OK" = true ]; then
    # Get all packages from @gnome-desktop + @critical-path-gnome
    python3 > /tmp/gnome-comps.txt <<-'PYEOF'
import xml.etree.ElementTree as ET

tree = ET.parse('/tmp/comps.xml')
root = tree.getroot()
packages = set()

for group in root.iter('group'):
    gid = group.find('id')
    if gid is not None and gid.text and gid.text in {
        'critical-path-gnome', 'gnome-desktop'
    }:
        pkgs = group.find('packagelist')
        if pkgs is not None:
            for p in pkgs.iter('packagereq'):
                if p.text:
                    packages.add(p.text.strip())

for pkg in sorted(packages):
    print(pkg)
PYEOF

    mapfile -t COMPS_PACKAGES < /tmp/gnome-comps.txt

    # Find comps packages installed on system but NOT handled by our rules
    # (these are non-gnome- system infrastructure that we intentionally skip)
    declare -a COMPS_LEFT=()
    for pkg in "${COMPS_PACKAGES[@]}"; do
        # Skip if it starts with gnome- (handled above)
        [[ "$pkg" =~ ^gnome- ]] && continue
        # Skip if it's in our targeted list
        for t in "${TARGET_NON_GNOME[@]}"; do
            [[ "$pkg" == "$t" ]] && continue 2
        done
        # Skip extras
        for e in "${EXTRA_REMOVE[@]}"; do
            [[ "$pkg" == "$e" ]] && continue 2
        done
        # Skip keep-list entries (they're gnome-* but just in case)
        for k in "${KEEP_LIST[@]}"; do
            [[ "$pkg" == "$k" ]] && continue 2
        done
        # If installed, add to reporting list
        rpm -q "$pkg" &>/dev/null && COMPS_LEFT+=("$pkg")
    done
fi

# ---------------------------------------------------------------------------
# Step 4 — Report
# ---------------------------------------------------------------------------
total_remove=$(( ${#REMOVE_GNOME_PREFIX[@]} + ${#REMOVE_TARGETED[@]} + ${#REMOVE_EXTRA[@]} ))

echo ""
echo "=== GNOME Removal Plan ==="
echo "Fedora: ${FEDORA_VERSION}"
echo "Strategy: remove gnome-* packages + known GNOME packages"
echo "           (system infrastructure from @gnome-desktop is LEFT alone)"
echo ""
echo "Packages to remove: ${total_remove}"
echo "  gnome-* prefix:     ${#REMOVE_GNOME_PREFIX[@]}"
echo "  targeted:           ${#REMOVE_TARGETED[@]}"
echo "  bluefin additions:  ${#REMOVE_EXTRA[@]}"
echo "Kept (gnome-* infra): ${#KEPT[@]}"
echo ""

if [ ${#REMOVE_GNOME_PREFIX[@]} -gt 0 ]; then
    echo "=== REMOVE: gnome-* packages (${#REMOVE_GNOME_PREFIX[@]}) ==="
    for pkg in "${REMOVE_GNOME_PREFIX[@]}"; do printf '  %s\n' "$pkg"; done
    echo ""
fi

if [ ${#REMOVE_TARGETED[@]} -gt 0 ]; then
    echo "=== REMOVE: targeted (${#REMOVE_TARGETED[@]}) ==="
    for pkg in "${REMOVE_TARGETED[@]}"; do printf '  %s\n' "$pkg"; done
    echo ""
fi

if [ ${#REMOVE_EXTRA[@]} -gt 0 ]; then
    echo "=== REMOVE: bluefin additions (${#REMOVE_EXTRA[@]}) ==="
    for pkg in "${REMOVE_EXTRA[@]}"; do printf '  %s\n' "$pkg"; done
    echo ""
fi

if [ ${#KEPT[@]} -gt 0 ]; then
    echo "=== KEPT (gnome-* infrastructure) (${#KEPT[@]}) ==="
    for pkg in "${KEPT[@]}"; do printf '  %s\n' "$pkg"; done
    echo ""
fi

if [ "$COMPS_OK" = true ] && [ ${#COMPS_LEFT[@]} -gt 0 ]; then
    echo "=== LEFT INSTALLED: from @gnome-desktop groups (${#COMPS_LEFT[@]}) ==="
    echo "   These are system libraries/tools, not GNOME-desktop."
    echo "   They appear in comps but are NOT removed."
    for pkg in "${COMPS_LEFT[@]}"; do printf '  %s\n' "$pkg"; done
    echo ""
fi

# ---------------------------------------------------------------------------
# Step 5 — Execute or dry-run
# ---------------------------------------------------------------------------
ALL_REMOVE=("${REMOVE_GNOME_PREFIX[@]}" "${REMOVE_TARGETED[@]}" "${REMOVE_EXTRA[@]}")

if $DRY_RUN; then
    echo "DRY RUN — no changes made."
    echo "Set DRY_RUN=false or unset to execute removal."
elif [ ${#ALL_REMOVE[@]} -gt 0 ]; then
    echo "Removing ${#ALL_REMOVE[@]} packages..."
    dnf remove -y "${ALL_REMOVE[@]}" && rm -rf /usr/share/gnome-shell/extensions/*
else
    echo "No GNOME packages to remove."
fi

echo "::endgroup::"
