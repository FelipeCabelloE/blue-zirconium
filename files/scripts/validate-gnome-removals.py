#!/usr/bin/python3
"""Validate GNOME removal for blue-zirconium.

Modes:
  Build-time (default) — Phase 1 + Phase 3: reports removal set,
    cross-references comps, checks kept-package integrity and dependencies.
  --container-check — Phase 2: mounts this script into the base image
    container and runs with --inside-container to do dnf remove --dry-run.
"""

import argparse
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "gnome-removal-config.json")
COMPS_CANDIDATES = [
    os.path.normpath(os.path.join(SCRIPT_DIR, "..", "comps-f44.xml.in")),
    os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", "comps-f44.xml.in")),
]


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def rpm_installed(pkg):
    return subprocess.run(["rpm", "-q", pkg], capture_output=True).returncode == 0


def get_installed_gnome():
    r = subprocess.run(
        ["rpm", "-qa", "--queryformat=%{NAME}\n"], capture_output=True, text=True
    )
    return sorted(p for p in r.stdout.strip().splitlines() if p.startswith("gnome-"))


def parse_comps():
    for path in COMPS_CANDIDATES:
        if os.path.exists(path):
            try:
                tree = ET.parse(path)
                groups = {}
                for group in tree.getroot().iter("group"):
                    gid = group.find("id")
                    if gid is not None and gid.text in (
                        "gnome-desktop",
                        "critical-path-gnome",
                    ):
                        pkgs = group.find("packagelist")
                        if pkgs is not None:
                            groups[gid.text] = sorted(
                                p.text for p in pkgs.iter("packagereq") if p.text
                            )
                return groups
            except ET.ParseError:
                pass
    return None


def phase1_report(config, comps, installed_gnome):
    keep_set = set(config["keep_list"])
    target_set = set(config["target_non_gnome"])
    extra_set = set(config["extra_remove"])

    gnome_remove = [p for p in installed_gnome if p not in keep_set]
    gnome_kept = [p for p in installed_gnome if p in keep_set]

    print("=" * 60)
    print("GNOME REMOVAL VALIDATION REPORT")
    print("=" * 60)

    print(f"\nConfig ({CONFIG_PATH}):")
    print(f"  Keep list:           {len(config['keep_list'])} packages")
    print(f"  Targeted non-gnome:   {len(target_set)} packages")
    print(f"  Bluefin extras:      {len(extra_set)} packages")

    print(f"\nInstalled gnome-* packages: {len(installed_gnome)}")
    if gnome_remove:
        print("  REMOVE:")
        for p in gnome_remove:
            print(f"    {p}")
    if gnome_kept:
        print("  KEPT (infrastructure):")
        for p in gnome_kept:
            print(f"    {p}")

    found_targeted = [p for p in config["target_non_gnome"] if rpm_installed(p)]
    found_extra = [p for p in config["extra_remove"] if rpm_installed(p)]
    if found_targeted:
        print("\n  Targeted (found installed):")
        for p in found_targeted:
            print(f"    {p}")
    if found_extra:
        print("  Bluefin extras (found installed):")
        for p in found_extra:
            print(f"    {p}")

    if comps:
        for group_name, pkgs in comps.items():
            removed = [
                p
                for p in pkgs
                if (p.startswith("gnome-") and p not in keep_set)
                or p in target_set
                or p in extra_set
            ]
            kept = sorted(set(pkgs) - set(removed))
            intersection = sorted(set(pkgs) - set(kept))
            print(f"\nComps @{group_name}: {len(pkgs)} total")
            if intersection:
                print(f"  Packages handled by removal: {len(intersection)}")
            if kept:
                print(f"  System infra left installed: {len(kept)}")


def phase3_check_kept(config):
    missing = [p for p in config["keep_list"] if not rpm_installed(p)]
    if missing:
        print(f"\nFAIL: Kept packages missing: {', '.join(missing)}")
    return missing


