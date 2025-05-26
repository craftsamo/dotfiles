local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local sticky = require("plugins.copilotchat.utils.sticky")
local window = require("plugins.copilotchat.utils.window")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

---@alias AnalyzeTarget "Practicality"|"Security"|"Performance"|"Maintainability"

---@class AnalyzeOpts
---@field selected_files table|nil
---@field restored_selection RestoreSelection

local common_steps = [[
**Analyze steps**:

  - Step 1: Understand the input information
    - Check the target file name, function name, line numbers, and code block range
    - Confirm the presence of comments or docstrings to understand the intended specification or purpose
    - Identify the function's inputs and outputs, as well as the variables, arguments, and return values used

  - Step 2: Identify scope and structure
    - Analyze the structure of the function body (sequential processing, conditionals, loops, recursion, exception handling, etc.)
    - Understand code block divisions and nesting depth
    - Clarify the role of the logic and the intent of each section

  - Step 3: Identify dependencies
    - Extract dependencies on external modules (imports) and internal modules (other functions or constants)
    - Understand the potential impact and side effects when changes are made

  - Step 4: Identify side effects and state changes
    - Extract side effects such as global variable modifications, I/O, database access, or API communication
    - Track where state changes occur
]]

local analysis_items = {
	Practicality = [[
  - Step 5: Practicality Assessment
    - Evaluate usefulness in actual business or project scenarios
    - Consider code reusability and versatility
    - Judge the feasibility and practicality of the implementation

  - Step 6: Identify Practicality Issues
    - Reduced practicality due to excessive abstraction or complexity
    - Excessive dependency on specific environments
    - Inconsistencies with performance requirements
    - Difficulties in operation and maintenance

  - Step 7: Practicality Metrics
    - Appropriateness of function granularity
    - Usability of interfaces
    - Practicality of error handling
]],

	Security = [[
  - Step 5: Security Risk Assessment
    - Check adequacy of input validation
    - Evaluate implementation of authentication and authorization
    - Verify handling of confidential information
    - Confirm security of communication with external systems

  - Step 6: Detect Vulnerability Patterns
    - Vulnerabilities such as SQL injection, XSS, CSRF, etc.
    - Hardcoded credentials or secret keys
    - Improper permission settings or access control
    - Insecure encryption or communication

  - Step 7: Security Metrics
    - Input validation coverage
    - Degree of authentication and authorization implementation
    - Adherence to secure programming principles
]],

	Performance = [[
  - Step 5: Performance Characteristics Assessment
    - Analyze time complexity (Big O notation)
    - Evaluate space complexity and memory usage patterns
    - Check efficiency of I/O operations
    - Verify appropriateness of data structure selection

  - Step 6: Identify Performance Bottlenecks
    - Inefficient loops or algorithms
    - Unnecessary memory allocation or redundant computation
    - Insufficient optimization of database queries
    - Wait times due to synchronous processing

  - Step 7: Performance Metrics
    - Complexity of computation
    - Memory usage efficiency
    - Degree of I/O operation optimization
]],

	Maintainability = [[
  - Step 5: Maintainability Assessment
    - Evaluate code readability and understandability
    - Check scope of impact and ease of modification when changes are made
    - Verify testability and ease of debugging
    - Confirm documentation status
 
  - Step 6: Identify Factors Hindering Maintainability
    - Overly complex functions or classes
    - Tight coupling or circular dependencies
    - Magic numbers or hardcoded values
    - Inappropriate naming or insufficient comments
 
  - Step 7: Maintainability Metrics
    - Cyclomatic complexity
    - Degree of coupling and cohesion
    - Comment rate and level of documentation
]],
}

local evaluation_criteria = {
	Practicality = [[
- Practicality: 30 points
- Reusability: 25 points
- Maintainability: 25 points
- Operability
]],

	Security = [[
- Input Validation: 30 points
- Authentication/Authorization: 25 points
- Data Protection: 25 points
- Secure Programming: 20 points
]],

	Performance = [[
- Time Complexity: 30 points
- Space Complexity: 25 points
- I/O Efficiency: 25 points
- Data Structure Selection: 20 points
]],

	Maintainability = [[
- Readability: 30 points
- Ease of Modification: 25 points
- Testability: 25 points
- Documentation: 20 points
]],
}

local common_important = [[
- `<analysis_content>` describes the detected issue category (e.g., "Complexity Issue", "Security Risk").
- `<analysis_content.content_description>` concisely explains the specific issue and always includes the relevant line number.
- Add a status icon before each item:
  - ✘ Critical issue
  - ⚠ Recommended improvement
  - ✔ Good status
- Line numbers must accurately reference the actual code lines.
- Improvement suggestions should be concrete and actionable.
]]

local prompts = {
	Practicality = 'Analyze and evaluate the "practicality" of the selected code range using the following steps.'
		.. "\n\n"
		.. common_steps
		.. "\n"
		.. analysis_items.Practicality
		.. "\n"
		.. "**Evaluation criteria**:\n\n"
		.. evaluation_criteria.Practicality
		.. "\n"
		.. "**Important**:\n\n"
		.. common_important,
}

local function build_sticky(target, opts)
	return sticky.build({
		reply_language = system_languages.default,
		file = sticky.build_file_contexts(opts and opts.selected_files or nil),
	})
end

local function build_system_prompt(target, restored_selection)
	return system_prompt.build({
		role = "analyst",
		character = "ai",
		guideline = { change_code = true, localization = true, software_principles = true, message_markup = true },
		specialties = restored_selection and { restored_selection.filetype, "analysis" } or { "analysis" },
		question_focus = "selection",
		format = "analyze",
	})
end

--- Open the CopilotChat window for the given analyze action and selection.
---@param target AnalyzeTarget
---@param opts AnalyzeOpts
local function open_window(target, opts)
	local prompt = prompts[target]
	if not prompt then
		return
	end

	local callback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Analyze" })
		return response
	end

	window.open_float(prompt, {
		system_prompt = build_system_prompt(target, opts and opts.restored_selection),
		sticky = build_sticky(target, opts),
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Restore selection and open window for the given analyze action.
---@param target AnalyzeTarget
---@param opts AnalyzeOpts|nil
local function on_selected_files(target, opts)
	selection.restore(function(restored_selection)
		open_window(target, vim.tbl_extend("force", opts or {}, { restored_selection = restored_selection }))
	end)
end

local function select_files(target)
	local callback = function(selected_files)
		on_selected_files(target, { selected_files = selected_files })
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

M.execute = function()
	local targets = { "Practicality", "Security", "Performance", "Maintainability" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		select_files(target)
	end)
end

return M
