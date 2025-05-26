local copilotchat = require("CopilotChat")

---@class WindowOpts: CopilotChat.config
---@field draft_prompt string|nil

local M = {}

M.float_window = {
	layout = "float",
	relative = "cursor",
	width = 1,
	height = 0.8,
	row = 1,
}

M.reset_title = function()
	vim.g.copilot_chat_title = nil
end

M.reset_chat = function()
	copilotchat.reset()
end

M.clear = function()
	M.reset_title()
	M.reset_chat()
end

---@param prompt string | nil
---@param opts WindowOpts
M.open = function(prompt, opts)
	M.clear()
	if prompt and prompt ~= "" then
		copilotchat.ask(prompt, opts)
	else
		copilotchat.open(opts)
		if opts.draft_prompt and opts.draft_prompt ~= "" then
			vim.schedule(function()
				vim.cmd("normal! gv")
				copilotchat.chat:set_prompt(opts.draft_prompt)
				vim.schedule(function()
					if opts.sticky then
						local stickies = type(opts.sticky) == "table" and opts.sticky or { opts.sticky }
						for _, sticky in ipairs(stickies) do
							if sticky and sticky ~= "" then
								copilotchat.chat:add_sticky(sticky)
							end
						end
					end
				end)
			end)
		end
	end
end

---@param prompt string
---@param opts WindowOpts
M.open_float = function(prompt, opts)
	opts = opts or {}
	opts.window = M.float_window
	M.open(prompt, opts)
end

---@param prompt string
---@param opts WindowOpts
M.open_vertical = function(prompt, opts)
	opts = opts or {}
	opts.window = { layout = "vertical" }
	M.open(prompt, opts)
end

---@param opts WindowOpts
M.toggle = function(opts)
	copilotchat.open(opts)
end

---@param opts WindowOpts
M.toggle_float = function(opts)
	opts = opts or {}
	opts.window = M.float_window
	M.toggle(opts)
end

---@param opts WindowOpts
M.toggle_vertical = function(opts)
	opts = opts or {}
	opts.window = { layout = "vertical" }
	M.toggle(opts)
end

return M
