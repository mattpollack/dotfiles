vim.wo.number = true
vim.wo.relativenumber = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.cursorcolumn = true
vim.o.scrolloff = 20
vim.o.winborder = "rounded"

vim.api.nvim_set_option("clipboard", "unnamed")

vim.g.mapleader = ' '

local function is_work_computer()
  return os.getenv("WORK_COMPUTER") ~= nil
end

vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""

return {
  is_work_computer = is_work_computer
}

