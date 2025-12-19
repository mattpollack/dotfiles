--- pane-balancer.lua
--- Auto-balance tmux panes and nvim windows for equal horizontal spacing
--- Accounts for nested nvim windows within tmux panes

local M = {}
local bridge = require('tmux-bridge')

M.config = {
  enabled = true,
  auto_balance = true,
  min_pane_width = 20, -- minimum width for any pane
  balance_threshold = 5, -- only balance if width difference > this value
  defer_window_events = 10, -- ms to defer window events (reduced from 50)
  defer_pane_events = 10, -- ms to defer pane events (reduced from 100)
  defer_resize_events = 10, -- ms to defer resize events (reduced from 50)
}

--- Cache for tmux queries during a single balance operation
local tmux_cache = {
  panes = nil,
  pane_info = {},
}

--- Find nvim socket for a given PID
---@param pid number The process ID
---@return string|nil socket_path
local function find_nvim_socket(pid)
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
local function query_nvim_window_count(socket_path)
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

  -- Check if file is readable (removed blocking wait for better performance)
  if vim.fn.filereadable(tmp_file) == 1 then
    local content = vim.fn.readfile(tmp_file)[1]
    vim.fn.delete(tmp_file)
    return tonumber(content)
  end

  return nil
end

--- Cached wrapper for bridge.get_panes()
local function get_panes_cached()
  if tmux_cache.panes then
    return tmux_cache.panes
  end

  local panes = bridge.get_panes()
  tmux_cache.panes = panes
  return panes
end

--- Cached wrapper for bridge.get_pane_info()
local function get_pane_info_cached(pane_id)
  if tmux_cache.pane_info[pane_id] then
    return tmux_cache.pane_info[pane_id]
  end

  local info = bridge.get_pane_info(pane_id)
  tmux_cache.pane_info[pane_id] = info
  return info
end

--- Get top-level vertical split windows (non-floating, at row 0)
--- Returns list of window IDs that are top-level vertical splits
local function get_top_level_vertical_windows()
  local wins = vim.api.nvim_list_wins()
  local top_level_wins = {}

  -- Collect all non-floating windows at row 0 (top-level)
  for _, win in ipairs(wins) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == '' then
      local pos = vim.api.nvim_win_get_position(win)
      -- Top-level windows start at row 0
      if pos[1] == 0 then
        table.insert(top_level_wins, {
          id = win,
          col = pos[2],
          width = vim.api.nvim_win_get_width(win),
        })
      end
    end
  end

  -- Sort by column position (left to right)
  table.sort(top_level_wins, function(a, b) return a.col < b.col end)

  return top_level_wins
end

--- Count top-level vertical windows
--- Only counts windows that should affect horizontal balancing
local function count_vertical_windows()
  return #get_top_level_vertical_windows()
end

--- Get all nvim instances running in tmux panes
--- Returns a map of pane_id -> nvim_window_count
local function get_nvim_instances_in_panes()
  if not bridge.in_tmux() then
    return {}
  end

  local panes = get_panes_cached()
  if not panes then return {} end

  local nvim_panes = {}
  local current_pane = bridge.get_pane_id()

  for _, pane_id in ipairs(panes) do
    local pane_info = get_pane_info_cached(pane_id)

    if pane_info and pane_info.command == 'nvim' then
      if pane_id == current_pane then
        -- For current pane, count vertical non-floating windows
        local win_count = count_vertical_windows()
        nvim_panes[pane_id] = win_count
      else
        -- For other panes, try to query via socket
        local socket = find_nvim_socket(pane_info.pid)
        if socket then
          local win_count = query_nvim_window_count(socket)
          if win_count then
            nvim_panes[pane_id] = win_count
          else
            nvim_panes[pane_id] = 1
          end
        else
          nvim_panes[pane_id] = 1
        end
      end
    end
  end

  return nvim_panes
end

--- Calculate total logical panes
--- Each tmux pane with nvim contributes its window count
--- Each tmux pane without nvim contributes 1
local function calculate_logical_panes()
  if not bridge.in_tmux() then
    local vertical_wins = count_vertical_windows()
    return {
      total_logical_panes = vertical_wins,
      tmux_panes = {},
      current_pane_windows = vertical_wins,
    }
  end

  local panes = get_panes_cached()

  if not panes or #panes == 0 then
    return {
      total_logical_panes = 1,
      tmux_panes = {},
      current_pane_windows = 1,
    }
  end

  local nvim_panes = get_nvim_instances_in_panes()

  local current_pane = bridge.get_pane_id()
  local total_logical = 0
  local tmux_pane_info = {}

  for _, pane_id in ipairs(panes) do
    local nvim_windows = nvim_panes[pane_id] or 0
    local logical_count = nvim_windows > 0 and nvim_windows or 1

    tmux_pane_info[pane_id] = {
      nvim_windows = nvim_windows,
      logical_panes = logical_count,
      is_current = pane_id == current_pane,
    }

    total_logical = total_logical + logical_count
  end

  return {
    total_logical_panes = total_logical,
    tmux_panes = tmux_pane_info,
    current_pane_windows = nvim_panes[current_pane] or 1,
    num_tmux_panes = #panes,
  }
end

--- Get the total available width for horizontal balancing
local function get_total_width()
  if not bridge.in_tmux() then
    return vim.o.columns
  end

  local window_size = bridge.get_window_size()
  return window_size and window_size.width or vim.o.columns
end

