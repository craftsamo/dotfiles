---@alias ChatRole Role
---@alias ChatCharacter Character
---@alias ChatSpecialty Specialty

---@class ChatOpenOpts
---@field role ChatRole|nil
---@field character ChatCharacter|nil
---@field specialty ChatSpecialty|nil
---@field style "float"|"vertical"|nil

local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

--- Generate a system prompt string based on role, character, and specialty.
---@param role ChatRole
---@param character ChatCharacter
---@param specialty ChatSpecialty|nil
---@param restored_selection RestoreSelection|nil
---@return string
local function generate_system_prompt(role, character, specialty, restored_selection)
	return system_prompt.to_sticky(role, character, specialty or restored_selection and restored_selection.filetype)
end

--- Fallback chat title generator.
---@param role ChatRole
---@param character ChatCharacter
---@param specialty ChatSpecialty|nil
---@return string
local function fallback_chat_title(role, character, specialty)
	-- Capitalize helper (same as in generate_system_prompt)
	local function capitalize(str)
		return (str and str ~= "") and (str:gsub("^%l", string.upper)) or ""
	end

	-- Handle "ai" character/role context
	if character == "ai" or role == "assistant" then
		return "New chat with AI about " .. (specialty and capitalize(specialty) or "General")
	end

	-- Compose title with available context
	local parts = {}
	if character and character ~= "" then
		table.insert(parts, capitalize(character))
	end
	if role and role ~= "" then
		table.insert(parts, capitalize(role))
	end
	if specialty and specialty ~= "" then
		table.insert(parts, capitalize(specialty))
	end

	if #parts > 0 then
		return "New chat about " .. table.concat(parts, " ")
	else
		return "New chat"
	end
end

--- Open the chat window with the given options.
---@param role ChatRole
---@param character ChatCharacter
---@param specialty ChatSpecialty|nil
---@param style "float"|"vertical"|nil
---@param restored_selection RestoreSelection|nil
local function open_chat_window(role, character, specialty, style, restored_selection)
	local fallback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	local stickies = sticky.build({
		system_prompt = generate_system_prompt(role, character, specialty, restored_selection),
		reply_language = system_languages.default,
	})

	vim.ui.input({ prompt = "Prompt> " }, function(input)
		if not input or input == "" then
			input = ""
		end

		local callback = function(response)
			chat_history.save(response, {
				used_prompt = input or fallback_chat_title(role, character, specialty),
				tag = "Instruction",
			})
			return response
		end

		if style == "vertical" then
			window.open_vertical(input, {
				sticky = stickies,
				selection = fallback_selection,
				callback = callback,
			})
		else
			window.open_float(input, {
				sticky = stickies,
				selection = fallback_selection,
				callback = callback,
			})
		end
	end)
end

--- Prompt user to select window style and open chat window.
---@param role ChatRole
---@param character ChatCharacter
---@param specialty ChatSpecialty|nil
local function select_style(role, character, specialty)
	vim.ui.select({ "float", "vertical" }, {
		prompt = "Select window style> ",
	}, function(style)
		selection.restore(function(restored_selection)
			open_chat_window(role, character, specialty, style, restored_selection)
		end)
	end)
end

--- Handle specialty selection and proceed to style selection.
---@param role ChatRole
---@param character ChatCharacter
---@param specialty ChatSpecialty|nil
local function on_specialty_selected(role, character, specialty)
	if not specialty or specialty == "" then
		specialty = nil
	end
	select_style(role, character, specialty)
end

--- Prompt user to select specialty.
---@param role ChatRole
---@param character ChatCharacter
local function select_specialty(role, character)
	vim.ui.select(system_prompt.specialties, {
		prompt = "Select specialty> ",
	}, function(specialty)
		if not specialty or specialty == "" then
			specialty = nil
		end
		on_specialty_selected(role, character, specialty)
	end)
end

--- Handle character selection and proceed to specialty selection.
---@param role ChatRole
---@param character ChatCharacter
local function on_character_selected(role, character)
	select_specialty(role, character)
end

--- Prompt user to select character.
---@param role ChatRole
local function select_character(role)
	vim.ui.select(system_prompt.characters, {
		prompt = "Select character> ",
	}, function(character)
		if not character or character == "" then
			character = "ai"
		end
		on_character_selected(role, character)
	end)
end

--- Handle role selection and proceed to next step.
---@param role ChatRole
local function on_role_selected(role)
	select_character(role)
end

M.open = function()
	vim.ui.select(system_prompt.roles, {
		prompt = "Select role> ",
	}, function(role)
		if not role or role == "" then
			role = "assistant"
		end
		on_role_selected(role)
	end)
end

return M
