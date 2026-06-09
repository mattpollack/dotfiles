--- nvim-clustering.lua
--- Clustering and communication for Neovim instances
--- Allows nvim instances to discover each other and communicate

local M = {}

M.config = {
  debug = false,
  discovery_cache_ttl = 1000, -- ms to cache discovered instances
  broadcast_timeout = 200,    -- ms to wait for broadcast responses
  socket_dir = nil,           -- auto-detect from TMPDIR or /tmp
}

M._initialized = false
M.handlers = {}
M._instance_id = nil
M._discovered_instances = {}
M._last_discovery_time = 0

--- Debug logging
local function debug_log(...)
  if M.config.debug then
    print('[nvim-clustering]', ...)
  end
end

--- Get unique instance ID for this nvim process
---@return string
function M.get_instance_id()
  if not M._instance_id then
    M._instance_id = tostring(vim.fn.getpid())
  end
  return M._instance_id
end

--- Get socket path for this nvim instance
---@return string|nil
function M.get_socket_path()
  local socket = vim.v.servername
  if socket and socket ~= '' then
    return socket
  end

  -- Fallback: construct expected socket path
  local pid = vim.fn.getpid()
  local tmpdir = vim.env.TMPDIR or '/tmp'
  return string.format('%s/nvim.%d.0', tmpdir, pid)
end

--- Get the socket directory to search for nvim instances
---@return string
local function get_socket_dir()
  if M.config.socket_dir then
    return M.config.socket_dir
  end
  return vim.env.TMPDIR or '/tmp'
end

