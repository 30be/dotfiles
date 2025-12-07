local wezterm = require("wezterm")
local config = wezterm.config_builder()
config.window_background_opacity = 0.9
config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_padding = {
	left = "0",
	right = "0",
	top = "0",
	bottom = "0",
}
config.default_prog = { "bash" }
config.color_scheme = "Dracula (Official)"
return config
