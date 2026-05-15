# `[keys.*]` Configuration Reference

Complete reference for keymap configuration, key event format, and all available commands.

---

## Key event format

```
[Modifier-]KeyCode
```

**Modifiers** (prefix, case-sensitive):
| Prefix | Key |
|---|---|
| `C-` | Ctrl |
| `A-` | Alt |
| `S-` | Shift |
| `Meta-` / `Cmd-` / `Win-` | Super/Command/Windows |

**Single characters** (e.g. `"w"`, `"g"`, `"a"`, `"$"`, `"+"`) resolve to `KeyCode::Char(c)`.

**Named key codes:**

| String | Key | String | Key |
|---|---|---|---|
| `esc` | Escape | `backspace` | Backspace |
| `ret` / `enter` | Enter | `tab` | Tab |
| `space` | Space | `del` | Delete |
| `ins` | Insert | `home` | Home |
| `end` | End | `pageup` | Page Up |
| `pagedown` | Page Down | `up` / `down` / `left` / `right` | Arrows |
| `minus` | `-` | `lt` | `<` |
| `gt` | `>` | `null` | Null |
| `capslock` | CapsLock | `scrolllock` | ScrollLock |
| `numlock` | NumLock | `printscreen` | PrintScreen |
| `pause` | Pause | `menu` | Menu |
| `keypadbegin` | KeypadBegin | | |
| `F1` .. `F24` | Function keys | | |

**Media keys:** `play`, `pausemedia`, `playpause`, `stop`, `reverse`, `fastforward`, `rewind`, `tracknext`, `trackprevious`, `record`, `lowervolume`, `raisevolume`, `mutevolume`

**Modifier keys (for mapping to):** `leftshift`, `leftcontrol`, `leftalt`, `leftsuper`, `lefthyper`, `leftmeta`, `rightshift`, `rightcontrol`, `rightalt`, `rightsuper`, `righthyper`, `rightmeta`, `isolevel3shift`, `isolevel5shift`

---

## Binding value types

```toml
[keys.normal]
# Single command
"j" = "move_visual_line_down"

# Command sequence (executed in order)
"+" = ["select_all", "shell_pipe", "format"]

# Sub-keymap node (nested bindings)
"g" = { "g" = "goto_file_start", "e" = "goto_last_line", "$" = "goto_line_end" }

# Override an existing sub-keymap entirely
"space" = "no_op"  # replaces whole picker menu
```

Modes: `[keys.normal]`, `[keys.select]`, `[keys.insert]`.

---

## Merge behavior

User keymaps merge into defaults with these rules:
- **Leaf replaces leaf** — user binds `"y"` to `"move_line_down"`, yank is replaced
- **Leaf replaces node** — user binds `"space"` to `"no_op"`, entire picker sub-keymap replaced
- **Node merges into node** — user defines `"g" = { "$" = "goto_line_end" }`, `$` is added to goto menu, existing `g` bindings preserved
- **New keys** — any key not in defaults is added

Default keymap source: `helix-term/src/keymap/default.rs`

---

## Static commands (313)

These are bound directly in keymaps by their name string.

