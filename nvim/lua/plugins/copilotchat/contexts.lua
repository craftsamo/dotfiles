-- This file contains the contexts for CopilotChat
local M = {}

-- Import language settings from prompts
local prompts_module = require("plugins.copilotchat.prompts")
local languages = prompts_module.languages

-- AI characters (chat only)
local characters = { "Friendly", "Sociable", "Humorous", "Philosophical", "Cute", "Tsundere" }
local roles = { "Teacher", "Mentor", "Explainer", "Teammate", "Assistant" }

M.contexts = {
	file = {
		input = function(callback)
			local fzf = require("fzf-lua")
			local fzf_path = require("fzf-lua.path")
			fzf.files({
				complete = function(selected, opts)
					local file = fzf_path.entry_to_file(selected[1], opts, opts._uri)
					if file.path == "none" then
						return
					end
					-- Convert file paths to relative paths
					local current_dir = vim.fn.getcwd()
					local relative_path = file.path
					if vim.startswith(file.path, current_dir) then
						relative_path = file.path:sub(#current_dir + 2)
					end
					vim.defer_fn(function()
						callback(relative_path)
					end, 100)
				end,
			})
		end,
	},

	reply_language = {
		description = "Specifies the language in which AI responds.",
		input = function(callback)
			vim.ui.select(languages, {
				prompt = "Select language> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = (input or "en"):match("(%a+)$-"),
					filename = "Reply_Language",
					filetype = "text",
				},
			}
		end,
	},

	content_language = {
		description = "Specifies the language in which AI generates content.",
		input = function(callback)
			vim.ui.select(languages, {
				prompt = "Select language> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = (input or "en"):match("(%a+)$-"),
					filename = "Content_Language",
					filetype = "text",
				},
			}
		end,
	},

	-- Chat (<leader>acch) only
	character = {
		description = "Characters that AI behaves in conversation.",
		input = function(callback)
			vim.ui.select(characters, {
				prompt = "Select character> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = (input or "en"):match("(%a+)$-"),
					filename = "Character",
					filetype = "text",
				},
			}
		end,
	},

	role = {
		description = "Position and role of AI.",
		input = function(callback)
			vim.ui.select(roles, {
				prompt = "Select Role> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = (input or "en"):match("(%a+)$-"),
					filename = "Role",
					filetype = "text",
				},
			}
		end,
	},
}

-- Export characters and roles for use in other modules
M.characters = characters
M.roles = roles

return M
