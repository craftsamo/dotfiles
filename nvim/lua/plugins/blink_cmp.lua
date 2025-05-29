return {
	{
		"saghen/blink.cmp",
		optional = true,
		dependencies = {
			"Kaiser-Yang/blink-cmp-avante",
		},

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			sources = {
				default = { "avante", "lsp", "path", "snippets", "buffer" },
				providers = {
					avante = {
						module = "blink-cmp-avante",
						name = "Avante",
						opts = {},
					},
					path = {
						enabled = function()
							return vim.bo.filetype ~= "copilot-chat" and vim.bo.filetype ~= "AvanteInput"
						end,
					},
				},
			},
		},
	},
}
