local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.window_decorations = "RESIZE"
-- config.enable_wayland = true
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.6
config.text_background_opacity = 0.4
config.macos_window_background_blur = 100
-- config.window_padding = {
--   left = 16,
--   right = 16,
--   top = 16,
--   bottom = 64
-- }
-- config.window_frame = {
--   border_left_width = '0.5cell',
--   border_right_width = '0.5cell',
--   border_bottom_height = '0.25cell',
--   border_top_height = '0.25cell',
--   border_left_color = 'green',
--   border_right_color = 'green',
--   border_bottom_color = 'green',
--   border_top_color = 'green',
-- }
-- Ensure PATH includes common package manager locations
-- This fixes GUI app PATH issues on macOS while staying portable
local original_path = os.getenv("PATH") or ""
config.set_environment_variables = {
  PATH = "/opt/homebrew/bin:" .. os.getenv("HOME") .. "/.nix-profile/bin:" .. original_path
}

-- Set tmux as default program
config.default_prog = { 'tmux' }

return config
