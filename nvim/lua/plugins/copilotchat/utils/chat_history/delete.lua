local CHAT_HISTORY_DIR = vim.fn.stdpath("data") .. "/copilotchat_history"

local function old_files()
	local scandir = require("plenary.scandir")

	local files = scandir.scan_dir(CHAT_HISTORY_DIR, {
		search_pattern = "%.json$",
		depth = 1,
	})

	local current_time = os.time()
	local one_month_ago = current_time - (30 * 24 * 60 * 60) -- 30 days in seconds
	local deleted_count = 0

	for _, file in ipairs(files) do
		local mtime = vim.fn.getftime(file)

		if mtime < one_month_ago then
			local success, err = os.remove(file)
			if success then
				deleted_count = deleted_count + 1
			else
				vim.notify("Failed to delete old chat file: " .. err, vim.log.levels.WARN)
			end
		end
	end

	if deleted_count > 0 then
		vim.notify("Deleted " .. deleted_count .. " old chat files", vim.log.levels.INFO)
	end
end

return {
	CHAT_HISTORY_DIR = CHAT_HISTORY_DIR,
	old_files = old_files,
}
