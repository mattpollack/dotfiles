# Code Trace Plugin

A simple, reliable plugin for tracing through code with explicit nesting support.

## Features

- **Infinite Nesting Levels**: Mark code locations with explicit hierarchy (supports unlimited depth)
- **Simple Keybinds**: Use home row keys `asdf` for levels 1-4
- **Plain Text Storage**: All traces stored in a simple text file you can edit directly
- **Jump to Location**: Press `<CR>` or `gd` on any trace to jump to that location
- **Visual Indicators**: Different colors for each nesting level
- **No Database**: No SQL, no corruption, just plain text

## Usage

### Keymaps

- `<leader>tt` - Open traces buffer
- `<leader>ta` - Mark current line as Level 1 (main flow)
- `<leader>ts` - Mark current line as Level 2 (nested)
- `<leader>td` - Mark current line as Level 3 (deep nested)
- `<leader>tf` - Mark current line as Level 4 (deeper)
- `<leader>tc` - Clear all traces

**Mnemonic**: Home row `asdf` = Levels 1-4

### In the Traces Buffer

- `<CR>` or `gd` - Jump to the trace location
- Edit freely to reorganize your traces
- `:w` - Save changes

## Example Workflow

1. Navigate to entry point of a function: `<leader>ta` (a = level 1)
   - Enter note: "Entry: handleUserAuth()"

2. Navigate to a nested call: `<leader>ts` (s = level 2)
   - Enter note: "Validates token"

3. Navigate deeper: `<leader>td` (d = level 3)
   - Enter note: "Checks expiry date"

4. Open traces: `<leader>tt`
   - See your hierarchical trace
   - Press `<CR>` on any line to jump back

5. Manually organize in the buffer:
   ```
   1. src/auth.ts:45 - Entry: handleUserAuth()
     2. src/validator.ts:12 - Validates token
       3. src/jwt.ts:89 - Checks expiry date
       3. src/jwt.ts:102 - Verifies signature
     2. src/db.ts:156 - Loads user data
   ```

## File Location

Traces are stored at: `~/.local/share/nvim/code-traces.txt`

## Customization

In your config:

```lua
require("code-trace").setup({
  trace_file = vim.fn.stdpath("data") .. "/my-traces.txt",
  indent_size = 4,  -- Change indentation (default: 2)
  default_mark = "→",  -- Fallback marker for very deep levels
})
```

## Extending Beyond 4 Levels

The plugin supports infinite nesting levels! You can add more keybinds:

```lua
-- Add level 5 with 'g' key
vim.keymap.set('n', '<leader>tg', require('code-trace').mark_level(4), { desc = "Code Trace: Level 5" })
```
