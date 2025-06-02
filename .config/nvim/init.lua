-- TRIVIAL

vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.cursorcolumn = true
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.api.nvim_set_option("clipboard","unnamed")

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

vim.api.nvim_set_keymap("i", "<C-y>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
--vim.keymap.set("i", "<C-w>", '<Plug>(copilot-accept-word)')
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

local function is_work_computer()
  return os.getenv("WORK_COMPUTER") ~= nil
end

-- PACKAGES

require("lazy").setup({
  "rebelot/kanagawa.nvim",
  { 'JoosepAlviste/nvim-ts-context-commentstring' }, -- Not working??
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
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim',
    },
  },
  'nvim-treesitter/playground',
  'mbbill/undotree',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  { 'VonHeikemen/lsp-zero.nvim',                  branch = 'v3.x' },
  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/nvim-cmp' },
  { 'L3MON4D3/LuaSnip' },
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
    'github/copilot.vim',
    enabled = is_work_computer()
  },
  --{
  --  'folke/which-key.nvim',
  --  --event = "VeryLazy",
  --  init = function()
  --    vim.o.timeout = true
  --    vim.o.timeoutlen = 300
  --  end,
  --  opts = {},
  --},
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
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    "olimorris/codecompanion.nvim",
    opts = {},
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  { 'echasnovski/mini.nvim', version = '*' },
  { 'itchyny/vim-qfedit' },
  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   main = "ibl",
  --   ---@module "ibl"
  --   ---@type ibl.config
  --   opts = {},
  -- }

  'tpope/vim-fugitive',
})

-- AFTER REMAPS

local telescope = require("telescope")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function get_entry_filename(entry)
  if entry.path or entry.filename then
    return entry.path or entry.filename
  elseif not entry.bufnr then
    local value = entry.value

    if not value then
      return
    end

    if type(value) == "table" then
      value = entry.display
    end

    local sections = vim.split(value, ":")

    return sections[1]
  end
end

local function push_selected_to_harpoon(prompt_bufnr)
  local harpoon = require("harpoon")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local multi_selections = picker:get_multi_selection()

  if #multi_selections == 0 then
    local entry = action_state.get_selected_entry()
    if entry then
      harpoon:list():add(get_entry_filename(entry))
    end
  else
    for _, entry in ipairs(multi_selections) do
      harpoon:list():add(get_entry_filename(entry))
    end
  end
end

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-t>"] = actions.send_selected_to_qflist + actions.open_qflist,
        -- ["<C-a>"] = push_selected_to_harpoon,
      },
      n = {
        ["<C-t>"] = actions.send_selected_to_qflist + actions.open_qflist,
        --["<C-a>"] = push_selected_to_harpoon,
      },
    }
  }
})
telescope.load_extension("live_grep_args")

local builtin = require('telescope.builtin')

-- [P]ROJECT

local function get_visual_selection()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})

  text = string.gsub(text, "\n", "")
  if #text > 0 then
    return text
  else
    return ''
  end
end

vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pl', vim.cmd.Ex, { desc = "[P]roject [L]isting" })
vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "[P]roject [F]ind" })
vim.keymap.set({ 'n', 'v' }, '<leader>pg',
  function() telescope.extensions.live_grep_args.live_grep_args({ default_text = get_visual_selection() }) end,
  { desc = "[P]roject [G]rep" })

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

-- [Q]uickfix

vim.keymap.set('n', '<leader>qq', function()
  if vim.fn.getwininfo(vim.fn.getqflist({ winid = 0 }).winid)[1] then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
  end
end, { desc = "[Q]uickfix Toggle" })

vim.keymap.set('n', '<leader>qn', vim.cmd.cnext, { desc = "[Q]uickfix Next" })
vim.keymap.set('n', '<leader>qp', vim.cmd.cprev, { desc = "[Q]uickfix Prev" })
vim.keymap.set('n', '<leader>qd', vim.diagnostic.setqflist, { desc = "[Q]uickfix [D]iagnostics" })
vim.keymap.set('n', '<leader>qg', ':Git mergetool<CR>', { desc = "[Q]uickfix [G]it Merge Tool" })
vim.keymap.set('n', '<leader>qc', function()
  vim.fn.setqflist({}); vim.cmd.cclose()
end, { desc = "[Q]uickfix [C]lear" })
vim.api.nvim_set_keymap('n', '<leader>qf', ':InsertQuickfixFiles<CR>', { noremap = true, silent = true })

-- MISC ONE OFF BINDINGS

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = "[U]ndo Tree" })

