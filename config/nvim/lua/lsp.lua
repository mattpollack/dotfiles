local keymaps = require('keymaps')

local on_attach = function(client, bufnr)
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

  local opts = { noremap = true, silent = true, buffer = bufnr }

  keymaps.lsp_keymaps(opts)

  if client.name == "ts_ls" then
    vim.keymap.set('n', '<leader>wt', function()
      local current_dir = vim.fn.expand('%:p:h')
      vim.lsp.buf.add_workspace_folder(current_dir)
      print("Added workspace folder: " .. current_dir)
    end, opts)
  end
end

require('blink.cmp').setup({
  keymap = { preset = 'default' },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  cmdline = { sources = { 'cmdline' }, completion = { menu = { auto_show = true } } },
  completion = { ghost_text = { enabled = true } },
})

local capabilities = require('blink.cmp').get_lsp_capabilities()

require("lazydev").setup()

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
      preferences = {
        includePackageJsonAutoImports = "auto",
        importModuleSpecifierPreference = "relative",
      },
    },
    javascript = {
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

vim.lsp.config('bashls', {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { "sh", "bash" },
  root_markers = { '.git' },
  capabilities = capabilities,
  settings = {
    bashIde = {
      globPattern = "*@(.sh|.inc|.bash|.command)",
    },
  },
})

vim.lsp.config('omnisharp', {
  cmd = { 'omnisharp' },
  filetypes = { 'cs', 'vb' },
  root_markers = { '*.sln', '*.csproj', 'omnisharp.json', '.git' },
  capabilities = capabilities,
  settings = {
    FormattingOptions = {
      EnableEditorConfigSupport = true,
    },
    RoslynExtensionsOptions = {
      EnableAnalyzersSupport = true,
      EnableDecompilationSupport = true,
    },
  },
})

vim.lsp.config('kotlin_language_server', {
  cmd = { 'kotlin-language-server' },
  filetypes = { 'kotlin' },
  root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.xml', 'pom.xml', 'build.gradle', 'build.gradle.kts' },
  capabilities = capabilities,
  init_options = {
    storagePath = vim.fn.stdpath('cache') .. '/kotlin_language_server',
  },
  settings = {
    kotlin = {
      compiler = {
        jvm = { target = '17' },
      },
    },
  },
})

vim.lsp.config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', 'eslint.config.js', 'eslint.config.mjs', 'package.json', '.git' },
  capabilities = capabilities,
  settings = {
    validate = 'on',
    format = false,
    codeAction = {
      disableRuleComment = { enable = true },
      showDocumentation = { enable = true },
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf
    on_attach(client, bufnr)
  end,
})

vim.lsp.enable('lua_ls')
vim.lsp.enable('gdscript')
vim.lsp.enable('ts_ls')
vim.lsp.enable('pyright')
vim.lsp.enable('terraformls')
vim.lsp.enable('bashls')
vim.lsp.enable('omnisharp')
vim.lsp.enable('kotlin_language_server')
vim.lsp.enable('eslint')

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  signs = true,
  underline = true,
})
