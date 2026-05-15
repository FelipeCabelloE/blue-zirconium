---
name: dms-config
description: |-
  Install, configure, and troubleshoot DankMaterialShell across Linux distros and Wayland
  compositors. Covers installation (dankinstall, distro packages, Nix, source), compositor
  setup (niri, Hyprland, Sway, MangoWC, labwc, Scroll), settings management, IPC commands,
  theming (matugen, custom themes), env vars, and debugging (dms doctor, journalctl).
  Use for DMS installation, config editing, compositor integration, debugging, or general
  usage. For plugin development, use dms-plugin-dev skill instead.

  Examples:
  - user: "Install DMS on Fedora" -> detect distro, use dankinstall or COPR, validate via doctor
  - user: "Set up DMS with Hyprland" -> install, configure hyprland.conf with exec-once + IPC keybinds
  - user: "DMS brightness controls not working" -> run dms doctor, check DDC/backlight/logind
  - user: "Create a custom theme" -> create theme JSON with MD3 colors, set in settings.json
  - user: "How do I add IPC keybinds" -> add dms ipc call commands to compositor config
---
# DankMaterialShell Configuration & Usage

## Architecture

- **Go backend** (`core/`) — system integration, IPC server, CLI (`dms`, `dankinstall`)
- **QML frontend** (`quickshell/`) — UI layer consuming IPC from Go backend
- **IPC** — Unix socket JSON-RPC (`/tmp/dms-ipc-<uid>.sock`). All system integration goes through Go. QML services are thin IPC wrappers — no business logic in QML.

## 1. Detect Environment

Before installing or debugging, identify:

### Distribution
- Check `/etc/os-release` `ID` field. Supported families: arch, fedora, debian, ubuntu, opensuse, gentoo, nixos.
- `dms doctor` detects distro automatically.

### Compositor
- **niri**: `$NIRI_SOCKET` set
- **Hyprland**: `$HYPRLAND_INSTANCE_SIGNATURE` set
- **Sway**: `$SWAYSOCK` set
- **MangoWC/dwl**: dwl-ipc-unstable-v2 protocol
- **labwc**: `$LABWC_PID` set
- **Miracle WM**: `$MIRACLESOCK` set
- **Scroll**: uses `$SWAYSOCK` (Sway-compatible)
- River/Wayfire: detected via `--version` checks

### Current config location
Config search order (first match wins):
1. `--config`/`-c` flag
2. Active session state file (`$XDG_RUNTIME_DIR/danklinux.path`)
3. `$XDG_CONFIG_HOME/quickshell/dms/`
4. `$XDG_DATA_DIRS/*/quickshell/dms/`
5. `$XDG_CONFIG_DIRS/*/quickshell/dms/`

## 2. Installation

### dankinstall (recommended)
```bash
curl -fsSL https://install.danklinux.com | sh    # interactive TUI

# Headless (unattended) — requires cached sudo
sudo -v && curl -fsSL https://install.danklinux.com | sh -s -- \
  -c niri -t ghostty --include-deps dms-greeter -y
```

Headless flags: `--compositor` (`-c`), `--term` (`-t`), `--include-deps`, `--exclude-deps`, `--replace-configs`, `--replace-configs-all`, `--yes` (`-y`).
Both `--compositor` and `--term` required in headless mode.
Config files NOT replaced by default — use `--replace-configs` or `--replace-configs-all`.

### Distro packages
| Distro | Package | Source |
|--------|---------|--------|
| Arch | `dms-shell` (extra) / `dms-shell-git` (AUR) | `pacman -S dms-shell` |
| Fedora | `dms-shell` | COPR `avengemedia/danklinux` |
| Debian 13+ | `dms-shell` / `dms-greeter` | OBS |
| Ubuntu | `dms-shell` | PPA |
| openSUSE | `dms-shell` | OBS |
| Gentoo | `gui-apps/dms-shell` | GURU overlay |
| NixOS | flake module | `github:AvengeMedia/DankMaterialShell` |

### Nix flake
```nix
{
  inputs.dms.url = "github:AvengeMedia/DankMaterialShell";
  imports = [ inputs.dms.nixosModules.dank-material-shell ];
  # or for home-manager:
  imports = [ inputs.dms.homeModules.dank-material-shell ];
}
```
NixOS module: `programs.dank-material-shell.enable = true`.
Greeter NixOS module: `nixosModules.greeter` with `programs.dank-material-shell.greeter.enable = true`.

