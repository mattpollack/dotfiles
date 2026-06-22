-- Set up autocommands for plugin hooks before adding plugins
local augroup = vim.api.nvim_create_augroup("PackHooks", { clear = true })

-- Tree-sitter build hook
vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup,
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then
      vim.cmd("TSUpdate")
    end
  end,
})

-- Add all plugins with dependencies listed first
vim.pack.add({
  -- Core dependencies
  { src = "https://github.com/nvim-lua/plenary.nvim" },

  -- LSP and completion plugins
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/saghen/blink.cmp",                               version = "v1.10.2" },

  -- Formatter
  { src = "https://github.com/stevearc/conform.nvim" },

  -- Tree-sitter parser manager (lightweight alternative to nvim-treesitter)
  { src = "https://github.com/romus204/tree-sitter-manager.nvim" },

  -- Telescope
  { src = "https://github.com/nvim-telescope/telescope.nvim",               version = "0.1.5" },
  { src = "https://github.com/nvim-telescope/telescope-live-grep-args.nvim" },
  { src = "https://github.com/catgoose/telescope-helpgrep.nvim" },

  -- Navigation
  { src = "https://github.com/ThePrimeagen/harpoon",                        version = "harpoon2" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/folke/flash.nvim" },
  { src = "https://github.com/christoomey/vim-tmux-navigator" },

  -- Editor utilities

  { src = "https://github.com/rmagatti/auto-session" },
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/itchyny/vim-qfedit" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/kylechui/nvim-surround" },
  { src = "https://github.com/folke/zen-mode.nvim" },
  { src = "https://github.com/chentoast/marks.nvim" },

  -- Debugging
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/williamboman/mason.nvim" },
  { src = "https://github.com/jay-babu/mason-nvim-dap.nvim" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },

  -- Themes
  { src = "https://github.com/rebelot/kanagawa.nvim" },
  { src = "https://github.com/oskarnurm/koda.nvim" },
  { src = "https://github.com/serhez/teide.nvim" },
})

-- Local plugins don't need vim.pack - they're loaded from lua/ directory automatically

-- Configure plugins that need setup
-- Auto-session
require('auto-session').setup({
  suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
})

-- Conform.nvim (formatter)
require('conform').setup({
  formatters = {
    ktlint = { command = vim.fn.expand("~/.local/bin/ktlint") },
  },
  formatters_by_ft = {
    python = { "black", "isort" },
    kotlin = { "ktlint" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },
  },
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype == "kotlin" then return nil end
    return { timeout_ms = 500, lsp_fallback = true }
  end,
  format_after_save = function(bufnr)
    if vim.bo[bufnr].filetype == "kotlin" then
      return { lsp_fallback = false }
    end
  end,
})
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Treesitter configuration for Neovim 0.12
-- Enable treesitter automatically for all filetypes
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local bufnr = args.buf
    -- Start treesitter for parsing/text objects
    pcall(vim.treesitter.start, bufnr)
    -- Enable treesitter highlighting
    pcall(vim.treesitter.highlighter.attach, bufnr)
  end,
})

-- Tree-sitter parser manager
require('tree-sitter-manager').setup({
  ensure_installed = {
    'python',
    'typescript',
    'tsx',
    'javascript',
    'rust',
    'c',
    'cpp',
    'go',
    'gdscript',
    'lua',
    'c_sharp',
    'kotlin',
  },
  auto_install = true,
  highlight = true,
})

-- Telescope
local telescope = require("telescope")
local telescope_actions = require("telescope.actions")
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-t>"] = telescope_actions.send_selected_to_qflist + telescope_actions.open_qflist,
      },
      n = {
        ["<C-t>"] = telescope_actions.send_selected_to_qflist + telescope_actions.open_qflist,
      },
    },
    file_ignore_patterns = {
      "node_modules"
    }
  },
  pickers = {
    find_files = {
      hidden = true,
      find_command = { "rg", "--files", "--hidden", "--glob", "!.git" },
    },
  }
})
telescope.load_extension("live_grep_args")

-- Harpoon
local harpoon = require("harpoon")
harpoon:setup()

-- Oil.nvim
require("oil").setup({
  view_options = {
    show_hidden = true,
  },
})

-- Zen mode
require("zen-mode").setup({})

-- Code trace (local plugin)
require("code-trace").setup({})

-- Vim quiz (local plugin)
require("vim-quiz").setup({})

-- DAP (debugger)
local dap = require('dap')
require('dapui').setup()

dap.adapters.godot = {
  type = 'server',
  host = '127.0.0.1',
  port = 6006
}

dap.configurations.gdscript = {
  {
    type = 'godot',
    request = 'launch',
    name = 'Launch scene',
    project = '${workspaceFolder}',
    launch_scene = true
  }
}

-- Lazy-loaded plugins (using vim.schedule for deferred loading)
vim.schedule(function()
  -- Load plugins that don't need immediate startup

  -- Nvim-surround (using v4 defaults)
  require('nvim-surround').setup({})

  -- Marks.nvim
  require('marks').setup({
    default_mappings = false,
  })

  -- Flash.nvim keymaps
  local flash = require("flash")
  vim.keymap.set({ "n", "x", "o" }, "s", function() flash.jump() end, { desc = "Flash" })
  vim.keymap.set({ "n", "x", "o" }, "S", function() flash.treesitter() end, { desc = "Flash Treesitter" })
  vim.keymap.set("o", "r", function() flash.remote() end, { desc = "Remote Flash" })
  vim.keymap.set({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
  vim.keymap.set("c", "<c-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })

  -- Note: vim-tmux-navigator sets up its own default keymaps (C-h/j/k/l)
end)

-- Conditional plugins (AI assistants)
local options = require('options')
if options.is_work_computer() then
  vim.pack.add({ { src = "https://github.com/github/copilot.vim" } })
end
