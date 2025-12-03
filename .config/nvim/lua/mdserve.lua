local M = {}

local mdserve_jobs = {}
local mdserve_port_start = 8000

local function is_port_available(port)
  local handle = io.popen('lsof -i :' .. port .. ' 2>/dev/null')
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result == ""
end

local function get_next_port()
  local port = mdserve_port_start
  local attempts = 0
  local max_attempts = 100

  while attempts < max_attempts do
    if is_port_available(port) then
      return port
    end
    port = port + 1
    attempts = attempts + 1
  end

  return nil
end

function _G.mdserve_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local info = mdserve_jobs[bufnr]
  if info then
    return string.format('  mdserve:%d', info.port)
  end
  return ''
end

local function start_mdserve(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if file_path == "" then
    return
  end

  if mdserve_jobs[bufnr] then
    local info = mdserve_jobs[bufnr]
    vim.notify('mdserve already running for ' .. vim.fn.fnamemodify(file_path, ':t') .. ' on port ' .. info.port,
      vim.log.levels.INFO)
    return
  end

  local port = get_next_port()
  if not port then
    vim.notify('Failed to find available port after 100 attempts', vim.log.levels.ERROR)
    return
  end

  local job_id = vim.fn.jobstart('mdserve -p ' .. port .. ' "' .. file_path .. '"', {
    detach = false,
    on_exit = function()
      mdserve_jobs[bufnr] = nil
    end
  })

  if job_id > 0 then
    mdserve_jobs[bufnr] = { job_id = job_id, port = port }
    vim.notify('mdserve started for ' .. vim.fn.fnamemodify(file_path, ':t') .. ' on port ' .. port, vim.log.levels.INFO)
    vim.cmd('redrawstatus')
  else
    vim.notify('Failed to start mdserve', vim.log.levels.ERROR)
  end
end

local function stop_mdserve(bufnr)
  local info = mdserve_jobs[bufnr]
  if info then
    vim.fn.jobstop(info.job_id)
    mdserve_jobs[bufnr] = nil
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    vim.notify('mdserve stopped for ' .. vim.fn.fnamemodify(file_path, ':t') .. ' (port ' .. info.port .. ')',
      vim.log.levels.INFO)
    vim.cmd('redrawstatus')
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.md",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local file_path = vim.api.nvim_buf_get_name(bufnr)

      if mdserve_jobs[bufnr] then
        local info = mdserve_jobs[bufnr]
        vim.notify('Attached to ' .. vim.fn.fnamemodify(file_path, ':t') .. ' (mdserve on port ' .. info.port .. ')',
          vim.log.levels.INFO)
      else
        start_mdserve(bufnr)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    pattern = "*.md",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      stop_mdserve(bufnr)
    end,
  })

  vim.api.nvim_create_user_command('MdServeStart', function()
    local bufnr = vim.api.nvim_get_current_buf()
    start_mdserve(bufnr)
  end, { desc = 'Start mdserve for current markdown file' })

  vim.api.nvim_create_user_command('MdServeStop', function()
    local bufnr = vim.api.nvim_get_current_buf()
    stop_mdserve(bufnr)
  end, { desc = 'Stop mdserve for current markdown file' })
end

return M
