local M = {}

M.config = {}
M._initialized = false
M.handlers = {}

--- Register an event handler
---@param event_name string The event to listen for
---@param handler_id string Unique identifier for this handler
---@param handler function The handler function(payload)
function M.on(event_name, handler_id, handler)
  if not M.handlers[event_name] then
    M.handlers[event_name] = {}
  end
  M.handlers[event_name][handler_id] = handler
end

--- Unregister an event handler
---@param event_name string The event name
---@param handler_id string The handler identifier
function M.off(event_name, handler_id)
  if M.handlers[event_name] then
    M.handlers[event_name][handler_id] = nil
  end
end

--- Emit an event to all registered handlers
---@param event_name string The event to emit
---@param payload table|nil Optional event payload
function M.emit(event_name, payload)
  if not M.handlers[event_name] then
    return
  end

  for handler_id, handler in pairs(M.handlers[event_name]) do
    local ok, err = pcall(handler, payload or {})
    if not ok then
      vim.notify(
        string.format('[tmux-bridge] Handler "%s" for event "%s" failed: %s',
          handler_id, event_name, err),
        vim.log.levels.ERROR
      )
    end
  end
end

--- Check if running inside tmux
---@return boolean
function M.in_tmux()
  return vim.env.TMUX ~= nil
end

--- Get current tmux pane ID
---@return string|nil
function M.get_pane_id()
  return vim.env.TMUX_PANE
end

