return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		opts = {
			provider = "copilot",
			auto_suggestions_provider = "copilot",
			behaviour = {
				auto_suggestions = true,
				auto_set_highlight_group = true,
				auto_set_keymaps = false,
				auto_apply_diff_after_generation = true,
				support_paste_from_clipboard = true,
			},
			windows = {
				position = "right",
				width = 50,
				sidebar_header = {
					align = "center",
					rounded = false,
				},
				ask = {
					floating = true,
					start_insert = true,
					border = "rounded",
				},
			},
		},
		build = "make",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"echasnovski/mini.pick", -- for file_selector provider mini.pick
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"ibhagwan/fzf-lua", -- for file_selector provider fzf
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
		},

		config = function(_, opts)
			local avante = require("avante")
			local avante_api = require("avante.api")
			avante.setup(opts)

			vim.keymap.set("n", "<leader>av", "", { desc = "Avante" })

			-- Toggle
			vim.keymap.set("n", "<leader>avt", "", { desc = "Toggle" })

			---- Window
			vim.keymap.set("n", "<leader>avtw", function()
				avante.toggle()
			end, { desc = "Window" })

			---- Debug
			vim.keymap.set("n", "<leader>avtd", function()
				avante.toggle.debug()
			end, { desc = "Debug" })

			----  Hint
			vim.keymap.set("n", "<leader>avth", function()
				avante.toggle.hint()
			end, { desc = "Hint" })

			---- Suggestion
			vim.keymap.set("n", "<leader>avts", function()
				avante.toggle.suggestion()
			end, { desc = "Suggestion" })

			-- Chat
			vim.keymap.set("n", "<leader>avc", "", { desc = "Chat" })
			vim.keymap.set({ "n", "v" }, "<leader>avcc", avante_api.ask, { desc = "Chat" })
			vim.keymap.set({ "n", "v" }, "<leader>avcn", function()
				avante_api.ask({ new_chat = true })
			end, { desc = "New Chat" })

			-- Edit
			vim.keymap.set("v", "<leader>ave", avante_api.edit, { desc = "Edit" })

			-- Stop
			vim.keymap.set("n", "<leader>avS", avante_api.stop, { desc = "Stop" })

			-- Refresh
			vim.keymap.set("n", "<leader>avr", function()
				avante_api.refresh()
			end, { desc = "Refresh" })

			-- Focus
			vim.keymap.set("n", "<leader>avf", avante_api.focus, { desc = "Focus Window" })

			-- Display repo map
			vim.keymap.set("n", "<leader>avR", require("avante.repo_map").show, { desc = "Display Repo Map" })

			-- Chat History
			vim.keymap.set("n", "<leader>avh", avante_api.select_history, { desc = "Chat History" })

			-- Add all buffers
			vim.keymap.set("n", "<leader>ava", "", { desc = "Add contexts" })
			vim.keymap.set("n", "<leader>avab", avante_api.add_buffer_files, { desc = "All Buffers" })
		end,
	},
}
