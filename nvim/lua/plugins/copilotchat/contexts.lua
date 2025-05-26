local system_languages = require("plugins.copilotchat.utils.system_languages")

local M = {}

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
			vim.ui.select(system_languages.names, {
				prompt = "Select language> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = input or system_languages.default,
					filename = "Reply_Language",
					filetype = "text",
				},
			}
		end,
	},

	content_language = {
		description = "Specifies the language in which AI generates content.",
		input = function(callback)
			vim.ui.select(system_languages.names, {
				prompt = "Select language> ",
			}, callback)
		end,
		resolve = function(input)
			return {
				{
					content = input or system_languages.default,
					filename = "Content_Language",
					filetype = "text",
				},
			}
		end,
	},
}

return M
