vim.cmd([[autocmd BufWritePre * :%s/\s\+$//e]])

vim.api.nvim_create_autocmd('CursorMoved', {
  group = vim.api.nvim_create_augroup('auto-hlsearch', { clear = true }),
  callback = function()
    if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
      vim.schedule(function() vim.cmd.nohlsearch() end)
    end
  end
})

local gdproject = io.open(vim.fn.getcwd() .. '/project.godot', 'r')

if gdproject then
  io.close(gdproject)
  vim.fn.serverstart '/Users/m/.config/godothost'
  print("Listening on /godothost")
end

