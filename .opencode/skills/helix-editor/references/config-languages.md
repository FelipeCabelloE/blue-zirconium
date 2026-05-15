# `languages.toml` Configuration Reference

Complete reference for language, language server, formatter, and DAP debugger configuration.

---

## Three-layer merge

1. **Built-in** — compiled from `languages.toml` at repo root
2. **Global** — `~/.config/helix/languages.toml`
3. **Project-local** — `<workspace>/.helix/languages.toml` (only if workspace is trusted)

Merge depth = 3. Arrays of `[[language]]` tables matched by `name` field. Higher priority layers override lower.

Workspace trust controlled by `editor.insecure` in global `config.toml`.

---

## Top-level structure

```toml
[[language]]
# per-language config (see below)

[language-server.rust-analyzer]
# LSP server definitions referenced by [[language]] blocks
command = "rust-analyzer"
args = []
timeout = 20
config = { check = { command = "clippy" } }
```

---

## `[[language]]` fields

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | (required) | Language ID. Used as `runtime/queries/<name>/` directory name |
| `language-id` | `Option<String>` | `None` | LSP protocol language ID (e.g. `"typescriptreact"`) |
| `scope` | `String` | (required) | Tree-sitter scope (e.g. `"source.rust"`) |
| `file-types` | `Vec<FileType>` | (required) | File extensions or globs for auto-detection |
| `shebangs` | `[String]` | `[]` | Interpreter shebangs (e.g. `["deno"]` for TypeScript) |
| `roots` | `RootMarkers` | — | Project root markers (e.g. `["Cargo.toml", ".git"]`) |
| `comment-token` | `Option<String>` | `None` | Line comment string (e.g. `"//"`) |
| `comment-tokens` | `Option<[String]>` | `None` | Multiple line comment tokens |
| `block-comment-tokens` | `Option<[{start, end}]>` | `None` | Block comment markers |
| `text-width` | `Option<usize>` | `None` | Line length limit (overrides global) |
| `soft-wrap` | `Option<SoftWrap>` | `None` | Override global soft-wrap |
| `auto-format` | `bool` | `false` | Auto-format on save |
| `formatter` | `Option<FormatterConfig>` | `None` | External formatter |
| `path-completion` | `Option<bool>` | `None` | Override global path-completion |
| `word-completion` | `Option<WordCompletion>` | `None` | Override global word-completion |
| `diagnostic-severity` | `Severity` | `"hint"` | Minimum diagnostic severity to show |
| `grammar` | `Option<String>` | language-id | Tree-sitter grammar name |
| `injection-regex` | `Option<String>` | `None` | Regex for language injection lookup |
| `language-servers` | `Vec<LanguageServerFeatures>` | `[]` | LSP servers with optional feature toggles |
| `language-server` | `Option<LanguageServer>` | `None` | Inline LSP config (shorthand for single server) |
| `indent` | `Option<IndentConfig>` | `None` | Indentation settings |
| `debugger` | `Option<DebugAdapterConfig>` | `None` | DAP debugger |
| `auto-pairs` | `Option<AutoPairs>` | `None` | Per-language auto-pair overrides |
| `rulers` | `Option<[u16]>` | `None` | Override global rulers |
| `workspace-lsp-roots` | `Option<[PathBuf]>` | `None` | Hardcoded LSP root indicators |
| `persistent-diagnostic-sources` | `[String]` | `[]` | Persistent diagnostic sources by name |
| `rainbow-brackets` | `Option<bool>` | `None` | Override global rainbow-brackets |
| `config` | `Option<Value>` | `None` | LSP initialization options (inline shorthand) |

---

## `FileType` format

```toml
# Simple extension
file-types = ["rs", "py", "js"]

# Glob pattern (for specific filenames)
file-types = ["rs", { glob = "Cargo.toml" }, { glob = "**/test/**" }]
```

---

## `[language-server.*]` fields

```toml
[language-server.rust-analyzer]
command = "rust-analyzer"
args = []
environment = { RUST_LOG = "info" }     # optional env vars
timeout = 20                              # request timeout (seconds)
config = { checkOnSave = true }           # initializationOptions
required-root-patterns = ["Cargo.toml"]   # optional: only start if root matches
```

### Referencing in `[[language]]`

```toml
[[language]]
name = "rust"
language-servers = [
  "rust-analyzer",                                              # use all features
  { name = "typescript-language-server", except-features = ["format"] }  # exclude format
]
```

### Feature flags (21)

Toggle per language server with `only-features` or `except-features`:

| Flag string | Feature |
|---|---|
| `"format"` | Formatting |
| `"goto-declaration"` | Goto declaration |
| `"goto-definition"` | Goto definition |
| `"goto-type-definition"` | Goto type definition |
| `"goto-reference"` | Goto references |
| `"goto-implementation"` | Goto implementation |
| `"signature-help"` | Signature help |
| `"hover"` | Hover docs |
| `"document-highlight"` | Document highlight |
| `"completion"` | Code completion |
| `"code-action"` | Code actions |
| `"document-links"` | Document links |
| `"workspace-command"` | Workspace commands |
| `"document-symbols"` | Document symbols |
| `"workspace-symbols"` | Workspace symbols |
| `"diagnostics"` | Pull diagnostics |
| `"pull-diagnostics"` | Pull diagnostics (push-alternative) |
| `"rename-symbol"` | Rename symbol |
| `"inlay-hints"` | Inlay hints |
| `"document-colors"` | Document colors |
| `"call-hierarchy"` | Call hierarchy |

