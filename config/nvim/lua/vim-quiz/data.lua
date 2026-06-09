-- Vim commands data for quiz
-- Each entry: { command, description, category }

local M = {}

M.commands = {
  -- Cursor movement
  { cmd = "h", desc = "move cursor left", category = "Cursor movement" },
  { cmd = "j", desc = "move cursor down", category = "Cursor movement" },
  { cmd = "k", desc = "move cursor up", category = "Cursor movement" },
  { cmd = "l", desc = "move cursor right", category = "Cursor movement" },
  { cmd = "w", desc = "jump forwards to the start of a word", category = "Cursor movement" },
  { cmd = "b", desc = "jump backwards to the start of a word", category = "Cursor movement" },
  { cmd = "e", desc = "jump forwards to the end of a word", category = "Cursor movement" },
  { cmd = "0", desc = "jump to the start of the line", category = "Cursor movement" },
  { cmd = "$", desc = "jump to the end of the line", category = "Cursor movement" },
  { cmd = "gg", desc = "go to the first line of the document", category = "Cursor movement" },
  { cmd = "G", desc = "go to the last line of the document", category = "Cursor movement" },
  { cmd = "H", desc = "move to top of screen", category = "Cursor movement" },
  { cmd = "M", desc = "move to middle of screen", category = "Cursor movement" },
  { cmd = "L", desc = "move to bottom of screen", category = "Cursor movement" },
  { cmd = "%", desc = "move cursor to matching character (parenthesis, bracket, brace)", category = "Cursor movement" },
  { cmd = "^", desc = "jump to the first non-blank character of the line", category = "Cursor movement" },
  { cmd = "}", desc = "jump to next paragraph (or function/block)", category = "Cursor movement" },
  { cmd = "{", desc = "jump to previous paragraph (or function/block)", category = "Cursor movement" },
  { cmd = "zz", desc = "center cursor on screen", category = "Cursor movement" },
  { cmd = "zt", desc = "position cursor on top of the screen", category = "Cursor movement" },
  { cmd = "zb", desc = "position cursor on bottom of the screen", category = "Cursor movement" },

  -- Insert mode
  { cmd = "i", desc = "insert before the cursor", category = "Insert mode" },
  { cmd = "I", desc = "insert at the beginning of the line", category = "Insert mode" },
  { cmd = "a", desc = "insert (append) after the cursor", category = "Insert mode" },
  { cmd = "A", desc = "insert (append) at the end of the line", category = "Insert mode" },
  { cmd = "o", desc = "append (open) a new line below the current line", category = "Insert mode" },
  { cmd = "O", desc = "append (open) a new line above the current line", category = "Insert mode" },
  { cmd = "ea", desc = "insert (append) at the end of the word", category = "Insert mode" },

  -- Editing
  { cmd = "r", desc = "replace a single character", category = "Editing" },
  { cmd = "R", desc = "replace more than one character, until ESC is pressed", category = "Editing" },
  { cmd = "J", desc = "join line below to the current one with one space in between", category = "Editing" },
  { cmd = "cc", desc = "change (replace) entire line", category = "Editing" },
  { cmd = "ciw", desc = "change (replace) entire word", category = "Editing" },
  { cmd = "cw", desc = "change (replace) to the end of the word", category = "Editing" },
  { cmd = "s", desc = "delete character and substitute text", category = "Editing" },
  { cmd = "S", desc = "delete line and substitute text", category = "Editing" },
  { cmd = "u", desc = "undo", category = "Editing" },
  { cmd = ".", desc = "repeat last command", category = "Editing" },

  -- Visual mode
  { cmd = "v", desc = "start visual mode, mark lines, then do a command", category = "Visual mode" },
  { cmd = "V", desc = "start linewise visual mode", category = "Visual mode" },

  -- Cut and paste
  { cmd = "yy", desc = "yank (copy) a line", category = "Cut and paste" },
  { cmd = "yw", desc = "yank (copy) the characters of the word from cursor to start of next word", category = "Cut and paste" },
  { cmd = "yiw", desc = "yank (copy) word under the cursor", category = "Cut and paste" },
  { cmd = "p", desc = "put (paste) the clipboard after cursor", category = "Cut and paste" },
  { cmd = "P", desc = "put (paste) before cursor", category = "Cut and paste" },
  { cmd = "dd", desc = "delete (cut) a line", category = "Cut and paste" },
  { cmd = "dw", desc = "delete (cut) the characters of the word from cursor to start of next word", category = "Cut and paste" },
  { cmd = "diw", desc = "delete (cut) word under the cursor", category = "Cut and paste" },
  { cmd = "x", desc = "delete (cut) character", category = "Cut and paste" },

  -- Search
  { cmd = "/pattern", desc = "search for pattern", category = "Search" },
  { cmd = "n", desc = "repeat search in same direction", category = "Search" },
  { cmd = "N", desc = "repeat search in opposite direction", category = "Search" },

  -- Advanced cursor movement
  { cmd = "fx", desc = "jump to next occurrence of character x", category = "Cursor movement" },
  { cmd = "Fx", desc = "jump to previous occurrence of character x", category = "Cursor movement" },
  { cmd = "tx", desc = "jump to before next occurrence of character x", category = "Cursor movement" },
  { cmd = ";", desc = "repeat previous f, t, F or T movement", category = "Cursor movement" },
  { cmd = ",", desc = "repeat previous f, t, F or T movement, backwards", category = "Cursor movement" },
  { cmd = "gd", desc = "move to local declaration", category = "Cursor movement" },
  { cmd = "gD", desc = "move to global declaration", category = "Cursor movement" },

  -- Indentation
  { cmd = ">>", desc = "indent (move right) line one shiftwidth", category = "Indent" },
  { cmd = "<<", desc = "de-indent (move left) line one shiftwidth", category = "Indent" },

  -- Marks
  { cmd = "ma", desc = "set current position for mark A", category = "Marks" },
  { cmd = "`a", desc = "jump to position of mark A", category = "Marks" },

  -- Macros
  { cmd = "qa", desc = "record macro a", category = "Macros" },
  { cmd = "@a", desc = "run macro a", category = "Macros" },
}

return M
