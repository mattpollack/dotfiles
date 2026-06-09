local M = {}
local syntax = require('code-trace.syntax')

-- Configuration
M.config = {
  trace_file = vim.fn.stdpath("data") .. "/code-traces.txt",
  indent_size = 2,
  default_mark = "•",
  min_padding = 2, -- Minimum spaces between description and file path
}

-- Get current location as a string
local function get_location()
  local file = vim.fn.expand("%:p")
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local content = vim.api.nvim_get_current_line():gsub("^%s+", ""):gsub("%s+$", "")
  return file, line, content
end

-- Calculate the maximum description length from all entries in the file
-- Returns the minimum column needed to align all file paths
local function calculate_align_column()
  if vim.fn.filereadable(M.config.trace_file) == 0 then
    return 0 -- Will be calculated dynamically
  end

  local max_len = 0
  local f = io.open(M.config.trace_file, "r")
  if not f then
    return 0
  end

  for line in f:lines() do
    -- Skip comments and empty lines
    if not line:match("^#") and line:match("%S") then
      -- Match everything up to the last occurrence of a file path (path:number)
      -- Look for the closing paren of the description
      local prefix = line:match("^(.-%))%s+")
      if prefix then
        max_len = math.max(max_len, #prefix)
      end
    end
  end
  f:close()

  -- Add minimum padding
  return max_len + M.config.min_padding
end

-- Format a trace entry with aligned file paths
local function format_entry(file, line, content, level, note, align_col)
  local indent = string.rep(" ", (level or 0) * M.config.indent_size)
  local mark = "-"
  -- Use path relative to home directory for portability
  local display_file = vim.fn.fnamemodify(file, ":~")

  local description
  if note and note ~= "" then
    description = note
  else
    -- Show a short preview of the line content
    local preview = content:sub(1, 60)
    if #content > 60 then
      preview = preview .. "..."
    end
    description = preview
  end

  -- Build the prefix (indent + mark + description)
  local prefix = string.format("%s%s (%s)", indent, mark, description)
  
  -- Calculate padding needed to align file path
  local padding_needed
  if align_col and align_col > 0 then
    padding_needed = align_col - #prefix
    if padding_needed < M.config.min_padding then
      padding_needed = M.config.min_padding
    end
  else
    padding_needed = M.config.min_padding
  end
  local padding = string.rep(" ", padding_needed)

  return string.format("%s%s%s:%d", prefix, padding, display_file, line)
end

-- Parse a trace entry line
local function parse_entry(line)
  -- Match pattern: [indent][mark] (description) file:line
  local indent_count = 0
  local stripped = line:gsub("^(%s*)", function(spaces)
    indent_count = #spaces
    return ""
  end)

  local level = math.floor(indent_count / M.config.indent_size)

  -- Remove the mark (-, •, etc.) at the beginning
  stripped = stripped:gsub("^[%-•*+]%s+", "")

  -- Match file:line at the end of the string
  -- Pattern: (optional description in parens) file:line
  -- We need to match the last occurrence of a path followed by :digits
  local file, line_num = stripped:match("([^%s]+):(%d+)%s*$")

  if file and line_num then
    -- Expand ~ to home directory first
    file = vim.fn.expand(file)

    -- If still relative, make it absolute relative to cwd
    if not file:match("^/") then
      file = vim.fn.getcwd() .. "/" .. file
    end

    return {
      file = file,
      line = tonumber(line_num),
      level = level,
      raw = line
    }
  end
  return nil
end

-- Add a trace mark
function M.mark(level, note)
  level = level or 0
  local file, line, content = get_location()

  -- Prompt for note if not provided
  if not note then
    vim.ui.input({
      prompt = string.format("Trace note (Level %d): ", level),
    }, function(input)
      if input then
        M._add_mark(file, line, content, level, input)
      else
        M._add_mark(file, line, content, level, content:sub(1, 60))
      end
    end)
  else
    M._add_mark(file, line, content, level, note)
  end
end

-- Reformat entire file with aligned paths
local function reformat_file()
  if vim.fn.filereadable(M.config.trace_file) == 0 then
    return
  end

  -- Read all lines
  local f = io.open(M.config.trace_file, "r")
  if not f then return end
  
  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()

  -- Calculate the minimum alignment column based on the longest description
  local max_prefix_len = 0
  for _, line in ipairs(lines) do
    if not line:match("^#") and line:match("%S") then
      -- Match everything up to the closing paren of the description
      local prefix = line:match("^(.-%))%s+")
      if prefix then
        max_prefix_len = math.max(max_prefix_len, #prefix)
      end
    end
  end
  
  -- Alignment column is just the longest prefix + minimum padding
  local align_col = max_prefix_len + M.config.min_padding

  -- Reformat each line
  local formatted_lines = {}
  for _, line in ipairs(lines) do
    -- Keep comments and empty lines as-is
    if line:match("^#") or not line:match("%S") then
      table.insert(formatted_lines, line)
    else
      -- Parse and reformat trace entries
      local entry = parse_entry(line)
      if entry then
        -- Extract the description from the original line
        local desc = line:match("%((.-)%)")
        if desc then
          local indent = string.rep(" ", entry.level * M.config.indent_size)
          local mark = line:match("^%s*([%-•*+])") or "-"
          local prefix = string.format("%s%s (%s)", indent, mark, desc)
          local padding_needed = align_col - #prefix
          if padding_needed < M.config.min_padding then
            padding_needed = M.config.min_padding
          end
          local padding = string.rep(" ", padding_needed)
          local display_file = vim.fn.fnamemodify(entry.file, ":~")
          local formatted = string.format("%s%s%s:%d", prefix, padding, display_file, entry.line)
          table.insert(formatted_lines, formatted)
        else
          -- Couldn't parse, keep original
          table.insert(formatted_lines, line)
        end
      else
        -- Couldn't parse, keep original
        table.insert(formatted_lines, line)
      end
    end
  end

  -- Write back to file
  f = io.open(M.config.trace_file, "w")
  if f then
    for i, line in ipairs(formatted_lines) do
      f:write(line)
      if i <= #formatted_lines then
        f:write("\n")
      end
    end
    f:close()
  end
end

-- Internal function to add mark
function M._add_mark(file, line, content, level, note)
  -- Calculate current alignment
  local align_col = calculate_align_column()
  local entry = format_entry(file, line, content, level, note, align_col)

  -- Check if file exists and has content
  local file_exists = vim.fn.filereadable(M.config.trace_file) == 1
  local needs_newline = false

  if file_exists then
    local f = io.open(M.config.trace_file, "r")
    if f then
      local content = f:read("*all")
      f:close()
      -- Only add newline if file has content and doesn't end with newline
      needs_newline = #content > 0 and not content:match("\n$")
    end
  end

  -- Append to trace file
  local f = io.open(M.config.trace_file, "a")
  if f then
    if needs_newline then
      f:write("\n")
    end
    f:write(entry .. "\n")
    f:close()
    
    -- Reformat entire file to maintain alignment
    reformat_file()
    
    vim.notify(string.format("Trace added (Level %d)", level), vim.log.levels.INFO)

    -- Refresh the buffer if it's open
    M._refresh_buffer()
  else
    vim.notify("Failed to write trace file", vim.log.levels.ERROR)
  end
end

-- Refresh the trace buffer if it's open
function M._refresh_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf):match("code%-traces%.txt$") then
      -- Save cursor position
      local wins = vim.fn.win_findbuf(buf)
      local cursor_pos = nil
      if #wins > 0 then
        cursor_pos = vim.api.nvim_win_get_cursor(wins[1])
      end

      -- Reload the buffer
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("edit!")
      end)

      -- Restore cursor position
      if cursor_pos and #wins > 0 then
        vim.api.nvim_win_set_cursor(wins[1], cursor_pos)
      end
      break
    end
  end