| Name | Description |
|---|---|
| `no_op` | Do nothing |
| `move_char_left` | Move left |
| `move_char_right` | Move right |
| `move_line_up` | Move up |
| `move_line_down` | Move down |
| `move_visual_line_up` | Move up (visual lines) |
| `move_visual_line_down` | Move down (visual lines) |
| `extend_char_left` | Extend left |
| `extend_char_right` | Extend right |
| `extend_line_up` | Extend up |
| `extend_line_down` | Extend down |
| `extend_visual_line_up` | Extend up (visual) |
| `extend_visual_line_down` | Extend down (visual) |
| `copy_selection_on_next_line` | Copy selection on next line |
| `copy_selection_on_prev_line` | Copy selection on previous line |
| `move_next_word_start` | Move to start of next word |
| `move_prev_word_start` | Move to start of prev word |
| `move_next_word_end` | Move to end of next word |
| `move_prev_word_end` | Move to end of prev word |
| `move_next_long_word_start` | Move to start of next WORD |
| `move_prev_long_word_start` | Move to start of prev WORD |
| `move_next_long_word_end` | Move to end of next WORD |
| `move_prev_long_word_end` | Move to end of prev WORD |
| `move_next_sub_word_start` | Move to start of next sub-word |
| `move_prev_sub_word_start` | Move to start of prev sub-word |
| `move_next_sub_word_end` | Move to end of next sub-word |
| `move_prev_sub_word_end` | Move to end of prev sub-word |
| `move_parent_node_end` | Move to end of parent syntax node |
| `move_parent_node_start` | Move to start of parent syntax node |
| `extend_next_word_start` | Extend to start of next word |
| `extend_prev_word_start` | Extend to start of prev word |
| `extend_next_word_end` | Extend to end of next word |
| `extend_prev_word_end` | Extend to end of prev word |
| `extend_next_long_word_start` | Extend to start of next WORD |
| `extend_prev_long_word_start` | Extend to start of prev WORD |
| `extend_next_long_word_end` | Extend to end of next WORD |
| `extend_prev_long_word_end` | Extend to end of prev WORD |
| `extend_next_sub_word_start` | Extend to start of next sub-word |
| `extend_prev_sub_word_start` | Extend to start of prev sub-word |
| `extend_next_sub_word_end` | Extend to end of next sub-word |
| `extend_prev_sub_word_end` | Extend to end of prev sub-word |
| `extend_parent_node_end` | Extend to end of parent node |
| `extend_parent_node_start` | Extend to start of parent node |
| `find_till_char` | Move till next occurrence of char |
| `find_next_char` | Move to next occurrence of char |
| `extend_till_char` | Extend till next occurrence of char |
| `extend_next_char` | Extend to next occurrence of char |
| `till_prev_char` | Move till previous occurrence of char |
| `find_prev_char` | Move to previous occurrence of char |
| `extend_till_prev_char` | Extend till previous occurrence of char |
| `extend_prev_char` | Extend to previous occurrence of char |
| `repeat_last_motion` | Repeat last motion |
| `replace` | Replace with new char |
| `switch_case` | Toggle case |
| `switch_to_uppercase` | Switch to uppercase |
| `switch_to_lowercase` | Switch to lowercase |
| `page_up` | Move page up |
| `page_down` | Move page down |
| `half_page_up` | Move half page up |
| `half_page_down` | Move half page down |
| `page_cursor_up` | Move page and cursor up |
| `page_cursor_down` | Move page and cursor down |
| `page_cursor_half_up` | Move page and cursor half up |
| `page_cursor_half_down` | Move page and cursor half down |
| `select_all` | Select whole document |
| `select_regex` | Select all regex matches inside selections |
| `split_selection` | Split selections on regex |
| `split_selection_on_newline` | Split selection on newlines |
| `merge_selections` | Merge selections |
| `merge_consecutive_selections` | Merge consecutive selections |
| `search` | Search for regex pattern |
| `rsearch` | Reverse search for regex pattern |
| `search_next` | Select next search match |
| `search_prev` | Select previous search match |
| `extend_search_next` | Add next search match to selection |
| `extend_search_prev` | Add previous search match to selection |
| `search_selection` | Use selection as search pattern |
| `search_selection_detect_word_boundaries` | Use selection as search, auto-wrap with `\b` |
| `make_search_word_bounded` | Make current search word-bounded |
| `global_search` | Global search in workspace |
| `extend_line` | Select current line, extend if already selected |
| `extend_line_below` | Select and extend to next line |
| `extend_line_above` | Select and extend to previous line |
| `select_line_above` | Select/extend/shrink line above |
| `select_line_below` | Select/extend/shrink line below |
| `extend_to_line_bounds` | Extend selection to line bounds |
| `shrink_to_line_bounds` | Shrink selection to line bounds |
| `delete_selection` | Delete selection |
| `delete_selection_noyank` | Delete selection without yanking |
| `change_selection` | Change selection |
| `change_selection_noyank` | Change selection without yanking |
| `collapse_selection` | Collapse selection to single cursor |
| `flip_selections` | Flip cursor and anchor |
| `ensure_selections_forward` | Ensure all selections face forward |
| `insert_mode` | Insert before selection |
| `append_mode` | Append after selection |
| `command_mode` | Enter command mode |
| `file_picker` | Open file picker |
| `file_picker_in_current_buffer_directory` | File picker at current buffer dir |
| `file_picker_in_current_directory` | File picker at CWD |
| `file_explorer` | Open file explorer |
| `file_explorer_in_current_buffer_directory` | File explorer at buffer dir |
| `file_explorer_in_current_directory` | File explorer at CWD |
| `code_action` | Code action picker |
| `buffer_picker` | Buffer picker |
| `jumplist_picker` | Jumplist picker |
| `symbol_picker` | Symbol picker |
| `syntax_symbol_picker` | Symbol picker (syntax) |
| `lsp_or_syntax_symbol_picker` | Symbol picker (LSP or syntax) |
| `changed_file_picker` | Changed file picker |
| `select_references_to_symbol_under_cursor` | Select symbol references |
| `workspace_symbol_picker` | Workspace symbol picker |
| `syntax_workspace_symbol_picker` | Workspace symbol picker (syntax) |
| `lsp_or_syntax_workspace_symbol_picker` | Workspace symbol picker (LSP or syntax) |
| `diagnostics_picker` | Diagnostics picker |
| `workspace_diagnostics_picker` | Workspace diagnostics picker |
| `last_picker` | Open last picker |
| `insert_at_line_start` | Insert at start of line |
| `insert_at_line_end` | Insert at end of line |
| `open_below` | Open new line below |
| `open_above` | Open new line above |
| `normal_mode` | Enter normal mode |
| `select_mode` | Enter selection extend mode |
| `exit_select_mode` | Exit selection mode |
| `goto_definition` | Goto definition |
| `goto_declaration` | Goto declaration |
| `add_newline_above` | Add newline above |
| `add_newline_below` | Add newline below |
| `goto_type_definition` | Goto type definition |
| `goto_implementation` | Goto implementation |
| `goto_file_start` | Goto file start (or line `<n>`) |
| `goto_file_end` | Goto file end |
| `extend_to_file_start` | Extend to file start |
| `extend_to_file_end` | Extend to file end |
| `goto_file` | Goto file/URL in selection |
| `goto_file_hsplit` | Goto file in horizontal split |
| `goto_file_vsplit` | Goto file in vertical split |
| `goto_reference` | Goto references |
| `goto_window_top` | Goto window top |
| `goto_window_center` | Goto window center |
| `goto_window_bottom` | Goto window bottom |
| `goto_last_accessed_file` | Goto last accessed file |
| `goto_last_modified_file` | Goto last modified file |
| `goto_last_modification` | Goto last modification |
| `goto_line` | Goto line |
| `goto_last_line` | Goto last line |
| `extend_to_last_line` | Extend to last line |
| `goto_first_diag` | Goto first diagnostic |
| `goto_last_diag` | Goto last diagnostic |
| `goto_next_diag` | Goto next diagnostic |
| `goto_prev_diag` | Goto previous diagnostic |
| `goto_next_change` | Goto next change |
| `goto_prev_change` | Goto previous change |
| `goto_first_change` | Goto first change |
| `goto_last_change` | Goto last change |
| `goto_line_start` | Goto line start |
| `goto_line_end` | Goto line end |
| `goto_column` | Goto column |
| `extend_to_column` | Extend to column |
| `goto_next_buffer` | Goto next buffer |
| `goto_previous_buffer` | Goto previous buffer |
| `goto_line_end_newline` | Goto newline at line end |
| `goto_first_nonwhitespace` | Goto first non-blank in line |
| `trim_selections` | Trim whitespace from selections |
| `extend_to_line_start` | Extend to line start |
| `extend_to_first_nonwhitespace` | Extend to first non-blank |
| `extend_to_line_end` | Extend to line end |
| `extend_to_line_end_newline` | Extend to line end newline |
| `signature_help` | Show signature help |
| `smart_tab` | Smart tab (whitespace or LSP completion) |
| `insert_tab` | Insert tab char |
| `insert_newline` | Insert newline |
| `insert_char_interactive` | Insert interactively-chosen char |
| `append_char_interactive` | Append interactively-chosen char |
| `delete_char_backward` | Delete previous char |
| `delete_char_forward` | Delete next char |
| `delete_word_backward` | Delete previous word |
| `delete_word_forward` | Delete next word |
| `kill_to_line_start` | Delete to line start |
| `kill_to_line_end` | Delete to line end |
| `undo` | Undo |
| `redo` | Redo |
| `earlier` | Move backward in history |
| `later` | Move forward in history |
| `commit_undo_checkpoint` | Commit changes to new checkpoint |
| `yank` | Yank selection |
| `yank_to_clipboard` | Yank to clipboard |
| `yank_to_primary_clipboard` | Yank to primary clipboard |
| `yank_joined` | Join and yank selections |
| `yank_joined_to_clipboard` | Join and yank to clipboard |
| `yank_main_selection_to_clipboard` | Yank main selection to clipboard |
| `yank_joined_to_primary_clipboard` | Join and yank to primary clipboard |
| `yank_main_selection_to_primary_clipboard` | Yank main selection to primary clipboard |
| `replace_with_yanked` | Replace with yanked text |
| `replace_selections_with_clipboard` | Replace with clipboard |
| `replace_selections_with_primary_clipboard` | Replace with primary clipboard |
| `paste_after` | Paste after selection |
| `paste_before` | Paste before selection |
| `paste_clipboard_after` | Paste clipboard after |
| `paste_clipboard_before` | Paste clipboard before |
| `paste_primary_clipboard_after` | Paste primary clipboard after |
| `paste_primary_clipboard_before` | Paste primary clipboard before |
| `indent` | Indent |
| `unindent` | Unindent |
| `format_selections` | Format selection |
| `join_selections` | Join lines inside selection |
| `join_selections_space` | Join lines and select spaces |
| `keep_selections` | Keep selections matching regex |
| `remove_selections` | Remove selections matching regex |
| `align_selections` | Align selections in column |
| `keep_primary_selection` | Keep primary selection |
| `remove_primary_selection` | Remove primary selection |
| `completion` | Invoke completion popup |
| `hover` | Show docs for item under cursor |
| `toggle_comments` | Toggle comments |
| `toggle_line_comments` | Toggle line comments |
| `toggle_block_comments` | Toggle block comments |
| `rotate_selections_forward` | Rotate selections forward |
| `rotate_selections_backward` | Rotate selections backward |
| `rotate_selection_contents_forward` | Rotate selection contents forward |
| `rotate_selection_contents_backward` | Rotate selection contents backward |
| `reverse_selection_contents` | Reverse selection contents |
| `expand_selection` | Expand selection to parent syntax node |
| `shrink_selection` | Shrink selection to previous node |
| `select_next_sibling` | Select next sibling in syntax tree |
| `select_prev_sibling` | Select previous sibling in syntax tree |
| `select_all_siblings` | Select all siblings of current node |
| `select_all_children` | Select all children of current node |
| `jump_forward` | Jump forward on jumplist |
| `jump_backward` | Jump backward on jumplist |
| `save_selection` | Save current selection to jumplist |
| `jump_view_right` | Jump to right split |
| `jump_view_left` | Jump to left split |
| `jump_view_up` | Jump to split above |
| `jump_view_down` | Jump to split below |
| `swap_view_right` | Swap with right split |
| `swap_view_left` | Swap with left split |
| `swap_view_up` | Swap with split above |
| `swap_view_down` | Swap with split below |
| `transpose_view` | Transpose splits |
| `rotate_view` | Goto next window |
| `rotate_view_reverse` | Goto previous window |
| `hsplit` | Horizontal split (bottom) |
| `hsplit_new` | Horizontal split with scratch buffer |
| `vsplit` | Vertical split (right) |
| `vsplit_new` | Vertical split with scratch buffer |
| `wclose` | Close window |
| `wonly` | Close all windows except current |
| `select_register` | Select register |
| `insert_register` | Insert register |
| `copy_between_registers` | Copy between two registers |
| `align_view_middle` | Align view middle |
| `align_view_top` | Align view top |
| `align_view_center` | Align view center |
| `align_view_bottom` | Align view bottom |
| `scroll_up` | Scroll view up |
| `scroll_down` | Scroll view down |
| `match_brackets` | Goto matching bracket |
| `surround_add` | Surround add |
| `surround_replace` | Surround replace |
| `surround_delete` | Surround delete |
| `select_textobject_around` | Select around textobject |
| `select_textobject_inner` | Select inside textobject |
| `goto_next_function` | Goto next function |
| `goto_prev_function` | Goto previous function |
| `goto_next_class` | Goto next type definition |
| `goto_prev_class` | Goto previous type definition |
| `goto_next_parameter` | Goto next parameter |
| `goto_prev_parameter` | Goto previous parameter |
| `goto_next_comment` | Goto next comment |
| `goto_prev_comment` | Goto previous comment |
| `goto_next_test` | Goto next test |
| `goto_prev_test` | Goto previous test |
| `goto_next_xml_element` | Goto next XML element |
| `goto_prev_xml_element` | Goto previous XML element |
| `goto_next_entry` | Goto next pairing |
| `goto_prev_entry` | Goto previous pairing |
| `goto_next_paragraph` | Goto next paragraph |
| `goto_prev_paragraph` | Goto previous paragraph |
| `dap_launch` | Launch debug target |
| `dap_restart` | Restart debugging session |
| `dap_toggle_breakpoint` | Toggle breakpoint |
| `dap_continue` | Continue program execution |
| `dap_pause` | Pause program execution |
| `dap_step_in` | Step in |
| `dap_step_out` | Step out |
| `dap_next` | Step to next |
| `dap_variables` | List variables |
| `dap_terminate` | End debug session |
| `dap_edit_condition` | Edit breakpoint condition |
| `dap_edit_log` | Edit breakpoint log message |
| `dap_switch_thread` | Switch current thread |
| `dap_switch_stack_frame` | Switch stack frame |
| `dap_enable_exceptions` | Enable exception breakpoints |
| `dap_disable_exceptions` | Disable exception breakpoints |
| `shell_pipe` | Pipe selections through shell command |
| `shell_pipe_to` | Pipe selections to shell, ignore output |
| `shell_insert_output` | Insert shell output before selections |
| `shell_append_output` | Append shell output after selections |
| `shell_keep_pipe` | Filter selections with shell predicate |
| `suspend` | Suspend and return to shell |
| `rename_symbol` | Rename symbol |
| `increment` | Increment item under cursor |
| `decrement` | Decrement item under cursor |
| `record_macro` | Record macro |
| `replay_macro` | Replay macro |
| `command_palette` | Open command palette |
| `goto_word` | Jump to two-character label |
| `extend_to_word` | Extend to two-character label |
| `goto_next_tabstop` | Goto next snippet placeholder |
| `goto_prev_tabstop` | Goto previous snippet placeholder |
| `rotate_selections_first` | Make first selection primary |
| `rotate_selections_last` | Make last selection primary |