### Build from source
```bash
cd core
make              # builds bin/dms
make dankinstall  # builds bin/dankinstall
make test         # runs Go tests
```
Requires Go 1.26.1+ (from `core/go.mod`).
Distribution build (disables update/greeter features): `make dist` → `bin/dms-linux-amd64` + `bin/dms-linux-arm64`.

## 3. Post-Install Setup

### Systemd service
```bash
systemctl --user enable --now dms
```
Service installed to `~/.config/systemd/user/dms.service`.
View logs: `journalctl --user -u dms.service -f`.

### Compositor autostart

**niri** (`~/.config/niri/config.kdl`): `spawn-at-startup "dms" "run"`
Configs deployed to `~/.config/niri/dms/*.kdl` (colors, layout, binds, outputs, windowrules, cursor, alttab).

**Hyprland** (`~/.config/hypr/hyprland.conf`): `exec-once = dms run`
Configs deployed to `~/.config/hypr/dms/*.conf`. Requires `hyprland-session.target` systemd unit.

**MangoWC** (`~/.config/mango/dms/`): `dms/` subdirectory configs (outputs, layout, cursor).

### Environment variables

| Variable | Purpose |
|----------|---------|
| `DMS_RUN_GREETER` | `1`/`true` to run in greeter mode |
| `DMS_LOG_LEVEL` | `debug`, `info`, `warn`, `error`, `fatal` |
| `DMS_LOG_FILE` | Path for log output |
| `DMS_DISABLE_HOT_RELOAD` | `1` to disable QML hot-reload |
| `DMS_HYPRLAND_EXCLUSIVE_FOCUS` | `1` to disable Hyprland focus hack |
| `DMS_LOCAL_PATH` | Path to dev checkout (greeter sync) |
| `DMS_GREETER_WRAPPER_CMD` | Override greeter wrapper binary |
| `DMS_GREET_CFG_DIR` | Custom greeter cache path |
| `DMS_LOG_PRETTY` | Pretty-print log output |
| `QS_ICON_THEME` | Quickshell icon theme |
| `QT_WAYLAND_FORCE_DPI` | Force DPI override |

Installer writes `~/.config/environment.d/90-dms.conf` setting `TERMINAL` and `ELECTRON_OZONE_PLATFORM_HINT`.

## 4. Configuration Files

| Path | Purpose |
|------|---------|
| `~/.config/DankMaterialShell/settings.json` | Main user settings (versioned, schema in `SettingsData.qml`) |
| `~/.config/DankMaterialShell/plugin_settings.json` | Per-plugin persistent data |
| `~/.config/DankMaterialShell/clsettings.json` | Clipboard history settings |
| `~/.config/DankMaterialShell/themes/<id>/theme.json` | Installed themes |
| `~/.config/DankMaterialShell/matugen/config.toml` | User matugen template overrides |
| `~/.config/DankMaterialShell/plugins/<id>/plugin.json` | Plugin manifests |
| `~/.local/state/DankMaterialShell/session.json` | Session state (wallpaper, per-monitor config) |
| `~/.cache/DankMaterialShell/dms-colors.json` | Current matugen color cache |
| `~/.cache/DankMaterialShell/themes/<id>/` | Theme preview images |

Settings schema lives in `quickshell/Common/SettingsData.qml` (singleton, version `settingsConfigVersion`). Categories: Theme, Layout overrides (per-compositor), Animation (speed, variant, motion), Blur, Bar configs (per-bar: position, widgets, spacing), widget visibility, power management, authentication, matugen template toggles, dock, desktop widgets, etc.

Key settings to know:
- `currentThemeName`: `"default"`, `"custom"`, or installed theme name
- `customThemeFile`: path to custom JSON theme
- `matugenScheme`: matugen scheme variant
- `matugenContrast`: contrast level
- `barConfigs[]`: array of per-monitor bar configurations
- `animationSpeed`: UI animation speed multiplier
- `blurEnabled` / `frameEnabled`: visual effects

## 5. CLI Reference

### Core lifecycle
```bash
dms run [-d]          # start shell (daemon mode)
dms restart            # restart shell
dms kill               # stop shell
dms version            # show version
```

