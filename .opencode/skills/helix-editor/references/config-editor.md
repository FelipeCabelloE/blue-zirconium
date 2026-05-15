# `[editor]` Configuration Reference

Complete reference for all `[editor]` settings in `config.toml`. See `config-keymaps.md` for `[keys.*]` and `config-themes.md` for `[theme]`.

---

## Primitive fields

| Key | Type | Default | Description |
|---|---|---|---|
| `scrolloff` | `usize` | `5` | Padding lines between cursor and screen edge |
| `scroll-lines` | `isize` | `3` | Lines to scroll per scroll event |
| `mouse` | `bool` | `true` | Enable mouse support |
| `mouse-yank-register` | `char` | `'*'` | Register used for mouse middle-click yank |
| `middle-click-paste` | `bool` | `true` | Enable middle-click paste |
| `shell` | `[String]` | `["sh", "-c"]` / `["cmd", "/C"]` | Shell command and argument |
| `cursorline` | `bool` | `false` | Highlight cursor line |
| `cursorcolumn` | `bool` | `false` | Highlight cursor column |
| `auto-completion` | `bool` | `true` | Auto-popup LSP completions |
| `path-completion` | `bool` | `true` | File path completion |
| `auto-format` | `bool` | `true` | Format on save |
| `default-yank-register` | `char` | `'"'` | Default yank/paste register |
| `text-width` | `usize` | `80` | Global text width |
| `idle-timeout` | `u64` (ms) | `250` | Idle timer before UI updates |
| `completion-timeout` | `u64` (ms) | `250` | Delay before auto-completion |
| `preview-completion-insert` | `bool` | `true` | Insert completion on hover |
| `completion-trigger-len` | `u8` | `2` | Min chars before completion triggers |
| `completion-replace` | `bool` | `false` | LSP replaces entire word (vs insert) |
| `continue-comments` | `bool` | `true` | Auto-continue line comments on Enter |
| `auto-info` | `bool` | `true` | Display infoboxes |
| `true-color` | `bool` | `false` | Override truecolor detection |
| `undercurl` | `bool` | `false` | Override undercurl detection |
| `color-modes` | `bool` | `false` | Color the mode indicator |
| `workspace-lsp-roots` | `[PathBuf]` | `[]` | Ceiling dirs for LSP workspace detection |
| `insert-final-newline` | `bool` | `true` | Auto-insert trailing newline on save |
| `atomic-save` | `bool` | `true` | Use atomic writes |
| `trim-final-newlines` | `bool` | `false` | Remove trailing newlines past one on save |
| `trim-trailing-whitespace` | `bool` | `false` | Remove trailing whitespace on save |
| `editor-config` | `bool` | `true` | Read `.editorconfig` files |
| `rainbow-brackets` | `bool` | `false` | Rainbow bracket coloring |
| `insecure` | `bool` | `false` | Trust all workspaces implicitly (skips trust prompts) |

---

## Enum fields

| Key | Type | Default | Valid values |
|---|---|---|---|
| `line-number` | `LineNumber` | `"absolute"` | `"absolute"`, `"relative"` |
| `bufferline` | `BufferLine` | `"never"` | `"never"`, `"always"`, `"multiple"` |
| `popup-border` | `PopupBorderConfig` | `"none"` | `"none"`, `"all"`, `"popup"`, `"menu"` |
| `indent-heuristic` | `IndentationHeuristic` | `"hybrid"` | `"simple"`, `"tree-sitter"`, `"hybrid"` |
| `clipboard-provider` | `ClipboardProvider` | auto-detected | See below |
| `end-of-line-diagnostics` | `DiagnosticFilter` | `"hint"` | `"disable"`, `"hint"`, `"info"`, `"warning"`, `"error"` |
| `default-line-ending` | `LineEndingConfig` | `"native"` | `"native"`, `"lf"`, `"crlf"` (with `unicode-lines`: `"ff"`, `"cr"`, `"nel"`) |
| `kitty-keyboard-protocol` | `KittyKeyboardProtocolConfig` | `"auto"` | `"auto"`, `"disabled"`, `"enabled"` |

