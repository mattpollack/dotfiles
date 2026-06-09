# Quick Start Guide

## What is Code Trace?

A plugin to help you trace through complicated/nested code flows by marking points of interest with explicit nesting levels.

## Quick Reference

### Mark Locations (from any code file)
- `<leader>ta` - Mark as **Level 1** (main flow / entry point)
- `<leader>ts` - Mark as **Level 2** (first level nested)
- `<leader>td` - Mark as **Level 3** (second level nested)
- `<leader>tf` - Mark as **Level 4** (third level nested)

**Mnemonic**: Home row keys `asdf` = Levels 1-4

### View & Navigate
- `<leader>tt` - **Open traces buffer** (shows all your marks)
- In traces buffer: `<CR>` or `gd` - **Jump to location**

### Manage
- `<leader>tc` - Clear all traces
- Edit the traces buffer directly to reorganize

## Example: Tracing a Complex Flow

Let's say you're tracing through authentication code:

1. **Find the entry point** in `auth.ts` line 45
   - Press `<leader>ta` (a = level 1)
   - Enter: "Entry: handleUserAuth()"

2. **Follow into validation** at `validator.ts` line 12
   - Press `<leader>ts` (s = level 2)
   - Enter: "Validates token"

3. **Dive into JWT check** at `jwt.ts` line 89
   - Press `<leader>td` (d = level 3)
   - Enter: "Checks expiry"

4. **View your trace** with `<leader>tt`:
   ```
   1. auth.ts:45 - Entry: handleUserAuth()
     2. validator.ts:12 - Validates token
       3. jwt.ts:89 - Checks expiry
   ```

5. **Jump back** by pressing `<CR>` on any line!

## Tips

- The traces file is just plain text - edit it however you want
- Use comments (lines starting with `#`) to organize sections
- Copy/paste traces to reorganize them
- The file persists across Neovim sessions
- No database = no corruption issues!

## File Location

Your traces are saved at: `~/.local/share/nvim/code-traces.txt`
