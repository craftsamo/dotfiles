---@alias LanguageCode "en"|"ja"|"fr"|"de"|"es"|"it"|"pt"|"ru"|"zh"|"ko"
---@alias LanguageName "English"|"Japanese"|"French"|"German"|"Spanish"|"Italian"|"Portuguese"|"Russian"|"Chinese (Simplified)"|"Korean"

---@class SystemLanguages
---@field table table<LanguageCode, LanguageName>
---@field codes LanguageCode[]
---@field names LanguageName[]
local M = {}

---@return LanguageCode[]
local function get_system_languages()
	if vim.fn.has("mac") == 1 then
		local raw_list = vim.fn.system("defaults read -g AppleLanguages")
		local langs = {}
		for lang in raw_list:gmatch('"(.-)"') do
			table.insert(langs, lang)
		end
		return langs
	elseif vim.fn.has("unix") == 1 then
		local lang = os.getenv("LANG") or ""
		return { lang:match("^[^_.]+") or "en" }
	elseif vim.fn.has("win32") == 1 then
		local lang = os.getenv("LANG") or os.getenv("LANGUAGE") or ""
		return { lang:match("^[^_.]+") or "en" }
	else
		return { "en" }
	end
end

M.raw_lang = get_system_languages()

---@type table<LanguageCode, LanguageName>
M.table = {
	en = "English",
	ja = "Japanese",
	fr = "French",
	de = "German",
	es = "Spanish",
	it = "Italian",
	pt = "Portuguese",
	ru = "Russian",
	zh = "Chinese (Simplified)",
	ko = "Korean",
}

---@type LanguageCode[]
M.codes = vim.tbl_keys(M.table)

---@type LanguageName[]
M.names = vim.tbl_values(M.table)

local first_lang = M.raw_lang[1] or "en"
local lang_code = first_lang:match("^([%a]+)") or "en"

---@type LanguageName
M.default = M.table[lang_code] or M.table["en"]

return M
