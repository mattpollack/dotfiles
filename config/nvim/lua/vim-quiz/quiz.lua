-- Quiz logic for Vim command quiz

local data = require("vim-quiz.data")
local M = {}

-- Quiz state
M.state = {
  current_question = nil,
  score = 0,
  total_questions = 0,
  asked_indices = {},
}

-- Fisher-Yates shuffle
local function shuffle(tbl)
  local result = vim.deepcopy(tbl)
  for i = #result, 2, -1 do
    local j = math.random(i)
    result[i], result[j] = result[j], result[i]
  end
  return result
end

-- Get a random command that hasn't been asked yet
function M.get_random_command()
  local available_indices = {}

  for i = 1, #data.commands do
    if not vim.tbl_contains(M.state.asked_indices, i) then
      table.insert(available_indices, i)
    end
  end

  -- If all questions have been asked, reset
  if #available_indices == 0 then
    M.state.asked_indices = {}
    available_indices = {}
    for i = 1, #data.commands do
      table.insert(available_indices, i)
    end
  end

  local random_idx = available_indices[math.random(#available_indices)]
  table.insert(M.state.asked_indices, random_idx)

  return data.commands[random_idx], random_idx
end

-- Generate wrong answers (distractors) from other commands
function M.generate_distractors(correct_idx, count)
  local distractors = {}
  local available_indices = {}

  for i = 1, #data.commands do
    if i ~= correct_idx then
      table.insert(available_indices, i)
    end
  end

  -- Shuffle and take the first 'count' items
  available_indices = shuffle(available_indices)

  for i = 1, math.min(count, #available_indices) do
    table.insert(distractors, data.commands[available_indices[i]].desc)
  end

  return distractors
end

-- Generate a new question with 3 answer choices
function M.generate_question()
  local command, cmd_idx = M.get_random_command()
  local correct_answer = command.desc

  -- Generate 2 wrong answers
  local distractors = M.generate_distractors(cmd_idx, 2)

  -- Create answer choices (1 correct + 2 wrong)
  local choices = { correct_answer }
  for _, distractor in ipairs(distractors) do
    table.insert(choices, distractor)
  end

  -- Shuffle the choices
  choices = shuffle(choices)

  -- Find the index of the correct answer
  local correct_index = nil
  for i, choice in ipairs(choices) do
    if choice == correct_answer then
      correct_index = i
      break
    end
  end

  M.state.current_question = {
    command = command.cmd,
    category = command.category,
    choices = choices,
    correct_index = correct_index,
    correct_answer = correct_answer,
  }

  return M.state.current_question
end

-- Check if the user's answer is correct
function M.check_answer(user_choice)
  if not M.state.current_question then
    return false, "No active question"
  end

  M.state.total_questions = M.state.total_questions + 1

  local is_correct = user_choice == M.state.current_question.correct_index
  if is_correct then
    M.state.score = M.state.score + 1
  end

  return is_correct, M.state.current_question.correct_answer
end

-- Get current score
function M.get_score()
  return M.state.score, M.state.total_questions
end

-- Reset quiz state
function M.reset()
  M.state = {
    current_question = nil,
    score = 0,
    total_questions = 0,
    asked_indices = {},
  }
end

return M