end

-- Toggle trace buffer
function M.toggle_traces()
  -- Save current window
  local current_win = vim.api.nvim_get_current_win()

  -- Check if trace buffer is visible in any window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):match("code%-traces%.txt$") then
      -- Buffer is visible, close the window
      vim.api.nvim_win_close(win, false)
      return
    end
  end

  -- Buffer not visible, open it
  M.open_traces()

  -- Return to original window
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

-- Setup keymaps for trace buffer
local function setup_trace_keymaps(buf)
  vim.keymap.set("n", "<CR>", function()
    M.jump_to_trace()
  end, { buffer = buf, desc = "Jump to trace location" })

  vim.keymap.set("n", "gd", function()
    M.jump_to_trace()
  end, { buffer = buf, desc = "Jump to trace location" })
end

-- Open trace buffer
function M.open_traces()
  -- Create or find trace buffer
  local trace_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("code%-traces%.txt$") then
      trace_buf = buf
      break
    end
  end

  if not trace_buf or not vim.api.nvim_buf_is_loaded(trace_buf) then
    -- Create new buffer at bottom with fixed height
    vim.cmd("botright split " .. M.config.trace_file)
    vim.cmd("resize 10")
    trace_buf = vim.api.nvim_get_current_buf()
    local trace_win = vim.api.nvim_get_current_win()

    -- Set buffer options to make it special like quickfix
    vim.api.nvim_buf_set_option(trace_buf, "filetype", "codetrace")
    vim.api.nvim_buf_set_option(trace_buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(trace_buf, "buflisted", false)
    
    -- Set up syntax highlighting
    syntax.setup(trace_buf)
    
    -- Set window options to maintain fixed height
    vim.api.nvim_win_set_option(trace_win, "winfixheight", true)

    -- Add helpful header if file is empty
    if vim.fn.filereadable(M.config.trace_file) == 0 then
      local header = {
        "# Code Traces",
        "# Press <CR> or 'gd' on a line to jump to that location",
        "# Edit this file freely to organize your traces",
        "# Format: [indent]mark (description or line preview) file:line",
      }
      vim.api.nvim_buf_set_lines(trace_buf, 0, 0, false, header)
    end
  else
    -- Switch to existing buffer
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == trace_buf then
        vim.api.nvim_set_current_win(win)
        -- Ensure keymaps are set
        setup_trace_keymaps(trace_buf)
        -- Ensure window options are set
        vim.api.nvim_win_set_option(win, "winfixheight", true)
        vim.cmd("resize 10")
        return
      end
    end
    vim.cmd("botright split")
    vim.cmd("resize 10")
    vim.api.nvim_win_set_buf(0, trace_buf)
    local trace_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_option(trace_win, "winfixheight", true)
  end

  -- Always ensure keymaps are set
  setup_trace_keymaps(trace_buf)
end

-- Jump to trace location from trace buffer
function M.jump_to_trace()
  local line = vim.api.nvim_get_current_line()
  local entry = parse_entry(line)

  if entry then
    -- Save the trace window
    local trace_win = vim.api.nvim_get_current_win()

    -- Find the previous window (not the trace window)
    local wins = vim.api.nvim_list_wins()
    local target_win = nil

    for _, win in ipairs(wins) do
      if win ~= trace_win then
        target_win = win
        break
      end
    end

    if target_win then
      vim.api.nvim_set_current_win(target_win)
    end

    -- Open the file and jump to line
    if vim.fn.filereadable(entry.file) == 1 then
      local ok, err = pcall(function()
        vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
        vim.api.nvim_win_set_cursor(0, { entry.line, 0 })
        vim.cmd("normal! zz")
      end)

      if not ok then
        vim.notify(string.format("Error jumping to file: %s", err), vim.log.levels.ERROR)
      end

      -- Return to trace window
      if vim.api.nvim_win_is_valid(trace_win) then
        vim.api.nvim_set_current_win(trace_win)
      end
    else
      vim.notify(string.format("File not found: %s", vim.fn.fnamemodify(entry.file, ":~")), vim.log.levels.WARN)
    end
  else
    vim.notify("No valid trace entry on this line", vim.log.levels.WARN)
  end
end

-- Clear all traces
function M.clear_traces()
  vim.ui.input({
    prompt = "Clear all traces? (yes/no): "
  }, function(input)
    if input == "yes" then
      local f = io.open(M.config.trace_file, "w")
      if f then
        f:close()
        vim.notify("All traces cleared", vim.log.levels.INFO)
        -- Reload buffer if open
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):match("code%-traces%.txt$") then
            vim.cmd("edit!")
            break
          end
        end
      end
    end
  end)
