-- Detect OS and use appropriate open command
local function get_open_command()
  if vim.fn.has('mac') == 1 then
    return 'open'
  else
    return 'xdg-open'
  end
end

local open_cmd = get_open_command()

-- Get the default branch (main/master) for a git repository
local function get_default_branch(git_root)
  -- Try to get the default branch from remote HEAD
  local branch = vim.fn.system('cd "' .. git_root .. '" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed "s@^refs/remotes/origin/@@"'):gsub('\n', '')

  if branch ~= '' then
    return branch
  end

  -- Fall back to checking which branch exists locally
  local main_check = vim.fn.system('cd "' .. git_root .. '" && git show-ref --verify refs/heads/main 2>/dev/null'):gsub('\n', '')
  if main_check ~= '' then
    return 'main'
  end

  local master_check = vim.fn.system('cd "' .. git_root .. '" && git show-ref --verify refs/heads/master 2>/dev/null'):gsub('\n', '')
  if master_check ~= '' then
    return 'master'
  end

  -- Last resort: use current branch
  return vim.fn.system('cd "' .. git_root .. '" && git rev-parse --abbrev-ref HEAD 2>/dev/null'):gsub('\n', '')
end

vim.api.nvim_create_user_command("Godoc", function(opts)
  vim.fn.jobstart(open_cmd .. ' "https://pkg.go.dev/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Google", function(opts)
  vim.fn.jobstart(open_cmd .. ' "https://google.com/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Godot", function(opts)
  vim.fn.jobstart(
    open_cmd .. ' "https://docs.godotengine.org/en/stable/search.html?check_keywords=yes&area=default&q=' .. opts.args .. '"',
    { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command('Open',
  function()
    local path = vim.api.nvim_buf_get_name(0)
    if vim.fn.has('mac') == 1 then
      os.execute('open -R "' .. path .. '"')
    else
      -- On Linux, open the parent directory
      os.execute('xdg-open "' .. vim.fn.fnamemodify(path, ':h') .. '"')
    end
  end,
  {}
)

vim.api.nvim_create_user_command('Blame', function()
  local file_path = vim.fn.expand('%:p')

  -- Find the nearest .git directory by traversing up from the current file
  local function find_git_root(path)
    local current_dir = vim.fn.fnamemodify(path, ':h')
    while current_dir ~= '/' do
      local git_dir = current_dir .. '/.git'
      if vim.fn.isdirectory(git_dir) == 1 then
        return current_dir
      end
      current_dir = vim.fn.fnamemodify(current_dir, ':h')
    end
    return nil
  end

  local git_root = find_git_root(file_path)
  if not git_root then
    vim.api.nvim_err_writeln('Could not find .git directory in parent directories.')
    return
  end

  -- Run git commands from the git root directory
  local git_remote = vim.fn.system('cd "' .. git_root .. '" && git config --get remote.origin.url'):gsub('\n', '')
  local repo_url = git_remote:match('github.com[:/](.+)%.git$')
  if not repo_url then
    vim.api.nvim_err_writeln('Could not determine GitHub repository URL.')
    return
  end

  local branch = get_default_branch(git_root)

  -- Get relative path from the git root
  local relative_path = vim.fn.substitute(file_path, '^' .. vim.fn.escape(git_root, '/') .. '/', '', '')
  local line_number = vim.fn.line('.')
  local github_url = 'https://github.com/' ..
      repo_url .. '/blame/' .. branch .. '/' .. relative_path .. '#L' .. line_number
  vim.fn.system({ open_cmd, github_url })
end, { desc = 'Open current file in GitHub' })




local function open_visible_buffers_cursor_ide()
  local buffers = vim.fn.getbufinfo({ buflisted = true })
  local command = "cursor "

  for _, buf in ipairs(buffers) do
    if buf.hidden == 0 and buf.loaded == 1 then
      local file_path = buf.name
      local line_number = vim.fn.line('.')
      if file_path ~= "" then
        command = command .. string.format("-g %s:%s ", file_path, line_number)
      end
    end
  end

  vim.fn.system(command)
end

vim.api.nvim_create_user_command(
  'Cursor',
  open_visible_buffers_cursor_ide,
  { desc = "Open Cursor IDE for all visible buffers" }
)

vim.api.nvim_create_user_command('YankFilePath', function()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return
  end
  vim.fn.setreg('+', filepath)
end, { desc = "Yank current buffer's file path to clipboard" })

vim.api.nvim_create_user_command('PrettierFormat', function()
  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)

  if filename == "" then
    print("Buffer has no name. Please save the file first.")
    return
  end

  vim.cmd('write')

  local cmd = string.format('prettier --write "%s"', filename)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print("Prettier failed: " .. result)
    return
  end

  vim.cmd('edit!')
end, { desc = "Format current buffer with Prettier" })

vim.api.nvim_create_user_command('SearchToQF', function()
  local search = vim.fn.getreg('/')
  if search == '' then
    vim.notify('No active search pattern.', vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local qf_list = {}
  local pattern = search

  for lnum, line in ipairs(lines) do
    local start = 1
    while true do
      local s, e = string.find(line, pattern, start)
      if not s then break end
      table.insert(qf_list, {
        bufnr = bufnr,
        lnum = lnum,
        col = s,
        text = line,
      })
      start = e + 1
    end
  end

  if #qf_list == 0 then
    vim.notify('No matches found for pattern: ' .. pattern, vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, ' ', {
    title = 'Search: ' .. pattern,
    items = qf_list,
  })
  vim.cmd('copen')
end, { desc = 'Move all search occurrences to quickfix list in active file' })

local mockoon_job_id = nil

vim.api.nvim_create_user_command('MockoonStart', function(opts)
  if mockoon_job_id then
    vim.notify('Mockoon is already running', vim.log.levels.WARN)
    return
  end

  local data_file = opts.args ~= '' and opts.args
    or vim.fn.findfile('BoomerangMocks.json', vim.fn.getcwd() .. ';')

  if data_file == '' then
    vim.notify('No Mockoon data file found. Pass a path or run from a project containing BoomerangMocks.json', vim.log.levels.ERROR)
    return
  end

  mockoon_job_id = vim.fn.jobstart({ 'mockoon-cli', 'start', '--data', data_file }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then vim.notify('[Mockoon] ' .. line, vim.log.levels.INFO) end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then vim.notify('[Mockoon] ' .. line, vim.log.levels.WARN) end
      end
    end,
    on_exit = function(_, code)
      mockoon_job_id = nil
      vim.notify('Mockoon stopped (exit ' .. code .. ')', vim.log.levels.INFO)
    end,
  })

  if mockoon_job_id <= 0 then
    mockoon_job_id = nil
    vim.notify('Failed to start mockoon-cli — is it installed? (npm install -g @mockoon/cli)', vim.log.levels.ERROR)
    return
  end

  vim.notify('Mockoon started: ' .. data_file, vim.log.levels.INFO)
end, { nargs = '?', complete = 'file', desc = 'Start Mockoon CLI mock server' })

vim.api.nvim_create_user_command('MockoonStop', function()
  if not mockoon_job_id then
    vim.notify('Mockoon is not running', vim.log.levels.WARN)
    return
  end
  vim.fn.jobstop(mockoon_job_id)
end, { desc = 'Stop Mockoon CLI mock server' })

vim.api.nvim_create_user_command('BufCleanup', function()
  local closed_count = 0
  local current_buf = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local is_modified = vim.bo[buf].modified
      local wins = vim.fn.win_findbuf(buf)
      local is_current = buf == current_buf

      if not is_modified and #wins == 0 and not is_current then
        local success = pcall(vim.api.nvim_buf_delete, buf, { force = false })
        if success then
          closed_count = closed_count + 1
        end
      end
    end
  end

  if closed_count > 0 then
    vim.notify('Closed ' .. closed_count .. ' unmodified buffer(s)', vim.log.levels.INFO)
  else
    vim.notify('No buffers to clean up', vim.log.levels.INFO)
  end
end, { desc = 'Close all unmodified buffers that are not visible' })