local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(_, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

require('Comment').setup()
require('ts_context_commentstring').setup({ enable_autocmd = false })
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

vim.api.nvim_create_user_command('Blame', function()
  local file_path = vim.fn.expand('%:p')
  local git_remote = vim.fn.system('git config --get remote.origin.url'):gsub('\n', '')
  local repo_url = git_remote:match('github.com[:/](.+)%.git$')
  if not repo_url then
    vim.api.nvim_err_writeln('Could not determine GitHub repository URL.')
    return
  end

  local branch = 'main'
  if vim.fn.system('git show-ref --verify refs/heads/master'):gsub('\n', '') ~= '' then
    branch = 'master'
  end

  local relative_path = vim.fn.fnamemodify(file_path, ':~:.')
  local line_number = vim.fn.line('.')
  local github_url = 'https://github.com/' ..
      repo_url .. '/blame/' .. branch .. '/' .. relative_path .. '#L' .. line_number
  vim.fn.system({ 'open', github_url })
end, { desc = 'Open current file in GitHub' })

vim.api.nvim_create_user_command('InsertOpenBuffers', function()
  local chat = require("codecompanion").chat()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'buftype') == '' then
      local file_path = vim.api.nvim_buf_get_name(buf)
      local cwd = vim.fn.getcwd()
      local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

      if relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
        chat.references:add({
          id = '<file>' .. relative_path .. '</file>',
          path = relative_path,
          source = "codecompanion.strategies.chat.slash_commands.file",
          opts = {
            pinned = true,
            watched = false,
            visible = true,
          }
        })
      end
    end
  end
end, {})

vim.api.nvim_create_user_command('InsertQuickfixFiles', function()
  local chat = require("codecompanion").chat()
  local qf_list = vim.fn.getqflist()
  local added_files = {} -- To avoid duplicates

  for _, item in ipairs(qf_list) do
    local bufnr = item.bufnr
    if bufnr > 0 then
      local file_path = vim.api.nvim_buf_get_name(bufnr)
      local cwd = vim.fn.getcwd()
      local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

      -- Avoid duplicates and check if file exists
      if not added_files[relative_path] and relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
        chat.references:add({
          id = '<file>' .. relative_path .. '</file>',
          path = relative_path,
          source = "codecompanion.strategies.chat.slash_commands.file",
          opts = {
            pinned = true,
            watched = false,
            visible = true,
          }
        })
        added_files[relative_path] = true
      end
    end
  end
end, {})

vim.api.nvim_create_user_command('InsertHarpoonFiles', function()
  local chat = require("codecompanion").chat()
  local harpoon = require("harpoon")
  local harpoon_list = harpoon:list()

  for _, item in ipairs(harpoon_list.items) do
    local file_path = item.value
    local cwd = vim.fn.getcwd()
    local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

    if relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
      chat.references:add({
        id = '<file>' .. relative_path .. '</file>',
        path = relative_path,
        source = "codecompanion.strategies.chat.slash_commands.file",
        opts = {
          pinned = true,
          watched = false,
          visible = true,
        }
      })
    end
  end
end, {})

vim.api.nvim_create_autocmd('CursorMoved', {
  group = vim.api.nvim_create_augroup('auto-hlsearch', { clear = true }),
  callback = function()
    if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
      vim.schedule(function() vim.cmd.nohlsearch() end)
    end
  end
})

-- Harpoon Setup

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end)
vim.keymap.set("n", "<leader>hl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Open harpoon window" })
vim.api.nvim_set_keymap('n', '<leader>hf', ':InsertHarpoonFiles<CR>', { noremap = true, silent = true })

-- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
-- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = is_work_computer() and "copilot" or "anthropic",
    },
    inline = {
      adapter = is_work_computer() and "copilot" or "anthropic",
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

vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "gr", "<cmd>CodeCompanionChat Reject<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>af', ':InsertOpenBuffers<CR>', { noremap = true, silent = true })

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

-- THEME
-- OLD THEMES:
-- "daschw/leaf.nvim",
-- "shaunsingh/nord.nvim",


-- Default options:

require('kanagawa').setup({
  transparent = true,
  -- theme = "dark",
  -- contrast = "low",
  overrides = function(colors)
    local theme = colors.theme
    return {
      -- TelescopeTitle = { fg = theme.ui.special, bold = true },
      -- TelescopePromptNormal = { bg = theme.ui.bg_p1 },
      TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = 'none' },
      -- TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
      TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = 'none' },
      -- TelescopePreviewNormal = { bg = theme.ui.bg_dim },
      TelescopePreviewBorder = { bg = 'none', fg = theme.ui.bg_dim },
    }
  end,
})

vim.cmd("colorscheme kanagawa")
vim.cmd('hi! LineNr guibg=none ctermbg=none')
vim.cmd('hi! SignColumn guibg=none ctermbg=none')

--
-- vim.g.nord_contrast = false
-- vim.g.nord_borders = false
-- vim.g.nord_disable_background = true
-- vim.g.nord_italic = false
-- vim.g.nord_uniform_diff_background = true
-- vim.g.nord_bold = false
--
-- -- Load the colorscheme
-- require('nord').set()
--
-- INDENT BLANKLINE

-- local highlight = {
--   "RainbowRed",
--   "RainbowYellow",
--   "RainbowBlue",
--   "RainbowOrange",
--   "RainbowGreen",
--   "RainbowViolet",
--   "RainbowCyan",
-- }
-- local hooks = require "ibl.hooks"
-- -- create the highlight groups in the highlight setup hook, so they are reset
-- -- every time the colorscheme changes
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--   vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--   vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--   vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--   vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--   vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--   vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--   vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
-- end)
--
-- vim.g.rainbow_delimiters = { highlight = highlight }
-- require("ibl").setup { scope = { highlight = highlight } }
--
-- hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

