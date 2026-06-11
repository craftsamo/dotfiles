return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
		ft = { "markdown", "norg", "rmd", "org", "codecompanion", "octo" },

		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			quote = { repeat_linebreak = true },
			win_options = {
				showbreak = {
					default = "",
					rendered = "  ",
				},
				breakindent = {
					default = false,
					rendered = true,
				},
				breakindentopt = {
					default = "",
					rendered = "",
				},
			},
			link = {
				image = vim.g.neovim_mode == "skitty" and "" or "󰥶 ",
			},
			code = {
				sign = true,
			},
			html = {
				enabled = true,
				comment = {
					conceal = false,
				},
			},
			heading = {
				sign = false,
				icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
			},
			checkbox = {
				enabled = true,
				custom = {
					important = {
						raw = "[~]",
						rendered = "󰓎 ",
						highlight = "DiagnosticWarn",
					},
				},
				unchecked = {
					-- Replaces '[ ]' of 'task_list_marker_unchecked'
					icon = "   󰄱 ",
					-- Highlight for the unchecked icon
					highlight = "RenderMarkdownUnchecked",
					-- Highlight for item associated with unchecked checkbox
					scope_highlight = nil,
				},
				checked = {
					-- Replaces '[x]' of 'task_list_marker_checked'
					icon = "   󰱒 ",
					-- Highlight for the checked icon
					highlight = "RenderMarkdownChecked",
					-- Highlight for item associated with checked checkbox
					scope_highlight = nil,
				},
			},
			overrides = {
				filetype = {
					["octo"] = {
						indent = { enabled = false },
					},
				},
			},
		},
	},
}
