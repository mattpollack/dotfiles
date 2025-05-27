local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.6
config.text_background_opacity = 0.3
config.macos_window_background_blur = 100

return config
