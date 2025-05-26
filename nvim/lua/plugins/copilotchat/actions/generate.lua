local fzf_lua = require("fzf-lua")
local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

---@alias GenerateAction "Code"|"PullRequest"

---@class GenerateOpts
---@field prompt string|nil
---@field base_branch string|nil
---@field content_language LanguageName|nil
---@field selected_files table|nil
---@field restored_selection RestoreSelection|nil

local M = {}

local draft_prompt = {
	English = [[
Please generate code that meets the requirements, paying attention to the following important points:

Purpose & Functionality
- Purpose: [What do you want to achieve with this feature?]
- Key Features: [Specific features to implement]
- Use Cases: [Situations in which this will be used]

Technical Specifications
- Language/Framework: [Technology stack to use]
- Architecture Pattern: [e.g., MVC, layered architecture]
- Dependencies: [Libraries or modules to use]

Input/Output Specifications
- Input: [Parameters, arguments, data formats]
- Output: [Return values, responses, side effects]
- Data Format: [JSON, XML, plain text, etc.]

Constraints & Requirements
- Performance: [Requirements for speed, memory usage]
- Security: [Authentication, authorization, validation requirements]
- Error Handling: [Exception handling, error response requirements]
- Compatibility: [Integration requirements with existing code]

Code Quality
- Naming Conventions: [Style for variable and function names]
- Comments: [Documentation requirements]
- Testing: [Need for unit tests, integration tests]
- Maintainability: [Requirements for extensibility, readability]

Implementation Guidelines
- Design Patterns: [Patterns to use]
- Best Practices: [Conventions and principles to follow]
- Prohibited Implementations: [Methods or libraries not to use]

Other
- Priority: [Required features vs. optional features]
- Deadlines/Constraints: [Time or resource constraints]
- References: [Specification documents, references to existing implementations]

**Important**

- If an item is not specified, interpret it as "the user is leaving the decision to you" and make the best possible decision by referring to related files and other resources.
- Always apply software design principles to the generated code.
- After generating the code, provide an "explanation of the deliverable," and then suggest the next step, such as "What would you like to create next using this feature?" to conclude the task.
]],

	Japanese = [[
次の重要事項に注意しながら要件を満たすコードを生成してください:

目的・機能
- 目的: [この機能で何を実現したいか]
- 主要機能: [実装すべき具体的な機能]
- 使用場面: [どのような状況で使用されるか]

技術仕様
- 言語・フレームワーク: [使用する技術スタック]
- アーキテクチャパターン: [MVC、レイヤードアーキテクチャなど]
- 依存関係: [使用するライブラリ・モジュール]

入出力仕様
- 入力: [パラメータ、引数、データ形式]
- 出力: [戻り値、レスポンス、副作用]
- データ形式: [JSON、XML、プレーンテキストなど]

制約・要求事項
- パフォーマンス: [速度、メモリ使用量の要件]
- セキュリティ: [認証、認可、バリデーション要件]
- エラーハンドリング: [例外処理、エラー応答の要件]
- 互換性: [既存コードとの統合要件]

コード品質
- 命名規則: [変数名、関数名のスタイル]
- コメント: [ドキュメント化の要件]
- テスト: [単体テスト、統合テストの必要性]
- 保守性: [拡張性、可読性の要件]

実装指針
- デザインパターン: [使用すべきパターン]
- ベストプラクティス: [従うべき慣例・原則]
- 避けるべき実装: [使用禁止の手法・ライブラリ]

その他
- 優先度: [必須機能 vs オプション機能]
- 締切・制約: [時間的制約、リソース制約]
- 参考資料: [仕様書、既存実装への言及]

**重要**

- 項目が指定されていない場合は「ユーザーが判断を委ねている」と解釈し、関連ファイルや他のリソースを参照して最善の判断を行ってください。
- 生成するコードには常にソフトウェア設計の原則を適用してください。
- コード生成後は「成果物の説明」を行い、最後に「この機能を使って次に何を作成しますか？」など、次のステップを提案してタスクを締めくくってください。
]],
}

local prompts = {
	Code = nil,
	PullRequest = [[
Please create a GitHub Pull Request with attention to the following:

- Create a title that meets these requirements:
  - The title must be no longer than 50 characters
  - Start with a verb (e.g., Add xx, Fix xx, Enable xx)
  - Summarize the overall purpose of the changes in `command_output_git_log_main__*`

- Create a body that meets these requirements:
  - Carefully analyze the contents of `command_output_git_diff_*` and base the body on them
  - Sections:
    - Overview: `text`
    - Changes: `text`
    - Related Issues, Pull Requests, Discussions: `list (#{number})`
    - Breaking Changes: `checkbox (Yes or No)`

**Important**:

- Output the title first, then the body.
- If `**github_PULL_REQUEST_TEMPLATE**` or `**github_pull_request_template**` is provided, generate the Pull Request content based on that template.
]],
}

local fallback_chat_title = {
	Code = "Request to generate code",
	PullRequest = "Request to generate a pull request",
}

