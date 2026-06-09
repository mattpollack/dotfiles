# Vim Quiz Plugin

A fun, interactive Neovim plugin to help you learn and practice Vim motions and commands through multiple-choice quizzes!

## Features

- **80+ Vim commands** covering cursor movement, editing, visual mode, cut/paste, search, and more
- **Three-answer multiple choice** format for each question
- **Score tracking** to monitor your progress
- **Beautiful floating window** UI
- **Category-based questions** to help you learn systematically
- **No repeats** - questions won't repeat until you've seen them all

## Usage

### Commands

The plugin provides the following commands:

- `:VimQuiz` - Start a new quiz session
- `:VimQuizScore` - Display your current score
- `:VimQuizReset` - Reset your score to 0

### Quiz Controls

When the quiz window is open, you can:

- Press `1`, `2`, or `3` to select an answer
- Press `n` to skip to the next question
- Press `q` or `Esc` to quit the quiz

### Optional Keymap

You can add a custom keymap to quickly start the quiz by modifying the setup in `lua/plugins/editor.lua`:

```lua
require("vim-quiz").setup({
  keymap = "<leader>vq",  -- Uncomment and customize as needed
})
```

## How It Works

1. The plugin randomly selects a Vim command from its database
2. It generates two incorrect answers (distractors) from other commands
3. All three answers are shuffled randomly
4. You select your answer using keys 1-3
5. Immediate feedback shows if you're correct
6. Your score is tracked throughout the session

## Examples

```
┌─────────────── Vim Motion Quiz ───────────────┐
│                                               │
│  Score: 5/8                                   │
│                                               │
│  Category: Cursor movement                    │
│                                               │
│  What does 'w' do?                            │
│                                               │
│                                               │
│  1) jump backwards to the start of a word     │
│                                               │
│  2) jump forwards to the start of a word      │
│                                               │
│  3) jump to the end of the line               │
│                                               │
│                                               │
│  Press 1-3 to answer, 'n' for next, 'q' to quit│
└───────────────────────────────────────────────┘
```

## Categories Covered

- **Cursor movement** - h, j, k, l, w, b, e, 0, $, gg, G, etc.
- **Insert mode** - i, I, a, A, o, O, ea
- **Editing** - r, R, J, cc, ciw, cw, s, S, u, .
- **Visual mode** - v, V
- **Cut and paste** - yy, yw, yiw, p, P, dd, dw, diw, x
- **Search** - /pattern, n, N
- **Advanced movement** - fx, Fx, tx, ;, ,, gd, gD
- **Indentation** - >>, <<
- **Marks** - ma, `a
- **Macros** - qa, @a

## Tips for Learning

1. Start with `:VimQuiz` and answer questions at your own pace
2. When you get an answer wrong, try to remember the correct answer
3. Use `:VimQuizScore` to track your improvement
4. Practice the commands you miss in your actual editing workflow
5. Reset with `:VimQuizReset` when you want to start fresh

## Customization

The plugin is designed to be simple and focused. If you want to add more commands or modify the existing ones, edit `lua/vim-quiz/data.lua`.

## Contributing

Feel free to add more Vim commands to the database in `data.lua`! Each entry should follow this format:

```lua
{ cmd = "command", desc = "description of what it does", category = "Category Name" }
```

Enjoy learning Vim the fun way! 🚀
