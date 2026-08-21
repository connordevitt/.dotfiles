-- ~/.wezterm.lua  --  WezTerm configuration
-- Docs: https://wezfurlong.org/wezterm/config/lua/general.html
-- This file hot-reloads: save it and open windows update instantly.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

--------------------------------------------------------------------
-- APPEARANCE
--------------------------------------------------------------------

-- Try also: 'Tokyo Night', 'Kanagawa (Gogh)', 'Gruvbox dark, hard (base16)',
-- 'Dracula (Official)', 'rose-pine'.  All ~1000 are browsable in-app with
-- Ctrl+Shift+P -> "Set Color Scheme" (live preview as you arrow through them).
config.color_scheme = 'Catppuccin Mocha'

-- JetBrains Mono ships INSIDE wezterm, so this works with nothing installed.
-- Nerd Font Symbols is bundled too and is used automatically for icons.
config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Regular', harfbuzz_features = { 'calt=1', 'liga=1' } },
  'Symbols Nerd Font Mono',
  'Cascadia Mono',
}
config.font_size = 11.5
config.line_height = 1.1

-- Windows 11 acrylic blur behind the terminal.
-- Set opacity to 1.0 if you would rather have a solid, opaque window.
config.window_background_opacity = 0.88
config.win32_system_backdrop = 'Acrylic'

config.window_decorations = 'RESIZE'  -- thin frame, no chunky titlebar
config.window_padding = { left = 14, right = 14, top = 10, bottom = 8 }
config.initial_cols = 120
config.initial_rows = 32

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 600
config.animation_fps = 60
config.max_fps = 120

config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'NeverPrompt'

--------------------------------------------------------------------
-- TAB BAR
--------------------------------------------------------------------

config.use_fancy_tab_bar = false          -- retro bar = fully themable, compact
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = true

-- Powerline-style tab titles with per-process icons.
local ICONS = {
  ['powershell'] = wezterm.nerdfonts.md_console_line,
  ['pwsh']       = wezterm.nerdfonts.md_console_line,
  ['cmd']        = wezterm.nerdfonts.md_console,
  ['bash']       = wezterm.nerdfonts.cod_terminal_bash,
  ['wsl']        = wezterm.nerdfonts.linux_tux,
  ['nvim']       = wezterm.nerdfonts.custom_vim,
  ['vim']        = wezterm.nerdfonts.custom_vim,
  ['git']        = wezterm.nerdfonts.dev_git,
  ['node']       = wezterm.nerdfonts.dev_nodejs_small,
  ['python']     = wezterm.nerdfonts.dev_python,
  ['ssh']        = wezterm.nerdfonts.md_lan_connect,
  ['claude']     = wezterm.nerdfonts.md_robot_outline,
}

local function tab_title(tab)
  local proc = tab.active_pane.foreground_process_name or ''
  proc = proc:gsub('.*[/\\]', ''):gsub('%.exe$', ''):lower()
  local icon = ICONS[proc] or wezterm.nerdfonts.oct_terminal
  local title = tab.tab_title
  if title == nil or #title == 0 then
    title = (proc ~= '' and proc) or tab.active_pane.title
  end
  return string.format(' %s  %s ', icon, title)
end

wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
  -- active tab colour. Catppuccin Mocha: green #a6e3a1, teal #94e2d5,
  -- mauve #cba6f7, blue #89b4fa, peach #fab387, red #f38ba8.
  local bg = tab.is_active and '#a6e3a1' or (hover and '#45475a' or '#1e1e2e')
  local fg = tab.is_active and '#11111b' or '#a6adc8'
  local text = wezterm.truncate_right(tab_title(tab), max_width - 4)
  return {
    { Background = { Color = '#1e1e2e' } }, { Foreground = { Color = bg } },
    { Text = wezterm.nerdfonts.pl_left_hard_divider },
    { Background = { Color = bg } }, { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Text = text },
    { Background = { Color = '#1e1e2e' } }, { Foreground = { Color = bg } },
    { Text = wezterm.nerdfonts.pl_right_hard_divider },
  }
end)

-- Right-hand status: current folder, then clock.
wezterm.on('update-right-status', function(window, pane)
  local cwd = pane:get_current_working_dir()
  local cwd_str = ''
  if cwd then
    cwd_str = (type(cwd) == 'userdata' and cwd.file_path or tostring(cwd))
    cwd_str = cwd_str:gsub('/$', ''):gsub('.*[/\\]', '')
  end
  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#89b4fa' } },
    { Text = cwd_str ~= '' and (wezterm.nerdfonts.oct_file_directory .. '  ' .. cwd_str .. '   ') or '' },
    { Foreground = { Color = '#f9e2af' } },
    { Text = wezterm.nerdfonts.md_clock_outline .. '  ' .. wezterm.strftime '%H:%M  ' },
  })
end)

--------------------------------------------------------------------
-- SHELLS
--------------------------------------------------------------------

config.default_prog = { 'powershell.exe', '-NoLogo' }

config.launch_menu = {
  { label = 'PowerShell', args = { 'powershell.exe', '-NoLogo' } },
  { label = 'Command Prompt', args = { 'cmd.exe' } },
  { label = 'WSL', args = { 'wsl.exe', '--cd', '~' } },
}

--------------------------------------------------------------------
-- KEYS   (leader = Ctrl+a, tmux style)
--------------------------------------------------------------------

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- Splits
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'x',  mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z',  mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Move between panes
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- Resize panes
  { key = 'LeftArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'UpArrow',    mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'DownArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },

  -- Tabs
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = false } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },

  -- Pick a shell / rename tab / command palette
  { key = 'l', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS' } },
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'r', mods = 'LEADER', action = act.PromptInputLine {
      description = 'Rename tab:',
      action = wezterm.action_callback(function(win, _, line)
        if line and #line > 0 then win:active_tab():set_title(line) end
      end),
  }},

  -- Font size
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- Copy / paste / search
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search { CaseInSensitiveString = '' } },

  -- Fullscreen
  { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },
}

-- Ctrl+1..9 jumps to that tab
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CTRL', action = act.ActivateTab(i - 1) })
end

return config
