local function load_prompt(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return ""
	end
	local content = file:read("*a")
	file:close()
	return content
end

-- MacOS Only
local languages_raw = vim.fn.system("defaults read -g AppleLanguages")
local languages = vim.split(languages_raw:gsub("[%(%)]", ""):gsub('"', ""):gsub("%s+", ""), ",")
local language = (languages_raw:match('"(.-)"') or "en"):match("(%a+)$-")

local base_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_instructions.md") .. "\n\n"

return {

	-- CopilotC-Nvim/CopilotChat.nvim

	{
		"CopilotC-Nvim/CopilotChat.nvim",

		-- debug = true,
		-- log_level = "debug",
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
			}

			options.prompts = {
				-- System prompts
				SystemPromptInstructions = {
					system_prompt = base_prompt,
				},
				SystemPromptReview = {
					system_prompt = base_prompt
						.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_review.md"),
				},
				SystemPromptExplain = {
					system_prompt = base_prompt
						.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_explain.md"),
				},
				SystemPromptOutputTemplate = {
					system_prompt = base_prompt
						.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_output_template.md"),
				},
				SystemPromptGenerateSpecification = {
					system_prompt = base_prompt .. load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_generate_specification.md"
					),
				},
				SystemPromptCommit = {
					system_prompt = base_prompt
						.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_commit.md"),
				},

				-- /Explain
				Explain = {
					prompt = "Write an explanation for the selected code as paragraphs of text.",
					sticky = { "/SystemPromptExplain", "#reply_language:" .. language },
					description = "Used to understand what the specified code is doing.",
				},

				-- /Review
				Review = {
					prompt = "Review the selected code.",
					sticky = { "/SystemPromptReview", "#reply_language:" .. language },
					description = "Used to perform a review for a given code.",
				},

				-- /Fix
				Fix = {
					prompt = "There is a problem in this code. \nIdentify the issues and rewrite the code with fixes. Explain what was wrong and how your changes address the problems.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "It is used to fix problems (bugs and errors) occurring in the code.",
				},

				-- /Optimize
				Optimize = {
					prompt = "Optimize the selected code to improve performance and readability. \nExplain your optimization strategy and the benefits of your changes.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "It is used to propose optimizations for improving the performance and readability of the code.",
				},

				-- /Docs
				Docs = {
					prompt = "Please add documentation comments to the selected code.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Used to generate detailed documentation for the provided code, including descriptions for functions, classes, arguments, and usage examples.",
				},

				-- /Tests
				Tests = {
					prompt = "Please generate tests for my code.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Used to create test cases for the provided code, covering critical paths, edge cases, and various test types.",
				},

				-- /FixDiagnostic
				FixDiagnostic = {
					prompt = "Fix the problem according to the diagnostic content of the code.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Used to fix issues in the code based on diagnostic tool results, providing specific fixes and explanations.",
				},

				-- Evaluation
				Evaluation = {
					prompt = "Thoroughly evaluate the provided code snippet, focusing on functionality, efficiency, readability, and potential issues or improvements.",
					sticky = { "/SystemPromptExplain", "#reply_language:" .. language },
					description = "Used to evaluate the quality, performance, and maintainability of the specified code, along with recommendations for improvement.",
				},

				-- Generate Pull Request
				GeneratePullRequest = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request.md"),
					sticky = {
						"/SystemPromptInstructions",
						"#reply_language:" .. language,
						"#file:.github/PULL_REQUEST_TEMPLATE.md",
						"#file:.github/pull_request_template.md",
						"#system:`git diff main`",
					},
					description = "Generate pull request content.",
				},

				Summarize = {
					prompt = "Please summarize the following text.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Summarizes a given sentence.",
				},

				Spelling = {
					prompt = "Please correct any grammar and spelling errors in the following text.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Corrects grammatical and spelling errors in assigned sentences.",
				},

				Wording = {
					prompt = "Please improve the grammar and wording of the following text.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Improve grammar and expression of assigned sentences.",
				},

				Concise = {
					prompt = "Please rewrite the following text to make it more concise.",
					sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
					description = "Rewrite the specified sentences in a more concise manner.",
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
								-- Convert file paths to relative paths
								local current_dir = vim.fn.getcwd()
								local relative_path = file.path
								if vim.startswith(file.path, current_dir) then
									relative_path = file.path:sub(#current_dir + 2)
								end
								vim.defer_fn(function()
									callback(relative_path)
								end, 100)
							end,
						})
					end,
				},

				reply_language = {
					description = "Specifies the language in which AI responds.",
					input = function(callback)
						vim.ui.select(languages, {
							prompt = "Select language> ",
						}, callback)
					end,
					resolve = function(input)
						return {
							{
								content = (input or "en"):match("(%a+)$-"),
								filename = "Reply_Language",
								filetype = "text",
							},
						}
					end,
				},

				content_language = {
					description = "Specifies the language in which AI generates content.",
					input = function(callback)
						vim.ui.select(languages, {
							prompt = "Select language> ",
						}, callback)
					end,
					resolve = function(input)
						return {
							{
								content = (input or "en"):match("(%a+)$-"),
								filename = "Content_Language",
								filetype = "text",
							},
						}
					end,
				},
			}

			-- Window layout settings
			options.window = {
				layout = function()
					-- vim.notify("options.window.layout: Start debug", vim.log.levels.DEBUG)

					-- For screen sizes of 16 inches or smaller
					if vim.o.lines <= 45 then
						return "horizontal"
					end

					-- Check the current window split status
					local current_tab = vim.api.nvim_get_current_tabpage()
					local wins = vim.api.nvim_tabpage_list_wins(current_tab)

					-- Filter only valid windows
					local valid_wins = vim.tbl_filter(function(win)
						local is_valid = vim.api.nvim_win_is_valid(win)
						return is_valid
					end, wins)

					if #valid_wins > 2 then
						-- Check the positioning of the first two valid windows
						local win1_pos = vim.api.nvim_win_get_position(valid_wins[1])
						local win2_pos = vim.api.nvim_win_get_position(valid_wins[2])

						-- If col (X coordinate) is the same, horizontally split (divided into top and bottom)
						if win1_pos[2] == win2_pos[2] then
							return "vertical"
						end

						-- Vertical division if col (X coordinate) is different (divided into left and right)
						return "horizontal"
					end

					-- Default is vertical (if not split)
					return "vertical"
				end,
			}
		end,
	},

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

	-- Commit
	vim.keymap.set({ "n", "v" }, "<leader>acc", function()
		vim.ui.select({ "Normal", "PullRequest" }, {
			prompt = "Select commit type> ",
		}, function(input)
			if not input or input == "" then
				return
			end

			local prompt = input == "Normal" and "Write a commit message for the Normal change accordingly."
				or "Write a commit message for the PullRequest accordingly."

			local sticky_files = {
				"/SystemPromptCommit",
				"#reply_language:" .. language,
				"#file:commitlint.config.js",
				"#file:.cz-config.js",
			}

			-- Add staged files only for "Normal" input
			if input == "Normal" then
				table.insert(sticky_files, "#git:staged")
			end

			require("CopilotChat").ask(prompt, {
				sticky = sticky_files,
				selection = input ~= "Normal" and false or nil,
			})
		end)
	end, { desc = "CopilotChat - Commit" }),

	-- Translation
	vim.keymap.set({ "n", "v" }, "<leader>act", function()
		vim.ui.select(languages, {
			prompt = "Select Language> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask("Translate the contents of the given Selection with `Reply_Language`.", {
					sticky = {
						"/SystemPromptInstructions",
						"#reply_language:" .. input,
					},
				})
			end
		end)
	end, { desc = "CopilotChat - Translation Selection" }),

	-- Output Template
	vim.keymap.set({ "n", "v" }, "<leader>aco", function()
		vim.ui.select({
			"Proposal",
			"Design",
		}, {
			prompt = "Select Template> ",
		}, function(input)
			if input ~= "" then
				require("CopilotChat").ask(
					"Output the contents of the provided `"
						.. input
						.. ".yaml` file with complete markdown. \n!! Translate the output into the language of the `Content_Language`.",
					{
						sticky = {
							"/SystemPromptOutputTemplate",
							"#reply_language:" .. language,
							"#content_language:" .. language,
							"#file:~/.config/nvim/lua/plugins/templates/" .. input .. ".yaml",
						},
						selection = false,
					}
				)
			end
		end)
	end, { desc = "CopilotChat - Output template" }),

	-- Generate Specification Document
	vim.keymap.set({ "n", "v" }, "<leader>acg", function()
		vim.ui.select({
			"Frontend",
			"Backend",
		}, {
			prompt = "Select Specification> ",
		}, function(input)
			if input ~= "" then
				local base_prompt = load_prompt(
					vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_specification.md"
				) or ""
				local full_prompt = base_prompt:gsub("{{input}}", input)
				require("CopilotChat").ask(full_prompt, {
					sticky = {
						"/SystemPromptGenerateSpecification",
						"#reply_language:" .. language,
						"#content_language:" .. language,
						"#file:~/.config/nvim/lua/plugins/templates/" .. input .. "_Specification.yaml",
						"#file:system-design/Proposal.md",
						"#file:system-design/Design.md",
					},
					selection = false,
				})
			end
		end)
	end, { desc = "CopilotChat - Generate Specification Document" }),
}
