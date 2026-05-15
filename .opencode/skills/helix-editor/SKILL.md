---
name: helix-editor
description: Help users configure, debug, and improve their Helix editor experience. Covers Helix editing workflow, configuration (global and project-local), debugging Helix internals, DAP integration for debugging user code, and tree-sitter query authoring. Trigger on questions about config.toml, languages.toml, .helix/, keymaps, Helix commands, LSP setup, tree-sitter queries, or debugger configuration.
---

# Helix Editor Skill

Start here for orientation. For deep configuration reference, see the `references/` directory.

---

## 1. Basics & Editing Workflow

**Modes:** Normal (default), Select (`v`), Insert (`i`). `esc` to Normal.

**Noun then verb:** Select first, then act. Selections have a `head` (moving) and `anchor` (fixed). Multiple selections are core — `Alt-c` add cursor, `Alt-C` add below, `Alt-n` add next match, `Alt-;` collapse to cursors, `Alt-,` remove primary, `Alt-_` trim selections.

**Movement:** `hjkl` (visual lines), `w/b/e` words, `W/B/E` WORDS, `f/F/t/T` find char, `%` match bracket. `g` goto: `gg` top, `ge` end, `gd` definition, `gD` declaration, `gr` references, `gh` hover, `gs` symbol.

**Textobjects** (`ma` around, `mi` inside): `w` word, `W` WORD, `f` function, `t` class, `a` parameter, `c` comment, `e` entry, `T` test, `x` xml-element, `p` paragraph, `g` diff hunk, `m` match pair, non-alpha = pair char.

**Actions:** `d` delete, `c` change, `y` yank, `p` paste, `~` toggle case, `.` repeat last insert. `;` / `,` repeat/undo last motion.

**Pickers** (`space` leader): `space f` files, `space b` buffers, `space k` grep, `space d` diagnostics, `space S` workspace symbols, `space s` document symbols, `space /` search project, `space a` code actions, `space R` rename, `space j` jumplist, `space '` last picker. `Tab` toggles preview.

**Registers:** `"a`-`"z`. `"ay` yank to `a`, `"ap` paste from `a`, `"aY` append to `a`. `"*p` system clipboard. `"/` last search. `":` last command. `.` last insert.

**Macros:** `qm (keys) q` record to `m`. `Q` replay last. `@m` replay register.

**Typed commands (`:`):** `:w` write, `:wq` write-quit, `:q` quit, `:o` open, `:pipe` pipe selection, `:sh` shell, `:format`, `:reload`, `:config-reload`, `:set` set option, `:toggle` toggle, `:theme` switch. `:tutor` opens tutorial.

---

## 2. Configuration Concepts

### File resolution (see `references/config-editor.md` for all options)

| File | Location |
|---|---|
| Global `config.toml` | `~/.config/helix/config.toml` |
| Global `languages.toml` | `~/.config/helix/languages.toml` |
| Project `config.toml` | `<workspace>/.helix/config.toml` |
| Project `languages.toml` | `<workspace>/.helix/languages.toml` |
| CLI override | `hx -c <path>` |

Workspace root detected by walking up from CWD for `.git`, `.svn`, `.jj`, or `.helix`.

### Workspace trust

`editor.insecure` in **global** config controls trust:
- `false` (default): untrusted workspaces — `.helix/*` configs **completely ignored**. Trust persisted in data dir.
- `true`: all workspaces trusted, no prompt.

### Merge rules (config.toml)

- `[editor]`: TOML deep-merge, depth 3. Project overrides global overrides defaults.
- `[keys.*]`: Node-by-node merge — leaf replaces leaf, leaf replaces node, node merges recursively. See `references/config-keymaps.md`.
- `[theme]`: Project wins over global.

### Merge rules (languages.toml)

Three-layer merge: built-in → global → project. Depth 3. Arrays of `[[language]]` tables matched on `name`. See `references/config-languages.md`.

### Quick patterns

```toml
# Project-specific settings
theme = "onedark"
[editor]
line-number = "relative"
soft-wrap = { enable = true }

# Override a keybinding
[keys.normal]
"A-x" = "command_palette"

# Per-language auto-format
# in .helix/languages.toml:
[[language]]
name = "rust"
auto-format = true
formatter = { command = "rustfmt", args = ["--edition", "2021"] }
```

