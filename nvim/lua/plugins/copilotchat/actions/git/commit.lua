local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function commit()
	vim.ui.select({ "Normal", "WIP", "Normal Merge", "Squash Merge" }, {
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

			local sticky_files = {
				"/SystemPromptCommit",
				"#content_language:" .. selected_language,
				"#file:commitlint.config.js",
				"#file:.cz-config.js",
			}
			local selection = nil
			local prompt = ""

			--
			if type == "Normal" then
				prompt = 'Write a clear and concise "Normal" commit message for the selected changes.'
				table.insert(sticky_files, "#git:staged")
				selection = false

			--
			elseif type == "WIP" then
				prompt = 'Write a commit message indicating this is a work in progress "WIP" commit.'
				table.insert(sticky_files, "#git:staged")
				selection = false

			--
			elseif type == "Normal Merge" then
				prompt =
					'Write a commit message for merging the specified branches. \nSummarize the changes introduced by the "Normal Merge".'

			--
			elseif type == "Squash Merge" then
				prompt = 'Write a commit message for a "Squash Merge", summarizing all combined changes.'
				vim.ui.select({ "main", "develop" }, {
					prompt = "Select base branch> ",
				}, function(selected_base_branch)
					if not selected_base_branch or selected_base_branch == "" then
						selected_base_branch = "main"
					end

					local branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))

					table.insert(
						sticky_files,
						"#system:`git log "
							.. selected_base_branch
							.. ".."
							.. branch
							.. ' --reverse --pretty="%an -> %s"`'
					)

					new_float_window(prompt, {
						sticky = sticky_files,
						selection = selection,
					})
				end)
				return
			end

			--
			new_float_window(prompt, {
				sticky = sticky_files,
				selection = selection,
			})
		end)
	end)
end

return commit
