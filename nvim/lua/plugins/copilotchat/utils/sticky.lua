---@alias Register
---| 'system_clipboard'                -- synchronized with the system clipboard
---| 'selection_clipboard'             -- synchronized with the selection clipboard
---| 'unnamed'                         -- last deleted, changed, or yanked content
---| 'last_yank'                       -- last yank
---| 'small_delete'                    -- deleted or changed content smaller than one line
---| 'last_inserted'                   -- last inserted text
---| 'current_file'                    -- name of the current file
---| 'last_command'                    -- most recent executed command
---| 'alternate_buffer'                -- alternate buffer
---| 'expression'                      -- result of an expression
---| 'last_search'                     -- last search pattern

---@class Fields
---@field system_prompt string|nil
---@field buffer nil|number
---@field buffers nil|("listed"|"visible")
---@field file nil|(string|table<string>)
---@field files nil|string
---@field filenames nil|string
---@field git nil|((string|table<string>)|("staged"|"unstaged"))
---@field url nil|(string|table<string>)
---@field register nil|(Register|table<Register>)
---@field quickfix nil|boolean
---@field system nil|(string|table<string>)
---@field reply_language nil|string
---@field content_language nil|string

local M = {}

--- Map of register names to symbols.
---@type table<Register, string>
M.RegisterSymbolMap = {
	["system_clipboard"] = "+",
	["selection_clipboard"] = "*",
	["unnamed"] = '"',
	["last_yank"] = "0",
	["small_delete"] = "-",
	["last_inserted"] = ".",
	["current_file"] = "%",
	["last_command"] = ":",
	["alternate_buffer"] = "#",
	["expression"] = "=",
	["last_search"] = "/",
}

--- Normalize selected files to a table of strings.
---@param selected_files string|table<string>|nil
---@return table<string>
local function normalize_selected_files(selected_files)
	if type(selected_files) == "string" then
		return { selected_files }
	end
	return selected_files or {}
end

--- Build file contexts from selected files.
---@param selected_files string|table<string>|nil
---@return table<string>
function M.build_file_contexts(selected_files)
	selected_files = normalize_selected_files(selected_files)
	local file_contexts = {}
	local seen = {}
	for _, f in ipairs(selected_files) do
		local clean = f:gsub("^%s*", ""):gsub("^[^%w%./\\-_]+ *", "")
		if not seen[clean] then
			table.insert(file_contexts, clean)
			seen[clean] = true
		end
	end
	return file_contexts
end

--- Add a field to the sticky context.
---@param sticky table
---@param fields Fields
---@param field string
---@param prefix string
local function add_field(sticky, fields, field, prefix)
	local value = fields[field]
	if not value then
		return
	end
	if type(value) == "table" then
		local seen = {}
		for _, v in ipairs(value) do
			local key = tostring(v)
			if not seen[key] then
				table.insert(sticky, prefix .. key)
				seen[key] = true
			end
		end
	else
		table.insert(sticky, prefix .. tostring(value))
	end
end

--- Add register(s) to the sticky context.
---@param sticky table
---@param reg Register|table<Register>|nil
local function add_register(sticky, reg)
	if not reg then
		return
	end

	---@param val Register|table<Register>
	---@param seen table<string, boolean>
	local function add_register_inner(val, seen)
		local symbol = M.RegisterSymbolMap[val] or val
		local key = tostring(symbol)
		if not seen[key] then
			table.insert(sticky, "#register:" .. key)
			seen[key] = true
		end
	end
	if type(reg) == "table" then
		local seen = {}
		for _, v in ipairs(reg) do
			add_register_inner(v, seen)
		end
	else
		add_register_inner(reg, {})
	end
end

--- Add system command(s) to the sticky context.
---@param sticky table
---@param sys string|table<string>|nil
local function add_system(sticky, sys)
	if not sys then
		return
	end

	---@param val string|table<string>
	---@param seen table<string, boolean>
	local function add_system_inner(val, seen)
		local key = tostring(val)
		if not seen[key] then
			table.insert(sticky, "#system:`" .. key .. "`")
			seen[key] = true
		end
	end
	if type(sys) == "table" then
		local seen = {}
		for _, v in ipairs(sys) do
			add_system_inner(v, seen)
		end
	else
		add_system_inner(sys, {})
	end
end

--- Build the sticky context array from fields.
---@param fields Fields
---@return table
function M.build(fields)
	local sticky = {}

	add_field(sticky, fields, "system_prompt", "/")
	add_field(sticky, fields, "buffer", "#buffer:")
	add_field(sticky, fields, "buffers", "#buffers:")
	add_field(sticky, fields, "file", "#file:")
	add_field(sticky, fields, "files", "#files:")
	add_field(sticky, fields, "filenames", "#filenames:")
	add_field(sticky, fields, "git", "#git:")
	add_field(sticky, fields, "url", "#url:")

	add_register(sticky, fields["register"])
	add_system(sticky, fields["system"])

	add_field(sticky, fields, "reply_language", "#reply_language:")
	add_field(sticky, fields, "content_language", "#content_language:")

	return sticky
end

return M
