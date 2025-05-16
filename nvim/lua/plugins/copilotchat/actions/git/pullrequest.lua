local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function pullrequest()
	vim.ui.select({ "main", "develop" }, { prompt = "Select base branch> " }, function(selected_branch)
		if not selected_branch or selected_branch == "" then
			return
		end

		vim.ui.select(languages, { prompt = "Select content language> " }, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = language
			end

			new_float_window("Create the contents of a 'Pull Request' based on the contents of the given Diff.", {
				sticky = {
					"/SystemPromptGenerate",
					"#content_language:" .. selected_language,
					"#system:`git diff " .. selected_branch .. "`",
					"#file:.github/PULL_REQUEST_TEMPLATE.md",
					"#file:.github/pull_request_template.md",
				},
				selection = false,
			})
		end)
	end)
end

return pullrequest
