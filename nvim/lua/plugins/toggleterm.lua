return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		opts = function(_, opts)
			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)

			-- scroll
			vim.keymap.set("t", "<S-PageUp>", [[<C-\><C-n><C-b>]], opts)
			vim.keymap.set("t", "<S-PageDown>", [[<C-\><C-n><C-f>]], opts)

			opts.size = 100
			opts.open_mapping = [[<c-\>]]
			opts.hide_numbers = true
			opts.shade_filetypes = {}
			opts.shade_terminals = true
			opts.shading_factor = 2
			opts.start_in_insert = true
			opts.insert_mappings = true
			opts.persist_size = true
			opts.direction = "float"
			opts.close_on_exit = true
			opts.shell = vim.o.shell
			opts.float_opts = {
				border = "curved",
				winblend = 3,
			}
			opts.scrollback = 10000
		end,
	},
}