### DiagnosticFilter values

| String | Shows |
|---|---|
| `"disable"` | Nothing |
| `"hint"` | Hints + everything above |
| `"info"` | Info + warning + error |
| `"warning"` | Warning + error |
| `"error"` | Errors only |

---

## Sub-config structs

### `[editor.gutters]`

```toml
[editor.gutters]
layout = ["diagnostics", "spacer", "line-numbers", "spacer", "diff"]
line-numbers = { min-width = 3 }
```

**`layout` elements:**
| Value | Panel |
|---|---|
| `"diagnostics"` | Diagnostic icons |
| `"line-numbers"` | Line numbers |
| `"spacer"` | Spacer gap |
| `"diff"` | Diff indicators |

### `[editor.auto-pairs]`

```toml
# Boolean shorthand
auto-pairs = true

# Custom pairs
[editor.auto-pairs]
"(" = ")"
"{" = "}"
"[" = "]"
"'" = "'"
```

### `[editor.word-completion]`

```toml
[editor.word-completion]
enable = true
trigger-length = 7       # min chars before word completion shows
```

### `[editor.auto-save]`

```toml
# Shorthand (same as focus-lost = true)
auto-save = true

# Full config
[editor.auto-save]
after-delay = { enable = false, timeout = 3000 }  # ms
focus-lost = false
```

### `[editor.file-picker]`

```toml
[editor.file-picker]
hidden = true               # hide dotfiles
follow-symlinks = true
deduplicate-links = true    # hide symlinks pointing into cwd
parents = true              # read ignore files from parent dirs
ignore = true               # respect .ignore
git-ignore = true           # respect .gitignore
git-global = true           # respect global gitignore
git-exclude = true          # respect .git/info/exclude
max-depth = <int>           # optional max recursion depth
```

### `[editor.file-explorer]`

```toml
[editor.file-explorer]
hidden = false
follow-symlinks = false
parents = false
ignore = false
git-ignore = false
git-global = false
git-exclude = false
flatten-dirs = true         # flatten single-child dirs
```

### `[editor.lsp]`

```toml
[editor.lsp]
enable = true
display-progress-messages = false   # show $/progress
display-messages = true             # show window/showMessage
auto-signature-help = true
display-signature-help-docs = true
display-inlay-hints = false
auto-document-highlight = false
inlay-hints-length-limit = <int>    # optional max chars
display-color-swatches = true
snippets = true
goto-reference-include-declaration = true
```

### `[editor.search]`

```toml
[editor.search]
smart-case = true           # case-insensitive unless uppercase in pattern
wrap-around = true
```

### `[editor.statusline]`

```toml
[editor.statusline]
left = ["mode", "spinner", "file-name", "read-only-indicator", "file-modification-indicator"]
center = []
right = ["diagnostics", "selections", "register", "position", "file-encoding"]
separator = "│"

[editor.statusline.mode]
normal = "NOR"
insert = "INS"
select = "SEL"

[editor.statusline.diagnostics]
severities = ["warning", "error"]

[editor.statusline.workspace-diagnostics]
severities = ["warning", "error"]
```

**StatusLineElement values:**
| Value | Shows |
|---|---|
| `"mode"` | Current mode (NOR/INS/SEL) |
| `"spinner"` | LSP activity spinner |
| `"file-name"` | Relative file path |
| `"file-base-name"` | Basename only |
| `"file-absolute-path"` | Full path |
| `"file-modification-indicator"` | Modified indicator |
| `"read-only-indicator"` | `[readonly]` |
| `"file-encoding"` | Encoding |
| `"file-line-ending"` | CRLF/LF |
| `"file-indent-style"` | Tabs/spaces |
| `"file-type"` | Language ID |
| `"diagnostics"` | Error/warning count |
| `"workspace-diagnostics"` | Workspace error/warning |
| `"selections"` | Cursor count |
| `"primary-selection-length"` | Chars in primary selection |
| `"position"` | Cursor position |
| `"position-percentage"` | Cursor % in file |
| `"separator"` | Separator string |
| `"spacer"` | Space |
| `"total-line-numbers"` | Total lines |
| `"version-control"` | VCS info |
| `"register"` | Active register indicator |
| `"current-working-directory"` | CWD |

