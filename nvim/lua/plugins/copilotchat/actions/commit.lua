---@alias CommitType "Basic"|"WIP"|"Merge"|"Squash Merge"

---@class CommitOpts
---@field base_branch string|nil
---@field commit_language LanguageName|nil

local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local M = {}

local prompts = {
  Basic = 'Write a clear and concise "Basic" commit message for the selected changes.',
  WIP = 'Write a commit message indicating this is a work in progress "WIP" commit.',
  Merge = 'Write a commit message for merging the specified branches. \nSummarize the changes introduced by the "Merge".',
  ["Squash Merge"] = 'Write a commit message for a "Squash Merge", summarizing all combined changes.',
}

local base_note_list = {
  "<type> must follow the commitzen convention",
  "Use the imperative mood in the summary (e.g., 'add', 'fix', 'update').",
  "Keep the <short_summary> under 50 characters.",
  "Wrap the <body> at 72 characters per line.",
  "Leave one blank line between the summary and the body.",
  "Omit <scope> if not applicable.",
  "! If the user is provided with `commitlint.config.js` or `.cz-config.js` registers, please follow those rules.",
}

local note_lists = {
  Basic = base_note_list,
  WIP = base_note_list,
  Merge = base_note_list,
  ["Squash Merge"] = vim.tbl_extend("force", base_note_list, {
    "Include all commits in the branch inside `-----` in <internal_commits>.",
  }),
}

local format = {
  Basic = "basic_commit",
  WIP = "basic_commit",
  Merge = "merge_commit",
  ["Squash Merge"] = "squash_commit",
}

local fallback_chat_title = {
  Basic = "Request to create basic commitments.",
  WIP = "Request to create WIP commitments.",
  Merge = "Request to Create Merge Commit.",
  ["Squash Merge"] = "Request to Create Squash Merge Commit.",
}

--- @param commit_type string
local build_prompt = function(commit_type)
  local prompt = prompts[commit_type]
  local note_list = note_lists[commit_type]

  if not prompt or prompt == "" then
    return nil
  end

  if not note_list or #note_list == 0 then
    return prompt
  end

  return prompt .. "\n\n**Note**:\n- " .. table.concat(note_list, "\n- ")
end

--- Build sticky context for the given commit type, base branch, and commit language.
---@param commit_type CommitType
---@param opts CommitOpts
---@return table
local function build_sticky(commit_type, opts)
  local git = nil
  local system = nil

  if commit_type == "Basic" or commit_type == "WIP" then
    git = "staged"
  elseif commit_type == "Merge" then
    system = "git diff " .. opts.base_branch
  elseif commit_type == "Squash Merge" then
    local current_branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
    local show_commit_list_command = "git log "
      .. opts.base_branch
      .. ".."
      .. current_branch
      .. ' --reverse --pretty="%an -> %s"'
    system = { "git diff " .. opts.base_branch, show_commit_list_command }
  end

  return sticky.build({
    content_language = opts.commit_language,
    file = { "commitlint.config.js", ".cz-config.js" },
    git = git,
    system = system,
  })
end

--- Build the system prompt for commit actions.
---@param commit_type CommitType
---@return string
local build_system_prompt = function(commit_type)
  return system_prompt.build({
    role = "assistant",
    character = "ai",
    guideline = { change_code = true, localization = true },
    specialties = "gitcommit",
    format = format[commit_type],
  })
end

--- Open the CopilotChat window for the given commit type, base branch, and commit language.
---@param commit_type CommitType
---@param opts CommitOpts
local function open_window(commit_type, opts)
  local prompt = build_prompt(commit_type)
  if not prompt then
    return
  end

  local save_chat = function(response)
    chat_history.save(response, {
      used_prompt = prompt or fallback_chat_title[commit_type],
      tag = "Commit",
    })
  end

  window.open_float(prompt, {
    system_prompt = build_system_prompt(commit_type),
    sticky = build_sticky(commit_type, opts),
    selection = false,
    callback = save_chat,
  })
end

--- Handle commit language selection and open window.
---@param commit_type CommitType
---@param opts CommitOpts
local function on_commit_language_selected(commit_type, opts)
  if not opts.commit_language or opts.commit_language == "" then
    opts.commit_language = system_languages.default
  end
  open_window(commit_type, opts)
end

--- Prompt user to select commit language.
---@param commit_type CommitType
---@param base_branch string
local function select_commit_language(commit_type, base_branch)
  vim.ui.select(system_languages.names, {
    prompt = "Select language> ",
  }, function(language)
    on_commit_language_selected(commit_type, {
      base_branch = base_branch,
      commit_language = language,
    })
  end)
end

--- Prompt user to input base branch.
---@param commit_type CommitType
local function input_base_branch(commit_type)
  vim.ui.input({ prompt = "Enter base branch> " }, function(input)
    if not input or input == "" then
      input = "main"
    end
    select_commit_language(commit_type, input)
  end)
end

--- Prompt user to select base branch.
---@param commit_type CommitType
local function select_base_branch(commit_type)
  local next = {
    main = select_commit_language,
    develop = select_commit_language,
    Other = input_base_branch,
  }

  vim.ui.select({ "main", "develop", "Other" }, {
    prompt = "Select base branch> ",
  }, function(selected_base_branch)
    if not selected_base_branch or selected_base_branch == "" then
      selected_base_branch = "main"
    end
    next[selected_base_branch](commit_type, selected_base_branch)
  end)
end

local next = {
  Basic = select_commit_language,
  WIP = select_commit_language,
  Merge = select_base_branch,
  ["Squash Merge"] = select_base_branch,
}

M.execute = function()
  vim.ui.select({ "Basic", "WIP", "Merge", "Squash Merge" }, {
    prompt = "Select commit type> ",
  }, function(commit_type)
    if not commit_type or commit_type == "" then
      return
    end
    next[commit_type](commit_type)
  end)
end

return M
