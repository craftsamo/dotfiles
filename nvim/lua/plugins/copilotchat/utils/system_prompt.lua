---@alias Role
---| "assistant"
---| "teacher"
---| "reviewer"
---| "debugger"
---| "documenter"
---| "analyst"
---| "refactor"

---@alias Character
---| "ai"
---| "friendly"
---| "cute"
---| "tsundere"

---@alias Specialty string|FiletypeConfigPrompt

---@class Guideline
---@field change_code boolean|nil
---@field localization boolean|nil
---@field software_principles boolean|nil
---@field message_markup boolean|nil

---@alias QuestionFocus "selection"

---@alias Format "review"|"basic_commit"|"merge_commit"|"squash_commit"|"pull_request"|"analyze"|"refactoring"

---@class BuildOptions
---@field role Role|nil
---@field character Character|nil
---@field specialties Specialty|false|table<Specialty>|nil
---@field guideline Guideline|nil
---@field question_focus QuestionFocus|nil
---@field format Format|nil

local filetype = require("plugins.copilotchat.utils.filetype")

local M = {}

-- Cache storage
local file_cache = {} -- Cache for file contents
local build_cache = {} -- Cache for build results
local cache_enabled = true -- Flag to enable/disable cache

-- Cache for checking the last modification time of files
local file_mtime_cache = {}

-- Function to enable/disable cache
M.enable_cache = function(enabled)
	cache_enabled = enabled
	if not enabled then
		M.clear_cache()
	end
end

-- Function to clear the cache
M.clear_cache = function()
	file_cache = {}
	build_cache = {}
	file_mtime_cache = {}
end

-- Get the last modification time of a file
local function get_file_mtime(file_path)
	local stat = vim.loop.fs_stat(file_path)
	return stat and stat.mtime.sec or 0
end

-- Check if the file has been updated
local function is_file_updated(file_path)
	if not cache_enabled then
		return true
	end

	local current_mtime = get_file_mtime(file_path)
	local cached_mtime = file_mtime_cache[file_path] or 0

	if current_mtime > cached_mtime then
		file_mtime_cache[file_path] = current_mtime
		return true
	end

	return false
end