### `[editor.cursor-shape]`

```toml
[editor.cursor-shape]
normal = "block"
insert = "bar"
select = "underline"
```

**CursorKind values:** `"block"`, `"bar"`, `"underline"`, `"hidden"`

### `[editor.soft-wrap]`

```toml
[editor.soft-wrap]
enable = false
max-wrap = 20                # max chars per wrapped line
max-indent-retain = 40       # max indent to preserve on wrap
wrap-indicator = "↪"         # wrap indicator char
wrap-at-text-width = false   # wrap at text-width instead of screen edge
```

### `[editor.whitespace]`

```toml
# Simple: render all or none
[editor.whitespace]
render = "all"   # or "none"

# Per-character control
[editor.whitespace.render]
default = "none"   # optional
space = "none"
nbsp = "none"
nnbsp = "none"
tab = "none"
newline = "none"

# Custom characters
[editor.whitespace.characters]
space = "·"      # U+00B7
nbsp = "⍽"       # U+237D
nnbsp = "␣"      # U+2423
tab = "→"        # U+2192
tabpad = " "     # trailing tab fill
newline = "⏎"    # U+23CE
```

### `[editor.indent-guides]`

```toml
[editor.indent-guides]
render = false
character = "│"
skip-levels = 0
```

### `[editor.smart-tab]`

```toml
[editor.smart-tab]
enable = true
supersede-menu = false    # tab dismisses completion menu
```

### `[editor.terminal]`

```toml
[editor.terminal]
command = "kitty"
args = []
```

Auto-detected (in order): tmux (if in tmux), WezTerm, Windows Terminal, conhost.

### `[editor.buffer-picker]`

```toml
[editor.buffer-picker]
start-position = "current"   # or "previous"
```

### `[editor.inline-diagnostics]`

```toml
[editor.inline-diagnostics]
cursor-line = "warning"         # DiagnosticFilter
other-lines = "disable"         # DiagnosticFilter
min-diagnostic-width = 40
prefix-len = 1
max-wrap = 20
max-diagnostics = 10
```

### `[editor.popup-border]`

| Value | Effect |
|---|---|
| `"none"` | No border |
| `"all"` | Border on all popups |
| `"popup"` | Border on doc popups |
| `"menu"` | Border on completion menus |

### Clipboard providers

```toml
# String provider name
clipboard-provider = "xclip"

# Or custom command
[editor.clipboard-provider]
yank = { command = "xclip", args = ["-selection", "clipboard"] }
paste = { command = "xclip", args = ["-selection", "clipboard", "-o"] }
# yank-primary / paste-primary — optional for primary selection
```

**Built-in provider names:**
| Name | Platform |
|---|---|
| `"pasteboard"` | macOS |
| `"wayland"` | Linux (wl-copy/wl-paste) |
| `"xclip"` | Linux |
| `"xsel"` | Linux |
| `"win32yank"` | Windows |
| `"tmux"` | tmux |
| `"termux"` | Android |
| `"termcode"` | Terminal escape sequences |
| `"windows"` | Windows API |
| `"none"` | Disabled |

---

## Example: complete minimal config

```toml
theme = "catppuccin_mocha"

[editor]
scrolloff = 8
cursorline = true
line-number = "relative"
bufferline = "multiple"
color-modes = true
auto-save = { focus-lost = true }
soft-wrap = { enable = true }
indent-guides = { render = true }

[editor.lsp]
display-inlay-hints = true

[editor.cursor-shape]
normal = "block"
insert = "bar"
select = "underline"

[editor.statusline]
left = ["mode", "spinner", "file-name"]
right = ["diagnostics", "selections", "position"]

[editor.whitespace]
render = "all"

[editor.file-picker]
hidden = false
```
