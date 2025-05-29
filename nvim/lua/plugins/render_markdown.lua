return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
		ft = { "markdown", "norg", "rmd", "org", "codecompanion", "copilot-chat", "octo" },

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
			code = {
				sign = true,
			},
			heading = {
				sign = true,
				position = "inline",
				icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			},
			indent = {
				enabled = true,
				skip_level = 0,
				icon = "|",
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
			},
			overrides = {
				filetype = {
					["copilot-chat"] = {
						indent = { enabled = false },
					},
					["Avante"] = {
						indent = { enabled = false },
					},
					["octo"] = {
						indent = { enabled = false },
					},
				},
			},
		},
	},
}
