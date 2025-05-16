local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function explain_code()
	local sticky = {
		"/SystemPromptExplain",
		"#reply_language:" .. language,
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

				new_float_window("Write an explanation for the selected code as paragraphs of text.", {
					sticky = sticky,
				})
			end,
		},
		multi = true,
	})
end

return explain_code
