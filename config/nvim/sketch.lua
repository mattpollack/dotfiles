--
-- FOR QUICKLY SKETCHING OUT LUA CODE
-- :luafile %
--

-- here
vim.api.nvim_create_user_command('OpenHarpoonFiles', function()
  local harpoon = require("harpoon")
  local harpoon_list = harpoon.get_marked_files()

  for _, file_path in ipairs(harpoon_list) do
    if vim.fn.filereadable(file_path) == 1 then
      vim.cmd("edit " .. file_path)
    else
      vim.api.nvim_err_writeln("File not readable: " .. file_path)
    end
  end
end, { desc = "Open all Harpoon files as buffers" })


local harpoon = require("harpoon")
local harpoon_list = harpoon:list()

for _, file_path in ipairs(harpoon_list) do
  if vim.fn.filereadable(file_path) == 1 then
    vim.cmd("edit " .. file_path)
  else
    vim.api.nvim_err_writeln("File not readable: " .. file_path)
  end
end
