local cmp = require('cmp')
local luasnip = require('luasnip')
local keymaps = require('keymaps')

local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  local opts = { noremap = true, silent = true, buffer = bufnr }
  -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  -- vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  -- vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  -- vim.keymap.set('n', '<leader>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, opts)
  -- vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  -- vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  -- vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  -- vim.keymap.set('n', '<leader>f', function()
  --   vim.lsp.buf.format { async = true }
  -- end, opts)

  -- This doesn't seem to be working??

  keymaps.lsp_keymaps(opts)

  -- Special keymap for TypeScript: add current directory as workspace folder
  if client.name == "ts_ls" then
    vim.keymap.set('n', '<leader>wt', function()
      local current_dir = vim.fn.expand('%:p:h')
      vim.lsp.buf.add_workspace_folder(current_dir)
      print("Added workspace folder: " .. current_dir)
    end, opts)
  end
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
  -- Enable completion on typing
  completion = {
    completeopt = 'menu,menuone,noinsert,noselect'
  },
  -- Show completion menu automatically
  experimental = {
    ghost_text = true,
  },
})

cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

require('Comment').setup()
require('ts_context_commentstring').setup({ enable_autocmd = false })

local lspconfig = require('lspconfig')

-- Setup neodev for better vim API support
require("neodev").setup({})

lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = function(fname)
    return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
  end,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
      workspace = {
        checkThirdParty = false,
      }
    }
  }
})

lspconfig.gdscript.setup({
  cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("project.godot"),
})

-- Fennel LSP setup
lspconfig.fennel_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern(".git", "fnl"),
  settings = {
    fennel = {
      workspace = {
        library = vim.api.nvim_list_runtime_paths(),
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

lspconfig.ts_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = function(fname)
    -- First try to find a project root
    local root = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
    if root then
      return root
    end

    -- If no project root found, use current working directory
    -- This allows LSP to work outside of project directories
    return vim.fn.getcwd()
  end,
  settings = {
    typescript = {
      inlayHints = {
        enabled = true,
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      preferences = {
        includePackageJsonAutoImports = "auto",
        importModuleSpecifierPreference = "relative",
      },
    },
    javascript = {
      inlayHints = {
        enabled = true,
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      preferences = {
        includePackageJsonAutoImports = "auto",
        importModuleSpecifierPreference = "relative",
      },
    },
  },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
})

-- Python LSP setup with Pyright
lspconfig.pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = function(fname)
    -- Look for Python project indicators
    local root = lspconfig.util.root_pattern("pyproject.toml", "setup.py", "requirements.txt", "Pipfile",
      "pyrightconfig.json", ".git")(fname)
    if root then
      return root
    end

    -- If no project root found, use current working directory
    return vim.fn.getcwd()
  end,
  settings = {
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic",
        inlayHints = {
          functionReturnTypes = true,
          variableTypes = true,
          classVariableTypes = true,
        },
      },
    },
  },
  filetypes = { "python" },
})

vim.diagnostic.config({
  virtual_text = true
})
