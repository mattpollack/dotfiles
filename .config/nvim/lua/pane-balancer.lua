--- pane-balancer.lua
--- Auto-balance tmux panes and nvim windows for equal horizontal spacing
--- Accounts for nested nvim windows within tmux panes

local M = {}
local bridge = require('tmux-bridge')

M.config = {
  enabled = true,
  auto_balance = true,
  min_pane_width = 20, -- minimum width for any pane
  debug = false,
}

--- Debug logging
local function debug_log(...)
  if M.config.debug then
    print('[pane-balancer]', ...)
  end
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

  debug_log(string.format('Found %d top-level vertical windows', #top_level_wins))
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

  local panes = bridge.get_panes()
  if not panes then return {} end

  local nvim_panes = {}
  local current_pane = bridge.get_pane_id()

  for _, pane_id in ipairs(panes) do
    local pane_info = bridge.get_pane_info(pane_id)

    if pane_info and pane_info.command == 'nvim' then
      if pane_id == current_pane then
        -- For current pane, count vertical non-floating windows
        local win_count = count_vertical_windows()
        nvim_panes[pane_id] = win_count
        debug_log(string.format('Current pane %s has %d vertical nvim windows', pane_id, win_count))
      else
        -- For other panes, assume 1 window (we can't easily query other nvim instances)
        -- TODO: Could potentially query via socket if needed
        nvim_panes[pane_id] = 1
        debug_log(string.format('Other nvim pane %s assumed to have 1 window', pane_id))
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

  local panes = bridge.get_panes()
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
    debug_log('Only 1 or fewer top-level windows, skipping balance')
    return
  end

  -- Calculate equal width for each top-level vertical window
  local total_width = vim.o.columns
  local target_width = math.floor(total_width / #top_level_wins)

  for _, win_info in ipairs(top_level_wins) do
    vim.api.nvim_win_set_width(win_info.id, target_width)
  end

  debug_log(string.format('Balanced %d top-level windows to width %d', #top_level_wins, target_width))
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
  local current_pane = bridge.get_pane_id()

  debug_log(string.format('Total width: %d, Total logical panes: %d', total_width, total_logical))

  -- Calculate target width for each tmux pane based on its logical pane count
  for pane_id, info in pairs(layout_info.tmux_panes) do
    local proportion = info.logical_panes / total_logical
    local target_width = math.floor(total_width * proportion)

    -- Ensure minimum width
    target_width = math.max(target_width, M.config.min_pane_width)

    debug_log(string.format(
      'Pane %s: %d logical panes (%.2f%%) -> target width: %d',
      pane_id, info.logical_panes, proportion * 100, target_width
    ))

    -- Resize the pane
    local pane_info = bridge.get_pane_info(pane_id)
    if pane_info and pane_info.width then
      local width_diff = target_width - pane_info.width

      if math.abs(width_diff) > 2 then -- Only resize if difference is significant
        local resize_cmd = width_diff > 0
            and string.format('resize-pane -t %s -x %d', pane_id, target_width)
            or string.format('resize-pane -t %s -x %d', pane_id, target_width)

        bridge.tmux(resize_cmd)
        debug_log(string.format('Resized pane %s from %d to %d', pane_id, pane_info.width, target_width))
      end
    end
  end
end

--- Main balance function
function M.balance()
  if not M.config.enabled then
    return
  end

  debug_log('=== Starting balance ===')

  -- Calculate the layout
  local layout_info = calculate_logical_panes()

  debug_log(string.format(
    'Layout: %d tmux panes, %d total logical panes, current pane has %d nvim windows',
    layout_info.num_tmux_panes or 0,
    layout_info.total_logical_panes,
    layout_info.current_pane_windows
  ))

  -- Balance nvim windows first (within current pane)
  balance_nvim_windows()

  -- Then balance tmux panes based on logical distribution
  if bridge.in_tmux() and layout_info.num_tmux_panes and layout_info.num_tmux_panes > 1 then
    balance_tmux_panes(layout_info)
  end

  debug_log('=== Balance complete ===')
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
          debug_log(string.format('Top-level window count changed: %d -> %d', 
            prev_top_level_count, current_top_level_count))
          prev_top_level_count = current_top_level_count
          M.balance()
        else
          debug_log('Top-level window count unchanged, skipping balance')
        end
      end, 50)
    end,
  })

  -- Balance on tmux pane events (via bridge)
  if bridge.in_tmux() then
    bridge.on('pane:split', 'pane-balancer', function()
      vim.defer_fn(function()
        M.balance()
      end, 100)
    end)

    bridge.on('pane:killed', 'pane-balancer', function()
      vim.defer_fn(function()
        M.balance()
      end, 100)
    end)

    -- Balance on window resize
    vim.api.nvim_create_autocmd('VimResized', {
      group = vim.api.nvim_create_augroup('PaneBalancerResize', { clear = true }),
      callback = function()
        vim.defer_fn(function()
          M.balance()
        end, 50)
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

  vim.api.nvim_create_user_command('PaneBalanceDebug', function()
    M.config.debug = not M.config.debug
    print('Pane balancer debug:', M.config.debug and 'enabled' or 'disabled')
  end, { desc = 'Toggle pane balancer debug logging' })

  -- Setup auto-balancing
  setup_auto_balance()

  debug_log('Pane balancer initialized')
end

return M
