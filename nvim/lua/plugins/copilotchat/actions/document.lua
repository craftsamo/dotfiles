---@alias DocumentAction "Comment"|"Code Document"|"API Document"|"Developer Document"

---@class DocumentOpts
---@field user_language LanguageName
---@field selected_files table|nil
---@field restored_selection RestoreSelection

local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompts = {
	["Comment"] = [[
Add concise and clear comments to the selected code.

**Important**:

- Consider not only the selected line but also related code and definitions from other files.
- Focus on clarity and brevity.
- Explain the intent and behavior, not just what the code does.
]],
	["Code Document"] = [[
Generate detailed documentation comments for the selected code, including its functionality, arguments, and return values.

**Important**:

- Follow the language's documentation style (e.g., TSDoc for TypeScript).
- Describe the function/class purpose, arguments, return values, and typical usage.
- Reference related code context if available.
]],
	["API Document"] = [[
Document the usage, arguments, return values, and important notes of the selected API in clear language.

**Important**:

- Include usage examples and describe input/output parameters.
- Document error cases and important constraints.
- Incorporate relevant context from related files or definitions.
]],
	["Developer Document"] = [[
Document the design intent, implementation details, and usage of the selected code in detail for developers.

**Important**:

- Explain the architectural context, design patterns, and key decisions.
- Include references to related modules, files, or components.
- Make the documentation suitable for README.md, pull requests, or new documentation files.
]],
}

--- Build the system prompt for the given document action and selection.
---@param action DocumentAction
---@param opts DocumentOpts
---@return string
local build_system_prompt = function(action, opts)
	return system_prompt.build({
		role = "documenter",
		character = "ai",
		guideline = { change_code = true, localization = true },
		specialties = opts.restored_selection and { opts.restored_selection.filetype, "markdown" } or { "markdown" },
		question_focus = "selection",
	})
end

--- Build sticky context for the given user language and selected files.
---@param action DocumentAction
---@param opts DocumentOpts
---@return table
local build_sticky = function(action, opts)
	return sticky.build({
		reply_language = system_languages.default,
		content_language = opts.user_language,
		file = sticky.build_file_contexts(opts.selected_files),
	})
end

--- Open the CopilotChat window for the given document action and options.
---@param action DocumentAction
---@param opts DocumentOpts
local open_window = function(action, opts)
	local prompt = prompts[action]
	if not prompt then
		return
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Doc" })
		return response
	end

	local callback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(action, opts),
		sticky = build_sticky(action, opts),
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Restore selection and open window for the given document action and options.
---@param action DocumentAction
---@param opts DocumentOpts
local on_selected_files = function(action, opts)
	selection.restore(function(restored_selection)
		open_window(action, vim.tbl_extend("force", opts or {}, { restored_selection = restored_selection }))
	end)
end

--- Prompt user to select files and handle selection for the given document action and user language.
---@param action DocumentAction
local select_files = function(action, opts)
	local callback = function(selected_files)
		on_selected_files(action, vim.tbl_extend("force", opts or {}, { selected_files = selected_files }))
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Prompt user to select a language and proceed to file selection for the given document action.
---@param action DocumentAction
local select_user_language = function(action)
	local ui_opts = { prompt = "Select language> " }
	vim.ui.select(system_languages.names, ui_opts, function(user_language)
		if not user_language or user_language == "" then
			user_language = system_languages.default
		end
		select_files(action, { user_language = user_language })
	end)
end

local next = {
	["Comment"] = select_user_language,
	["Code Document"] = select_user_language,
	["API Document"] = select_user_language,
	["Developer Document"] = select_user_language,
}

M.execute = function()
	local actions = { "Comment", "Code Document", "API Document", "Developer Document" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(actions, ui_opts, function(action)
		if not action or action == "" then
			return
		end
		next[action](action)
	end)
end

return M