---

## Typable commands (99)

Used as `:name` in keymaps or typed in command mode. Aliases in parentheses.

| Name (aliases) | Description |
|---|---|
| `:exit` (`:x`, `:xit`) | Write modified buffer and quit |
| `:exit!` (`:x!`, `:xit!`) | Force write and quit |
| `:quit` (`:q`) | Close current view |
| `:quit!` (`:q!`) | Force close current view |
| `:open` (`:o`, `:edit`, `:e`) | Open file |
| `:buffer-close` (`:bc`, `:bclose`) | Close current buffer |
| `:buffer-close!` (`:bc!`, `:bclose!`) | Force close buffer |
| `:buffer-close-others` (`:bco`, `:bcloseother`) | Close other buffers |
| `:buffer-close-others!` (`:bco!`, `:bcloseother!`) | Force close other buffers |
| `:buffer-close-all` (`:bca`, `:bcloseall`) | Close all buffers |
| `:buffer-close-all!` (`:bca!`, `:bcloseall!`) | Force close all buffers |
| `:buffer-next` (`:bn`, `:bnext`) | Next buffer |
| `:buffer-previous` (`:bp`, `:bprev`) | Previous buffer |
| `:write` (`:w`) | Write to disk |
| `:write!` (`:w!`) | Force write (create dirs) |
| `:write-buffer-close` (`:wbc`) | Write and close buffer |
| `:write-buffer-close!` (`:wbc!`) | Force write and close |
| `:new` (`:n`) | New scratch buffer |
| `:format` (`:fmt`) | Format file |
| `:indent-style` | Set indent style (`t` for tab, 1-16 for spaces) |
| `:line-ending` | Set line ending (crlf, lf) |
| `:earlier` (`:ear`) | Jump back in edit history |
| `:later` (`:lat`) | Jump forward in edit history |
| `:write-quit` (`:wq`) | Write and close view |
| `:write-quit!` (`:wq!`) | Force write and close |
| `:write-all` (`:wa`) | Write all buffers |
| `:write-all!` (`:wa!`) | Force write all buffers |
| `:write-quit-all` (`:wqa`, `:xa`) | Write all and quit all |
| `:write-quit-all!` (`:wqa!`, `:xa!`) | Force write all and quit |
| `:quit-all` (`:qa`) | Close all views |
| `:quit-all!` (`:qa!`) | Force close all views |
| `:cquit` (`:cq`) | Quit with exit code (default 1) |
| `:cquit!` (`:cq!`) | Force quit with exit code |
| `:theme` | Change theme |
| `:yank-join` | Yank joined (optional separator) |
| `:clipboard-yank` | Yank main selection to clipboard |
| `:clipboard-yank-join` | Yank joined to clipboard |
| `:primary-clipboard-yank` | Yank to primary clipboard |
| `:primary-clipboard-yank-join` | Yank joined to primary |
| `:clipboard-paste-after` | Paste clipboard after |
| `:clipboard-paste-before` | Paste clipboard before |
| `:clipboard-paste-replace` | Replace with clipboard |
| `:primary-clipboard-paste-after` | Paste primary after |
| `:primary-clipboard-paste-before` | Paste primary before |
| `:primary-clipboard-paste-replace` | Replace with primary |
| `:show-clipboard-provider` | Show clipboard provider |
| `:change-current-directory` (`:cd`) | Change CWD |
| `:show-directory-stack` | Show directory stack |
| `:push-directory` (`:pushd`) | Push and change directory |
| `:pop-directory` (`:popd`) | Pop directory |
| `:show-directory` (`:pwd`) | Show CWD |
| `:encoding` | Set encoding |
| `:character-info` (`:char`) | Info about char under cursor |
| `:reload` (`:rl`) | Reload file from disk |
| `:reload-all` (`:rla`) | Reload all files |
| `:update` (`:u`) | Write if modified |
| `:lsp-workspace-command` | LSP workspace command picker |
| `:lsp-restart` | Restart language servers |
| `:lsp-stop` | Stop language servers |
| `:tree-sitter-scopes` | Show tree-sitter scopes |
| `:tree-sitter-highlight-name` | Show highlight scope name |
| `:tree-sitter-layers` | Show injection layers |
| `:debug-start` (`:dbg`) | Start debug session |
| `:debug-remote` (`:dbg-tcp`) | Connect via TCP debug adapter |
| `:debug-eval` | Evaluate expression in debug context |
| `:vsplit` (`:vs`) | Open file in vertical split |
| `:vsplit-new` (`:vnew`) | Scratch buffer in vertical split |
| `:hsplit` (`:hs`, `:sp`) | Open file in horizontal split |
| `:hsplit-new` (`:hnew`) | Scratch buffer in horizontal split |
| `:tutor` | Open tutorial |
| `:goto` (`:g`) | Goto line number |
| `:set-language` (`:lang`) | Set buffer language |
| `:set-option` (`:set`) | Set config option at runtime |
| `:toggle-option` (`:toggle`) | Toggle config option |
| `:get-option` (`:get`) | Get config option value |
| `:sort` | Sort ranges (`-i` case insensitive, `-r` reverse) |
| `:reflow` | Hard-wrap selection to width |
| `:tree-sitter-subtree` (`:ts-subtree`) | Show syntax subtree |
| `:config-reload` | Refresh config |
| `:config-open` | Open global config.toml |
| `:config-open-workspace` | Open workspace config.toml |
| `:log-open` | Open log file |
| `:insert-output` | Run shell, insert output |
| `:append-output` | Run shell, append output |
| `:pipe` (`:\|`) | Pipe selection to shell |
| `:pipe-to` | Pipe selection to shell, ignore output |
| `:run-shell-command` (`:sh`, `:!`) | Run shell command |
| `:reset-diff-change` (`:diffget`, `:diffg`) | Reset diff hunk |
| `:clear-register` | Clear register (or all) |
| `:set-register` | Set register contents |
| `:redraw` | Clear and re-render UI |
| `:move` (`:mv`) | Move file |
| `:move!` (`:mv!`) | Force move file |
| `:yank-diagnostic` | Yank diagnostic under cursor |
| `:read` (`:r`) | Load file into buffer |
| `:echo` | Print to statusline |
| `:noop` | Do nothing |
| `:workspace-trust` | Trust current workspace |
| `:workspace-untrust` | Untrust current workspace |

---

## Macro commands

Referenced in keymaps as `@<register>` (e.g., `@a`, `@m`). Replays the key sequence recorded into that register via `qm (keys) q`.

---

## Default keybinding structure

Default keymap defined in `helix-term/src/keymap/default.rs`:
- **Normal mode:** ~340 bindings across `hjkl`, `wbe`, `fFtT`, `dcyp`, `/?nN`, `g`, `C-w`/`space w`, `z`/`Z`, `m`, `[]`, `space` pickers, etc.
- **Select mode:** Cloned from normal with `extend_*` overrides for movement
- **Insert mode:** ~25 bindings (`esc` to normal, completion, register insert)
