return {
	{
		"saghen/blink.cmp",
		optional = true,

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},
}
