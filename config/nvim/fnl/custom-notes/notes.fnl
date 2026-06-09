(global vim _G.vim)

(local M {})

(fn M.setup [opts]
  "Setup the notes plugin"
  (vim.notify :todo)
  (vim.notify opts))

M
