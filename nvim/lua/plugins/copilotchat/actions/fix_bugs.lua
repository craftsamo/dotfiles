local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

local function fix_bugs()
	local user_memo = vim.fn.input("Memo: ")
	if not user_memo or user_memo == "" then
		user_memo = ""
	end

	local sticky = {
		"/SystemPromptFixBugs",
		"#reply_language:" .. language,
		"#register:0",
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

				local prompt = "Fix the bug based on the given stack trace. \n\n" .. "**user_memo**:\n\n" .. user_memo
				new_vertical_window(prompt, {
					sticky = sticky,
				})
			end,
		},
		multi = true,
	})
end

return fix_bugs
