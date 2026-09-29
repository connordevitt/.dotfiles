local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font_with_fallback({
	{ family = "JetBrains Mono", weight = "Regular", harfbuzz_features = { "calt=1", "liga=1" } },
	"Symbols Nerd Font Mono",
	"Cascadia Mono",
})
config.font_size = 11.5
config.line_height = 1.1

-- Set opacity to 1.0 if you would rather have a solid, opaque window.
config.window_background_opacity = 0.88
config.win32_system_backdrop = "Acrylic"

config.window_decorations = "RESIZE" -- thin frame, no chunky titlebar
config.window_padding = { left = 14, right = 14, top = 10, bottom = 8 }
config.initial_cols = 120
config.initial_rows = 32

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
config.animation_fps = 60
config.max_fps = 120

config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

config.use_fancy_tab_bar = false -- retro bar = fully themable, compact
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = true

-- Powerline-style tab titles with per-process icons.
local ICONS = {
	["powershell"] = wezterm.nerdfonts.md_console_line,
	["pwsh"] = wezterm.nerdfonts.md_console_line,
	["cmd"] = wezterm.nerdfonts.md_console,
	["bash"] = wezterm.nerdfonts.cod_terminal_bash,
	["wsl"] = wezterm.nerdfonts.linux_tux,
	["nvim"] = wezterm.nerdfonts.custom_vim,
	["vim"] = wezterm.nerdfonts.custom_vim,
	["git"] = wezterm.nerdfonts.dev_git,
	["node"] = wezterm.nerdfonts.dev_nodejs_small,
	["python"] = wezterm.nerdfonts.dev_python,
	["ssh"] = wezterm.nerdfonts.md_lan_connect,
	["claude"] = wezterm.nerdfonts.md_robot_outline,
}

local function tab_title(tab)
	local proc = tab.active_pane.foreground_process_name or ""
	proc = proc:gsub(".*[/\\]", ""):gsub("%.exe$", ""):lower()
	local icon = ICONS[proc] or wezterm.nerdfonts.oct_terminal
	local title = tab.tab_title
	if title == nil or #title == 0 then
		title = (proc ~= "" and proc) or tab.active_pane.title
	end
	return string.format(" %s  %s ", icon, title)
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
	-- active tab colour. Catppuccin Mocha: green #a6e3a1, teal #94e2d5,
	-- mauve #cba6f7, blue #89b4fa, peach #fab387, red #f38ba8.
	local bg = tab.is_active and "#a6e3a1" or (hover and "#45475a" or "#1e1e2e")
	local fg = tab.is_active and "#11111b" or "#a6adc8"
	local text = wezterm.truncate_right(tab_title(tab), max_width - 4)
	return {
		{ Background = { Color = "#1e1e2e" } },
		{ Foreground = { Color = bg } },
		{ Text = wezterm.nerdfonts.pl_left_hard_divider },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = text },
		{ Background = { Color = "#1e1e2e" } },
		{ Foreground = { Color = bg } },
		{ Text = wezterm.nerdfonts.pl_right_hard_divider },
	}
end)

wezterm.on("update-right-status", function(window, pane)
	local cwd = pane:get_current_working_dir()
	local cwd_str = ""
	if cwd then
		cwd_str = (type(cwd) == "userdata" and cwd.file_path or tostring(cwd))
		cwd_str = cwd_str:gsub("/$", ""):gsub(".*[/\\]", "")
	end
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#89b4fa" } },
		{ Text = cwd_str ~= "" and (wezterm.nerdfonts.oct_file_directory .. "  " .. cwd_str .. "   ") or "" },
		{ Foreground = { Color = "#f9e2af" } },
		{ Text = wezterm.nerdfonts.md_clock_outline .. "  " .. wezterm.strftime("%-I:%M %p  ") },
	}))
end)

config.default_prog = { "powershell.exe", "-NoLogo" }

config.launch_menu = {
	{ label = "PowerShell", args = { "powershell.exe", "-NoLogo" } },
	{ label = "Command Prompt", args = { "cmd.exe" } },
	{ label = "WSL", args = { "wsl.exe", "--cd", "~" } },
}

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Sends Herdr's prefix (ctrl+;, see herdr/config.toml) followed by a key.
-- A physically pressed ctrl+; never reaches Herdr on Windows: Herdr's input
-- decoder drops VK_OEM_1 with Ctrl held (it only special-cases ctrl+/). The
-- SendKey version carries the ';' character, which Herdr does decode.
local function herdr(key, mods)
	return act.Multiple({ act.SendKey({ key = ";", mods = "CTRL" }), act.SendKey({ key = key, mods = mods }) })
end

config.keys = {
	-- Ctrl+a twice sends a real Ctrl+a, which the leader otherwise swallows
	-- (nvim increment, PowerShell select-all). dmmulroy uses Ghostty with no
	-- leader, so there is nothing of his to mirror here.
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	{ key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },

	{ key = "LeftArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "RightArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	{ key = "UpArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "DownArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },

	{ key = "m", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },

	{ key = "t", mods = "CTRL", action = herdr("c") },
	-- Cycle Herdr panes (cycle_pane_next = prefix+tab), tap until you land.
	-- result with two side-by-side panes, but it wraps, and nvim never sees
	-- ctrl+l. Also costs PowerShell's clear-screen.
	{ key = "l", mods = "CTRL", action = herdr("Tab") },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

	{ key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
	{
		key = "r",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(win, _, line)
				if line and #line > 0 then
					win:active_tab():set_title(line)
				end
			end),
		}),
	},

	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },

	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
}

-- Leader + key becomes Herdr prefix + key, so ctrl+a drives dmmulroy's Herdr
-- bindings. Splits and close must go to Herdr: a WezTerm split spawns a bare
-- PowerShell outside Herdr, and a WezTerm close kills Herdr's host pane.
-- r and z stay WezTerm's (rename tab, zoom) above.
for _, key in ipairs({
	"\\",
	"-",
	"x", -- split right, split down, close pane
	"h",
	"j",
	"k",
	"l", -- focus pane
	"c",
	"n",
	"p",
	",", -- new, next, previous, rename tab
	"w",
	"s",
	"(",
	")", -- workspace picker, previous/next workspace
	"i",
	"o", -- jump to the notifying agent (dmmulroy: i, Herdr default: o)
	"m",
	"v",
	"b",
	"d",
	"q",
	"?", -- zoom, copy mode, sidebar, detach, help
}) do
	table.insert(config.keys, { key = key, mods = "LEADER", action = herdr(key) })
end

for i = 1, 9 do
	table.insert(
		config.keys,
		{ key = tostring(i), mods = "CTRL", action = act.SendKey({ key = tostring(i), mods = "ALT" }) }
	)
	-- Leader + ctrl+N focuses Agent N (focus_agent = "prefix+alt+1..9"). Ctrl, not
	-- alt: another app on this machine grabs alt+1/alt+2 as global hotkeys, and
	-- SendKey synthesizes the alt+N so it never passes through Windows.
	table.insert(config.keys, { key = tostring(i), mods = "LEADER|CTRL", action = herdr(tostring(i), "ALT") })
end

return config
