# Up-to-Date Documentation Sources

## Web fetch targets

Fetch current docs from the DMS website. These pages are maintained and always current:

| URL | Content |
|-----|---------|
| `https://danklinux.com/docs/dankmaterialshell/installation` | Install guide for all distros |
| `https://danklinux.com/docs/dankmaterialshell/keybinds-ipc` | CLI commands and IPC reference |
| `https://danklinux.com/docs/dankmaterialshell/compositors` | Per-compositor configuration |
| `https://danklinux.com/docs/dankmaterialshell/application-themes` | App theming (GTK, Qt, terminals, editors) |
| `https://danklinux.com/docs/dankmaterialshell/custom-themes` | Custom theme creation guide |
| `https://danklinux.com/docs/dankmaterialshell/plugins-overview` | Plugin development guide |
| `https://plugins.danklinux.com` | Plugin registry (browse, install) |

**Generic doc root**: `https://danklinux.com/docs/` — table of contents for all guides.

## Codebase search patterns

To find things in the repo that aren't in docs:

| What you need | Search pattern |
|---------------|----------------|
| All IPC targets and methods | `rg "case \"\.\w+\"" core/internal/server/router.go` |
| Available settings keys | `rg "property\s+\w+\s+\w+:" quickshell/Common/SettingsData.qml` |
| Compositor-specific env vars | `rg "Getenv\|os\.Getenv\|env\(" core/cmd/dms/commands_doctor.go` |
| Matugen template configs | `ls quickshell/matugen/configs/*.toml` |
| Registered IPC modules | `rg "router\[\"\w+\"\]" core/internal/server/router.go` |
| QML service singletons | `ls quickshell/Services/*.qml` |
| Available CLI commands | `rg "func init\(\)" core/cmd/dms/` |
| D-Bus interfaces used | `rg "org\.\w+" core/internal/ --include '*.go' \| rg "bus\.Object\|conn\.Object"` |
| Plugin manifest fields | `cat quickshell/PLUGINS/plugin-schema.json` |
| Settings version | `rg "settingsConfigVersion" quickshell/Common/SettingsData.qml` |

## Known stale info

These facts are stable and safe to use from the skill body:
- Config file paths and search order
- Environment variables
- IPC socket path format
- Plugin directory structure
- Compositor detection env vars
- CLI command structure (though subcommands may change)
