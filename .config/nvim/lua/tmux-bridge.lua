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
  return {
    id = parts[1],
    width = tonumber(parts[2]),
    height = tonumber(parts[3]),
    pid = tonumber(parts[4]),
    command = parts[5],
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

-- Standard event names
M.events = {
  -- pane events
  PANE_NEW = 'pane:new',
  PANE_CLOSED = 'pane:closed',
  PANE_FOCUS = 'pane:focus',

  -- window events
  WINDOW_NEW = 'window:new',
  WINDOW_CLOSED = 'window:closed',
  WINDOW_CHANGED = 'window:changed',
  WINDOW_RENAMED = 'window:renamed',
  WINDOW_RESIZED = 'window:resized',

  -- session events
  SESSION_NEW = 'session:new',
  SESSION_CLOSED = 'session:closed',
  SESSION_CHANGED = 'session:changed',
}

--- Create standard payload for tmux events
---@return table
local function create_tmux_payload()
  return {
    pane_info = M.get_pane_info(),
    timestamp = os.time(),
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
