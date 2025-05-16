local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local function commit()
	vim.ui.select({ "Normal", "PullRequest" }, {
		prompt = "Select commit type> ",
	}, function(type)
		if not type or type == "" then
			return
		end

		vim.ui.select(languages, {
			prompt = "Select content language> ",
		}, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = language
			end

			local prompt = type == "Normal" and "Write a commit message for the Normal change accordingly."
				or "Write a commit message for the PullRequest accordingly."

			local sticky_files = {
				"/SystemPromptCommit",
				"#content_language:" .. selected_language,
				"#file:commitlint.config.js",
				"#file:.cz-config.js",
			}

			-- Add staged files only for "Normal" input
			if type == "Normal" then
				table.insert(sticky_files, "#git:staged")
			end

			require("CopilotChat").ask(prompt, {
				sticky = sticky_files,
				selection = type ~= "Normal" and false or nil,
			})
		end)
	end)
end

return commit
