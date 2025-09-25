return {
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup {
        pre_hook = function()
          return vim.bo.commentstring
        end,
      }
    end,
  },
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    }
  },
  { 'echasnovski/mini.nvim', version = '*' },
  { 'itchyny/vim-qfedit' },
  'tpope/vim-fugitive',
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup({
        -- Configuration here is optional
        keymaps = {
          normal = 'ys',
          normal_cur = 'yss',
          visual = 'Y',
          visual_line = 'lY',
          delete = 'yds',
          change = 'ycs',
        },
      })
    end,
  },
}