### Diagnostics

`hx --health rust` — checks LSP, grammar, config. `hx --health all` for everything.

### Hot-reload

`:config-reload` reloads all configs at runtime.

---

## 3. Debugging Helix & DAP

### Debugging Helix itself

| Technique | Command |
|---|---|
| Info logging | `hx -v --log helix.log` |
| Debug logging | `hx -vv` |
| Trace logging | `hx -vvv` |
| View logs in-editor | `:log-open` |
| Skip grammar build | `HELIX_DISABLE_AUTO_GRAMMAR_BUILD=1 cargo check` |
| Override runtime | `HELIX_RUNTIME=/path cargo run` |
| Backtrace | `RUST_BACKTRACE=1` |
| Integration tests | `cargo integration-test` (or `HELIX_LOG_LEVEL=debug cargo integration-test`) |
| CI validation | `cargo fmt --all --check && cargo clippy --workspace --all-targets -- -D warnings && cargo doc --no-deps --workspace --document-private-items && cargo xtask query-check && cargo xtask theme-check` |

### DAP (debugging user code)

All debug commands under `space G` (experimental sticky mode):

| Key | Action |
|---|---|
| `space G l` | Launch debug session |
| `space G b` | Toggle breakpoint |
| `space G c` | Continue |
| `space G i/n/o` | Step in / over / out |
| `space G v` | Show variables |
| `space G t` | Terminate |
| `space G s t` | Switch thread |
| `space G s f` | Stack frame |
| `space G e/E` | Enable/disable exception breakpoints |

Typed: `:debug-start` / `:dbg`, `:debug-remote` / `:dbg-tcp`, `:debug-eval`.

Configure debugger in `languages.toml` under `[language.debugger]`. See `references/config-languages.md` for full schema.

**Limitations:** Experimental. Single active debugger in UI. One-level variable expansion. `block_on` for async calls. Breakpoints not persisted. `runInTerminal` needs `[terminal]` config.

---

## 4. Tree-Sitter Query Authoring

Query files live in `runtime/queries/<language_id>/`. The `language_id` matches `name` in `languages.toml`.

| File | Purpose | Captures |
|---|---|---|
| `highlights.scm` | Syntax highlighting | `@keyword`, `@string`, `@function`, `@type`, `@variable`, `@operator`, `@constant`, `@punctuation.*`, `@comment`, `@attribute`, `@parameter`, `@property`, `@constructor`, `@namespace`, `@method`, `@tag`, `@label`, `@markup.*`, `@diff.*` |
| `injections.scm` | Embedded languages | `@injection.content`, `(#set! injection.language "X")`, `(#set! injection.combined)` |
| `indents.scm` | Indentation | `@indent`, `@outdent`, `@align`, `@anchor`, `(#set! "scope" "all")` |
| `textobjects.scm` | `ma`/`mi` selections | `@name.inside`, `@name.around` |
| `locals.scm` | Symbol navigation | `@local.scope`, `@local.definition.*`, `@local.reference` |
| `tags.scm` | LSP symbols | `@definition.*` |
| `rainbows.scm` | Bracket coloring | `@rainbow.scope`, `@rainbow.bracket` |

**Predicates:** `(#eq? @cap "val")`, `(#any-of? @cap "a" "b")`, `(#match? @cap "^regex")`, `(#not-eq?)`, `(#not-match?)`, `(#not-same-line? @a @b)`, `(#set! key "value")`.

**Resolving scope names:** When highlighting, the longest dotted match wins. E.g., `function.builtin` matches before `function`.

**Step by step for a new language:**
1. Ensure grammar entry in `languages.toml`
2. Create `runtime/queries/<id>/`
3. Write `highlights.scm` first — map grammar nodes to captures
4. Validate: `cargo xtask query-check <id>`
5. Run `cargo run` and open a file to verify
6. Add `injections.scm` for embedded code, `textobjects.scm` for `ma`/`mi`, `indents.scm` for auto-indent, `locals.scm` for navigation, `rainbows.scm` for brackets, `tags.scm` for symbols
7. Re-validate after each file

**Reference:** `runtime/queries/rust/` has all 7 files. `runtime/queries/toml/` has a compact 48-line `highlights.scm`.