### IPC commands
```bash
dms ipc call <target> <function> [args...]
```
Common targets: `audio`, `brightness`, `night`, `wallpaper`, `spotlight`, `clipboard`, `notifications`, `settings`, `processlist`, `powermenu`, `control-center`, `notepad`, `dash`, `lock`, `inhibit`, `theme`, `bar`, `mpris`, `systemupdater`, `file`, `color-picker`, `hypr`, `profile`, `dankdash`.

Full IPC reference: `docs/IPC.md` in repo, or <https://danklinux.com/docs/dankmaterialshell/keybinds-ipc>.

### Setup & theming
```bash
dms setup                        # full compositor config deployment
dms setup binds|layout|colors    # deploy specific configs
dms matugen generate             # generate theme from wallpaper
dms matugen queue                # queue async theme generation
dms dank16 generate              # terminal-safe 16-color palette
dms color pick                   # native Wayland color picker
dms brightness list|set          # display brightness
```

### System & diagnostics
```bash
dms doctor                       # health check (TUI)
dms doctor --json                # machine-readable
dms doctor --copy                # GitHub-formatted output
dms features                     # available features
dms system update                # update DMS + deps
dms config resolve-include       # resolve compositor config includes
```

### Plugins
```bash
dms plugins browse               # browse registry
dms plugins install <id>         # install from registry
dms plugins list                 # list installed
dms plugins uninstall <id>       # remove
dms plugins update               # update all
```

## 6. IPC Architecture

- **Transport**: Unix socket `$XDG_RUNTIME_DIR/danklinux-<pid>.sock`
- **Protocol**: JSON-RPC over newline-delimited JSON
- **Request**: `{"id": <int>, "method": "<module>.<action>", "params": {...}}`
- **Response**: `{"id": <int>, "result": {...}}` or `{"id": <int>, "error": "<msg>"}`
- **API version**: 24 (`APIVersion` constant)
- **Subscription**: clients can subscribe to streaming events for network, bluetooth, brightness, clipboard, loginctl, gamma, etc.

Server sends capabilities JSON on connect. Agent should discard capabilities and send requests directly.

Test backend independently:
```bash
dms ipc module.action '{"key":"val"}'
```

Implement handler in `core/internal/server/<module>/`, register in `core/internal/server/router.go`, then add QML wrapper.

## 7. Compositor Integration Patterns

### IPC keybinds

**niri** (`~/.config/niri/config.kdl`):
```kdl
binds {
    Mod+Space { spawn "qs" "-c" "dms" "ipc" "call" "spotlight" "toggle"; }
    XF86AudioRaiseVolume { spawn "qs" "-c" "dms" "ipc" "call" "audio" "increment" "3"; }
}
```

**Hyprland** (`~/.config/hypr/hyprland.conf`):
```conf
bind = SUPER, Space, exec, qs -c dms ipc call spotlight toggle
bind = , XF86AudioRaiseVolume, exec, qs -c dms ipc call audio increment 3
bind = SUPER, Tab, exec, qs -c dms ipc call hypr toggleOverview
```

### Per-compositor quirks

**Hyprland only**: `hypr` target (`toggleBinds`, `toggleOverview`). Returns `"HYPR_NOT_AVAILABLE"` on other compositors.

**Per-monitor wallpapers**: Targets specific screens by name (e.g., `DP-2`, `eDP-1`):
```bash
dms ipc call wallpaper setFor DP-2 /path/to/image.jpg
dms ipc call wallpaper getFor eDP-1
```

### Modal IPC targets

All modals support `open`, `close`, `toggle`:
```bash
dms ipc call spotlight toggle      # app launcher
dms ipc call clipboard open        # clipboard history
dms ipc call notifications toggle  # notification center
dms ipc call control-center toggle # quick settings
dms ipc call settings open         # settings modal
dms ipc call powermenu toggle      # power menu
dms ipc call processlist toggle    # system monitor
dms ipc call notepad toggle        # scratchpad notes
dms ipc call dash open overview    # dashboard
```

## 8. Theming

### Color pipeline (3 layers)
1. **Matugen** — generates Material Design 3 colors from wallpaper. 25+ template targets (GTK, niri, hyprland, terminals, firefox, vscode, emacs, zed, etc.) in `quickshell/matugen/configs/*.toml`.
2. **Dank16** — derives ANSI 16-color palette from primary/surface colors for terminal safety.
3. **Theme manager** — installed themes from registry at `~/.config/DankMaterialShell/themes/<id>/`.