--- Find all nvim sockets by scanning the socket directory
---@return table List of {pid, socket_path, is_self}
function M.discover_instances()
  local now = vim.loop.now()

  -- Return cached results if still valid
  if now - M._last_discovery_time < M.config.discovery_cache_ttl then
    return M._discovered_instances
  end

  local instances = {}
  local self_pid = vim.fn.getpid()
  local socket_dir = get_socket_dir()

  -- Find all nvim socket files in the socket directory
  -- Sockets are typically named nvim.{pid}.0
  local find_cmd = string.format(
    "find '%s' -maxdepth 3 -name 'nvim.*.0' -type s 2>/dev/null",
    socket_dir
  )
  local sockets_output = vim.fn.system(find_cmd)

  if vim.v.shell_error == 0 and sockets_output ~= '' then
    for socket_path in sockets_output:gmatch("[^\r\n]+") do
      socket_path = vim.trim(socket_path)

      -- Extract PID from socket name (nvim.{pid}.0)
      local pid_str = socket_path:match("nvim%.(%d+)%.0")
      if pid_str then
        local pid = tonumber(pid_str)

        -- Verify the process still exists
        local ps_check = vim.fn.system(string.format("ps -p %d -o comm= 2>/dev/null", pid))
        if vim.v.shell_error == 0 and vim.trim(ps_check):match("nvim") then
          table.insert(instances, {
            pid = pid,
            socket = socket_path,
            is_self = pid == self_pid,
          })
          debug_log(string.format('Discovered nvim instance: pid=%d, socket=%s', pid, socket_path))
        end
      end
    end
  end

  -- Sort by PID for consistent ordering
  table.sort(instances, function(a, b) return a.pid < b.pid end)

  M._discovered_instances = instances
  M._last_discovery_time = now

  debug_log(string.format('Discovered %d nvim instances', #instances))
  return instances
end

--- Invalidate the discovery cache (call when you know instances changed)
function M.invalidate_discovery_cache()
  M._last_discovery_time = 0
  M._discovered_instances = {}
end

--- Register an event handler
---@param event_name string The event to listen for
---@param handler_id string Unique identifier for this handler
---@param handler function The handler function(payload)
function M.on(event_name, handler_id, handler)
  if not M.handlers[event_name] then
    M.handlers[event_name] = {}
  end
  M.handlers[event_name][handler_id] = handler
  debug_log(string.format('Registered handler "%s" for event "%s"', handler_id, event_name))
end

--- Unregister an event handler
---@param event_name string The event name
---@param handler_id string The handler identifier
function M.off(event_name, handler_id)
  if M.handlers[event_name] then
    M.handlers[event_name][handler_id] = nil
  end
end

--- Emit an event locally (to handlers in this instance)
---@param event_name string The event to emit
---@param payload table|nil Optional event payload
function M.emit_local(event_name, payload)
  if not M.handlers[event_name] then
    return
  end

  debug_log(string.format('Emitting local event: %s', event_name))

  for handler_id, handler in pairs(M.handlers[event_name]) do
    local ok, err = pcall(handler, payload or {})
    if not ok then
      vim.notify(
        string.format('[nvim-clustering] Handler "%s" for event "%s" failed: %s',
          handler_id, event_name, err),
        vim.log.levels.ERROR
      )
    end
  end
end

--- Send an event to a specific nvim instance
---@param socket_path string The target socket path
---@param event_name string The event name
---@param payload table|nil Optional payload data
---@return boolean success
function M.send_to(socket_path, event_name, payload)
  if not socket_path or socket_path == '' then
    return false
  end

  -- Serialize payload
  local payload_str = vim.fn.json_encode(payload or {})
  -- Escape single quotes for shell
  payload_str = payload_str:gsub("'", "'\\''")

  local lua_cmd = string.format(
    "lua pcall(require('nvim-clustering')._receive_event, '%s', '%s')",
    event_name, payload_str
  )

  local cmd = string.format(
    "nvim --server '%s' --remote-send '<Cmd>%s<CR>' 2>/dev/null",
    socket_path, lua_cmd
  )

  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

--- Broadcast an event to all nvim instances (including self)
---@param event_name string The event name
---@param payload table|nil Optional payload data
---@param opts table|nil Options: {exclude_self: boolean}
function M.broadcast(event_name, payload, opts)
  opts = opts or {}
  payload = payload or {}

  -- Add sender info to payload
  payload._sender_pid = M.get_instance_id()
  payload._timestamp = vim.loop.now()

  local instances = M.discover_instances()
  local sent_count = 0

  debug_log(string.format('Broadcasting event "%s" to %d instances', event_name, #instances))

  for _, instance in ipairs(instances) do
    if not opts.exclude_self or not instance.is_self then
      if M.send_to(instance.socket, event_name, payload) then
        sent_count = sent_count + 1
      end
    end
  end

  -- Also emit locally if not excluded
  if not opts.exclude_self then
    M.emit_local(event_name, payload)
  end

  debug_log(string.format('Broadcast complete: sent to %d instances', sent_count))
  return sent_count
end

--- Internal function to receive events from other instances
---@param event_name string
---@param payload_json string
function M._receive_event(event_name, payload_json)
  vim.schedule(function()
    local ok, payload = pcall(vim.fn.json_decode, payload_json)
    if not ok then
      debug_log(string.format('Failed to decode payload for event "%s"', event_name))
      return
    end

    debug_log(string.format('Received event "%s" from pid=%s', event_name, payload._sender_pid or 'unknown'))
    M.emit_local(event_name, payload)
  end)
end

--- Leader election: determine which instance should be the leader
--- Leader is the instance with the lowest PID
---@return boolean is_leader
function M.is_leader()
  local instances = M.discover_instances()
  if #instances == 0 then
    return true
  end

  local self_pid = vim.fn.getpid()
  local lowest_pid = self_pid

  for _, instance in ipairs(instances) do
    if instance.pid < lowest_pid then
      lowest_pid = instance.pid
    end
  end

  local is_leader = self_pid == lowest_pid
  debug_log(string.format('Leader check: self_pid=%d, lowest_pid=%d, is_leader=%s',
    self_pid, lowest_pid, is_leader))

  return is_leader
end

--- Get the leader instance
---@return table|nil {pid, socket, is_self}
function M.get_leader()
  local instances = M.discover_instances()
  if #instances == 0 then
    return nil
  end

  local leader = instances[1]
  for _, instance in ipairs(instances) do
    if instance.pid < leader.pid then
      leader = instance
    end
  end

  return leader
end

--- Request-response pattern: send a request and wait for response
---@param event_name string The request event name
---@param payload table|nil Request payload
---@param timeout number|nil Timeout in ms (default: broadcast_timeout)
---@return table|nil responses Array of responses from other instances
function M.request(event_name, payload, timeout)
  timeout = timeout or M.config.broadcast_timeout
  payload = payload or {}

  local request_id = string.format('%s-%d', M.get_instance_id(), vim.loop.now())
  payload._request_id = request_id

  local responses = {}
  local response_event = event_name .. ':response'

  -- Register temporary handler for responses
  local handler_id = 'request_' .. request_id
  M.on(response_event, handler_id, function(response_payload)
    if response_payload._request_id == request_id then
      table.insert(responses, response_payload)
    end
  end)

  -- Broadcast request
  M.broadcast(event_name, payload, { exclude_self = true })

  -- Wait for responses
  vim.wait(timeout, function() return false end)

  -- Cleanup handler
  M.off(response_event, handler_id)

  return responses
end

--- Respond to a request
---@param request_payload table The original request payload
---@param response_data table Response data
function M.respond(request_payload, response_data)
  if not request_payload._request_id or not request_payload._sender_pid then
    return false
  end

  response_data._request_id = request_payload._request_id
  response_data._responder_pid = M.get_instance_id()

  -- Find sender's socket
  local instances = M.discover_instances()
  for _, instance in ipairs(instances) do
    if tostring(instance.pid) == request_payload._sender_pid then
      return M.send_to(instance.socket, request_payload._event_name .. ':response', response_data)
    end
  end

  return false
end

--- Initialize the plugin
function M.setup(opts)
  if M._initialized then
    return
  end

  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  M._initialized = true

  -- Create user commands
  vim.api.nvim_create_user_command('ClusterInfo', function()
    local instances = M.discover_instances()
    local info = {
      instance_id = M.get_instance_id(),
      socket = M.get_socket_path(),
      is_leader = M.is_leader(),
      discovered_instances = #instances,
      instances = instances,
      handlers = {},
    }

    for event_name, handlers in pairs(M.handlers) do
      info.handlers[event_name] = vim.tbl_keys(handlers)
    end

    print(vim.inspect(info))
  end, { desc = 'Show cluster information' })

  vim.api.nvim_create_user_command('ClusterDebug', function()
    M.config.debug = not M.config.debug
    print('nvim-clustering debug:', M.config.debug and 'enabled' or 'disabled')
  end, { desc = 'Toggle cluster debug logging' })

  vim.api.nvim_create_user_command('ClusterTest', function()
    print('Testing nvim-clustering...')
    local old_debug = M.config.debug
    M.config.debug = true

    print('Instance ID:', M.get_instance_id())
    print('Socket:', M.get_socket_path())
    print('Is leader:', M.is_leader())

    local instances = M.discover_instances()
    print(string.format('Discovered %d instances:', #instances))
    for i, inst in ipairs(instances) do
      print(string.format('  %d. pid=%d, socket=%s, is_self=%s',
        i, inst.pid, inst.socket, inst.is_self))
    end

    M.config.debug = old_debug
  end, { desc = 'Test cluster discovery' })

  debug_log('nvim-clustering initialized')
end

return M
