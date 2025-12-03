local options = require('options')

return {
  {
    'github/copilot.vim',
    enabled = options.is_work_computer()
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-y>",
          clear_suggestion = "<C-p>",
          accept_word = "<C-j>",
        },
      })
    end,
    enabled = not options.is_work_computer()
  },
}

