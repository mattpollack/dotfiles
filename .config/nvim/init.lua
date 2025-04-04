-- TRIVIAL

vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")

-- LAZY PACKAGE MANAGER

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- PRE SETUP

--vim.api.nvim_set_keymap("i", "<C-y>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
--vim.keymap.set("i", "<C-w>", '<Plug>(copilot-accept-word)')
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

-- PACKAGES

require("lazy").setup({
  "rebelot/kanagawa.nvim",
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        ensure_installed = { "lua", "go", "gdscript" },
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<c-backspace>', -- not working?
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            }
          }
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer',
          },
        }
      })
    end
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
  'nvim-treesitter/playground',
  'mbbill/undotree',
  'tpope/vim-fugitive',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  { 'VonHeikemen/lsp-zero.nvim', branch = 'v3.x' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/nvim-cmp' },
  { 'L3MON4D3/LuaSnip' },
  { 'numToStr/Comment.nvim' },
  --{ 'github/copilot.vim' },
  {
    'folke/which-key.nvim',
    --event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  { "MunifTanjim/prettier.nvim" },
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    }
  },
  { 'echasnovski/mini.surround', version = '*' },
})


-- SETUP

vim.cmd("colorscheme kanagawa")

-- AFTER REMAPS

local builtin = require('telescope.builtin')

-- [P]ROJECT

vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pl', vim.cmd.Ex, { desc = "[P]roject [L]isting" })
vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "[P]roject [F]ind" })
vim.keymap.set('n', '<leader>pg', builtin.live_grep, { desc = "[P]roject [G]rep" })

-- [G]IT

vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = "[G]it [S]tatus" })
vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = "[G]it [F]iles" })

-- [L]SP

vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = "[L]SP [R]ename" })
vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { desc = "[L]SP [A]ction" })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, { desc = "[L]SP [F]ormat" })
vim.keymap.set('n', '<leader>lt', vim.lsp.buf.type_definition, { desc = "[L]SP [T]ype" })
vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, { desc = "[L]SP [H]over" })
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, { desc = "[L]SP [E]rror" })
vim.keymap.set('n', '<leader>lgd', vim.lsp.buf.definition, { desc = "[L]SP [G]oto [D]efinition" })
vim.keymap.set('n', '<leader>lgr', builtin.lsp_references, { desc = "[L]SP [G]oto [R]ereferences" })
vim.keymap.set('n', '<leader>lgi', vim.lsp.buf.implementation, { desc = "[L]SP [G]oto [I]mplementation" })

-- [D]iagnostic

vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next, { desc = "[D]iagnostic [N]ext" })
vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev, { desc = "[D]iagnostic [P]revious" })

vim.diagnostic.config({
  virtual_text = true
})
-- MISC ONE OFF BINDINGS

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = "[U]ndo Tree" })

local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

require('Comment').setup()
require('mini.surround').setup()
vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

require('lspconfig').lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

--local handle = io.popen("ip route")
--local result = handle:read("*a")
--ihandle:close()
--local ip = string.match(result, "default via ([0-9]+.[0-9]+.[0-9]+.[0-9]+).*")
--if (ip ~= nil) then
--  require('lspconfig').gdscript.setup({
--    name = "godot",
--    cmd = vim.lsp.rpc.connect(ip, 6005),
--  })
--else
require('lspconfig').gdscript.setup({
  name = "godot",
  cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
})
-- end

require('telescope').setup {
  defaults = {
    file_ignore_patterns = {
      "node_modules"
    }
  }
}

require("prettier").setup({
  bin = 'prettier',
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
})

-- CUSTOM COMMANDS

vim.api.nvim_create_user_command("Godoc", function(opts)
  vim.fn.jobstart('open "https://pkg.go.dev/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Google", function(opts)
  vim.fn.jobstart('open "https://google.com/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Godot", function(opts)
  vim.fn.jobstart(
    'open "https://docs.godotengine.org/en/stable/search.html?check_keywords=yes&area=default&q=' .. opts.args .. '"',
    { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command('Open',
  function()
    local path = vim.api.nvim_buf_get_name(0)
    os.execute('open -R ' .. path)
  end,
  {}
)

vim.cmd([[autocmd BufWritePre * :%s/\s\+$//e]])

-- https://github.com/relayfinancial/relay-portal/blob/master/config/demo.json
--vim.api.nvim_create_user_command(
--  "Blame",
--  function (opts)
--    local url = 'https://github.com/'
--
--
--  end
--)

-- AUTO COMMANDS
-- local autocmd_group = vim.api.nvim_create_augroup("Custom auto-commands", { clear = true })

--vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--  pattern = { "*.yaml", "*.yml" },
--  desc = "Auto-format YAML files after saving",
--  callback = function()
--    local fileName = vim.api.nvim_buf_get_name(0)
--    vim.cmd(":!yamlfmt " .. fileName)
--  end,
--  group = autocmd_group,
--})
