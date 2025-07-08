local M = {}

--- Prefill the edit window with a given request and submit it immediately.
-- Opens the edit window, populates it with the request text, sets the cursor position,
-- and simulates a submission via a keypress.
--- @param request string: The text to prefill in the edit window.
M.prefill_edit_window = function(request)
  require("avante.api").edit()
  local code_bufnr = vim.api.nvim_get_current_buf()
  local code_winid = vim.api.nvim_get_current_win()
  if code_bufnr == nil or code_winid == nil then
    return
  end
  vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
  -- Optionally set the cursor position to the end of the input
  vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
  -- Simulate Ctrl+S keypress to submit
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-s>", true, true, true), "v", true)
end

--Build a keymap configuration for a given key and callback.
--Constructs a keymap entry with a specific key, callback function, description, and mode.
--- @param key string: The key to bind.
--- @param callback function|nil: The function to execute when the key is pressed.
--- @param desc string: The description of the keymap.
--- @param mode string|table: The mode in which the keymap is active (e.g., "n" for normal mode).
--- @return table: A table representing the keymap configuration.
M.build_keymap = function(key, callback, desc, mode)
  return {
    key,
    callback or "",
    desc = desc,
    mode = mode,
  }
end

--Interpolates a template string with variables from a table.
--Replaces placeholders in the format {{key}} within the template string
--with corresponding values from the provided table.
--- @param template string: The template string containing placeholders in the format {{key}}.
--- @param vars table: A table containing key-value pairs used for substitution in the template.
--- @return string: The interpolated string with all placeholders replaced by their corresponding values.
M.interpolate = function(template, vars)
  return (template:gsub("{{(.-)}}", function(key)
    return tostring(vars[key] or "")
  end))
end

--############################################################################
--                              Select Operation
--############################################################################

--- Display a selection list and return the user's choice.
--- @param title string: The title of the selection list.
--- @param options table: A table containing the options to display.
--- @return string|nil: Returns the selected option as a string, or nil if no valid selection is made.
local function select_from_list(title, options)
  local choices = { title }
  for i, option in ipairs(options) do
    table.insert(choices, string.format("%d. %s", i, option))
  end
  table.insert(choices, "")

  local choice = vim.fn.inputlist(choices)
  if choice < 1 or choice > #options then
    return nil
  end

  return options[choice]
end

--- @param branches? table: A list of branches to choose from.
M.select_branch = function(branches)
  branches = branches
    or vim.split(vim.fn.system("git branch --format='%(refname:short)'"), "\n", { trimempty = true })
    or {}

  return select_from_list("Select base branch:", branches)
end

--- @param languages? table: A list of languages to choose from.
M.select_language = function(languages)
  languages = languages or { "English", "Japanese" }
  return select_from_list("Select language:", languages)
end

--- @param tones? table: A list of tones to choose from.
M.select_tone = function(tones)
  tones = tones or { "Formal", "Casual", "Emotional", "Persuasive", "Informative", "Narrative" }
  return select_from_list("Select tone:", tones)
end

--############################################################################
--                              Git Operation
--############################################################################

--Get the name of the current Git branch.
--Executes a Git command to retrieve the current branch name and trims any whitespace.
--- @return string: The name of the current Git branch.
M.get_current_branch = function()
  return vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
end

--Get the owner of the current Git repository.
--Extracts the repository owner from the remote origin URL in the Git configuration.
--If the remote origin URL is not configured, the result will be an empty string.
--- @return string: The owner of the repository.
M.get_repository_owner = function()
  return vim.trim(vim.fn.system("git config --get remote.origin.url | sed -n 's#.*[:/]\\([^/]*\\)/[^/]*\\.git#\\1#p'"))
end

--Retrieve the name of the current Git repository.
--Extracts the repository name from the remote origin URL in the Git configuration.
--If the remote origin URL is not configured, the result will be an empty string.
--- @return string: The name of the repository.
M.get_repository = function()
  return vim.trim(vim.fn.system("git config --get remote.origin.url | sed -n 's#.*[:/][^/]*/\\([^/]*\\)\\.git#\\1#p'"))
end

return M
