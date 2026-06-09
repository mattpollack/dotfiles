-- Vim Quiz Plugin
-- A multiple-choice quiz to help learn Vim motions and commands

local ui = require("vim-quiz.ui")
local quiz = require("vim-quiz.quiz")

local M = {}

-- Setup function to initialize the plugin
function M.setup(opts)
  opts = opts or {}

  -- Create user commands
  vim.api.nvim_create_user_command("VimQuiz", function()
    ui.start_quiz()
  end, {
    desc = "Start the Vim motion quiz",
  })

  vim.api.nvim_create_user_command("VimQuizReset", function()
    quiz.reset()
    print("Quiz reset! Score: 0/0")
  end, {
    desc = "Reset the quiz score",
  })

  vim.api.nvim_create_user_command("VimQuizScore", function()
    local score, total = quiz.get_score()
    print(string.format("Current Score: %d/%d (%.1f%%)", score, total, total > 0 and (score / total * 100) or 0))
  end, {
    desc = "Show current quiz score",
  })

  -- Optional: Setup a keymap if specified in opts
  if opts.keymap then
    vim.keymap.set("n", opts.keymap, function()
      ui.start_quiz()
    end, { desc = "Start Vim Quiz" })
  end
end

-- Expose UI functions for manual use
M.start = ui.start_quiz
M.close = ui.close
M.reset = quiz.reset

return M
