# Dotfiles

A Windows terminal configuration built around [WezTerm](https://wezfurlong.org/wezterm/),
kept under version control and linked into place with a single command.

## Overview

WezTerm is configured entirely in Lua — there is no settings GUI and no JSON
file. That makes the configuration a real program, which is why this repo is
worth having: the terminal's appearance, tab rendering, and key bindings are
all code that can be diffed, reverted, and carried to another machine.

This repository holds the source of truth. A directory junction connects it to
the path WezTerm actually reads, so the file lives here and runs there.

### Key Features

- 🎨 **Catppuccin Mocha throughout** — matching theme, tab bar, and status line,
  with the active-tab colour pulled from the same palette.
- ⚡ **Zero font installation** — WezTerm bundles JetBrains Mono and Nerd Font
  Symbols internally. Ligatures and icons render on a fresh machine with
  nothing installed.
- 🪟 **Native Windows 11 acrylic** — real system backdrop blur behind the
  window, not a faked translucent image.
- 🔗 **Admin-free linking** — uses a directory junction rather than a symlink,
  so no elevation and no Developer Mode required.
- ⌨️ **tmux-style leader key** — `Ctrl+a` prefix for splits, panes, and
  workspace navigation.
- 🔄 **Hot reload** — the config re-applies on save; no restart.

## Quick Start

```bash
git clone https://github.com/connordevitt/dotfiles.git C:\Repositorys\dotfiles
```

```powershell
cmd /c mklink /J "$env:USERPROFILE\.config\wezterm" "C:\Repositorys\dotfiles\wezterm"
```

Open WezTerm. That is the entire setup.

## Repository Structure

```
dotfiles/
├── README.md
├── .gitignore
└── wezterm/
    └── wezterm.lua        # the whole configuration, one file
```

## The WezTerm Config

Everything lives in `wezterm/wezterm.lua`, organised into commented sections.

### Appearance

| Setting | Value |
| --- | --- |
| Colour scheme | Catppuccin Mocha |
| Font | JetBrains Mono (bundled), ligatures on |
| Size / line height | 11.5 / 1.1 |
| Opacity | 0.88 with `Acrylic` system backdrop |
| Decorations | `RESIZE` — slim frame, no titlebar |
| Window | 120 × 32, padded 14px horizontally |
| Cursor | Blinking bar, 600ms |

Inactive panes are dimmed via `inactive_pane_hsb` so the focused pane is
obvious at a glance. Scrollback is 10,000 lines and the audible bell is off.

### Tab Bar & Status Bar

The tab bar uses the retro renderer rather than the fancy one, because the
retro bar is fully themable from Lua. Tabs are drawn as powerline segments
with hard dividers, and each tab shows an icon chosen from the process
running in it — PowerShell, cmd, git, vim, WSL, node, python, ssh.

The right status line shows the current directory and a clock.

### Shells

`powershell.exe -NoLogo` is the default. The launcher (`Ctrl+a` then `l`)
offers PowerShell, Command Prompt, and WSL.

### Keybindings

Leader is `Ctrl+a`, pressed before the listed key.

| Binding | Action |
| --- | --- |
| `Leader` + `\` | Split horizontally |
| `Leader` + `-` | Split vertically |
| `Leader` + `x` | Close pane |
| `Leader` + `z` | Zoom / unzoom pane |
| `Leader` + `l` | Launcher (pick a shell) |
| `Leader` + `r` | Rename current tab |
| `Alt` + arrows | Move between panes |
| `Alt`+`Shift` + arrows | Resize pane |
| `Ctrl`+`Shift` + `T` / `W` | New / close tab |
| `Ctrl` + `Tab` | Next tab (add `Shift` for previous) |
| `Ctrl` + `1`–`9` | Jump to tab N |
| `Ctrl`+`Shift` + `P` | Command palette |
| `Ctrl`+`Shift` + `F` | Search scrollback |
| `Ctrl`+`Shift` + `C` / `V` | Copy / paste |
| `Ctrl` + `=` / `-` / `0` | Font size up / down / reset |
| `Ctrl`+`Shift` + `R` | Reload config |
| `F11` | Fullscreen |

## Configuration

### How Linking Works

WezTerm only reads its configuration from fixed paths inside the user's home
directory, so the file cannot simply sit in a repository and be found. A
**directory junction** bridges the two:

```
C:\Users\<you>\.config\wezterm  ==>  C:\Repositorys\dotfiles\wezterm
```

A junction was chosen deliberately over the alternatives:

- **Symbolic link** — requires either an elevated shell or Developer Mode
  enabled. Not assumable on a normal Windows account.
- **Hard link** — works without elevation, but silently breaks the first time
  an editor saves by writing a new file and renaming over the old one. The two
  paths then quietly diverge, which is a miserable bug to track down.
- **Junction** ✅ — no elevation, operates at the directory level, and is
  unaffected by how individual files inside are written.

### Config Precedence on Windows

Verified against `wezterm 20240203-110809-5046fc22`, WezTerm resolves its
config in this order:

1. `$WEZTERM_CONFIG_FILE`
2. `%USERPROFILE%\.wezterm.lua`
3. `%USERPROFILE%\.config\wezterm\wezterm.lua` ← this repo

⚠️ Note this is the **reverse** of WezTerm's documented Unix ordering, where
`.config` wins. On Windows a stray `~/.wezterm.lua` takes priority and will
silently shadow this repository — the terminal keeps working, just from the
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

## Environment Setup

### Prerequisites

- **WezTerm** — Windows build, 20240203 or newer
- **Git**

No fonts, package managers, or runtimes are needed. Fonts ship inside WezTerm.

### First-Time Setup

1. Clone this repository to `C:\Repositorys\dotfiles`.
2. Delete `%USERPROFILE%\.wezterm.lua` if one exists — it outranks this repo
   and will shadow it.
3. Create the junction with the `mklink /J` command from
   [Quick Start](#quick-start).
4. Launch WezTerm, or press `Ctrl+Shift+R` in a running window.

Verify the config is the one being loaded:

```powershell
wezterm ls-fonts
```

JetBrains Mono listed as the primary font means this repo is live. Cascadia
Mono or a system default means WezTerm fell back — see Troubleshooting.

## Troubleshooting

### Common Issues

**Edits have no effect.**
Usually a leftover `%USERPROFILE%\.wezterm.lua` shadowing the repo. Delete it.
Otherwise the running window may predate the config file existing — WezTerm
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
The bundled Nerd Font Symbols fallback is not being reached — confirm the
`font_with_fallback` list in `wezterm.lua` still includes it.

## Acknowledgments

README structure inspired by [dmmulroy/.dotfiles](https://github.com/dmmulroy/.dotfiles).