---

## `FormatterConfiguration`

```toml
formatter = { command = "rustfmt", args = ["--edition", "2021"] }
```

Simple `command` + `args`.

---

## `IndentationConfiguration`

```toml
indent = { tab-width = 4, unit = "    " }   # 4 spaces
indent = { tab-width = 4, unit = "\t" }     # tabs
```

`tab-width` range: 1–16.

---

## Severity

| String | Level |
|---|---|
| `"hint"` | Hint (lowest) |
| `"info"` | Info |
| `"warning"` | Warning |
| `"error"` | Error (highest) |

---

## DAP Debugger Configuration

Defined under `[language.debugger]` inside a `[[language]]` block.

### `DebugAdapterConfig`

```toml
[[language]]
name = "rust"

[language.debugger]
name = "lldb-dap"
transport = "stdio"            # "stdio" | "tcp"
command = "lldb-dap"
args = []

# For TCP transport:
# transport = "tcp"
# command = "dlv"
# args = ["dap"]
# port-arg = "-l 127.0.0.1:{}"

[language.debugger.quirks]
absolute-paths = false          # workaround for adapter quirks
```

### `DebugAdapterConfig` fields

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Adapter identifier |
| `transport` | `String` | `"stdio"` (spawn+stdin/stdout) or `"tcp"` (spawn+connect after 500ms) |
| `command` | `String` | DAP server binary |
| `args` | `[String]` | Extra CLI args |
| `port-arg` | `Option<String>` | TCP format string with `{}` for port (e.g. `"-l 127.0.0.1:{}"`) |
| `templates` | `[DebugTemplate]` | Launch/attach configurations |
| `quirks` | `DebuggerQuirks` | Adapter workarounds |

### `DebugTemplate`

```toml
[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [
  { name = "binary", completion = "filename" },
  { name = "cwd", completion = "directory", default = "." }
]
args = { program = "{0}", cwd = "{1}" }
```

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Template label shown to user |
| `request` | `String` | `"launch"` or `"attach"` |
| `completion` | `[DebugConfigCompletion]` | User prompts for parameters |
| `args` | `HashMap<String, Value>` | DAP request args; `{0}`, `{1}` etc. substituted from user input |

### `DebugConfigCompletion`

- **Plain string** (e.g. `"pid"`): prompts with that label, accepts free text
- **Table** `{ name, completion?, default? }`:
  - `completion = "filename"` — filesystem picker
  - `completion = "directory"` — directory picker
  - No completion — free text input
  - `default = "..."` — pre-filled default

### `DebuggerQuirks`

| Field | Type | Default | Description |
|---|---|---|---|
| `absolute-paths` | `bool` | `false` | Whether adapter uses absolute paths (vs relative) |

### Built-in examples

**lldb-dap (stdio):**
```toml
[language.debugger]
name = "lldb-dap"
transport = "stdio"
command = "lldb-dap"

[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { program = "{0}" }

[[language.debugger.templates]]
name = "attach"
request = "attach"
completion = [ "pid" ]
args = { pid = "{0}" }
```

**Delve for Go (TCP):**
```toml
[language.debugger]
name = "go"
transport = "tcp"
command = "dlv"
args = ["dap"]
port-arg = "-l 127.0.0.1:{}"

[[language.debugger.templates]]
name = "source"
request = "launch"
completion = [ { name = "entrypoint", completion = "filename", default = "." } ]
args = { mode = "debug", program = "{0}" }
```

### All debug keybindings

| Key | Command | Action |
|---|---|---|
| `space G l` | `dap_launch` | Launch/show template picker |
| `space G r` | `dap_restart` | Restart session |
| `space G b` | `dap_toggle_breakpoint` | Toggle breakpoint |
| `space G c` | `dap_continue` | Continue |
| `space G h` | `dap_pause` | Pause |
| `space G i` | `dap_step_in` | Step in |
| `space G n` | `dap_next` | Step over |
| `space G o` | `dap_step_out` | Step out |
| `space G v` | `dap_variables` | Show variables |
| `space G t` | `dap_terminate` | End session |
| `space G C-c` | `dap_edit_condition` | Edit breakpoint condition |
| `space G C-l` | `dap_edit_log` | Edit breakpoint log message |
| `space G e` | `dap_enable_exceptions` | Enable all exception breakpoints |
| `space G E` | `dap_disable_exceptions` | Disable exception breakpoints |
| `space G s t` | `dap_switch_thread` | Switch active thread |
| `space G s f` | `dap_switch_stack_frame` | Switch stack frame |
| `:debug-start` / `:dbg` | — | Start debug by name with args |
| `:debug-remote` / `:dbg-tcp` | — | Connect via TCP DAP server |
| `:debug-eval` | — | Evaluate expression in debug context |

### Debugging status

Gutter indicators: `●` verified breakpoint, `◯` unverified, `▶` current execution line. Gutter click toggles breakpoint. Theme scopes: `ui.debug.breakpoint`, `ui.debug.active`.

### Limitations

- DAP is **experimental** — many TODOs in source
- Single active debugger in UI (though registry supports multi-session)
- Variable expansion is one level only (no nested object expansion)
- `block_on()` used for async DAP calls — can hang UI on slow adapters
- Editing during debug is not officially supported
- `runInTerminal` requires `[terminal]` config in `config.toml`
- TCP debuggers have a hardcoded 500ms sleep before connecting
- Breakpoints are **not persisted** between sessions
- Line indexing: 0-based internally, sent as 1-based to DAP adapter
