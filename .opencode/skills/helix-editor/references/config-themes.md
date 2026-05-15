# `[theme]` Configuration Reference

How to configure, extend, and create themes.

---

## Theme selection

```toml
# Simple: always use the same theme
theme = "catppuccin_mocha"

# Adaptive: choose by terminal light/dark mode
[theme]
dark = "catppuccin_mocha"
light = "catppuccin_latte"
fallback = "catppuccin_mocha"  # used if terminal doesn't declare mode; defaults to dark
```

---

## Theme file locations

Themes are TOML files. Search order (first match wins):
1. `~/.config/helix/themes/<name>.toml`
2. `<runtime>/themes/<name>.toml`

Reserved names `"default"` and `"base16_default"` are compiled into the binary and cannot be overridden.

---

## Theme file format

```toml
# Optional: inherit from another theme
inherits = "parent_theme_name"

# Simple key: hex color
"ui.text" = "#ffffff"

# Full table style
"ui.selection" = { fg = "#1e1e2e", bg = "#f5c2e7", modifiers = ["bold"] }

# Rainbow bracket colors (array)
rainbow = ["red", "peach", "yellow", "green", "sapphire", "lavender"]

# Color palette (defined last in file)
[palette]
my_color = "#aabbcc"
```

### Style table

| Key | Type | Description |
|---|---|---|
| `fg` | Color | Foreground color |
| `bg` | Color | Background color |
| `underline.color` | Color | Underline color |
| `underline.style` | String | `"line"`, `"curl"`, `"dashed"`, `"dotted"`, `"double_line"` |
| `modifiers` | [String] | See below |

### Color formats

| Format | Example |
|---|---|
| CSS hex | `"#ff8844"` or `"#f84"` |
| Palette reference | `"my_color"` (from `[palette]`) |
| ANSI name | `"red"`, `"green"`, `"blue"`, `"default"`, etc. (17 names) |
| ANSI index | `"42"` (stringified number 0-255) |

### Modifiers

| Value | Effect |
|---|---|
| `"bold"` | Bold |
| `"dim"` | Dim |
| `"italic"` | Italic |
| `"slow_blink"` | Slow blink |
| `"rapid_blink"` | Rapid blink |
| `"reversed"` | Reverse video |
| `"hidden"` | Hidden |
| `"crossed_out"` | Strikethrough |

---

## Inheritance

When `inherits = "parent"`, the parent theme is loaded and the child overrides:
- Palette: merged at depth 2 (child palette entries override parent's)
- Styles: child keys override parent keys (depth 1)
- Child file overrides parent file; cycles detected and resolved

---

## Scope resolution

When looking up a style (e.g., `ui.text.focus`):
1. Exact match on `ui.text.focus`
2. Fall back to `ui.text`
3. Fall back to `ui`

The **longest matching key wins** — so `function.builtin.static` matches `function.builtin` over `function`.

Syntax highlight scopes use the same dotted fallback. For example, `@string.special.url` resolves against the longest key `string.special` before `string`.

---

## UI scope families

Top-level UI scope families. Sub-keys follow the dotted fallback rule (e.g., `ui.cursor.normal`, `ui.cursor.insert`, `ui.statusline.normal`).

| Family | Purpose |
|---|---|
| `ui.background` | Overall background |
| `ui.cursor` | Cursor appearance |
| `ui.cursorline` | Cursor line highlight |
| `ui.cursorcolumn` | Cursor column highlight |
| `ui.selection` | **Required** — must exist in every theme |
| `ui.linenr` | Line numbers |
| `ui.statusline` | Status bar |
| `ui.bufferline` | Buffer tabs |
| `ui.popup` | Documentation popups |
| `ui.window` | Split borders |
| `ui.help` | Command help boxes |
| `ui.text` | General text in UI |
| `ui.virtual` | Virtual text (wrap, whitespace, inlay hints, etc.) |
| `ui.menu` | Completion menus |
| `ui.gutter` | Gutter panels |
| `ui.highlight` | Picker preview highlights |
| `ui.debug` | Debug indicators |
| `ui.picker` | Picker headers |

## Syntax scope families

Top-level families. Sub-keys like `keyword.control.conditional`, `string.special.url`, `variable.other.member` follow the dotted fallback.

| Family | Description |
|---|---|
| `attribute` | HTML/XML/tag attributes |
| `type` | Types (including `.builtin`, `.parameter`, `.enum.variant`) |
| `constructor` | Constructors |
| `constant` | Constants (including `.builtin`, `.character`, `.numeric`) |
| `string` | Strings (including `.regexp`, `.special`) |
| `comment` | Comments (including `.line`, `.block`, `.documentation`, `.unused`) |
| `variable` | Variables (including `.mutable`, `.builtin`, `.parameter`, `.other.member`) |
| `label` | Lifetimes, CSS classes/IDs |
| `punctuation` | Punctuation (including `.delimiter`, `.bracket`, `.special`) |
| `keyword` | Keywords (including `.control.*`, `.operator`, `.directive`, `.function`, `.storage.*`) |
| `operator` | Operators |
| `function` | Functions (including `.builtin`, `.method`, `.macro`, `.special`) |
| `tag` | HTML/XML tags (including `.builtin`) |
| `namespace` | Namespaces/modules |
| `special` | Special constructs (derive, etc.) |
| `markup` | Markdown/markup (heading, list, bold, italic, link, quote, raw, etc.) |
| `diff` | Diff indicators (plus, minus, delta) |

## Diagnostic scopes

| Scope | Description |
|---|---|
| `warning` / `error` / `info` / `hint` | Gutter diagnostic icons |
| `diagnostic` | Fallback editing-area diagnostic |
| `diagnostic.error` / `.warning` / `.info` / `.hint` | Underline style per severity |
| `diagnostic.unnecessary` | Dimmed unnecessary code |
| `diagnostic.deprecated` | Crossed-out deprecated code |

## Validation

```bash
cargo xtask theme-check              # check all themes
cargo xtask theme-check onedark      # check specific theme
```

Run from workspace root. Requires built grammars (or `HELIX_DISABLE_AUTO_GRAMMAR_BUILD=1`).

---

## Creating a user theme

```bash
mkdir -p ~/.config/helix/themes
touch ~/.config/helix/themes/mytheme.toml
```

Then use `:theme mytheme` to apply. To override a bundled theme, use the same name.