--- Execute a tmux command and return output
---@param cmd string The tmux command
---@return string|nil output
function M.tmux(cmd)
  if not M.in_tmux() then
    return nil
  end

  local result = vim.fn.system('tmux ' .. cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  return result
end

--- Get list of all pane IDs in current window
---@return table|nil
function M.get_panes()
  local output = M.tmux("list-panes -F '#{pane_id}'")
  if not output then return nil end

  local panes = {}
  for pane_id in output:gmatch("[^\r\n]+") do
    table.insert(panes, vim.trim(pane_id))
  end
  return panes
end

--- Get information about a specific pane
---@param pane_id string|nil The pane ID (defaults to current)
---@return table|nil
function M.get_pane_info(pane_id)
  pane_id = pane_id or M.get_pane_id()
  if not pane_id then return nil end

  local format = "#{pane_id}|#{pane_width}|#{pane_height}|#{pane_pid}|#{pane_current_command}"
  local output = M.tmux(string.format("display-message -p -t '%s' '%s'", pane_id, format))
  if not output then return nil end

  local parts = vim.split(vim.trim(output), '|')
  
  -- Validate we got all expected parts
  if #parts < 5 then
    vim.notify(
      string.format('[tmux-bridge] Invalid pane info format: expected 5 parts, got %d', #parts),
      vim.log.levels.WARN
    )
    return nil
  end
  
  return {
    id = parts[1],
    width = tonumber(parts[2]) or 0,
    height = tonumber(parts[3]) or 0,
    pid = tonumber(parts[4]) or 0,
    command = parts[5] or '',
  }
end

--- Get current window dimensions
---@return table|nil
function M.get_window_size()
  local width = M.tmux("display-message -p '#{window_width}'")
  local height = M.tmux("display-message -p '#{window_height}'")

  if width and height then
    return {
      width = tonumber(vim.trim(width)),
      height = tonumber(vim.trim(height)),
    }
  end
  return nil
end

--- Find nvim socket for a given PID
---@param pid number The process ID
---@return string|nil socket_path
function M.find_nvim_socket(pid)
  local socket_name = string.format('nvim.%d.0', pid)
  
  -- Try $TMPDIR first (macOS default)
  local tmpdir = vim.env.TMPDIR or '/tmp'
  local cmd = string.format("find '%s' -maxdepth 3 -name '%s' -type s 2>/dev/null | head -1", tmpdir, socket_name)
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error == 0 and result and result ~= '' then
    return vim.trim(result)
  end
  
  -- Try /tmp as fallback
  if tmpdir ~= '/tmp' then
    cmd = string.format("find /tmp -maxdepth 3 -name '%s' -type s 2>/dev/null | head -1", socket_name)
    result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 and result and result ~= '' then
      return vim.trim(result)
    end
  end
  
  return nil
end

--- Query window count from another nvim instance via socket
---@param socket_path string The socket path
---@return number|nil window_count
function M.query_nvim_window_count(socket_path)
  if not socket_path or socket_path == '' then
    return nil
  end
  
  -- Use a temporary file to get the result
  local tmp_file = vim.fn.tempname()
  local lua_cmd = string.format(
    "lua local wins = vim.api.nvim_list_wins(); local count = 0; " ..
    "for _, win in ipairs(wins) do " ..
    "local config = vim.api.nvim_win_get_config(win); " ..
    "if config.relative == '' then " ..
    "local pos = vim.api.nvim_win_get_position(win); " ..
    "if pos[1] == 0 then count = count + 1 end end end; " ..
    "local f = io.open('%s', 'w'); f:write(tostring(count)); f:close()",
    tmp_file
  )
  
  local cmd = string.format(
    "nvim --server '%s' --remote-send '<Cmd>%s<CR>' 2>/dev/null",
    socket_path, lua_cmd
  )
  
  vim.fn.system(cmd)
  
  -- Wait a bit for the command to execute
  vim.wait(100, function() return vim.fn.filereadable(tmp_file) == 1 end)
  
  if vim.fn.filereadable(tmp_file) == 1 then
    local content = vim.fn.readfile(tmp_file)[1]
    vim.fn.delete(tmp_file)
    return tonumber(content)
  end
  
  return nil
end

-- Standard event names
M.events = {
  -- pane events
  PANE_SPLIT = 'pane:split',
  PANE_KILLED = 'pane:killed',
  PANE_EXITED = 'pane:exited',
  PANE_SELECTED = 'pane:selected',
  PANE_RESIZED = 'pane:resized',

  -- window events
  WINDOW_NEW = 'window:new',
  WINDOW_SELECTED = 'window:selected',
  WINDOW_RENAMED = 'window:renamed',
  WINDOW_RESIZED = 'window:resized',
  WINDOW_LINKED = 'window:linked',
  WINDOW_UNLINKED = 'window:unlinked',
  WINDOW_CHANGED = 'window:changed',

  -- session events
  SESSION_CREATED = 'session:created',
  SESSION_CLOSED = 'session:closed',
  SESSION_RENAMED = 'session:renamed',
  SESSION_CHANGED = 'session:changed',

  -- client events
  CLIENT_ATTACHED = 'client:attached',
  CLIENT_DETACHED = 'client:detached',
  CLIENT_RESIZED = 'client:resized',
  CLIENT_FOCUS_IN = 'client:focus-in',
  CLIENT_FOCUS_OUT = 'client:focus-out',
  CLIENT_ACTIVE = 'client:active',

  -- layout events
  LAYOUT_SELECTED = 'layout:selected',

  -- alert events
  ALERT_ACTIVITY = 'alert:activity',
  ALERT_BELL = 'alert:bell',
  ALERT_SILENCE = 'alert:silence',

  -- copy mode events
  COPY_MODE_EXITED = 'copy-mode:exited',

  -- other events
  KEYS_SENT = 'keys:sent',
  COMMAND_ERROR = 'command:error',
}

--- Create standard payload for tmux events
---@return table
local function create_tmux_payload()
  return {
    pane_info = M.get_pane_info(),
    window_size = M.get_window_size(),
    all_panes = M.get_panes(),
    timestamp = os.time(),
    timestamp_ms = vim.loop.now(),
  }
end

--- Initialize the bridge
local function initialize()
  if M._initialized or not M.in_tmux() then
    return
  end

  M._initialized = true

  -- Create user commands
  vim.api.nvim_create_user_command('TmuxBridgeInfo', function()
    local info = {
      in_tmux = M.in_tmux(),
      pane_id = M.get_pane_id(),
      panes = M.get_panes(),
      handlers = vim.tbl_keys(M.handlers),
    }
    print(vim.inspect(info))
  end, {})
end

--- Single entry point for all tmux hook events
---@param event_type string The event type from the hook script (e.g., "pane:new")
function M._emit_from_hook(event_type)
  vim.schedule(function()
    M.emit(event_type, create_tmux_payload())
  end)
end

initialize()

return M
