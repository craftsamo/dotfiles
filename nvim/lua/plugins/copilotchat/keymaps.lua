return {

	-- Toggle window
	{ "<leader>at", "", desc = "Toggle window", mode = { "n", "v" } },
	{
		"<leader>atv",
		require("plugins.copilotchat.utils.window").toggle_vertical,
		desc = "Vertical",
		mode = { "n", "v" },
	},
	{
		"<leader>atf",
		require("plugins.copilotchat.utils.window").toggle_float,
		desc = "Float",
		mode = { "n", "v" },
	},

	-- Clear
	{
		"<leader>ax",
		require("plugins.copilotchat.utils.window").clear,
		desc = "Clear",
		mode = { "n", "v" },
	},

	-- List chat history
	{
		"<leader>ah",
		require("plugins.copilotchat.utils.chat_history").list,
		desc = "List chat history",
		mode = { "n", "v" },
	},

	-- Explain
	{
		"<leader>ae",
		require("plugins.copilotchat.actions.explain").execute,
		desc = "Explain",
		mode = { "n", "v" },
	},

	-- Review
	{
		"<leader>ar",
		require("plugins.copilotchat.actions.review").execute,
		desc = "Review",
		mode = { "n", "v" },
	},

	-- Fix
	{
		"<leader>af",
		require("plugins.copilotchat.actions.fix").execute,
		desc = "Fix",
		mode = { "n", "v" },
	},

	-- Document
	{
		"<leader>ad",
		require("plugins.copilotchat.actions.document").execute,
		desc = "Document",
		mode = { "n", "v" },
	},

	-- Analyze
	{
		"<leader>aa",
		require("plugins.copilotchat.actions.analyze").execute,
		desc = "Analyze",
		mode = { "n", "v" },
	},

	-- Optimize
	{
		"<leader>ao",
		require("plugins.copilotchat.actions.optimize").execute,
		desc = "Optimize",
		mode = { "n", "v" },
	},

	-- Generate
	{
		"<leader>ag",
		require("plugins.copilotchat.actions.generate").execute,
		desc = "Generate",
		mode = { "n", "v" },
	},

	-- Chat
	{
		"<leader>aC",
		require("plugins.copilotchat.actions.chat").open,
		desc = "Open chat",
		mode = { "n", "v" },
	},

	-- Commit
	{
		"<leader>ac",
		require("plugins.copilotchat.actions.commit").execute,
		desc = "Commit",
		mode = { "n", "v" },
	},

	-- Utils
	{ "<leader>au", "", desc = "Utils", mode = { "n", "v" } },
	{
		"<leader>aT",
		require("plugins.copilotchat.actions.translate").execute,
		desc = "Translate",
		mode = { "n", "v" },
	},
	{
		"<leader>auo",
		require("plugins.copilotchat.actions.utils.output_template"),
		desc = "Output template",
		mode = { "n", "v" },
	},
}
