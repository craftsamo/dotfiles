local float_window = {
	layout = "float",
	relative = "cursor",
	width = 1,
	height = 0.8,
	row = 1,
}

---@param opts CopilotChat.config
local function ensure_opts(opts)
	return opts or {}
end

---@param prompt string | nil
---@param opts CopilotChat.config
local function new_window(prompt, opts)
	local chat = require("CopilotChat")
	vim.g.copilot_chat_title = nil
	chat.reset()
	if prompt and prompt ~= "" then
		chat.ask(prompt, opts)
	else
		chat.open(opts)
	end
end

local function new_float_window(prompts, opts)
	opts = ensure_opts(opts)
	opts.window = float_window
	new_window(prompts, opts)
end

local function new_vertical_window(prompts, opts)
	opts = ensure_opts(opts)
	opts.window = { layout = "vertical" }
	new_window(prompts, opts)
end

---@param style string | "float" | "vertical"
---@param opts CopilotChat.config
local function toggle_window(style, opts)
	local chat = require("CopilotChat")
	opts = ensure_opts(opts)
	if style == "float" then
		opts.window = float_window
	else
		opts.window = { layout = "vertical" }
	end
	chat.open(opts)
end

local function toggle_inline_window(opts)
	toggle_window("float", opts)
end

local function toggle_vertical_window(opts)
	toggle_window("vertical", opts)
end

return {
	new_window = new_window,
	new_float_window = new_float_window,
	new_vertical_window = new_vertical_window,
	toggle_window = toggle_window,
	toggle_inline_window = toggle_inline_window,
	toggle_vertical_window = toggle_vertical_window,
}
