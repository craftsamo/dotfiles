local M = {}

local system_prompt = require("plugins.copilotchat.utils.system_prompt")

---@type table<Role, Guideline>
local guideline = {
	assistant = { change_code = true, localization = true, software_principles = true, message_markup = true },
	teacher = { localization = true, message_markup = true },
	reviewer = { localization = true, software_principles = true, message_markup = true },
	debugger = { change_code = true, localization = true, message_markup = true },
	documenter = { change_code = true, localization = true, message_markup = true },
	analyst = { change_code = true, localization = true, software_principles = true, message_markup = true },
}

---@type table<Role, QuestionFocus|nil>
local question_focus = {
	assistant = "selection",
	teacher = nil,
	reviewer = "selection",
	debugger = "selection",
	documenter = "selection",
	analyst = "selection",
}

---@type table<Role, Format|nil>
local format = {
	assistant = nil,
	teacher = nil,
	reviewer = nil,
	debugger = nil,
	documenter = nil,
	analyst = nil,
}

---@type table<Role, Specialty[]>
local removal_specialties = {
	assistant = { "angular", "rust", "gitcommit", "documentation" },
	teacher = { "angular", "rust", "gitcommit", "documentation" },
	reviewer = { "angular", "rust", "gitcommit", "documentation" },
	debugger = { "angular", "rust", "gitcommit", "documentation" },
	documenter = { "angular", "rust", "gitcommit", "documentation" },
	analyst = { "angular", "rust", "gitcommit", "documentation" },
}

M.prompts = {}

--- Creates a shallow copy of the given specialties table.
-- This function iterates over the input table and copies each element to a new table.
-- Useful for avoiding mutation of the original specialties list.
--- @param specialties table<Specialty[]>: The list of specialties to copy.
--- @return table<Specialty[]>: A new table containing the same elements as the input.
local function copy_specialties(specialties)
	local copied = {}
	for i, v in ipairs(specialties) do
		copied[i] = v
	end
	return copied
end

--- Removes specified specialties from a given specialties list.
-- This function filters out any specialties present in the 'to_remove' list from the input 'specialties' table.
-- If 'to_remove' is nil, the original specialties list is returned unchanged.
--- @param specialties table<Specialty>: The list of specialties to filter.
--- @param to_remove table<Specialty[]>: The list of specialties to remove from the input list.
--- @return table<Specialty>: A new table containing only the specialties not present in 'to_remove'.
local function remove_specialties(specialties, to_remove)
	if not to_remove then
		return specialties
	end
	local filtered = {}
	for _, v in ipairs(specialties) do
		local should_remove = false
		for _, rem in ipairs(to_remove) do
			if v == rem then
				should_remove = true
				break
			end
		end
		if not should_remove then
			table.insert(filtered, v)
		end
	end
	return filtered
end

for _, role in ipairs(system_prompt.roles) do
	for _, character in ipairs(system_prompt.characters) do
		local base_specialties = copy_specialties(system_prompt.specialties)
		local filtered_specialties = remove_specialties(base_specialties, removal_specialties[role])
		table.insert(filtered_specialties, "")

		for _, specialty in ipairs(filtered_specialties) do
			local key = system_prompt.to_sticky(role, character, specialty)
			M.prompts[key] = {
				system_prompt = system_prompt.build({
					role = role,
					character = character,
					guideline = guideline[role],
					question_focus = question_focus[role],
					specialties = specialty,
					format = format[role],
				}),
			}
		end
	end
end

return M
