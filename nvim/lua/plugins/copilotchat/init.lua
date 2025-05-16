return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",

		-- debug = true,
		-- log_level = "debug",
		show_help = "yes",
		highlight_headers = false,
		separator = "---",
		error_header = "> [!ERROR] Error",

		dependencies = {
			{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux

		opts = function(_, options)
			options.providers = require("plugins.copilotchat.providers").providers
			options.prompts = require("plugins.copilotchat.prompts").prompts
			options.contexts = require("plugins.copilotchat.contexts").contexts
			options.window = require("plugins.copilotchat.window").window
		end,
	},

	require("plugins.copilotchat.keymaps"),
}
