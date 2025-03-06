local function load_prompt(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local languages = { "english", "日本語" }

return {

	-- CopilotC-Nvim/CopilotChat.nvim

	{
		"CopilotC-Nvim/CopilotChat.nvim",

		show_help = "yes",
		highlight_headers = false,
		separator = "---",
		error_header = "> [!ERROR] Error",

		dependencies = {
			{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux

		opts = function(_, options)
			-- providers
			options.providers = {
				ollama = {
					prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,
					prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,

					get_models = function(headers)
						local response, err =
							require("CopilotChat.utils").curl_get("http://localhost:11434/v1/models", {
								headers = headers,
								json_response = true,
							})

						if err then
							error(err)
						end

						return vim.tbl_map(function(model)
							return {
								id = model.id,
								name = model.id,
							}
						end, response.body.data)
					end,

					embed = function(inputs, headers)
						local response, err =
							require("CopilotChat.utils").curl_post("http://localhost:11434/v1/embeddings", {
								headers = headers,
								json_request = true,
								json_response = true,
								body = {
									input = inputs,
									model = "all-minilm",
								},
							})

						if err then
							error(err)
						end

						return response.body.data
					end,

					get_url = function()
						return "http://localhost:11434/v1/chat/completions"
					end,
				},

				lmstudio = {
					prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,
					prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,

					get_models = function(headers)
						local response, err = require("CopilotChat.utils").curl_get("http://localhost:1234/v1/models", {
							headers = headers,
							json_response = true,
						})

						if err then
							error(err)
						end

						return vim.tbl_map(function(model)
							return {
								id = model.id,
								name = model.id,
							}
						end, response.body.data)
					end,

					embed = function(inputs, headers)
						local response, err =
							require("CopilotChat.utils").curl_post("http://localhost:1234/v1/embeddings", {
								headers = headers,
								json_request = true,
								json_response = true,
								body = {
									dimensions = 512,
									input = inputs,
									model = "text-embedding-nomic-embed-text-v1.5",
								},
							})

						if err then
							error(err)
						end

						return response.body.data
					end,

					get_url = function()
						return "http://localhost:1234/v1/chat/completions"
					end,
				},
			}

			options.prompts = {
				-- System prompts
				SystemPromptInstructions = {
					system_prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_instructions.md"
					),
				},
				SystemPromptReview = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_review.md"),
				},
				SystemPromptExplain = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_explain.md"),
				},

				-- /Explain
				Explain = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain.md"),
					sticky = "/SystemPrompExplain",
					language = "japanese",
					description = "Used to understand what the specified code is doing.",
				},

				-- /Review
				Review = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review.md"),
					sticky = "/SystemPromptReview",
					description = "Used to perform a review for a given code.",
				},

				-- /Fix
				Fix = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix.md"),
					sticky = "/SystemPromptInstructions",
					description = "It is used to fix problems (bugs and errors) occurring in the code.",
				},

				-- /Optimize
				Optimize = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/optimize.md"),
					sticky = "/SystemPromptInstructions",
					description = "It is used to propose optimizations for improving the performance and readability of the code.",
				},

				-- /Docs
				Docs = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc.md"),
					sticky = "/SystemPromptInstructions",
					description = "Used to generate detailed documentation for the provided code, including descriptions for functions, classes, arguments, and usage examples.",
				},

				-- /Tests
				Tests = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/test.md"),
					sticky = "/SystemPromptInstructions",
					description = "Used to create test cases for the provided code, covering critical paths, edge cases, and various test types.",
				},

				-- /FixDiagnostic
				FixDiagnostic = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix_diagnostic.md"),
					sticky = "/SystemPromptInstructions",
					description = "Used to fix issues in the code based on diagnostic tool results, providing specific fixes and explanations.",
				},

				-- Commit
				Commit = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_en.md"),
					sticky = { "/SystemPromptInstructions", "#git:staged" },
					description = "Used to create commit messages based on staged changes.",
				},

				-- CommitMerge
				CommitPR = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request.md"),
					sticky = { "/SystemPromptInstructions", "#git:staged" },
					description = "Create a commit message based on the content of the PullRequest.",
				},

				-- Evaluation
				Evaluation = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation.md"),
					sticky = "/SystemPromptExplain",
					description = "Used to evaluate the quality, performance, and maintainability of the specified code, along with recommendations for improvement.",
				},

				-- Generate Pull Request
				GeneratePullRequest = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request.md"),
					sticky = {
						"/SystemPromptInstructions",
						"#file:.github/PULL_REQUEST_TEMPLATE.md",
						"#file:.github/pull_request_template.md",
						"#system:`git diff main`",
					},
					description = "Generate pull request content.",
				},
			}

			-- contexts
			options.contexts = {
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
								vim.defer_fn(function()
									callback(file.path)
								end, 100)
							end,
						})
					end,
				},

				language = {
					description = "Specifies the language in which AL responds.",
					input = function(callback)
						vim.ui.select(languages, {
							prompt = "Select language> ",
						}, callback)
					end,
					resolve = function(input)
						return {
							{
								content = input or "japanese",
								filename = "Response_Language",
								filetype = "text",
							},
						}
					end,
				},
			}

			-- Window layout settings
			options.window = {
				layout = "float",
				relative = "cursor",
				width = 1,
				height = 0.7,
				row = 1,
			}
		end,
	},

	-- Explain
	vim.keymap.set({ "n", "v" }, "<leader>acee", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain.md"), {
					sticky = { "/SystemPromptExplain", "#language:" .. input },
				})
			end
		end)
	end, { desc = "CopilotChat - Explain" }),

	-- Review
	vim.keymap.set({ "n", "v" }, "<leader>acr", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review.md"), {
					sticky = { "/SystemPromptReview", "#language:" .. input },
				})
			end
		end)
	end, { desc = "CopilotChat - Review" }),

	-- Docs
	vim.keymap.set({ "n", "v" }, "<leader>acd", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc.md"), {
					sticky = { "/SystemPromptInstructions", "#language:" .. input },
				})
			end
		end)
	end, { desc = "CopilotChat - Docs" }),

	-- Commit
	vim.keymap.set({ "n", "v" }, "<leader>accc", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit.md"), {
					sticky = { "/SystemPromptInstructions", "#language:" .. input, "#git:staged" },
					selection = false,
				})
			end
		end)
	end, { desc = "CopilotChat - Commit" }),

	-- Commit Pull Request
	vim.keymap.set({ "n", "v" }, "<leader>accp", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(
					load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request.md"),
					{
						sticky = { "/SystemPromptInstructions", "#language:" .. input, "#system:`git diff main`" },
					}
				)
			end
		end)
	end, { desc = "CopilotChat - Commit Pull Request" }),

	-- Evaluation
	vim.keymap.set({ "n", "v" }, "<leader>acev", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(
					load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation.md"),
					{
						sticky = { "/SystemPromptExplain", "#language:" .. input },
					}
				)
			end
		end)
	end, { desc = "CopilotChat - Evaluation" }),

	-- Generate Pull Request
	vim.keymap.set({ "n", "v" }, "<leader>acgp", function()
		vim.ui.select(languages, {
			prompt = "Select language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(
					load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request.md"),
					{
						sticky = {
							"/SystemPromptInstructions",
							"#file:.github/PULL_REQUEST_TEMPLATE.md",
							"#file:.github/pull_request_template.md",
							"#system:`git diff main`",
						},
					}
				)
			end
		end)
	end, { desc = "CopilotChat - GeneratePullRequest" }),

	--  Perplexity Search
	vim.keymap.set({ "n", "v" }, "<leader>acs", function()
		local input = vim.fn.input("Perplexity: ")
		if input ~= "" then
			require("CopilotChat").ask(input, {
				agent = "perplexityai",
				sticky = "/SystemPromptInstructions",
				selection = false,
			})
		end
	end, { desc = "CopilotChat - Search" }),
}
