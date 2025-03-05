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
			local select = require("CopilotChat.select")
			local cached_gitdiff = nil

			local function load_prompt(file_path)
				local file = io.open(file_path, "r")
				if not file then
					return nil
				end
				local content = file:read("*a")
				file:close()
				return content
			end

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
				SystemPromptBase = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
				},
				SystemPromptReview = {
					system_prompt = table.concat({
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
						"",
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_review.md"),
					}, "\n"),
				},
				SystemPromptGeneration = {
					system_prompt = table.concat({
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
						"",
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_generate.md"),
					}, "\n"),
				},
				SystemPromptExplain = {
					system_prompt = table.concat({
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
						"",
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_explain.md"),
					}, "\n"),
				},

				-- /Explain
				Explain = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain_en.md"),
					description = "Used to understand what the specified code is doing.",
				},
				ExplainInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain_ja.md"),
					description = "指定したコードが何をしているのかを理解するために使用します。",
				},

				-- /Review
				Review = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review_en.md"),
					description = "Used to perform a review for a given code.",
				},
				ReviewInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review_ja.md"),
					description = "指定されたコードに対するレビューを行うために使用します。",
				},

				-- /Fix
				Fix = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix.md"),
					description = "It is used to fix problems (bugs and errors) occurring in the code.",
				},

				-- /Optimize
				Optimize = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/optimize.md"),
					description = "It is used to propose optimizations for improving the performance and readability of the code.",
				},

				-- /Docs
				Docs = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc_en.md"),
					description = "Used to generate detailed documentation for the provided code, including descriptions for functions, classes, arguments, and usage examples.",
				},
				DocsInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc_ja.md"),
					description = "指定したコードに対する詳細なドキュメントを作成するために使用します。",
				},

				-- /Tests
				Tests = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/tests.md"),
					description = "Used to create test cases for the provided code, covering critical paths, edge cases, and various test types.",
				},

				-- /FixDiagnostic
				FixDiagnostic = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix_diagnostic.md"),
					description = "Used to fix issues in the code based on diagnostic tool results, providing specific fixes and explanations.",
				},

				-- Commit
				Commit = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_en.md"),
					description = "Used to create commit messages based on staged changes.",
				},
				CommitInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_ja.md"),
					description = "ステージされた変更を基にコミットメッセージを作成するために使用します。",
				},

				-- CommitMerge
				CommitPR = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request_en.md"),
					description = "Create a commit message based on the content of the PullRequest.",
				},
				CommitPRInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request_ja.md"),
					description = "PullRequestの内容に基づいたコミットメッセージを作成します。",
				},

				-- Evaluation
				Evaluation = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation_en.md"),
					description = "Used to evaluate the quality, performance, and maintainability of the specified code, along with recommendations for improvement.",
				},
				EvaluationInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation_ja.md"),
					description = "指定されたコードの品質、性能、保守性を評価し、改善勧告を行うために使用します。",
				},

				-- Generate Pull Request
				GeneratePullRequest = {
					prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request_en.md"
					),
					description = "Generate pull request content.",
				},
				GeneratePullRequestInJapanese = {
					prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request_ja.md"
					),
					description = "PullRequestのコンテンツを生成する為に使用します。",
				},
			}

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

	--  Perplexity Search
	vim.keymap.set({ "n", "v" }, "<leader>as", function()
		local input = vim.fn.input("Perplexity: ")
		if input ~= "" then
			require("CopilotChat").ask("> /SystemPromptBase\n\n" .. input, {
				agent = "perplexityai",
				selection = false,
			})
		end
	end, { desc = "CopilotChat - Perplexity Search" }),
}
