return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        ensure_installed = { "lua", "go", "gdscript", "typescript", "tsx", "javascript" },
        modules = {},
        sync_install = false,
        ignore_install = {},
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<c-backspace>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            -- Available Treesitter text objects for reference:
            -- @parameter.outer/inner - Function parameters
            -- @function.outer/inner - Function definitions
            -- @class.outer/inner - Classes, interfaces, types
            -- @comment.outer/inner - Comments
            -- @conditional.outer/inner - if/else/switch statements
            -- @loop.outer/inner - for/while loops
            -- @block.outer/inner - Code blocks (curly braces, etc.)
            -- @statement.outer/inner - Individual statements
            -- @call.outer/inner - Function calls
            -- @string.outer/inner - String literals
            -- @number.inner - Numeric literals
            -- @assignment.outer/inner - Variable assignments
            -- @return.outer/inner - Return statements
            -- @field.outer/inner - Object fields/properties
            -- @attribute.outer/inner - Attributes/decorators
            -- @scopename.inner - Scope names
            -- @text.outer/inner - Text content
            -- @text.literal.outer/inner - String literals
            -- @text.reference.inner - References
            keymaps = {
              -- Parameters
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',

              -- Functions
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',

              -- Comments
              ['a/'] = '@comment.outer',
              ['i/'] = '@comment.inner',

              -- Conditionals (if/else/switch)
              ['a?'] = '@conditional.outer',
              ['i?'] = '@conditional.inner',

              -- Block
              ['ab'] = '@block.outer',
              ['ib'] = '@block.inner',

              -- Statements
              ['as'] = '@statement.outer',
              ['is'] = '@statement.inner',

              -- Calls (function calls)
              ['ac'] = '@call.outer',
              ['ic'] = '@call.inner',
            }
          }
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer',
            [']f'] = '@function.outer',
            [']c'] = '@class.outer',
            [']a'] = '@parameter.outer',
            [']b'] = '@block.outer',
            [']s'] = '@statement.outer',
            [']l'] = '@loop.outer',
            [']?'] = '@conditional.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer',
            [']F'] = '@function.outer',
            [']C'] = '@class.outer',
            [']A'] = '@parameter.outer',
            [']B'] = '@block.outer',
            [']S'] = '@statement.outer',
            [']L'] = '@loop.outer',
            [']?'] = '@conditional.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[['] = '@class.outer',
            ['[f'] = '@function.outer',
            ['[c'] = '@class.outer',
            ['[a'] = '@parameter.outer',
            ['[b'] = '@block.outer',
            ['[s'] = '@statement.outer',
            ['[l'] = '@loop.outer',
            ['[?'] = '@conditional.outer',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[]'] = '@class.outer',
            ['[F'] = '@function.outer',
            ['[C'] = '@class.outer',
            ['[A'] = '@parameter.outer',
            ['[B'] = '@block.outer',
            ['[S'] = '@statement.outer',
            ['[L'] = '@loop.outer',
            ['[?'] = '@conditional.outer',
          },
        }
      })
    end
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  { 'JoosepAlviste/nvim-ts-context-commentstring' },
}
