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
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = options.is_work_computer() and "copilot" or "anthropic",
          },
          inline = {
            adapter = options.is_work_computer() and "copilot" or "anthropic",
          },
        },
        adapters = {
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = "cmd:op read op://APIs/Anthropic/password --no-newline",
              },
            })
          end,
        },
        opts = {
          log_level = "DEBUG",
        },
        display = {
          diff = {
            provider = "mini_diff",
          },
        },
      })
    end,
  },
}