--- Build sticky context for the given commit type, base branch, and commit language.
---@param action GenerateAction
---@param opts GenerateOpts
---@return table
local function build_sticky(action, opts)
	local file = {
		Code = nil,
		PullRequest = { ".github/PULL_REQUEST_TEMPLATE.md", ".github/pull_request_template.md" },
	}
	local system = { Code = nil, PullRequest = {} }
	local sticky_system_prompt = nil

	if action == "Code" then
		file.Code = opts.selected_files and sticky.build_file_contexts(opts.selected_files) or nil
		sticky_system_prompt = (not opts.prompt or opts.prompt == "")
				and system_prompt.to_sticky(
					"assistant",
					"ai",
					opts.restored_selection and opts.restored_selection.filetype or nil
				)
			or nil
	end

	if action == "PullRequest" then
		table.insert(system.PullRequest, "git diff " .. opts.base_branch)
		table.insert(
			system.PullRequest,
			"git log "
				.. opts.base_branch
				.. ".."
				.. vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
				.. " --pretty=format:'%h %s'"
		)
	end

	return sticky.build({
		system_prompt = sticky_system_prompt,
		reply_language = system_languages.default,
		content_language = opts.content_language,
		file = file[action],
		system = system[action],
	})
end

--- Build the system prompt for commit actions.
---@param action GenerateAction
---@param opts GenerateOpts
---@return string
local build_system_prompt = function(action, opts)
	local role = {
		Code = "assistant",
		PullRequest = "documenter",
	}
	local guideline = {
		Code = { change_code = true, localization = true, software_principles = true, message_markup = true },
		PullRequest = { localization = true, message_markup = true },
	}
	local specialties = {
		Code = opts.restored_selection and opts.restored_selection.filetype or nil,
		PullRequest = { "documentation" },
	}
	local format = {
		Code = nil,
		PullRequest = "pull_request",
	}

	return system_prompt.build({
		role = role[action],
		character = "ai",
		guideline = guideline[action],
		specialties = specialties[action],
		format = format[action],
	})
end

--- Get the prompt for the given action and options.
--- @param action GenerateAction
--- @param opts GenerateOpts
--- @return table<"main"|"draft", string|nil>
local function get_prompt(action, opts)
	if action == "Code" then
		if opts.prompt and not opts.prompt == "" then
			return { main = opts.prompt, draft = nil }
		end
		return {
			main = nil,
			draft = draft_prompt[system_languages.default] or draft_prompt[system_languages.table.en],
		}
	end
	return { main = prompts[action], draft = nil }
end

--- Open the CopilotChat window for the given commit type, base branch, and commit language.
---@param action GenerateAction
---@param opts GenerateOpts
local function open_window(action, opts)
	local prompt = get_prompt(action, opts)

	local save_chat = function(response)
		chat_history.save(response, {
			used_prompt = prompt.main or fallback_chat_title[action],
			tag = "Generate",
		})
	end

	local callback_selection = function(source)
		if action == "Code" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	local open = {
		Code = window.open_vertical,
		PullRequest = window.open_float,
	}

	open[action](prompt.main, {
		draft_prompt = prompt.draft,
		auto_insert_mode = action == "Code" and opts.prompt == nil,
		system_prompt = build_system_prompt(action, opts),
		sticky = build_sticky(action, opts),
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Handle commit language selection and open window.
---@param action GenerateAction
---@param opts GenerateOpts
local function on_content_language_selected(action, opts)
	open_window(action, opts)
end

--- Prompt user to select commit language.
---@param action GenerateAction
---@param opts GenerateOpts
local function select_content_language(action, opts)
	vim.ui.select(system_languages.names, { prompt = "Select content language> " }, function(language)
		if not language or language == "" then
			language = system_languages.default
		end
		opts = vim.tbl_extend("force", opts, { content_language = language })
		on_content_language_selected(action, opts)
	end)
end

--- Prompt user to input base branch.
---@param action GenerateAction
---@param opts GenerateOpts
local function input_base_branch(action, opts)
	vim.ui.input({ prompt = "Enter base branch> " }, function(input)
		if not input or input == "" then
			input = "main"
		end
		opts.base_branch = input
		select_content_language(action, opts)
	end)
end

--- Prompt user to select base branch.
---@param action GenerateAction
local function select_base_branch(action)
	local next = {
		main = select_content_language,
		develop = select_content_language,
		Other = input_base_branch,
	}

	local base_branches = { "main", "develop", "Other" }
	local ui_opts = { prompt = "Select base branch> " }
	vim.ui.select(base_branches, ui_opts, function(selected_base_branch)
		if not selected_base_branch or selected_base_branch == "" then
			selected_base_branch = "main"
		end
		local opts = { base_branch = selected_base_branch }
		next[selected_base_branch](action, opts)
	end)
end

local on_selected_files = function(target, opts)
	selection.restore(function(restored_selection)
		opts = vim.tbl_extend("force", opts, { restored_selection = restored_selection })
		open_window(target, opts)
	end)
end

local select_files = function(target, opts)
	local callback = function(selected_files)
		on_selected_files(target, vim.tbl_extend("force", opts, { selected_files = selected_files }))
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

local input_prompt = function(target)
	vim.ui.input({ prompt = "Prompt> " }, function(input)
		select_files(target, { prompt = input })
	end)
end

local next = {
	Code = input_prompt,
	PullRequest = select_base_branch,
}

M.execute = function()
	local actions = { "Code", "PullRequest" }
	local ui_opts = { prompt = "Select action> " }
	vim.ui.select(actions, ui_opts, function(action)
		if not action or action == "" then
			return
		end
		next[action](action)
	end)
end

return M