--- Balance nvim windows within the current pane
--- Only balances top-level vertical splits
local function balance_nvim_windows()
  local top_level_wins = get_top_level_vertical_windows()

  if #top_level_wins <= 1 then
    return
  end

  -- Calculate equal width for each top-level vertical window
  local total_width = vim.o.columns
  local target_width = math.floor(total_width / #top_level_wins)

  for _, win_info in ipairs(top_level_wins) do
    -- Check if resize is needed based on threshold
    local width_diff = math.abs(win_info.width - target_width)
    if width_diff > M.config.balance_threshold then
      pcall(vim.api.nvim_win_set_width, win_info.id, target_width)
    end
  end
end

--- Resize tmux panes based on logical pane distribution
local function balance_tmux_panes(layout_info)
  if not bridge.in_tmux() then
    return
  end

  local total_width = get_total_width()
  if not total_width or total_width < M.config.min_pane_width then
    return
  end

  local total_logical = layout_info.total_logical_panes

  -- Get pane list (will use cached version)
  local current_panes = get_panes_cached()

  if not current_panes then
    return
  end

  -- Calculate target width for each tmux pane based on its logical pane count
  for pane_id, info in pairs(layout_info.tmux_panes) do
    -- Verify pane still exists
    local pane_exists = false
    for _, pid in ipairs(current_panes) do
      if pid == pane_id then
        pane_exists = true
        break
      end
    end

    if not pane_exists then
      goto continue
    end

    local proportion = info.logical_panes / total_logical
    local target_width = math.floor(total_width * proportion)

    -- Ensure minimum width
    target_width = math.max(target_width, M.config.min_pane_width)

    -- Resize the pane
    local pane_info = get_pane_info_cached(pane_id)

    if pane_info and pane_info.width then
      local width_diff = target_width - pane_info.width

      if math.abs(width_diff) > M.config.balance_threshold then
        local resize_cmd = string.format('resize-pane -t %s -x %d', pane_id, target_width)
        bridge.tmux(resize_cmd)
      end
    end

    ::continue::
  end
end

--- Debounce timer
local balance_timer = nil

--- Main balance function
function M.balance()
  if not M.config.enabled then
    return
  end

  -- Clear cache at start of each balance operation
  tmux_cache.panes = nil
  tmux_cache.pane_info = {}

  -- Calculate the layout
  local layout_info = calculate_logical_panes()

  -- Balance nvim windows first (within current pane)
  balance_nvim_windows()

  -- Then balance tmux panes based on logical distribution
  if bridge.in_tmux() and layout_info.num_tmux_panes and layout_info.num_tmux_panes > 1 then
    balance_tmux_panes(layout_info)
  end
end

--- Debounced balance function
---@param delay number|nil Delay in ms (uses config default if nil)
function M.balance_debounced(delay)
  delay = delay or M.config.defer_pane_events
  
  if balance_timer then
    vim.fn.timer_stop(balance_timer)
  end
  
  balance_timer = vim.fn.timer_start(delay, function()
    M.balance()
    balance_timer = nil
  end)
end

--- Get current layout info for debugging
function M.get_layout_info()
  local layout = calculate_logical_panes()
  return {
    in_tmux = bridge.in_tmux(),
    total_width = get_total_width(),
    layout = layout,
  }
end

--- Setup event handlers for auto-balancing
local function setup_auto_balance()
  if not M.config.auto_balance then
    return
  end

  -- Track the previous top-level window count
  local prev_top_level_count = count_vertical_windows()

  -- Balance on nvim window splits/closes
  vim.api.nvim_create_autocmd({ 'WinNew', 'WinClosed' }, {
    group = vim.api.nvim_create_augroup('PaneBalancer', { clear = true }),
    callback = function()
      -- Defer to avoid conflicts with window creation
      vim.defer_fn(function()
        local current_top_level_count = count_vertical_windows()

        -- Only balance if the top-level window count changed
        if current_top_level_count ~= prev_top_level_count then
          prev_top_level_count = current_top_level_count
          M.balance()
        end
      end, M.config.defer_window_events)
    end,
  })

  -- Balance on tmux pane events (via bridge)
  if bridge.in_tmux() then
    bridge.on('pane:split', 'pane-balancer', function()
      vim.defer_fn(M.balance, M.config.defer_pane_events)
    end)

    -- For pane removal, use a longer delay to ensure tmux has updated its state
    bridge.on('pane:killed', 'pane-balancer', function()
      vim.defer_fn(M.balance, M.config.defer_pane_events + 50)
    end)

    bridge.on('pane:exited', 'pane-balancer', function()
      vim.defer_fn(M.balance, M.config.defer_pane_events + 50)
    end)

    -- Balance on window resize
    vim.api.nvim_create_autocmd('VimResized', {
      group = vim.api.nvim_create_augroup('PaneBalancerResize', { clear = true }),
      callback = function()
        vim.defer_fn(M.balance, M.config.defer_resize_events)
      end,
    })
  end
end

--- Initialize the plugin
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  -- Create user commands
  vim.api.nvim_create_user_command('PaneBalance', function()
    M.balance()
  end, { desc = 'Balance tmux panes and nvim windows' })

  vim.api.nvim_create_user_command('PaneBalanceInfo', function()
    local info = M.get_layout_info()
    print(vim.inspect(info))
  end, { desc = 'Show pane balancer layout info' })

  vim.api.nvim_create_user_command('PaneBalanceToggle', function()
    M.config.enabled = not M.config.enabled
    print('Pane balancer:', M.config.enabled and 'enabled' or 'disabled')
  end, { desc = 'Toggle pane balancer' })

  -- Setup auto-balancing
  setup_auto_balance()
end

return M
