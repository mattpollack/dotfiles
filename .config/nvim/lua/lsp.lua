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
require("neodev").setup({})

-- Lua Language Server
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
  capabilities = capabilities,
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

vim.lsp.config('gdscript', {
  cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
  filetypes = { 'gd', 'gdscript', 'gdscript3' },
  root_markers = { 'project.godot' },
  capabilities = capabilities,
})

vim.lsp.config('ts_ls', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
  capabilities = capabilities,
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
})

vim.lsp.config('pyright', {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { "python" },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
  capabilities = capabilities,
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
})

vim.lsp.config('terraformls', {
  cmd = { 'terraform-ls', 'serve' },
  filetypes = { "terraform", "hcl", "tf" },
  root_markers = { '.terraform', '.git', 'terraform.workspace' },
  capabilities = capabilities,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    -- Call the on_attach function
    on_attach(client, bufnr)
  end,
})

vim.lsp.enable('lua_ls')
vim.lsp.enable('gdscript')
vim.lsp.enable('ts_ls')
vim.lsp.enable('pyright')
vim.lsp.enable('terraformls')

vim.diagnostic.config({
  virtual_text = true
})
