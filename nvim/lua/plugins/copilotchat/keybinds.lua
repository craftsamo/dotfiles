local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local contexts_module = require("plugins.copilotchat.contexts")
local characters = contexts_module.characters
local roles = contexts_module.roles

return {
	--  Perplexity Search
	vim.keymap.set({ "n", "v" }, "<leader>acs", function()
		local input = vim.fn.input("Perplexity: ")
		if input ~= "" then
			require("CopilotChat").ask(input, {
				agent = "perplexityai",
				sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
				selection = false,
			})
		end
	end, { desc = "CopilotChat - Search" }),

	-- Chat
	vim.keymap.set({ "n", "v" }, "<leader>acch", function()
		vim.ui.select(characters, {
			prompt = "Select character> ",
		}, function(character)
			if not character or character == "" then
				character = "Friendly"
			end
			vim.ui.select(roles, {
				prompt = "Select character> ",
			}, function(role)
				if not role or role == "" then
					role = "Teacher"
				end

				local input = vim.fn.input("Chat: ")
				if not input or input == "" then
					return
				end

				require("CopilotChat").ask(input, {
					sticky = {
						"/SysytemPromptChat",
						"#reply_language:" .. language,
						"#character:" .. character,
						"#role:" .. role,
					},
					selection = false,
				})
			end)
		end)
	end, { desc = "CopilotChat - Chat" }),

	-- Commit
	vim.keymap.set({ "n", "v" }, "<leader>acco", function()
		vim.ui.select({ "Normal", "PullRequest" }, {
			prompt = "Select commit type> ",
		}, function(type)
			if not type or type == "" then
				return
			end

			vim.ui.select(languages, { prompt = "Select content language> " }, function(selected_language)
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
	end, { desc = "CopilotChat - Commit" }),

	-- Translation
	vim.keymap.set({ "n", "v" }, "<leader>act", function()
		vim.ui.select(languages, {
			prompt = "Select Language> ",
		}, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = language
			end

			require("CopilotChat").ask("Translate the contents of the given Selection with `Content_Language`.", {
				sticky = {
					"/SystemPromptTranslate",
					"#content_language:" .. selected_language,
				},
			})
		end)
	end, { desc = "CopilotChat - Translation Selection" }),

	-- Output Template
	vim.keymap.set({ "n", "v" }, "<leader>aco", function()
		vim.ui.select({
			"Proposal",
			"BasicDesign",
			"FrontendDesign",
			"BackendDesign",
			"DatabaseDesign",
			"GitDesign",
			"InfraDesign",
		}, {
			prompt = "Select Template> ",
		}, function(content)
			if not content or content == "" then
				return
			end
			vim.ui.select(languages, { prompt = "Select content language> " }, function(selected_language)
				if not selected_language or selected_language == "" then
					selected_language = language
				end

				require("CopilotChat").ask(
					"Output the contents of the provided `"
						.. content
						.. ".yaml` file with complete markdown. \n!! Translate the output into the language of the `Content_Language`.",
					{
						sticky = {
							"/SystemPromptOutputTemplate",
							"#content_language:" .. selected_language,
							"#file:~/.config/nvim/lua/plugins/copilotchat/templates/" .. content .. ".yaml",
						},
						selection = false,
					}
				)
			end)
		end)
	end, { desc = "CopilotChat - Output template" }),

	-- Generate Pull Request
	vim.keymap.set({ "n", "v" }, "<leader>acgp", function()
		vim.ui.select({ "main", "develop" }, { prompt = "Select base branch> " }, function(selected_branch)
			if not selected_branch or selected_branch == "" then
				return
			end

			vim.ui.select(languages, { prompt = "Select content language> " }, function(selected_language)
				if not selected_language or selected_language == "" then
					selected_language = language
				end

				require("CopilotChat").ask(
					"Create the contents of a 'Pull Request' based on the contents of the given Diff.",
					{
						sticky = {
							"/SystemPromptGenerate",
							"#content_language:" .. selected_language,
							"#system: git diff " .. selected_branch,
							"#file:.github/PULL_REQUEST_TEMPLATE.md",
							"#file:.github/pull_request_template.md",
						},
						selection = false,
					}
				)
			end)
		end)
	end, { desc = "CopilotChat - Generate Pull Request" }),

	-- Fix bugs
	vim.keymap.set({ "n", "v" }, "<leader>acf", function()
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

					local prompt = "Fix the bug based on the given stack trace. \n\n"
						.. "**user_memo**:\n\n"
						.. user_memo
					require("CopilotChat").ask(prompt, {
						sticky = sticky,
					})
				end,
			},
			multi = true,
		})
	end, { desc = "CopilotChat - Fix bugs" }),

	-- Analize Code
	vim.keymap.set({ "n", "v" }, "<leader>aca", function()
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
	end, { desc = "CopilotChat - Analize code" }),
}
