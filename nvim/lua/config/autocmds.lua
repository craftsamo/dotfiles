-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc", "markdown" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
})

-- Sync :terminal ANSI palette with Ghostty. solarized-osaka maps both 0/8 to
-- c.black and both 7/15 to c.fg, which makes dim text (ANSI 8) invisible and
-- white (7) indistinguishable from bright white (15) inside :terminal.
local function sync_terminal_palette()
	vim.g.terminal_color_7 = "#c8d2e0" -- white (soft, matches Ghostty palette 7)
	vim.g.terminal_color_8 = "#5a6577" -- bright black (dim text, matches Ghostty palette 8)
end
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "solarized-osaka",
	callback = sync_terminal_palette,
})
-- The colorscheme is already applied by the time autocmds load (LazyVim
-- defers this file to VeryLazy), so sync once immediately as well.
sync_terminal_palette()
