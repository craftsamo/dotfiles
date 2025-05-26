local chat_select = require("CopilotChat.select")
local copilot_chat_ns = vim.api.nvim_create_namespace("copilot-chat-diagnostics")
local diagnostics_parser = require("plugins.copilotchat.utils.diagnostics")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

---@alias ReviewTarget "Code"|"Spelling"
---@class ReviewOpts
---@field restored_selection RestoreSelection

local M = {}

local prompts = {
	Code = [[
Please review the selected code based on the following criteria:

- Variable Names:
  - Are the names clear and descriptive?
  - Do they follow conventional naming practices?
- Comments:
  - Are there any missing comments?
  - Are there any redundant comments?
  - Do the comments accurately reflect the code's behavior?
- Code:
  - Are complex expressions simplified where possible?
  - Is there any deep nesting or overly complex control flow?
  - Is a consistent style and formatting maintained?
  - Is there any code duplication or redundancy?
  - Are there any performance issues?
  - Is error handling sufficient?
  - Are there any security concerns?
  - Does the code violate any software principles?

**Important**:

- If a single line contains multiple issues, separate them with semicolons.
- End your review with "**`To clear buffer highlights, please ask a different question`**".
]],

	Spelling = [[
Please review the natural language content in the selected range based on the following criteria:

- Check for any spelling mistakes or typographical errors
- Ensure correct grammar is used
- Confirm that appropriate expressions are used

**Important**:

- Do not comment on the language used (e.g., do not suggest translating to another language or that the content should be written in a different language)
- If a single line contains multiple issues, separate them with semicolons.
- End your review with "**`To clear buffer highlights, please ask a different question`**".
]],
}

--- Build the system prompt for the given review action and selection.
---@param target ReviewTarget
---@param restored_selection RestoreSelection
---@return string
local build_system_prompt = function(target, restored_selection)
	return system_prompt.build({
		role = "reviewer",
		character = "ai",
		guideline = { localization = true, software_principles = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		format = "review",
	})
end

--- Build sticky context for review.
---@return table
local function build_sticky()
	return sticky.build({
		reply_language = system_languages.default,
	})
end

--- Open the CopilotChat window for the given review action and selection.
---@param target ReviewTarget
---@param restored_selection RestoreSelection
local function open_window(target, restored_selection)
	local callback_selection = function(source)
		if target == "Code" or target == "Spelling" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	local function set_diagnostic(response, source)
		local diagnostics = diagnostics_parser.parse_review_response("Copilot Review", response)
		vim.diagnostic.set(copilot_chat_ns, source.bufnr, diagnostics)
	end

	window.open_vertical(prompts[target], {
		system_prompt = build_system_prompt(target, restored_selection),
		sticky = build_sticky(),
		selection = callback_selection,
		callback = function(response, source)
			chat_history.save(response, { used_prompt = prompts[target], tag = "Review" })
			set_diagnostic(response, source)
			return response
		end,
	})
end

--- Restore selection and open window for the given review action.
---@param target ReviewTarget
local function on_selected_target(target)
	selection.restore(function(restored_selection)
		open_window(target, restored_selection)
	end)
end

M.execute = function()
	local targets = { "Code", "Spelling" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		on_selected_target(target)
	end)
end

return M
