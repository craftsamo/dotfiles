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

local base_instructions = load_prompt(
	vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/instructions/base.md"
) .. "\n\n"
local change_code_instruction = load_prompt(
	vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/instructions/change_code.md"
) .. "\n\n"
local localize_instruction = load_prompt(
	vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/instructions/localization.md"
) .. "\n\n"

M.prompts = {
	-- System Prompts
	SystemPromptInstructions = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction,
	},

	-- Code
	SystemPromptReview = {
		system_prompt = base_instructions .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/review.md"
		),
	},
	SystemPromptExplain = {
		system_prompt = base_instructions .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/explain.md"
		),
	},
	SystemPromptFixBugs = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/fix_bugs.md"
		),
	},
	SystemPromptAnalyzeCode = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/analyze.md"
		),
	},
	SystemPromptCodeDoc = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/code/doc.md"
		),
	},

	-- Utils
	SystemPromptOutputTemplate = {
		system_prompt = base_instructions .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/output_template.md"
		),
	},
	SystemPromptTranslate = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/translate.md"
		),
	},
	SystemPromptSpelling = {
		system_prompt = base_instructions .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/utils/spelling.md"
		),
	},

	-- Git
	SystemPromptCommit = {
		system_prompt = base_instructions .. change_code_instruction .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/git/commit.md"
		),
	},
	SystemPromptGenerate = {
		system_prompt = base_instructions .. localize_instruction .. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/actions/git/generate.md"
		),
	},

	-- Chat
	SystemPromptChat = {
		system_prompt = localize_instruction
			.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/chat/free_chat.md"),
	},
}

-- Export language and languages for use in other modules
M.language = language
M.languages = languages

return M
