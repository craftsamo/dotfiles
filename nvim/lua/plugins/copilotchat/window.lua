-- Window management functions
local M = {}

M.window = {
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

return M
