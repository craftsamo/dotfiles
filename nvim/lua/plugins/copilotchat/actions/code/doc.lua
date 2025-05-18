local prompts_module = require("plugins.copilotchat.prompts")
local languages = prompts_module.languages
local language = prompts_module.language

local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

local function doc_code()
	vim.ui.select(languages, {
		prompt = "Select content language> ",
	}, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = language
		end

		local sticky = {
			"/SystemPromptCodeDoc",
			"#content_language:" .. selected_language,
		}

		require("fzf-lua").files({
			prompt = "Files> ",
			actions = {
				["default"] = function(selected_files)
					selected_files = selected_files or {}
					local file_tags = vim.tbl_map(function(f)
						local clean = f:gsub("^%s*", ""):gsub("^[^%w%./\\-_]+ *", "")
						return "#file:" .. clean
					end, selected_files)
					vim.list_extend(sticky, file_tags)

					new_vertical_window('Generate documentation comments for the "selected content".', {
						sticky = sticky,
					})
				end,
			},
			multi = true,
		})
	end)
end

return doc_code
