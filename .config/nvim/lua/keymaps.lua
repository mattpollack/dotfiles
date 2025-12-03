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

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")

local options = require('options')

if options.is_work_computer() then
  vim.api.nvim_set_keymap("i", "<C-y>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
end

local builtin = require('telescope.builtin')
local telescope = require("telescope")

-- [P]ROJECT
vim.keymap.set('n', '<leader>pl', vim.cmd.Oil, { desc = "[P]roject [L]isting" })
vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "[P]roject [F]ind" })
vim.keymap.set({ 'n', 'v' }, '<leader>pg',
  function() telescope.extensions.live_grep_args.live_grep_args({ default_text = get_visual_selection() }) end,
  { desc = "[P]roject [G]rep" })

-- [G]IT
vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = "[G]it [S]tatus" })
vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = "[G]it [F]iles" })

-- [L]SP
local function lsp_keymaps(opts)
  vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, opts)
  vim.keymap.set('n', '<leader>lt', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', '<leader>lh', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '<leader>lgd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', '<leader>lgr', builtin.lsp_references, opts)
  vim.keymap.set('n', '<leader>lgi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<leader>ls', function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      print("No LSP clients attached to current buffer")
    else
      for _, client in ipairs(clients) do
        print("LSP client: " .. client.name .. " (ID: " .. client.id .. ")")
      end
    end
  end, opts)
end
lsp_keymaps()

-- [D]iagnostic
vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next, { desc = "[D]iagnostic [N]ext" })
vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev, { desc = "[D]iagnostic [P]revious" })

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
vim.api.nvim_set_keymap('n', '<leader>qs', ':SearchToQF<CR>', { noremap = true, silent = true })

-- DAP De[b]ug
local dap = require('dap')

vim.keymap.set('n', '<leader>bc', dap.continue, { desc = "De[b]ug [C]ontinue" })
vim.keymap.set('n', '<leader>bi', dap.step_into, { desc = "De[b]ug Step [I]nto" })
vim.keymap.set('n', '<leader>bo', dap.step_out, { desc = "De[b]ug Step [O]ut" })
vim.keymap.set('n', '<leader>br', dap.repl.toggle, { desc = "De[b]ug [R]epl" })
vim.keymap.set('n', '<leader>bp', dap.toggle_breakpoint, { desc = "De[b]ug Break[p]oint" })

-- Harpoon
local harpoon = require("harpoon")

vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end)
vim.keymap.set("n", "<leader>hl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Open harpoon window" })
vim.api.nvim_set_keymap('n', '<leader>hf', ':InsertHarpoonFiles<CR>', { noremap = true, silent = true })

-- CodeCompanion
vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "gr", "<cmd>CodeCompanionChat Reject<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>af', ':InsertOpenBuffers<CR>', { noremap = true, silent = true })

-- [S]urround - Additional keymaps for surround functionality
vim.keymap.set('n', '<leader>sr', 'ys', { desc = "[S]urround [R]egister (ys)" })
vim.keymap.set('n', '<leader>sc', 'cs', { desc = "[S]urround [C]hange (cs)" })
vim.keymap.set('n', '<leader>sd', 'ds', { desc = "[S]urround [D]elete (ds)" })

return {
  lsp_keymaps = lsp_keymaps
}
