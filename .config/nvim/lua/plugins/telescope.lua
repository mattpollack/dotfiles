-- NOTE: Using quickfix list instead now
-- local function get_entry_filename(entry)
--   if entry.path or entry.filename then
--     return entry.path or entry.filename
--   elseif not entry.bufnr then
--     local value = entry.value
--
--     if not value then
--       return
--     end
--
--     if type(value) == "table" then
--       value = entry.display
--     end
--
--     local sections = vim.split(value, ":")
--
--     return sections[1]
--   end
-- end
--
-- local function push_selected_to_harpoon(prompt_bufnr)
--   local harpoon = require("harpoon")
--   local actions = require("telescope.actions")
--   local action_state = require("telescope.actions.state")
--   local picker = action_state.get_current_picker(prompt_bufnr)
--   local multi_selections = picker:get_multi_selection()
--
--   if #multi_selections == 0 then
--     local entry = action_state.get_selected_entry()
--     if entry then
--       harpoon:list():add(get_entry_filename(entry))
--     end
--   else
--     for _, entry in ipairs(multi_selections) do
--       harpoon:list():add(get_entry_filename(entry))
--     end
--   end
-- end

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim',
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-t>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
            n = {
              ["<C-t>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
          file_ignore_patterns = {
            "node_modules"
          }
        },
        pickers = {
          find_files = {
            hidden = true,
            -- Use git_files when in a git repo to respect .gitignore
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git" },
          },
        }
      })
      telescope.load_extension("live_grep_args")
    end
  },
  'catgoose/telescope-helpgrep.nvim',
}

