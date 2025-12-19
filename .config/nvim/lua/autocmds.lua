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
  local server_addr = '/Users/m/.config/godothost'

  -- Only start server if not already running
  local servers = vim.fn.serverlist()
  local already_running = false
  for _, addr in ipairs(servers) do
    if addr == server_addr then
      already_running = true
      break
    end
  end

  if not already_running then
    -- Try to remove stale socket if it exists
    os.remove(server_addr)

    local ok, result = pcall(vim.fn.serverstart, server_addr)
    if ok then
      print("Listening on " .. server_addr)
    else
      print("Could not start Godot server: " .. tostring(result))
    end
  else
    print("Godot server already running at " .. server_addr)
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*.md",
  callback = function()
    vim.opt_local.statusline = "%f %m%r%h%w%=%{v:lua.mdserve_status()} %l,%c %P"
  end,
})

-- Auto-close buffers when their window is closed (unless they have unsaved changes)
vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(event)
    local buf = vim.api.nvim_win_get_buf(tonumber(event.match))

    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end

    if vim.api.nvim_buf_get_option(buf, 'modified') then
      return
    end

    local wins = vim.fn.win_findbuf(buf)
    if #wins > 0 then
      return
    end

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = false })
      end
    end)
  end,
})