local function load_prompt_no_cache(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return ""
	end
	local content = file:read("*a")
	file:close()
	return content
end

-- File loading function with cache
local function load_prompt_cached(file_path)
	if not cache_enabled then
		return load_prompt_no_cache(file_path)
	end

	if is_file_updated(file_path) then
		file_cache[file_path] = nil
	end

	if file_cache[file_path] ~= nil then
		return file_cache[file_path]
	end

	local content = load_prompt_no_cache(file_path)
	file_cache[file_path] = content

	return content
end

-- Generate cache key from BuildOptions
local function generate_cache_key(opts)
	local key_parts = {}

	table.insert(key_parts, "role:" .. (opts.role or "assistant"))
	table.insert(key_parts, "character:" .. (opts.character or "ai"))

	if opts.specialties then
		if type(opts.specialties) == "table" then
			local specialties_sorted = {}
			for _, specialty in ipairs(opts.specialties) do
				table.insert(specialties_sorted, specialty)
			end
			table.sort(specialties_sorted)
			table.insert(key_parts, "specialties:" .. table.concat(specialties_sorted, ","))
		else
			table.insert(key_parts, "specialties:" .. tostring(opts.specialties))
		end
	end

	if opts.guideline then
		local guideline_parts = {}
		if opts.guideline.change_code then
			table.insert(guideline_parts, "change_code")
		end
		if opts.guideline.localization then
			table.insert(guideline_parts, "localization")
		end
		if opts.guideline.software_principles then
			table.insert(guideline_parts, "software_principles")
		end
		if #guideline_parts > 0 then
			table.insert(key_parts, "guideline:" .. table.concat(guideline_parts, ","))
		end
	end

	if opts.question_focus then
		table.insert(key_parts, "question_focus:" .. opts.question_focus)
	end

	if opts.format then
		table.insert(key_parts, "format:" .. opts.format)
	end

	return table.concat(key_parts, "|")
end

-- Check the last modification time of the files used
local function check_build_cache_validity(opts, cache_key)
	if not cache_enabled then
		return false
	end

	local config_path = vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/"
	local files_to_check = {}

	local role = opts.role or "assistant"
	table.insert(files_to_check, config_path .. "roles/" .. role .. ".md")

	local character = opts.character or "ai"
	table.insert(files_to_check, config_path .. "characters/" .. character .. ".md")

	table.insert(files_to_check, config_path .. "guidelines/base.md")

	if opts.guideline then
		if opts.guideline.change_code then
			table.insert(files_to_check, config_path .. "guidelines/change_code.md")
		end
		if opts.guideline.localization then
			table.insert(files_to_check, config_path .. "guidelines/localization.md")
		end
		if opts.guideline.software_principles then
			table.insert(files_to_check, config_path .. "guidelines/software_principles.md")
		end
		if opts.guideline.message_markup then
			table.insert(files_to_check, config_path .. "guidelines/message_markup.md")
		end
	end

	if opts.question_focus then
		table.insert(files_to_check, config_path .. "question_focus/" .. opts.question_focus .. ".md")
	end

	table.insert(files_to_check, config_path .. "specialties/base.md")

	local specialties = filetype.add_related(opts.specialties)
	if specialties and #specialties > 0 then
		for _, specialty in ipairs(specialties) do
			table.insert(files_to_check, config_path .. "specialties/" .. specialty .. ".md")
		end
	end

	if opts.format then
		table.insert(files_to_check, config_path .. "formats/base.md")
		table.insert(files_to_check, config_path .. "formats/" .. opts.format .. ".md")
	end

	-- If any file has been updated, invalidate the cache
	for _, file_path in ipairs(files_to_check) do
		if is_file_updated(file_path) then
			build_cache[cache_key] = nil
			return false
		end
	end

	return build_cache[cache_key] ~= nil
end

---@type Role[]
M.roles = {
	"assistant",
	"teacher",
	"reviewer",
	"documenter",
	"analyst",
}

---@type Character[]
M.characters = {
	"ai",
	"friendly",
	"cute",
	"tsundere",
}

---@return Specialty[]
M.specialties = (function()
	local specialties_set = {}
	for _, config in pairs(filetype.FILETYPE_CONFIGS) do
		if config.prompts then
			for _, prompt in ipairs(config.prompts) do
				specialties_set[prompt] = true
			end
		end
	end
	local specialties = {}
	for specialty, _ in pairs(specialties_set) do
		table.insert(specialties, specialty)
	end
	table.sort(specialties)
	return specialties
end)()

--- Converts the given role, character, and optional specialty into a "sticky" identifier string.
--- The function capitalizes each component and concatenates them in the order: character, specialty (if provided), and role.
---
--- This is typically used to generate a unique, human-readable identifier for a system prompt persona or configuration.
---
--- Example:
---   to_sticky("assistant", "ai", "python") --> "AIPythonAssistant"
--- @param role Role                -- The role of the entity (e.g., "assistant", "user").
--- @param character Character      -- The character or persona name (e.g., "ai").
--- @param specialty Specialty|nil  -- An optional specialty or sub-role (e.g., "python").
--- @return string                  -- The concatenated, capitalized identifier string, or nil if inputs are invalid.
M.to_sticky = function(role, character, specialty)
	---@param str string
	local function capitalize(str)
		return str == "ai" and "AI" or (str:gsub("^%l", string.upper))
	end

	local r = capitalize(role)
	local c = capitalize(character)
	if specialty and specialty ~= "" then
		local s = capitalize(specialty)
		return s .. c .. r
	else
		return c .. r
	end
end

---@param opts BuildOptions
---@return string
M.build = function(opts)
	-- Generate cache key
	local cache_key = generate_cache_key(opts)

	-- Check cache validity and return if valid
	if check_build_cache_validity(opts, cache_key) then
		return build_cache[cache_key]
	end

	-- Helper to build prompt path
	local config_path = vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/"
	local function prompt_path(subpath)
		return config_path .. subpath
	end

	local prompt_parts = {}

	-- Role
	local role = opts.role or "assistant"
	table.insert(prompt_parts, load_prompt_cached(prompt_path("roles/" .. role .. ".md")))

	-- Character
	local character = opts.character or "ai"
	table.insert(prompt_parts, load_prompt_cached(prompt_path("characters/" .. character .. ".md")))

	-- Guideline
	table.insert(prompt_parts, load_prompt_cached(prompt_path("guidelines/base.md")))
	if opts.guideline then
		if opts.guideline.change_code then
			table.insert(prompt_parts, load_prompt_cached(prompt_path("guidelines/change_code.md")))
		end
		if opts.guideline.localization then
			table.insert(prompt_parts, load_prompt_cached(prompt_path("guidelines/localization.md")))
		end
		if opts.guideline.software_principles then
			table.insert(prompt_parts, load_prompt_cached(prompt_path("guidelines/software_principles.md")))
		end
		if opts.guideline.message_markup then
			table.insert(prompt_parts, load_prompt_cached(prompt_path("guidelines/message_markup.md")))
		end
	end

	-- Question Focus
	if opts.question_focus then
		table.insert(prompt_parts, load_prompt_cached(prompt_path("question_focus/" .. opts.question_focus .. ".md")))
	end

	-- Specialties
	table.insert(prompt_parts, load_prompt_cached(prompt_path("specialties/base.md")))
	local specialties = filetype.add_related(opts.specialties)
	if specialties and #specialties > 0 then
		local failed_languages = {}
		for _, specialty in ipairs(specialties) do
			local specialty_prompt = load_prompt_cached(prompt_path("specialties/" .. specialty .. ".md"))
			if specialty_prompt ~= "" then
				table.insert(prompt_parts, specialty_prompt)
			else
				table.insert(failed_languages, specialty)
			end
		end

		if #failed_languages > 0 then
			vim.notify("Failed to load specialty: " .. table.concat(failed_languages, ", "), vim.log.levels.WARN)
		end
	end

	-- Format
	if opts.format then
		table.insert(prompt_parts, load_prompt_cached(prompt_path("formats/" .. "base.md")))
		table.insert(
			prompt_parts,
			string.format("```markdown\n%s```", load_prompt_cached(prompt_path("formats/" .. opts.format .. ".md")))
		)
	end

	local result = table.concat(prompt_parts, "\n")

	-- Save the result to cache
	if cache_enabled then
		build_cache[cache_key] = result
	end

	return result
end

-- For debugging: get cache statistics
M.get_cache_stats = function()
	return {
		file_cache_size = vim.tbl_count(file_cache),
		build_cache_size = vim.tbl_count(build_cache),
		cache_enabled = cache_enabled,
	}
end

return M
