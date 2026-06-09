-- UI components for Vim quiz

local quiz = require("vim-quiz.quiz")
local M = {}

-- State for UI
local state = {
  buf = nil,
  win = nil,
}

-- Create a centered floating window
local function create_floating_window()
  local width = 70
  local height = 15

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "vimquiz")

  -- Window options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Vim Motion Quiz ",
    title_pos = "center",
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

  return buf, win
end

-- Close the quiz window
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf = nil
  state.win = nil
end

-- Display question in the floating window
function M.display_question(question)
  if not question then
    return
  end

  -- Create window if it doesn't exist
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    state.buf, state.win = create_floating_window()
  end

  local score, total = quiz.get_score()

  -- Build the display content
  local lines = {
    "",
    string.format("  Score: %d/%d", score, total),
    "",
    string.format("  Category: %s", question.category),
    "",
    string.format("  What does '%s' do?", question.command),
    "",
    "",
  }

  -- Add answer choices
  for i, choice in ipairs(question.choices) do
    table.insert(lines, string.format("  %d) %s", i, choice))
    table.insert(lines, "")
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 1-3 to answer, 'n' for next, 'q' to quit")

  -- Set buffer content
  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- Set up keymaps for this buffer
  M.setup_keymaps(state.buf)
end

-- Show result feedback
function M.show_result(is_correct, correct_answer)
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local score, total = quiz.get_score()
  local result_msg = is_correct and "✓ Correct!" or "✗ Wrong!"
  local color = is_correct and "String" or "Error"

  local lines = {
    "",
    string.format("  Score: %d/%d", score, total),
    "",
    "  " .. result_msg,
    "",
  }

  if not is_correct then
    table.insert(lines, string.format("  Correct answer: %s", correct_answer))
    table.insert(lines, "")
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 'n' for next question, 'q' to quit")
  table.insert(lines, "")

  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- Highlight the result message
  local ns_id = vim.api.nvim_create_namespace("vim_quiz_result")
  vim.api.nvim_buf_clear_namespace(state.buf, ns_id, 0, -1)
  vim.api.nvim_buf_add_highlight(state.buf, ns_id, color, 3, 0, -1)
end

-- Handle answer selection
local function handle_answer(choice)
  local is_correct, correct_answer = quiz.check_answer(choice)
  M.show_result(is_correct, correct_answer)
end

-- Show next question
local function next_question()
  local question = quiz.generate_question()
  M.display_question(question)
end

-- Setup keymaps for the quiz buffer
function M.setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Answer keys (1, 2, 3)
  vim.keymap.set("n", "1", function()
    handle_answer(1)
  end, opts)

  vim.keymap.set("n", "2", function()
    handle_answer(2)
  end, opts)

  vim.keymap.set("n", "3", function()
    handle_answer(3)
  end, opts)

  -- Next question
  vim.keymap.set("n", "n", function()
    next_question()
  end, opts)

  -- Quit
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, opts)
end

-- Start the quiz
function M.start_quiz()
  quiz.reset()
  next_question()
end

return M
