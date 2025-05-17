-- This file contains the prompt templates for the LLMs.
local M = {}

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

local base_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/instructions.md")
	.. "\n\n"

M.prompts = {
	-- System system_prompt
	SystemPromptInstructions = {
		system_prompt = base_prompt,
	},
	SystemPromptReview = {
		system_prompt = base_prompt
			.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/review.md"),
	},
	SystemPromptExplain = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/explain.md"
		),
	},
	SystemPromptOutputTemplate = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/output_template.md"
		),
	},
	SystemPromptCommit = {
		system_prompt = base_prompt
			.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/git/commit.md"),
	},
	SystemPromptGenerate = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/git/generate.md"
		),
	},
	SystemPromptTranslate = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/translate.md"
		),
	},
	SystemPromptChat = {
		system_prompt = load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/chat/free_chat.md"
		),
	},
	SystemPromptFixBugs = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/fix_bugs.md"
		),
	},
	SystemPromptAnalyzeCode = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/analyze.md"
		),
	},
	SystemPromptSpelling = {
		system_prompt = base_prompt .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/spelling.md"
		),
	},
	SystemPromptZenn = {
		system_prompt = load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/system_zenn.md"
		),
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

-- Export language and languages for use in other modules
M.language = language
M.languages = languages

return M
