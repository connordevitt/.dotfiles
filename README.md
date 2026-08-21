# dotfiles

Personal configuration files, version controlled.

## Layout

```
dotfiles/
└── wezterm/
    └── wezterm.lua     # WezTerm terminal config
```

## How WezTerm finds this config

WezTerm only reads its config from fixed locations in the user's home
directory, so the file cannot simply live in this repo unreferenced.
A **directory junction** links the expected path to this repo:

```
C:\Users\conno\.config\wezterm  ==>  C:\Repositorys\dotfiles\wezterm
```

Edit `wezterm/wezterm.lua` here and WezTerm picks it up — same file,
two paths. Junctions need no admin rights, and unlike a file hardlink
they survive editors that replace files on save.

### Config precedence (Windows)

Verified on wezterm 20240203-110809-5046fc22:

1. `$WEZTERM_CONFIG_FILE`
2. `%USERPROFILE%\.wezterm.lua`   <- highest of the two default paths
3. `%USERPROFILE%\.config\wezterm\wezterm.lua`   <- what we use

Note this is the **opposite** order from WezTerm's documented Unix
behaviour. If a stray `~/.wezterm.lua` ever reappears it will silently
shadow this repo — delete it.

## Recreating the link on a new machine

```powershell
git clone <this-repo> C:\Repositorys\dotfiles
cmd /c mklink /J "$env:USERPROFILE\.config\wezterm" "C:\Repositorys\dotfiles\wezterm"
```

Then open WezTerm, or press `Ctrl+Shift+R` in a running window to reload.

## Notes

- The config hot-reloads on save. `Ctrl+Shift+R` forces a reload.
- Fonts are **bundled inside WezTerm** (JetBrains Mono + Nerd Font
  Symbols), so no font installation is needed on a new machine.
