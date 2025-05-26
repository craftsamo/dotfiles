---@alias ExplainTarget "Code"|"File"

---@class ExplainOpts
---@field selected_files table|nil
---@field restored_selection RestoreSelection

local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local sticky = require("plugins.copilotchat.utils.sticky")
local window = require("plugins.copilotchat.utils.window")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompts = {
	Code = [[
Please explain the selected code based on the following points:

- **Purpose and Role**: What is this code intended to accomplish?
- **Process Flow**: Step-by-step execution order and explanation of each stage
- **Dependencies**: Description of external functions, libraries, or modules used
- **Data Flow**: How data is transformed from input to output
- **Key Implementation Details**: Algorithms, design patterns, or special processing used
- **Error Handling**: How exceptions and edge cases are managed

**Important**

- Make use of information from the provided context files
- Maintain technical accuracy and base explanations on facts, not assumptions
- Add appropriate explanations for technical terms so that beginners can understand
- Do not mention code quality or possible improvements (focus only on explanation)
]],

	File = [[
Please explain the entire selected file based on the following points:

- **Purpose and Responsibility**: The role this file plays in the overall system
- **Architectural Position**: Its place in the layer structure or design pattern
- **Main Components**: Overview of included classes, functions, or interfaces
- **External Dependencies**: Imported modules or libraries and their purposes
- **Public API**: Main functions or classes used by other files
- **Internal Implementation**: Helper functions or internal logic used only within this file
- **Data Structures**: Defined types, interfaces, or schemas
- **Settings and Constants**: Explanation of important configuration values or constants

**Important**

- Make use of information from the provided context files
- Explain the overall structure of the file from a high-level perspective
- Focus on relationships and the big picture rather than detailed implementation of each component
- The goal is to help new developers quickly understand the file's role
- Include information useful for code review and maintenance
]],
}

--- Build sticky context for the given target and selected files.
---@param target ExplainTarget
---@param opts ExplainOpts
---@return table
local build_sticky = function(target, opts)
	local file = nil
	if target == "Code" or target == "File" then
		file = sticky.build_file_contexts(opts and opts.selected_files or nil)
	end
	return sticky.build({
		reply_language = system_languages.default,
		file = file,
	})
end

--- Build the system prompt for the given target and selection.
---@param target ExplainTarget
---@param opts ExplainOpts
---@return string
local build_system_prompt = function(target, opts)
	local question_focus = nil
	if target == "Code" or target == "File" then
		question_focus = "selection"
	end
	return system_prompt.build({
		role = "teacher",
		character = "ai",
		guideline = { localization = true, message_markup = true },
		specialties = opts and opts.restored_selection and opts.restored_selection.filetype or nil,
		question_focus = question_focus,
	})
end

--- Open the CopilotChat window for the given target and options.
---@param target ExplainTarget
---@param opts ExplainOpts
local open_window = function(target, opts)
	local prompt = prompts[target]
	local stickies = build_sticky(target, opts)
	local system_instruction = build_system_prompt(target, opts)

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Explain" })
		return response
	end

	local callback_selection = function(source)
		if target == "Code" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		if target == "File" then
			return chat_select.buffer(source)
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

--- Restore selection and open window for the given target and options.
---@param target ExplainTarget
---@param opts ExplainOpts
local on_selected_files = function(target, opts)
	selection.restore(function(restored_selection)
		open_window(target, vim.tbl_extend("force", opts or {}, { restored_selection = restored_selection }))
	end)
end

--- Prompt user to select files and handle selection for the given target.
---@param target ExplainTarget
local select_files = function(target)
	local callback = function(selected_files)
		on_selected_files(target, { selected_files = selected_files })
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

local next = {
	Code = select_files,
	File = select_files,
}

M.execute = function()
	local targets = { "Code", "File" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		next[target](target)
	end)
end

return M
