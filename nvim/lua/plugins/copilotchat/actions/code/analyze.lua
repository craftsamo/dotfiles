local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function analyze_code()
	local sticky = {
		"/SystemPromptAnalyzeCode",
		"#reply_language:" .. language,
		"#content_language:" .. language,
	}

	vim.ui.select({ "Track variable" }, {
		prompt = "Select analyze type> ",
	}, function(action)
		if not action or action == "" then
			return
		end

		require("fzf-lua").files({
			prompt = "Related Files> ",
			actions = {
				["default"] = function(selected_files)
					selected_files = selected_files or {}
					local file_tags = vim.tbl_map(function(f)
						local clean = f:gsub("^%s*", ""):gsub("^[^%w%./\\-_]+ *", "")
						return "#file:" .. clean
					end, selected_files)
					vim.list_extend(sticky, file_tags)

					local prompt = ""
					if action == "Track variable" then
						prompt = "Please analyze the provided file to Selected **" .. action .. "** and reveal details."
					end

					new_float_window(prompt, {
						sticky = sticky,
					})
				end,
			},
			multi = true,
		})
	end)
end

return analyze_code
