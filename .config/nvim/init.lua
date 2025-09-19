require('options')
require('lazy-setup')

require("lazy").setup({
  { import = "plugins.lsp" },
  { import = "plugins.treesitter" },
  { import = "plugins.telescope" },
  { import = "plugins.ai" },
  { import = "plugins.navigation" },
  { import = "plugins.editor" },
  { import = "plugins.debug" },
  { import = "plugins.theme" },
})

require('keymaps')
require('commands')
require('autocmds')
require('theme')
