local fzf_lua = require("fzf-lua")
local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

---@alias RefactorTarget "Code"|"Fuction"|"Class"|"File"

---@class RefactorOpts
---@field restored_selection RestoreSelection|nil
---@field related_files table|nil

local M = {}

local common_prompt = [[
- Unify variable naming conventions and improve clarity of meaning.
- Decompose deep nesting to enhance readability.
- Replace magic numbers with constants.
- Consolidate duplicate code.
- Add appropriate comments or documentation (including type documentation).
]]

local common_important = [[
**Important**:

- Always apply software principles when identifying and addressing areas for improvement.
- `<issue_category>` describes the detected issue category (e.g., "Duplicate Codes", "Magic Numbers").
- `<issue_category.issue_description>` concisely explains the specific issue and always includes the relevant line number.
- Add a status icon before each item:
  - ✘ Critical issue
  - ⚠ Recommended improvement
  - ✔ Good status
]]

local prompts = {
	Code = "Refactor the selected code range based on the following guidelines:"
		.. "\n\n"
		.. common_prompt
		.. "\n"
		.. common_important,

	Function = "Refactor the selected function based on the following guidelines:" .. "\n\n" .. common_prompt .. [[
- Improve the function name to clearly reflect its purpose and behavior.
- Clearly specify argument types and return types.
- Limit the number of arguments appropriately and group them into objects if necessary.
- Use early returns to reduce nesting.
- Divide internal logic into coherent units.
]] .. "\n" .. common_important .. [[
- Ensure the refactored function behaves exactly the same as the original.
- Avoid significant negative impact on performance.
]],

	Class = "Refactor the selected class based on the following guidelines:" .. "\n\n" .. common_prompt .. [[
- Improve the class name to clearly reflect its responsibility and role.
- Split the class as needed according to the single responsibility principle.
- Set method and property visibility (public/private/protected) appropriately.
- Group related methods and arrange them in a logical order.
- Review inheritance relationships and apply appropriate abstraction.
- Consider using interfaces or abstract classes.
- Properly initialize properties.
- Remove unnecessary dependencies.
- Consider applying suitable design patterns.
]] .. "\n" .. common_important .. [[
- Maintain the original contract (behavioral guarantees) of the class.
]],

	Type = "Refactor the selected type definition based on the following guidelines:" .. "\n\n" .. common_prompt .. [[
- Improve the type name to clearly reflect its purpose and structure.
- Organize the structure logically and group related properties.
- Add appropriate type constraints (such as Optional, Union, Generic).
- Extract common types for reusability.
- Review type inheritance and create appropriate hierarchies.
- Remove unnecessary type definitions and eliminate duplication.
- Clarify the responsibility of each type and split as needed.
]] .. "\n" .. common_important .. [[
- Maintain compatibility with types used in existing code.
- Consider the impact of type changes on other code.
- Prioritize improving type safety.
]],

	File = "Refactor the entire selected file based on the following guidelines:" .. "\n\n" .. [[
- Review file names and directory structure for appropriate organization.
- Organize and optimize imports/exports.
- Arrange the file structure logically (e.g., type definitions, constants, functions, classes).
- Place related code close together and consider splitting files as needed.
- Limit file size appropriately and split if necessary.
- Remove unnecessary code and unused dependencies.
- Add appropriate file-level documentation.
- Organize namespaces and avoid naming conflicts.
- Apply a consistent coding style.
]] .. "\n\n" .. common_important .. [[
- If proposing file splits or merges, clearly state the reasons and impacts.
- Consider the impact on dependencies from other files.
- Maintain the module's public interface.
- Ensure consistency with the overall project structure.
]],
}

---@param target RefactorTarget
---@param opts RefactorOpts
local build_sticky = function(target, opts)
	return sticky.build({
		reply_language = system_languages.default,
		file = sticky.build_file_contexts(opts.related_files or nil) or nil,
	})
end

---@param target RefactorTarget
---@param opts RefactorOpts
local build_system_prompt = function(target, opts)
	return system_prompt.build({
		role = "refactor",
		character = "ai",
		guideline = { change_code = true, localization = true, software_principles = true, message_markup = true },
		specialties = opts.restored_selection and { opts.restored_selection.filetype, "refactoring" }
			or { "refactoring" },
		question_focus = "selection",
		format = "refactoring",
	})
end

local open_window = function(target, opts)
	local prompt = prompts[target]
	if not prompt or prompt == "" then
		return
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Refactor" })
		return response
	end
	local callback_selection = function(source)
		if target == "Code" or target == "Function" or target == "Class" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return chat_select.buffer(source)
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(target, opts),
		sticky = build_sticky(target, opts),
		selection = callback_selection,
		callback = save_chat,
	})
end

---@param target RefactorTarget
---@param opts RefactorOpts
local on_selected_files = function(target, opts)
	selection.restore(function(restored_selection)
		local opts_with_selection = vim.tbl_extend("force", opts or {}, { restored_selection = restored_selection })
		open_window(target, opts_with_selection)
	end)
end

---@param target RefactorTarget
local select_files = function(target)
	local callback = function(selected_files)
		on_selected_files(target, { related_files = selected_files })
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

local next = {
	Code = select_files,
	Function = select_files,
	Class = select_files,
	File = select_files,
}

M.execute = function()
	local refactor_targets = { "Code", "Function", "Class", "File" }
	local ui_opts = { prompt = "Select action> " }
	vim.ui.select(refactor_targets, ui_opts, function(type)
		if not type or type == "" then
			return
		end
		next[type](type)
	end)
end

return M
