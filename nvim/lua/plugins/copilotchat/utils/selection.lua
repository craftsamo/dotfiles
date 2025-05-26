---@alias RestoreSelection CopilotChat.select.selection|nil

local M = {}

---@param callback fun(selection?: RestoreSelection)
---@param delay_ms? number
M.restore = function(callback, delay_ms)
	delay_ms = delay_ms or 20

	vim.cmd("normal! gv")

	vim.defer_fn(function()
		local chat = require("CopilotChat")
		local selection = chat.get_selection()
		callback(selection)
	end, delay_ms)
end

return M
