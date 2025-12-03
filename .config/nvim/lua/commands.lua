vim.api.nvim_create_user_command("Godoc", function(opts)
  vim.fn.jobstart('open "https://pkg.go.dev/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Google", function(opts)
  vim.fn.jobstart('open "https://google.com/search?q=' .. opts.args .. '"', { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command("Godot", function(opts)
  vim.fn.jobstart(
    'open "https://docs.godotengine.org/en/stable/search.html?check_keywords=yes&area=default&q=' .. opts.args .. '"',
    { detach = true })
end, { nargs = 1 })

vim.api.nvim_create_user_command('Open',
  function()
    local path = vim.api.nvim_buf_get_name(0)
    os.execute('open -R ' .. path)
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

  local branch = 'main'
  local master_check = vim.fn.system('cd "' .. git_root .. '" && git show-ref --verify refs/heads/master'):gsub('\n', '')
  if master_check ~= '' then
    branch = 'master'
  end

  -- Get relative path from the git root
  local relative_path = vim.fn.substitute(file_path, '^' .. vim.fn.escape(git_root, '/') .. '/', '', '')
  local line_number = vim.fn.line('.')
  local github_url = 'https://github.com/' ..
      repo_url .. '/blame/' .. branch .. '/' .. relative_path .. '#L' .. line_number
  vim.fn.system({ 'open', github_url })
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
