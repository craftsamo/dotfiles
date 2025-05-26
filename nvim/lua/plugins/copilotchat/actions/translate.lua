---@alias TranslateTarget "Text"|"Code"

---@class TranslateOpts
---@field programming_language string|nil
---@field user_language LanguageName|nil
---@field restored_selection RestoreSelection
---@field selected_files table|nil

local fzf_lua = require("fzf-lua")
local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local programming_languages = {
	"typescript",
	"javascript",
	"python",
	"java",
	"c",
	"go",
	"kotlin",
	"rust",
	"css",
	"zsh",
}

local M = {}

local prompts = {
	Text = [[
Please localize the natural language content in the selected range to `%s`, paying attention to the following:

**Important**:

- Do not reflect any incorrect context, spelling mistakes, or typographical errors from the original language
- Do not change the original meaning of the content
- Use native expressions appropriate for the target locale (`%s`)
]],

	Code = [[
Please fully reproduce the selected functionality in "%s", paying attention to the following:

**Important**:

- Do not change the structure of arguments or return values
- Do not change variable names or function names
- Ensure the behavior is exactly the same
- Fully reproduce all comments and documentation
- Fully reproduce any dependent features or dependencies (if a library is incompatible, suggest an alternative)
- If you are unable to fully reproduce the functionality, explain the reason and suggest an alternative to complete this task.
]],
}

--- Build sticky context for the given target, language, and selected files.
--- @param target TranslateTarget
--- @param opts TranslateOpts
--- @return table
local build_sticky = function(target, opts)
	local file = nil

	if target == "Code" then
		file = sticky.build_file_contexts(opts.selected_files)
	end

	return sticky.build({
		file = file,
		reply_language = system_languages.default,
	})
end

--- Build the system prompt for the given target, language, and selection.
--- @param target TranslateTarget
--- @param opts TranslateOpts
--- @return string
local build_system_prompt = function(target, opts)
	local role = { Text = "documenter", Code = "assistant" }
	local guideline = {
		Text = { change_code = true, localization = true },
		Code = { change_code = true, localization = true, software_principles = true },
	}
	local specialties = {
		Text = nil,
		Code = opts.restored_selection and { opts.restored_selection.filetype, opts.programming_language }
			or { opts.programming_language },
	}

	return system_prompt.build({
		role = role[target],
		character = "ai",
		guideline = guideline[target],
		specialties = specialties[target],
		question_focus = "selection",
	})
end

--- Open the CopilotChat window for the given options.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local open_window = function(target, opts)
	local lang = target == "Text" and opts.user_language or opts.programming_language
	local prompt = vim.trim(prompts[target]:format(lang, lang))
	local stickies = build_sticky(target, opts)
	local system_instruction = build_system_prompt(target, opts)

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Translate" })
		return response
	end

	local callback_selection = function(source)
		if target == "Text" or target == "Code" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	window.open_float(prompt, {
		system_prompt = system_instruction,
		sticky = stickies,
		selection = callback_selection,
		callback = save_chat,
	})
end

--- @param target TranslateTarget
--- @param opts TranslateOpts
local function selection_restore(target, opts)
	selection.restore(function(restored_selection)
		opts = vim.tbl_extend("force", opts, { target = target, restored_selection = restored_selection })
		open_window(target, opts)
	end)
end

--- Restore selection and open window for the given options.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local function on_selected_files(target, opts)
	selection_restore(target, opts)
end

--- Prompt user to select files and handle selection for the given target and language.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local select_files = function(target, opts)
	local callback = function(selected_files)
		on_selected_files(target, vim.tbl_extend("force", opts, { selected_files = selected_files }))
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Prompt user to select a programming language and proceed to file selection.
--- @param target TranslateTarget
local select_programming_language = function(target)
	local ui_opts = { prompt = "Select language> " }
	vim.ui.select(programming_languages, ui_opts, function(specialty)
		if not specialty or specialty == "" then
			specialty = nil
		end
		local opts = vim.tbl_extend("force", {}, { programming_language = specialty })
		select_files(target, opts)
	end)
end

--- Prompt user to select a user language and restore selection for the given target.
--- @param target TranslateTarget
local function select_user_language(target)
	local ui_opts = { prompt = "Select Language> " }
	vim.ui.select(system_languages.names, ui_opts, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = system_languages.default
		end
		selection.restore(function(restored_selection)
			local opts = vim.tbl_extend("force", {}, {
				user_language = selected_language,
				restored_selection = restored_selection,
			})
			open_window(target, opts)
		end)
	end)
end

local next = {
	Text = select_user_language,
	Code = select_programming_language,
}

M.execute = function()
	local targets = { "Text", "Code" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		next[target](target)
	end)
end

return M
