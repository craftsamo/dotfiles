---@alias FiletypeConfigPrompt "angular"|"javascript"|"typescript"|"ansible"|"css"|"docker"|"python"|"neovim"|"rust"|"react"|"zsh"|"lua"|"gitcommit"|"documentation"|"analysis"|"refactoring"

---@class FiletypeConfig
---@field patterns string[]|nil
---@field filetypes string[]|nil
---@field prompts (string|FiletypeConfigPrompt)[]
---@field contexts string[]|nil

local M = {}

---@type table<string, FiletypeConfig>
M.FILETYPE_CONFIGS = {
	angular = {
		patterns = {
			"%.component%.ts$",
			"%.component%.html$",
			"%.module%.ts$",
		},
		filetypes = { "htmlangular" },
		prompts = { "angular", "javascript", "typescript" },
	},
	ansible = {
		filetypes = { "yaml" },
		prompts = { "ansible" },
	},
	css = {
		filetypes = { "css", "scss", "less" },
		prompts = { "css" },
		patterns = {
			"%.css$",
			"%.scss$",
			"%.module%.css$",
		},
	},
	dockerfile = {
		filetypes = { "dockerfile" },
		prompts = { "docker" },
	},
	javascript = {
		filetypes = { "javascript" },
		prompts = { "javascript" },
	},
	python = {
		filetypes = { "python" },
		prompts = { "python" },
	},
	typescript = {
		filetypes = { "typescript" },
		prompts = { "javascript", "typescript" },
	},
	neovim = {
		filetypes = { "vim", "lua" },
		prompts = { "neovim", "lua" },
		contexts = { "url:https://github.com/ruicsh/nvim-config" },
	},
	rust = {
		filetypes = { "rust" },
		prompts = { "rust" },
	},
	react = {
		filetypes = { "typescriptreact" },
		prompts = { "react", "javascript", "typescript" },
	},
	zsh = {
		filetypes = { "zsh" },
		prompts = { "zsh" },
	},
	gitcommit = {
		filetypes = { "gitcommit" },
		prompts = { "gitcommit" },
	},
	markdown = {
		filetypes = { "markdown" },
		prompts = { "documentation" },
	},
	text = {
		filetypes = { "text" },
		prompts = { "documentation" },
	},
	analysis = {
		filetypes = { "analysis" },
		prompts = { "analysis", "css", "typescript", "javascript", "react", "python", "neovim", "lua", "zsh" },
	},
	refactoring = {
		filetypes = { "refactoring" },
		prompts = { "analysis", "css", "typescript", "javascript", "react", "python", "neovim", "lua", "zsh" },
	},
}

-- Precompute filetype to config mapping for fast lookup
---@type table<string, FiletypeConfig>
local filetype_to_config = {}
for _, config in pairs(M.FILETYPE_CONFIGS) do
	if config.filetypes then
		for _, ft in ipairs(config.filetypes) do
			filetype_to_config[ft] = config
		end
	end
end

---@param filetype string|string[]|nil|false
---@return FiletypeConfigPrompt[]|nil
M.add_related = function(filetype)
	if filetype == false then
		return nil
	end

	if filetype == nil then
		filetype = vim.bo.filetype
	end

	local filename = vim.fn.expand("%:t")

	local filetypes = {}
	if type(filetype) == "table" then
		filetypes = filetype
	else
		filetypes = { filetype }
	end

	local prompts = {}
	for _, ft in ipairs(filetypes) do
		if filetype_to_config[ft] then
			for _, prompt in ipairs(filetype_to_config[ft].prompts or {}) do
				table.insert(prompts, prompt)
			end
		end
	end
	if #prompts > 0 then
		local hash = {}
		local unique_prompts = {}
		for _, v in ipairs(prompts) do
			if not hash[v] then
				table.insert(unique_prompts, v)
				hash[v] = true
			end
		end
		return unique_prompts
	end

	for _, config in pairs(M.FILETYPE_CONFIGS) do
		if config.patterns then
			for _, pattern in ipairs(config.patterns) do
				if filename:match(pattern) then
					return config.prompts
				end
			end
		end
	end

	return nil
end

return M
