local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local function analize_code()
	local user_memo = vim.fn.input("Memo: ")
	if not user_memo or user_memo == "" then
		user_memo = ""
	end

	local sticky = {
		"/SystemPromptAnalizeCode",
		"#reply_language:" .. language,
		"#content_language:" .. language,
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

				local prompt = "Analyze selected codes to reveal the actual situation. \n\n"
					.. "**user_memo**:\n\n"
					.. user_memo
				require("CopilotChat").ask(prompt, {
					sticky = sticky,
				})
			end,
		},
		multi = true,
	})
end

return analize_code
