# Dotfiles

A Windows terminal environment built around [WezTerm](https://wezfurlong.org/wezterm/)
and [Neovim](https://neovim.io/), kept under version control and installed onto
a fresh machine with one command.

## Overview

WezTerm is configured entirely in Lua. There is no settings GUI and no JSON
file. That makes the configuration a real program, which is why this repo is
worth having: the terminal's appearance, tab rendering, and key bindings are
all code that can be diffed, reverted, and carried to another machine.

This repository holds the source of truth. A directory junction connects it to
the path WezTerm actually reads, so the file lives here and runs there. Neovim
is linked the same way, and Herdr through an environment variable. Three
configs, one repo, and no copies to keep in sync.

### Key Features

- 🎨 **Catppuccin Mocha throughout.** Matching theme, tab bar, and status line,
  with the active-tab colour pulled from the same palette.
- ⚡ **Zero font installation.** WezTerm bundles JetBrains Mono and Nerd Font
  Symbols internally. Ligatures and icons render on a fresh machine with
  nothing installed.
- 🪟 **Native Windows 11 acrylic.** Real system backdrop blur behind the
  window, not a faked translucent image.
- 🔗 **Admin-free linking.** Uses a directory junction rather than a symlink,
  so no elevation and no Developer Mode required.
- ⌨️ **tmux-style leader key.** `Ctrl+a` prefix for splits, panes, and
  workspace navigation.
- 🔄 **Hot reload.** The config re-applies on save, with no restart.
- 🧩 **Herdr layered on top.** Multiplexer and agent panel sharing WezTerm's
  palette, with keybindings chosen so the two never collide.
- ⌨️ **Neovim with a real LSP setup.** Lazy-loaded plugins, language servers
  installed on demand by Mason, format-on-save, and the same Mocha palette
  showing WezTerm's acrylic through a transparent background.
- 🔒 **Plugin versions pinned.** `nvim/lazy-lock.json` is tracked, so a fresh
  machine resolves to the same plugin commits rather than whatever is on HEAD
  that day.
- 📦 **One-command setup.** `.\dot.ps1 init` installs the stack from winget,
  links every config, and verifies the result. Idempotent, and no admin rights.
- 🩺 **A health check that catches silent drift.** `.\dot.ps1 doctor` proves the
  junctions still resolve back to this repo and that Herdr is reading the config
  in it — the two failures here that break nothing visibly.

## Quick Start

```bash
git clone https://github.com/connordevitt/dotfiles.git C:\Repositorys\dotfiles
```

```powershell
cd C:\Repositorys\dotfiles
.\dot.ps1 init
```

`init` installs the stack with winget, links this repo into the paths WezTerm
and Neovim actually read, points Herdr at its config, and finishes with a
health check. No administrator rights, and safe to re-run.

Then open a **new** WezTerm window and run `nvim` once while plugins install.
That is the entire setup.

Prefer to do it by hand? See [Manual setup](#manual-setup).

## Repository Structure

```
dotfiles/
├── README.md
├── .gitignore
├── dot.ps1                # bootstrap + maintenance CLI
├── packages/
│   └── winget.txt         # winget package IDs, one per line
├── herdr/
│   └── config.toml        # Herdr multiplexer: theme, keys, agent panel
├── nvim/
│   ├── init.lua           # entry point: three requires, load order matters
│   ├── lazy-lock.json     # pinned plugin commits, tracked on purpose
│   ├── stylua.toml        # Lua formatting rules for this repo
│   └── lua/
│       ├── config/
│       │   ├── options.lua    # vim.opt, leader key, autocmds
│       │   ├── lazy.lua       # plugin-manager bootstrap
│       │   └── keymaps.lua    # editor-level bindings
│       └── plugins/           # one file per concern, auto-imported
│           ├── colorscheme.lua
│           ├── ui.lua         # statusline, bufferline, indent guides
│           ├── editor.lua     # file tree, git signs, which-key
│           ├── telescope.lua  # fuzzy finder
│           ├── treesitter.lua # parsers, text objects
│           ├── lsp.lua        # servers, diagnostics, LSP keymaps
│           ├── completion.lua # blink.cmp
│           └── format.lua     # conform.nvim, format on save
└── wezterm/
    └── wezterm.lua        # terminal: theme, font, tabs, keybindings
```

The three are designed to sit inside one another. Neovim runs in Herdr, and
Herdr runs in a WezTerm window, so they share a palette and avoid colliding on
keys.

## The `dot.ps1` CLI

One script at the repo root handles setup and maintenance. Every command is
idempotent, and none of them need elevation.

| Command | What it does |
| --- | --- |
| `init` | Install packages, link configs, verify. The one-command setup. |
| `install` | Install the winget packages listed in `packages/winget.txt`. |
| `agents` | Install the agent CLIs: Claude Code and Codex. |
| `link` | Create the junctions and set `HERDR_CONFIG_PATH`. |
| `unlink` | Remove the junctions and clear `HERDR_CONFIG_PATH`. |
| `doctor` | Diagnose the environment. Exits non-zero if anything failed. |
| `update` | `git pull`, upgrade packages, re-link, verify. |
| `check-packages` | Manifest versus what is actually installed. |

| Flag | Effect |
| --- | --- |
| `-WithAgents` | Also install the agent CLIs during `init` or `install`. |
| `-SkipInstall` | `init` links and verifies without installing anything. |
| `-Yes` | Assume yes at every prompt, including the remote install scripts. |

Agent CLIs are opt-in. `init` sets up the terminal and editor only; nothing
pulls in Claude Code or Codex unless you ask:

```powershell
.\dot.ps1 agents          # or: .\dot.ps1 init -WithAgents
```

### Why `doctor` exists

Both failure modes this repo warns about are silent. A missing
`HERDR_CONFIG_PATH` leaves Herdr running happily from the wrong file, and a
stray `%USERPROFILE%\.wezterm.lua` outranks the whole repo. Nothing breaks
visibly in either case, so nothing prompts you to look. `doctor` looks:

```powershell
.\dot.ps1 doctor
```

It checks every package, that the junctions resolve back to this repo rather
than merely existing, that Neovim is new enough for `vim.lsp.config`, and that
Herdr's config path points where it should. Run it first whenever something
seems off.

### A note on remote install scripts

Two tools here cannot come from winget. Claude Code ships its own installer,
and Herdr is not packaged for Windows at all. `dot.ps1` prints the exact
command and asks before running Herdr's, rather than piping a third-party
script into your shell on your behalf. `-Yes` skips the prompt if you would
rather it did not ask.

## The WezTerm Config

Everything lives in `wezterm/wezterm.lua`, organised into commented sections.

### Appearance

| Setting | Value |
| --- | --- |
| Colour scheme | Catppuccin Mocha |
| Font | JetBrains Mono (bundled), ligatures on |
| Size / line height | 11.5 / 1.1 |
| Opacity | 0.88 with `Acrylic` system backdrop |
| Decorations | `RESIZE` (slim frame, no titlebar) |
| Window | 120 × 32, padded 14px horizontally |
| Cursor | Blinking bar, 600ms |

Inactive panes are dimmed via `inactive_pane_hsb` so the focused pane is
obvious at a glance. Scrollback is 10,000 lines and the audible bell is off.

### Tab Bar & Status Bar

The tab bar uses the retro renderer rather than the fancy one, because the
retro bar is fully themable from Lua. Tabs are drawn as powerline segments
with hard dividers, and each tab shows an icon chosen from the process
running in it: PowerShell, cmd, git, vim, WSL, node, python, ssh.

The right status line shows the current directory and a clock.

### Shells

`powershell.exe -NoLogo` is the default. The launcher (`Ctrl+a` then `l`)
offers PowerShell, Command Prompt, and WSL.

### Keybindings

Leader is `Ctrl+a`, pressed before the listed key.

| Binding | Action |
| --- | --- |
| `Leader` + `\` | Split into left and right panes |
| `Leader` + `-` | Split into top and bottom panes |
| `Leader` + `x` | Close the focused pane |
| `Leader` + `z` | Zoom / unzoom pane |
| `Leader` + `l` | Launcher (pick a shell) |
| `Leader` + `r` | Rename current tab |
| `Alt` + arrows | Move between panes |
| `Alt`+`Shift` + arrows | Resize pane |
| `Ctrl`+`Shift` + `T` / `W` | New / close tab |
| `Ctrl` + `Tab` | Next tab (add `Shift` for previous) |
| `Ctrl` + `1` to `9` | Jump to tab N |
| `Ctrl`+`Shift` + `P` | Command palette |
| `Ctrl`+`Shift` + `F` | Search scrollback |
| `Ctrl`+`Shift` + `C` / `V` | Copy / paste |
| `Ctrl` + `=` / `-` / `0` | Font size up / down / reset |
| `Ctrl`+`Shift` + `R` | Reload config |
| `F11` | Fullscreen |

### Panes

The layout worth knowing is an agent in one pane and an editor in the other,
side by side in a single window:

```
Ctrl+a  \        split into left and right
                 (left pane keeps focus, run your agent here)
Alt+Right        move to the right pane
nvim             open the editor there
```

Closing a pane again:

| Way | Behaviour |
| --- | --- |
| `Ctrl+a` then `x` | Closes the focused pane |
| `exit` | Shell exits, pane closes with it, never prompts |
| `Ctrl+d` | Same as `exit`, on an empty prompt |

`Leader+x` is bound with `confirm = true`, but that does not mean it always
asks. WezTerm keeps a default `skip_close_confirmation_for_processes_named`
list that includes `powershell.exe` and `pwsh.exe`, so a pane sitting at a
plain prompt closes instantly. The prompt only appears when something else is
running in the pane, which is exactly when it is wanted: an editor with unsaved
work, or an agent mid-task. Nothing in this repo overrides that list.

When the last pane in a tab closes, the tab closes. When the last tab closes,
so does the window, and `window_close_confirmation = 'NeverPrompt'` means it
goes without asking.

`Ctrl+a` then `z` is worth having in muscle memory alongside these. It zooms
the focused pane to fill the window and leaves the other one running behind
it, which beats closing a pane just to read something in full width.

⚠️ The two layers disagree on what to call these splits, and both names are
misleading. `Leader+\` maps to WezTerm's `SplitHorizontal`, while Herdr calls
the same key `split_vertical`. Neither name describes the result: **`\` always
gives you left and right panes, and `-` always gives you top and bottom**, at
either layer. Ignore the names and remember the keys.

## Herdr

[Herdr](https://herdr.dev) is a terminal multiplexer with an agent panel. It
provides workspaces, tabs, and splits, plus a sidebar tracking the state of any
AI agents running in panes. It runs *inside* WezTerm, so the two configs are
written to cooperate rather than fight.

That sidebar is the reason to run the two-pane layout at this layer rather than
in WezTerm directly. Herdr knows which pane holds an agent and shows you when
it wants attention, and the workspace persists in `session.json` instead of
dying with the window.

### Loading

Herdr reads a single `config.toml`, and on Windows that lives at
`%APPDATA%\herdr\`. That directory is **not** junctioned like WezTerm's,
because Herdr also keeps live runtime state there (sockets, logs, and
`session.json`), none of which belongs in version control.

Instead Herdr's own override is used:

```powershell
[Environment]::SetEnvironmentVariable(
  'HERDR_CONFIG_PATH',
  'C:\Repositorys\dotfiles\herdr\config.toml',
  'User')
```

Set once, persists across reboots, needs no admin, and leaves the runtime
directory alone.

⚠️ If `HERDR_CONFIG_PATH` is ever unset, Herdr silently falls back to
`%APPDATA%\herdr\config.toml`, which still exists. The terminal keeps
working, just from the wrong config. Same failure shape as the WezTerm
precedence trap below.

### Keybindings

Prefix is `Ctrl+;`, pressed before the listed key. Only the keys this repo
changes or relies on are listed; `prefix+?` shows the full set.

| Binding | Action |
| --- | --- |
| `Prefix` + `\` | Split into left and right panes |
| `Prefix` + `-` | Split into top and bottom panes |
| `Prefix` + `x` | Close the focused pane |
| `Prefix` + `s` / `w` | Workspace picker |
| `Prefix` + `d` / `q` | Detach |
| `Prefix` + `r` | Reload config |
| `Prefix` + `,` | Rename tab |
| `Prefix` + `v` | Keyboard copy mode |
| `Prefix` + `Shift`+`S` | Settings |
| `Prefix` + `Alt` + `1` to `9` | Focus agent N |

The split and close keys deliberately match WezTerm's, so the same two
keystrokes do the same thing whether or not Herdr is running.

### What Differs From Upstream

Adapted from [dmmulroy's Herdr config](https://github.com/dmmulroy/.dotfiles),
with these deliberate changes for this machine:

- **Shell.** `fish` becomes `powershell.exe`. Change it to `pwsh.exe` if
  PowerShell 7 is ever installed.
- **Palette.** His uses Catppuccin **Macchiato**, and Herdr's bundled
  catppuccin theme is Macchiato too. Overridden to **Mocha** to match
  `wezterm.lua`, since a Macchiato panel inside a Mocha terminal reads as a
  mismatch. Accent is green, matching the active tab.
- **Prefix.** Kept at `ctrl+semicolon`, deliberately **not** `ctrl+a`, which
  is WezTerm's leader. A shared prefix would make the inner and outer
  multiplexer fight over every keystroke.
- **Splits.** `prefix+\` and `prefix+-`, mirroring WezTerm's `leader+\` and
  `leader+-` so the same keys split a pane at either level.
- **Vim navigation.** His `ctrl+h/j/k/l` bindings are commented out here.
  They are `plugin_action` bindings requiring the `vim-herdr-navigation`
  plugin, which is not installed.
- **Omitted keys.** `theme.custom.active_row_bg`, `theme.custom.selection_bg`,
  and `ui.status_indicators` are in Herdr's published reference but rejected by
  the installed `0.8.0-preview.2026-08-04` build. Left out with notes inline.

### Verifying

```powershell
herdr config check
```

`config: ok` means the file parses and every key is recognised. It names any
unknown keys individually, which is the fastest way to spot options that
have drifted between Herdr versions.

Apply changes to a running instance with `prefix+r`, or:

```powershell
herdr server reload-config
```

## Neovim

Neovim is installed from winget and configured in Lua, for the same reason
WezTerm is: the configuration is a program, not a settings screen. It sits at
the innermost layer of the stack, running inside Herdr inside WezTerm.

The config is deliberately modular. `init.lua` is three `require` calls, and
every plugin lives in its own file under `lua/plugins/`, auto-imported by
lazy.nvim. Adding a plugin means adding a file, and removing one means deleting
that file.

### Load Order

`init.lua` runs three requires and the order is not cosmetic:

1. `config.options` sets `vim.g.mapleader` **before** anything else. Plugin
   keymaps are registered against whatever the leader is at load time, so a
   leader set after lazy.nvim runs would silently apply to nothing.
2. `config.lazy` bootstraps the plugin manager and loads `lua/plugins/*`.
3. `config.keymaps` runs last, so these bindings win over any plugin default.

### Appearance

| Setting | Value |
| --- | --- |
| Colour scheme | Catppuccin Mocha, `transparent_background = true` |
| Statusline | lualine with `globalstatus`, one bar for all splits |
| Buffer tabs | bufferline, with the file tree offset out of the way |
| Line numbers | Absolute + relative, cursor line in green (`#a6e3a1`) |
| Indent guides | indent-blankline, current scope highlighted |
| Signs | Always-on sign column, so text does not jitter |

Transparency is the point of the colour setup: WezTerm draws real Windows 11
acrylic behind the window, and an opaque editor background would paint over it.
Floating windows are given a solid `mantle` background so they stay readable
against whatever is showing through.

### Plugins

| Plugin | Purpose |
| --- | --- |
| lazy.nvim | Plugin manager; lazy-loads on key, command, or event |
| catppuccin | Colour scheme, shared palette with WezTerm and Herdr |
| telescope | Fuzzy finder for files, grep, buffers, LSP symbols |
| nvim-treesitter | Parser-driven highlighting, indentation, text objects |
| nvim-lspconfig + mason | Language servers, downloaded on demand |
| blink.cmp | Completion; prebuilt Rust matcher, nothing to compile |
| conform.nvim | Formatting, including format on save |
| mason-tool-installer | Installs the formatters Mason's LSP half ignores |
| neo-tree | Sidebar file explorer (netrw is disabled) |
| gitsigns | Gutter signs, hunk staging, inline blame |
| which-key | Shows what the pending leader key can do |
| lualine / bufferline | Statusline and buffer tabs |
| nvim-surround, autopairs, todo-comments | Small editing conveniences |

Plugin commits are pinned in `nvim/lazy-lock.json`, which is tracked. `:Lazy
update` rewrites it, so commit the result and another machine gets the same
versions rather than whatever happens to be on HEAD.

### Keybindings

Leader is `<Space>`. That is a third distinct prefix on purpose: WezTerm's
leader is `Ctrl+a` and Herdr's is `Ctrl+;`, so no keystroke is claimed twice
across the three layers.

Press `<Space>` and wait. which-key lists everything below without needing this
table.

| Binding | Action |
| --- | --- |
| `<leader>` `w` / `q` | Write / quit |
| `<leader>` `ff` | Find files |
| `<leader>` `fg` | Grep across the project (ripgrep) |
| `<leader>` `fb` / `fr` | Buffers / recent files |
| `<leader>` `fk` | Search keymaps |
| `<leader>` `/` | Fuzzy-find in the current buffer |
| `<leader>` `t` / `T` | Toggle file tree / reveal current file |
| `<leader>` `\` / `-` | Split left-right / top-bottom (mirrors WezTerm) |
| `<leader>` `?` | Keymaps for this buffer |
| `Ctrl` + `h/j/k/l` | Move between splits |
| `Ctrl` + arrows | Resize split |
| `Shift` + `h` / `l` | Previous / next buffer |
| `<leader>` `bd` / `bo` | Delete this buffer / all other buffers |
| `gd` / `gr` / `gI` | Definition / references / implementations |
| `K` | Hover documentation |
| `<leader>` `cr` / `ca` | Rename symbol / code action |
| `<leader>` `cf` | Format buffer |
| `<leader>` `ch` | Toggle inlay hints |
| `<leader>` `cs` / `cS` | Document / workspace symbols |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>` `e` | Diagnostics for this line |
| `[h` / `]h` | Previous / next git hunk |
| `<leader>` `gs` / `gr` / `gp` | Stage / reset / preview hunk |
| `<leader>` `gb` / `gd` | Blame line / diff against index |
| `Ctrl` + `Space` | Expand treesitter selection (`Backspace` shrinks) |
| `Esc` `Esc` | Leave terminal mode |

Note that `Ctrl+h/j/k/l` moves between **Neovim's** splits, while `Alt`+arrows
moves between **WezTerm's** panes. Different keys for the two levels, so an
editor split and a terminal pane never fight over the same keystroke.

### Language Servers

Mason downloads server binaries into Neovim's data directory, so nothing is
installed system-wide and nothing needs admin. `lua_ls`, `taplo`, `jsonls`,
`yamlls`, `ts_ls`, `bashls`, and `marksman` are installed automatically on
first launch. Between them they cover every file in this repo, including
`herdr/config.toml`, which is otherwise unvalidated.

Configuration uses Neovim 0.11's native `vim.lsp.config` and `vim.lsp.enable`
rather than the older `require('lspconfig').server.setup{}` pattern.
`nvim-lspconfig` is still a dependency, but only as the shipped catalogue of
server definitions.

`mason-lspconfig`'s `automatic_enable` is turned off deliberately. Left on, it
enables every server-ish package Mason has installed, which quietly attaches
`stylua --lsp` as a formatting server on top of conform and formats Lua twice.
The explicit server list at the bottom of `lsp.lua` is the only thing that
should decide what attaches.

`lua_ls` is given `diagnostics.globals = { 'vim' }`, without which every line
of this repo's own config is reported as an undefined global.

### Formatting

`conform.nvim` formats on save with an 800ms budget, falling back to the
language server when no dedicated formatter is configured. Lua goes through
stylua, and `lua_ls`'s own formatter is disabled in `lsp.lua` so the two cannot
disagree.

Formatters are not language servers, so `mason-lspconfig` does not install
them. `mason-tool-installer` does, from the same registry: stylua, prettierd,
ruff, and shfmt arrive on first launch. Lua style for this repo is pinned in
`nvim/stylua.toml` at 2 spaces and single quotes, matching `wezterm.lua`.

Turn it off when a reformat would bury a real diff:

```vim
:FormatDisable     " everywhere
:FormatDisable!    " this buffer only
:FormatEnable      " back on
```

### Windows-Specific Notes

Three things about this config exist only because it runs on Windows:

- **Shell.** `:terminal` and `:!` default to `cmd.exe`. `options.lua` repoints
  them at `pwsh` (falling back to `powershell`) with UTF-8 forced on both
  encodings, otherwise output arrives mojibaked.
- **Treesitter needs a C compiler.** Parsers are compiled from source on
  install, and Windows ships without one. `zig` is installed via winget and
  nvim-treesitter picks it up off `PATH` automatically. That is the whole
  reason zig is a prerequisite; nothing in this repo is written in it.
- **telescope-fzf-native is conditional.** Its native sorter needs cmake *and*
  a working MSVC toolchain, so the spec guards it with `cond`. Without them
  Telescope silently uses its Lua sorter, which is slower but correct.

### Verifying

```powershell
nvim --headless "+checkhealth" +qa    # written to the message history
nvim +Lazy                             # plugin status, load times, updates
nvim +Mason                            # installed language servers
```

Inside Neovim, `:checkhealth` is the fastest triage: it reports missing
external tools (`rg`, `fd`, `zig`, node) per-plugin rather than failing
silently at the moment they are needed.

## Configuration

### How Linking Works

WezTerm and Neovim both only read configuration from fixed paths inside the
user's home directory, so the files cannot simply sit in a repository and be
found. A **directory junction** bridges each of them:

```
C:\Users\<you>\.config\wezterm       ==>  C:\Repositorys\dotfiles\wezterm
C:\Users\<you>\AppData\Local\nvim    ==>  C:\Repositorys\dotfiles\nvim
```

Neovim's junction is at the directory level for a second reason beyond
convenience: the config is a whole `lua/` tree, not one file, and lazy.nvim
writes `lazy-lock.json` back into it. Both sides of that need to land in the
repository, not in `%LOCALAPPDATA%`.

A junction was chosen deliberately over the alternatives:

- **Symbolic link.** Requires either an elevated shell or Developer Mode
  enabled. Not assumable on a normal Windows account.
- **Hard link.** Works without elevation, but silently breaks the first time
  an editor saves by writing a new file and renaming over the old one. The two
  paths then quietly diverge, which is a miserable bug to track down.
- **Junction** ✅. No elevation, operates at the directory level, and is
  unaffected by how individual files inside are written.

### Config Precedence on Windows

Verified against `wezterm 20240203-110809-5046fc22`, WezTerm resolves its
config in this order:

1. `$WEZTERM_CONFIG_FILE`
2. `%USERPROFILE%\.wezterm.lua`
3. `%USERPROFILE%\.config\wezterm\wezterm.lua` ← this repo

⚠️ Note this is the **reverse** of WezTerm's documented Unix ordering, where
`.config` wins. On Windows a stray `~/.wezterm.lua` takes priority and will
silently shadow this repository. The terminal keeps working, just from the
wrong file. If edits here stop having any effect, check for that file first.

### Customization

Change the theme by editing one line:

```lua
config.color_scheme = 'Catppuccin Mocha'
```

Roughly a thousand schemes ship with WezTerm. Rather than guessing names,
press `Ctrl+Shift+P` and choose **Set Color Scheme** to preview them live.

The active tab colour is set in the `format-tab-title` handler, with the rest
of the Catppuccin palette listed in a comment directly above it:

```lua
local bg = tab.is_active and '#a6e3a1' or (hover and '#45475a' or '#1e1e2e')
```

For an opaque window instead of acrylic, set `window_background_opacity = 1.0`.

Changing the theme means changing it in three places, because each layer picks
its own colours and a mismatch is immediately visible:

| Layer | File | Setting |
| --- | --- | --- |
| WezTerm | `wezterm/wezterm.lua` | `config.color_scheme` |
| Herdr | `herdr/config.toml` | `theme` |
| Neovim | `nvim/lua/plugins/colorscheme.lua` | `flavour`, plus the plugin itself |

Neovim's is the awkward one: the colour scheme is a plugin, so a different
theme means swapping the `catppuccin/nvim` entry for another repo and updating
the `vim.cmd.colorscheme` call at the bottom of the same file. Leave
`transparent_background` on or the acrylic backdrop disappears behind the
editor.

## Environment Setup

### Prerequisites

- **WezTerm.** Windows build, 20240203 or newer.
- **Neovim.** 0.11 or newer, because the LSP setup uses `vim.lsp.config`,
  which does not exist before that.
- **Git.** Required at runtime, not just to clone: lazy.nvim fetches every
  plugin with it.
- **zig.** C compiler for Treesitter parsers. Any of MSVC, gcc, or clang works
  instead; zig is the smallest thing to install that satisfies it.
- **ripgrep** and **fd.** Telescope's grep and file pickers shell out to these.

All of it is on winget, WezTerm included. `.\dot.ps1 install` reads the same
list from `packages/winget.txt`, so the two never drift apart:

```powershell
winget install wez.wezterm Neovim.Neovim Git.Git zig.zig BurntSushi.ripgrep.MSVC sharkdp.fd
```

No fonts are needed. Fonts ship inside WezTerm.

Herdr is the exception. It is not on winget and publishes no Windows binaries,
so its only install path is a remote script, which its own README labels a beta:

```powershell
irm https://herdr.dev/install.ps1 | iex
```

`dot.ps1` shows you that command and asks before running it.

### Manual setup

`.\dot.ps1 init` does all of this. The steps stay documented because
understanding the wiring matters more than the script that applies it.

1. Clone this repository to `C:\Repositorys\dotfiles`.
2. Install the prerequisites with the winget line above.
3. Delete `%USERPROFILE%\.wezterm.lua` if one exists, because it outranks this
   repo and will shadow it.
4. Create both junctions:

   ```powershell
   cmd /c mklink /J "$env:USERPROFILE\.config\wezterm" "C:\Repositorys\dotfiles\wezterm"
   cmd /c mklink /J "$env:LOCALAPPDATA\nvim" "C:\Repositorys\dotfiles\nvim"
   ```

5. Point Herdr at its config. Easy to forget, and forgetting it fails silently:

   ```powershell
   [Environment]::SetEnvironmentVariable(
     'HERDR_CONFIG_PATH',
     'C:\Repositorys\dotfiles\herdr\config.toml',
     'User')
   ```

6. Launch WezTerm, or press `Ctrl+Shift+R` in a running window.
7. Run `nvim`. lazy.nvim clones itself, installs every plugin, and Mason pulls
   the language servers. This takes a minute or two and happens exactly once.
   Treesitter parsers compile in the background afterwards.
8. Confirm it all took: `.\dot.ps1 doctor`.

Verify the config is the one being loaded:

```powershell
wezterm ls-fonts
```

JetBrains Mono listed as the primary font means this repo is live. Cascadia
Mono or a system default means WezTerm fell back. See Troubleshooting.

And that Neovim is reading this repo rather than a stray config:

```powershell
nvim --headless "+echo stdpath('config')" +qa
```

It should print `C:\Users\<you>\AppData\Local\nvim`, the junction, which
resolves back here. A `<Space>` that opens which-key is the quicker informal
check.

## Troubleshooting

Start here:

```powershell
.\dot.ps1 doctor
```

It names the broken thing and the fix for most of what follows. The entries
below explain why each failure happens.

### Common Issues

**Edits have no effect.**
Usually a leftover `%USERPROFILE%\.wezterm.lua` shadowing the repo. Delete it.
Otherwise the running window may predate the config file existing. WezTerm
watches the config path, and if nothing was there at launch there was nothing
to watch. `Ctrl+Shift+R` forces a fresh search.

**`mklink` reports "Cannot create a file when that file already exists."**
`%USERPROFILE%\.config\wezterm` already exists as a real directory. Remove it
first, then re-run the junction command.

**Symlink attempt fails with "Administrator privilege required."**
Expected on a standard account. Use the `/J` junction, not a symlink.

**A config error is suspected.**
Both commands below load the config and report Lua errors without opening a
window:

```powershell
wezterm ls-fonts
wezterm show-keys
```

**Glyphs render as boxes.**
The bundled Nerd Font Symbols fallback is not being reached. Confirm the
`font_with_fallback` list in `wezterm.lua` still includes it.

**Neovim opens with no colours and no plugins.**
lazy.nvim never bootstrapped. It needs `git` on `PATH` at *runtime*, not only
at clone time. Running `nvim --headless "+Lazy! sync" +qa` will show the clone
error plainly.

**`nvim` is not recognised as a command.**
The shell predates the install. Processes inherit `PATH` at launch, so a
terminal opened before winget installed Neovim will never see it. Open a new
tab or window.

**`:TSInstall` fails with "no C compiler found".**
zig has fallen off `PATH`. winget installs it under
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\`, which a `PATH` edit can drop.
`nvim +checkhealth` names every missing external tool at once.

**Highlighting is plain but everything else works.**
The parser for that filetype has not compiled yet. `auto_install` fetches it on
first open, so it usually fixes itself on the second visit to the file. Force
it with `:TSInstall <lang>` and read the compiler error if it does not.

**Telescope's grep finds nothing.**
`rg` is not on `PATH`. The file picker keeps working because it can fall back
to Neovim's own file listing, so this shows up as grep alone being broken.

**Editing a file reformats half of it.**
Format on save, with a formatter whose style disagrees with the file.
`:FormatDisable!` turns it off for the current buffer, and `:ConformInfo` names
the formatter that ran.

## Acknowledgments

README structure inspired by [dmmulroy/.dotfiles](https://github.com/dmmulroy/.dotfiles).
