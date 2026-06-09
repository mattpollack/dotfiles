require('options')
require('plugins')
require('keymaps')
require('commands')
require('autocmds')
require('theme')
require('lsp')
require('mdserve')
require('tmux-bridge')

-- Initialize clustering
local cluster = require('nvim-clustering')
cluster.setup({
  debug = false, -- Set to true for debugging
})

-- Initialize pane balancer
local pane_balancer = require('pane-balancer')
pane_balancer.setup({
  enabled = true,
  auto_balance = true,
  min_pane_width = 20,
  debug = false, -- Set to true for debugging
})
