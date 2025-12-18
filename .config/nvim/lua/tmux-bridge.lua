local M = {}

M.config = {}
M._initialized = false
M.handlers = {}

--- Register an event handler
---@param event_name string The event to listen for
---@param handler_id string Unique identifier for this handler
---@param handler function The handler function(payload)
function M.on(event_name, handler_id, handler)
  initialize()
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

-- ============================================================================
-- ENVIRONMENT DETECTION
-- ============================================================================

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

--- Get this Neovim's server address
---@return string
function M.get_server()
  return vim.v.servername
end

-- ============================================================================
-- TMUX QUERY API
-- ============================================================================

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

--- Get Neovim socket for a specific pane
---@param pane_id string The pane ID
---@return string|nil socket path
function M.get_pane_nvim_socket(pane_id)
  local pane_info = M.get_pane_info(pane_id)
  if not pane_info or not pane_info.command:match('nvim') then
    return nil
  end

  -- Find socket by checking TMUX_PANE environment variable
  -- Check both /tmp and /var/folders for macOS compatibility
  local cmd = string.format([[
    for socket_dir in $(find /tmp /var/folders -type d -name "nvim.*" 2>/dev/null); do
      for socket_subdir in "$socket_dir"/*; do
        [ -d "$socket_subdir" ] || continue
        for socket in "$socket_subdir"/*; do
          [ -S "$socket" ] || continue
          pane=$(nvim --server "$socket" --remote-expr "vim.env.TMUX_PANE" 2>/dev/null)
          if [ "$pane" = "%s" ]; then
            echo "$socket"
            exit 0
          fi
        done
      done
    done
  ]], pane_id)

  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 and result ~= '' then
    return vim.trim(result)
  end

  return nil
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

-- ============================================================================
-- NEOVIM QUERY API
-- ============================================================================

--- Get current Neovim window layout
---@return table
function M.get_layout()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local windows = {}

  for _, win in ipairs(wins) do
    local config = vim.api.nvim_win_get_config(win)
    table.insert(windows, {
      id = win,
      width = vim.api.nvim_win_get_width(win),
      height = vim.api.nvim_win_get_height(win),
      floating = config.relative ~= '',
    })
  end

  return {
    count = #wins,
    windows = windows,
  }
end

-- ============================================================================
-- REMOTE COMMUNICATION
-- ============================================================================

--- Send command to another Neovim instance
---@param server string The server socket path
---@param cmd string The Vim command to execute
---@return boolean success
function M.remote_send(server, cmd)
  local result = vim.fn.system(string.format("nvim --server '%s' --remote-send '%s'", server, cmd))
  return vim.v.shell_error == 0
end

--- Evaluate expression in another Neovim instance
---@param server string The server socket path
---@param expr string The expression to evaluate
---@return string|nil result
function M.remote_expr(server, expr)
  local result = vim.fn.system(string.format("nvim --server '%s' --remote-expr '%s'", server, expr))
  if vim.v.shell_error == 0 then
    return result
  end
  return nil
end

-- ============================================================================
-- STANDARD EVENTS
-- ============================================================================

-- Standard event names
M.events = {
  -- Neovim events
  NVIM_WIN_NEW = 'nvim:win:new',
  NVIM_WIN_CLOSED = 'nvim:win:closed',
  NVIM_BUF_ENTER = 'nvim:buf:enter',

  -- tmux events
  TMUX_PANE_NEW = 'tmux:pane:new',
  TMUX_PANE_CLOSED = 'tmux:pane:closed',
  TMUX_WINDOW_CHANGED = 'tmux:window:changed',
}

--- Create standard payload for Neovim window events
---@return table
local function create_nvim_payload()
  return {
    server = M.get_server(),
    pane_id = M.get_pane_id(),
    layout = M.get_layout(),
    timestamp = os.time(),
  }
end

--- Create standard payload for tmux events
---@return table
local function create_tmux_payload()
  return {
    panes = M.get_panes(),
    pane_info = M.get_pane_info(),
    window_size = M.get_window_size(),
    timestamp = os.time(),
  }
end

-- ============================================================================
-- SETUP & INITIALIZATION
-- ============================================================================

--- Initialize the bridge (called automatically when needed)
local function initialize()
  if M._initialized or not M.in_tmux() then
    return
  end

  M._initialized = true

  -- Set up Neovim autocmds to emit events
  local group = vim.api.nvim_create_augroup('TmuxBridge', { clear = true })

  vim.api.nvim_create_autocmd('WinNew', {
    group = group,
    callback = function()
      M.emit(M.events.NVIM_WIN_NEW, create_nvim_payload())
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function()
      M.emit(M.events.NVIM_WIN_CLOSED, create_nvim_payload())
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      M.emit(M.events.NVIM_BUF_ENTER, create_nvim_payload())
    end,
  })

  -- Create user commands
  vim.api.nvim_create_user_command('TmuxBridgeInfo', function()
    local info = {
      in_tmux = M.in_tmux(),
      pane_id = M.get_pane_id(),
      server = M.get_server(),
      layout = M.get_layout(),
      panes = M.get_panes(),
      handlers = vim.tbl_keys(M.handlers),
    }
    print(vim.inspect(info))
  end, {})

  vim.api.nvim_create_user_command('TmuxBridgeHandlers', function()
    print('Registered event handlers:')
    for event, handlers in pairs(M.handlers) do
      print(string.format('  %s:', event))
      for id, _ in pairs(handlers) do
        print(string.format('    - %s', id))
      end
    end
  end, {})

  vim.api.nvim_create_user_command('TmuxBridgeTestPaneNew', function()
    M.handle_pane_new()
  end, { desc = 'Manually trigger pane new event for testing' })
end

-- ============================================================================
-- EXTERNAL ENTRY POINTS (called from tmux hooks)
-- ============================================================================

--- Handle tmux pane creation (called from tmux hook)
function M.handle_pane_new()
  initialize()
  vim.schedule(function()
    M.emit(M.events.TMUX_PANE_NEW, create_tmux_payload())
  end)
end

--- Handle tmux pane close (called from tmux hook)
function M.handle_pane_closed()
  initialize()
  vim.schedule(function()
    M.emit(M.events.TMUX_PANE_CLOSED, create_tmux_payload())
  end)
end

return M
