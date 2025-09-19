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
  local git_remote = vim.fn.system('git config --get remote.origin.url'):gsub('\n', '')
  local repo_url = git_remote:match('github.com[:/](.+)%.git$')
  if not repo_url then
    vim.api.nvim_err_writeln('Could not determine GitHub repository URL.')
    return
  end

  local branch = 'main'
  if vim.fn.system('git show-ref --verify refs/heads/master'):gsub('\n', '') ~= '' then
    branch = 'master'
  end

  local relative_path = vim.fn.fnamemodify(file_path, ':~:.')
  local line_number = vim.fn.line('.')
  local github_url = 'https://github.com/' ..
      repo_url .. '/blame/' .. branch .. '/' .. relative_path .. '#L' .. line_number
  vim.fn.system({ 'open', github_url })
end, { desc = 'Open current file in GitHub' })

vim.api.nvim_create_user_command('InsertOpenBuffers', function()
  local chat = require("codecompanion").chat()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'buftype') == '' then
      local file_path = vim.api.nvim_buf_get_name(buf)
      local cwd = vim.fn.getcwd()
      local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

      if relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
        chat.references:add({
          id = '<file>' .. relative_path .. '</file>',
          path = relative_path,
          source = "codecompanion.strategies.chat.slash_commands.file",
          opts = {
            pinned = true,
            watched = false,
            visible = true,
          }
        })
      end
    end
  end
end, {})

vim.api.nvim_create_user_command('InsertQuickfixFiles', function()
  local chat = require("codecompanion").chat()
  local qf_list = vim.fn.getqflist()
  local added_files = {}

  for _, item in ipairs(qf_list) do
    local bufnr = item.bufnr
    if bufnr > 0 then
      local file_path = vim.api.nvim_buf_get_name(bufnr)
      local cwd = vim.fn.getcwd()
      local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

      if not added_files[relative_path] and relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
        chat.references:add({
          id = '<file>' .. relative_path .. '</file>',
          path = relative_path,
          source = "codecompanion.strategies.chat.slash_commands.file",
          opts = {
            pinned = true,
            watched = false,
            visible = true,
          }
        })
        added_files[relative_path] = true
      end
    end
  end
end, {})

vim.api.nvim_create_user_command('InsertHarpoonFiles', function()
  local chat = require("codecompanion").chat()
  local harpoon = require("harpoon")
  local harpoon_list = harpoon:list()

  for _, item in ipairs(harpoon_list.items) do
    local file_path = item.value
    local cwd = vim.fn.getcwd()
    local relative_path = vim.fn.fnamemodify(file_path, ":." .. cwd)

    if relative_path ~= '' and vim.fn.filereadable(relative_path) == 1 then
      chat.references:add({
        id = '<file>' .. relative_path .. '</file>',
        path = relative_path,
        source = "codecompanion.strategies.chat.slash_commands.file",
        opts = {
          pinned = true,
          watched = false,
          visible = true,
        }
      })
    end
  end
end, {})

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