def phase3_check_deps():
    r = subprocess.run(["dnf", "check"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"\nFAIL: dnf check found issues:\n{r.stdout}{r.stderr}")
        return False
    return True


def phase3_check_whatrequires(config, installed_gnome):
    keep_set = set(config["keep_list"])
    target_set = set(config["target_non_gnome"])
    extra_set = set(config["extra_remove"])
    all_config_remove_names = set(installed_gnome) - keep_set | target_set | extra_set

    problems = []
    for pkg in sorted(all_config_remove_names):
        if rpm_installed(pkg):
            continue
        r = subprocess.run(
            ["rpm", "-q", "--whatrequires", pkg],
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            continue
        requires = [
            line.strip()
            for line in r.stdout.strip().splitlines()
            if line.strip() and "no package requires" not in line
        ]
        if requires:
            problems.append((pkg, requires))

    if problems:
        print("\nFAIL: Removed packages still required by remaining packages:")
        for pkg, reqs in problems:
            print(f"  {pkg} needed by: {', '.join(reqs)}")
    return problems


def container_main(config_path):
    """Runs inside the base-image container.  Reads config, computes removal
    set, runs dnf remove --dry-run, reports result."""
    with open(config_path) as f:
        config = json.load(f)

    keep_set = set(config["keep_list"])
    r = subprocess.run(
        ["rpm", "-qa", "--queryformat=%{NAME}\n"], capture_output=True, text=True
    )
    installed_gnome = sorted(
        p for p in r.stdout.strip().splitlines() if p.startswith("gnome-")
    )

    gnome_remove = [p for p in installed_gnome if p not in keep_set]
    all_remove = list(gnome_remove)
    for lst in (config["target_non_gnome"], config["extra_remove"]):
        for pkg in lst:
            if subprocess.run(["rpm", "-q", pkg], capture_output=True).returncode == 0:
                all_remove.append(pkg)

    print("=== Container Validation ===")
    print(f"Packages to remove: {len(all_remove)}")
    for p in all_remove:
        print(f"  {p}")

    if not all_remove:
        print("No GNOME packages found in this image.")
        return 0

    print()
    print("Running dnf remove --dry-run...")
    r = subprocess.run(
        ["dnf", "remove", "--dry-run", "-y"] + all_remove,
        capture_output=True,
        text=True,
    )
    print(r.stdout)
    if r.returncode != 0:
        print(f"FAIL: {r.stderr}")
        return 1
    print("PASS: No dependency conflicts")
    return 0


def phase2_container_dry_run(image):
    script = os.path.abspath(__file__)
    cmd = [
        "podman",
        "run",
        "--rm",
        "-v",
        f"{CONFIG_PATH}:/config.json:ro",
        "-v",
        f"{script}:/validate.py:ro",
        image,
        "python3",
        "/validate.py",
        "--inside-container",
    ]
    sys.exit(subprocess.run(cmd).returncode)


def main():
    parser = argparse.ArgumentParser(
        description="Validate GNOME removal for blue-zirconium"
    )
    parser.add_argument(
        "--container-check",
        action="store_true",
        help="Run full validation against base image via podman",
    )
    parser.add_argument(
        "--inside-container",
        action="store_true",
        help="Running inside base-image container (invoked by --container-check)",
    )
    parser.add_argument(
        "--image",
        default="ghcr.io/ublue-os/bluefin-dx:latest",
        help="Base image reference (default: %(default)s)",
    )
    args = parser.parse_args()

    if args.inside_container:
        sys.exit(container_main("/config.json"))

    if args.container_check:
        phase2_container_dry_run(args.image)
        return

    config = load_config()
    comps = parse_comps()
    installed_gnome = get_installed_gnome()
    phase1_report(config, comps, installed_gnome)

    issues = []
    issues.extend(phase3_check_kept(config))
    if not phase3_check_deps():
        issues.append("dependency check failed")
    wr_issues = phase3_check_whatrequires(config, installed_gnome)
    if wr_issues:
        for pkg, reqs in wr_issues:
            issues.append(f"{pkg} still required by: {', '.join(reqs)}")

    if issues:
        print(f"\nFAILED: {len(issues)} issue(s)")
        sys.exit(1)
    print("\nPASS: All validations OK")


if __name__ == "__main__":
    main()
