---
name: niri-config-usage
description: |-
  Configure and use the niri scrollable-tiling Wayland compositor. Covers the KDL config file format,
  all config sections (input, output, layout, binds, window rules, layer rules, animations, gestures),
  hotkeys, the windowed dev mode, session startup, IPC with `niri msg`, and where to find the latest
  documentation. Use proactively when user asks about niri setup, configuration, keybinds, or usage.

  Examples:
  - user: "Set up niri on Fedora" → install deps, create ~/.config/niri/config.kdl, start with niri-session
  - user: "How do I configure my touchpad in niri?" → edit input.touchpad section in config.kdl
  - user: "Add a keybind to niri" → add a binds section entry with Mod+Key { action; }
  - user: "Make Firefox PIP floating in niri" → add a window-rule with match + open-floating true
  - user: "How do I take screenshots in niri?" → use Print keybind or `niri msg action screenshot`
  - user: "Fix niri lag on hybrid GPU laptop" → set render-drm-device in debug section
  - user: "Get the latest niri config documentation" → fetch https://niri-wm.github.io/niri/ or read docs/wiki/
---
# niri Configuration & Usage

## Key Concepts

- **Scrollable-tiling**: Windows arranged in columns that scroll horizontally. The focused column stays centered.
- **Dynamic workspaces**: Workspaces created on demand. No fixed count. Referenced by index (1-based).
- **Floating windows**: Toggle with `Mod+V`. Useful for dialogs, PIP, etc.
- **Mod key**: `Super` on TTY, `Alt` in windowed mode.
- **IPC**: `niri msg action <name>` — most keybind actions work as IPC commands.

## Quickstart for new sessions

```sh
# Start niri session (recommended: systemd or dinit)
niri-session

# Or in a window (development/testing)
niri
```

Config lives at `~/.config/niri/config.kdl`. The default config is reproduced at `resources/default-config.kdl`.

## Config format (KDL)

All configuration uses [KDL](https://kdl.dev). The canonical reference is `resources/default-config.kdl` in the repo.

Key sections:

| Section | Purpose |
|---------|---------|
| `input { keyboard/touchpad/mouse/trackpoint }` | XKB layout, libinput settings, focus-follows-mouse |
| `output "name" { }` | Resolution, scale, transform, position |
| `layout { }` | Gaps, focus ring, border, shadow, struts, column widths, window heights |
| `binds { }` | Keybindings → actions |
| `window-rule { }` | Per-window overrides (floating, geometry corner radius, block-out, etc.) |
| `layer-rule { }` | Layer-surface positioning rules |
| `spawn-at-startup` / `spawn-sh-at-startup` | Autostart programs |
| `animations { }` | Animation speed, individual curve overrides |
| `gestures { }` | Touchpad/touchscreen gesture mapping |
| `debug { }` | Render device override, damage tracking, FPS overlay |

### Common syntax patterns

```kdl
// Comment with "/-" to disable a node
/-output "eDP-1" {
    scale 2
    mode "1920x1080@120.030"
}

// Window rule — multiple match lines are OR'd
window-rule {
    match app-id=r#"^firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

// Keybind
Mod+Shift+E { quit; }

// Shell command (goes through sh -c)
Mod+Shift+Slash allow-when-locked=true { spawn-sh "pkill orca || exec orca"; }

// Use allow-when-locked for binds that should work on lock screen
XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
```

## IPC reference

```sh
niri msg action <action-name>        # Run any action
niri msg action focus-workspace 1     # Example
niri msg outputs                      # List outputs + modes
niri msg windows                       # List windows
niri msg focused-window                # Focused window info
niri msg version                       # Version string
```

Find all actions in `niri-ipc/src/lib.rs` (the `Action` enum).

## Hotkey patterns

Navigation follows a consistent pattern:
- `Mod+Key` → focus/move in direction
- `Mod+Ctrl+Key` → move column in direction
- `Mod+Shift+Key` → cross-monitor
- `Mod+Shift+Ctrl+Key` → move column to another monitor
- `Mod+{1-9}` → workspace by index
- `Mod+Ctrl+{1-9}` → move column to workspace

See `resources/default-config.kdl` binds section (~lines 349–632) for the complete default layout.

## Recommended companion software (from defaults)

- **Terminal**: Alacritty
- **Launcher**: fuzzel
- **Bar**: waybar
- **Screen locker**: swaylock
- **Notifications**: mako
- **Portal**: xdg-desktop-portal-gnome + xdg-desktop-portal-gtk
- **X11**: xwayland-satellite (built-in integration since 25.08)

## Windows rules

`window-rule` matches by `app-id` (regex), `title` (regex), or both. Multiple matches in one rule are OR'd.
Common actions: `open-floating`, `default-column-width`, `geometry-corner-radius`, `block-out-from "screen-capture"`, `draw-border-with-background`.

## Where to find up-to-date docs

The latest documentation is always at `docs/wiki/` in this repo. Key pages mapped to topics:

| Topic | File |
|-------|------|
| Full config overview | `docs/wiki/Configuration:-Introduction.md` |
| Input devices | `docs/wiki/Configuration:-Input.md` |
| Outputs | `docs/wiki/Configuration:-Outputs.md` |
| Layout & gaps | `docs/wiki/Configuration:-Layout.md` |
| Key bindings | `docs/wiki/Configuration:-Key-Bindings.md` |
| Window rules | `docs/wiki/Configuration:-Window-Rules.md` |
| Layer rules | `docs/wiki/Configuration:-Layer-Rules.md` |
| Animations | `docs/wiki/Configuration:-Animations.md` |
| Gestures | `docs/wiki/Configuration:-Gestures.md` |
| Window effects | `docs/wiki/Window-Effects.md` |
| Floating windows | `docs/wiki/Floating-Windows.md` |
| Named workspaces | `docs/wiki/Configuration:-Named-Workspaces.md` |
| Screencasting | `docs/wiki/Screencasting.md` |
| Xwayland | `docs/wiki/Xwayland.md` |
| Fullscreen/maximize | `docs/wiki/Fullscreen-and-Maximize.md` |
| Tabs | `docs/wiki/Tabs.md` |
| NVIDIA | `docs/wiki/Nvidia.md` |
| Security model | `docs/wiki/Security-Model.md` |
| FAQ | `docs/wiki/FAQ.md` |
| Install/build | `docs/wiki/Getting-Started.md` |

The published website is at `https://niri-wm.github.io/niri/` — fetch it for the latest versioned docs.

## Common pitfalls

- **`--all-features`** is dangerous: enables unbounded profiling memory buffers. Use explicit feature flags instead.
- **Focus ring through transparent windows**: set `prefer-no-csd` or use `draw-border-with-background` window rule.
- **XKB vs niri layout switching**: do NOT bind both xkb options AND niri `switch-layout` to the same key — they fight.
- **NVIDIA black screen**: ensure `nvidia-drm.modeset=1` in kernel cmdline, update drivers, try `render-drm-device` debug option.
- **PipeWire screencast**: requires `xdp-gnome-screencast` feature + xdg-desktop-portal-gnome running.
