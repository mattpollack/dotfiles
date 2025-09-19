require('kanagawa').setup({
  transparent = true,
  overrides = function(colors)
    local theme = colors.theme
    return {
      TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = 'none' },
      TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = 'none' },
      TelescopePreviewBorder = { bg = 'none', fg = theme.ui.bg_dim },
    }
  end,
})

vim.cmd("colorscheme kanagawa")
vim.cmd('hi! LineNr guibg=none ctermbg=none')
vim.cmd('hi! SignColumn guibg=none ctermbg=none')

require('mini.diff').setup({
  view = {
    style = 'sign',
  },
  diff = {
    win_options = {
      foldmethod = 'expr',
      foldexpr = '0',
    },
  }
})