end

-- Public function to reformat traces
function M.reformat_traces()
  local before_count = 0
  if vim.fn.filereadable(M.config.trace_file) == 1 then
    local f = io.open(M.config.trace_file, "r")
    if f then
      for _ in f:lines() do
        before_count = before_count + 1
      end
      f:close()
    end
  end
  
  reformat_file()
  
  local after_count = 0
  if vim.fn.filereadable(M.config.trace_file) == 1 then
    local f = io.open(M.config.trace_file, "r")
    if f then
      for _ in f:lines() do
        after_count = after_count + 1
      end
      f:close()
    end
  end
  
  vim.notify(string.format("Traces reformatted (%d lines)", after_count), vim.log.levels.INFO)
  M._refresh_buffer()
end

-- Dynamic mark function that accepts any level
function M.mark_level(level)
  return function()
    M.mark(level)
  end
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create trace file if it doesn't exist
  if vim.fn.filereadable(M.config.trace_file) == 0 then
    local f = io.open(M.config.trace_file, "w")
    if f then f:close() end
  end

  -- Set up autocommand to configure trace buffers when opened
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*code-traces.txt",
    callback = function(ev)
      local buf = ev.buf

      -- Set buffer options
      vim.api.nvim_buf_set_option(buf, "filetype", "codetrace")
      vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
      vim.api.nvim_buf_set_option(buf, "buflisted", false)

      -- Set up syntax highlighting
      syntax.setup(buf)

      -- Set up keymaps
      setup_trace_keymaps(buf)
    end
  })

  -- Set up autocommand to maintain fixed height for trace windows
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    pattern = "*code-traces.txt",
    callback = function()
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_option(win, "winfixheight", true)
      -- Force resize to 10 if it's not already
      local height = vim.api.nvim_win_get_height(win)
      if height ~= 10 then
        vim.cmd("resize 10")
      end
    end
  })

  -- Enforce height on any window resize event
  vim.api.nvim_create_autocmd("WinResized", {
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_name(buf):match("code%-traces%.txt$") then
          local height = vim.api.nvim_win_get_height(win)
          if height ~= 10 then
            vim.api.nvim_win_set_height(win, 10)
          end
        end
      end
    end
  })
end

return M