### Custom theme JSON
```json
{
  "name": "My Theme",
  "primary": "#00FFCC",
  "surface": "#0F0F0F",
  "surfaceText": "#E0FFE0",
  "surfaceVariant": "#1F2F1F",
  "background": "#000000",
  "backgroundText": "#F0FFF0",
  "error": "#FF0066",
  "matugen_type": "scheme-expressive"
}
```
Set via settings: `currentThemeName: "custom"` + `customThemeFile: "/path/to/theme.json"`.
Editing the file auto-updates the shell.

### Matugen types
`scheme-tonal-spot` (default), `scheme-content`, `scheme-expressive`, `scheme-fidelity`, `scheme-fruit-salad`, `scheme-monochrome`, `scheme-neutral`, `scheme-rainbow`.

### Automation
Night mode automation: `time` (manual schedule) or `location` (sunrise/sunset via geolocation).
Auto theme mode: sync with GNOME portal or manual schedule.

## 9. Debugging

### First step: `dms doctor`
Comprehensive health check covering: OS, Wayland, Go version, QS version, compositor, D-Bus services (accountsservice, logind, cups), brightness subsystems (DDC/backlight), network stack (NetworkManager/iwd/systemd-networkd), CLI tools (matugen, dgop, cava, danksearch, fprintd), config files, systemd services, environment variables, QS features (Polkit, IdleMonitor, BackgroundBlur).

### Common failure points

| Symptom | Check |
|---------|-------|
| IPC not responding | Socket: `ls -la $XDG_RUNTIME_DIR/danklinux-*.sock` |
| | Test: `dms ipc test.ping` |
| | Logs: `journalctl --user -u dms.service -f` |
| D-Bus errors | `busctl --user list \| grep org.bluez` |
| | User must be in video, input groups |
| Wayland protocol | `dms features` for available protocols |
| | `WAYLAND_DEBUG=1 dms run` for protocol trace |
| QML import error | Check `quickshell/.qmlls.ini` exists (generated by `qs -p .`) |
| Build failure | Clean: `cd core && make clean && make` |
| matugen queue stuck | `dms ipc matugen.status` to check |
| QML not hot-reloading | Set `DMS_DISABLE_HOT_RELOAD=0` or restart shell |

### QML logging
Use `log.info/warn/error/debug/fatal("scope", "message")` — NOT `console.*`.
Log service defined in `quickshell/Services/Log.qml`.
Enforced by pre-commit hook (`no console.* in QML`).

## 10. Plugin Management

Four types:
| Type | Description |
|------|-------------|
| `widget` | Bar widget + popout (default if type omitted) |
| `daemon` | Background service, no UI |
| `launcher` | Searchable items in spotlight |
| `desktop` | Draggable on desktop |

Plugin directory: `~/.config/DankMaterialShell/plugins/<PluginName>/`
Each requires `plugin.json` manifest with `id`, `name`, `version`, `component` (`.qml`), optional `settings` (`.qml`).
Registry: <https://plugins.danklinux.com>

CLI: `dms plugins browse|list|install|uninstall|update`.

For plugin *development* (creating new plugins), load the `dms-plugin-dev` skill.

## 11. Authentication / Greeter

Greetd integration runs DMS as a fullscreen login screen.
```bash
dms greeter install              # full install
dms greeter enable               # activate in greetd config
dms greeter sync                 # sync theme/settings/wallpaper to greeter
dms greeter sync --auth          # include fingerprint/U2F
dms greeter sync --local         # use local dev checkout
dms greeter status               # health check
dms greeter uninstall            # remove
```

NixOS: `nixosModules.greeter` with `programs.dank-material-shell.greeter.enable = true`.
PAM: fingerprint (`fprintd`) and U2F support configured via `dms auth sync`.

## 12. Keeping Information Current

For always-up-to-date guidance, fetch from:
- <https://danklinux.com/docs/dankmaterialshell/installation>
- <https://danklinux.com/docs/dankmaterialshell/keybinds-ipc>
- <https://danklinux.com/docs/dankmaterialshell/compositors>
- <https://danklinux.com/docs/dankmaterialshell/application-themes>
- <https://danklinux.com/docs/dankmaterialshell/custom-themes>
- <https://danklinux.com/docs/dankmaterialshell/plugins-overview>
- <https://plugins.danklinux.com>

For codebase exploration, see `references/docs-sources.md`.
