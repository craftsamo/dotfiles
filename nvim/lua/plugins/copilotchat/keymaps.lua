return {

	-- Toggle window
	{ "<leader>aw", "", desc = "Toggle window", mode = { "n", "v" } },
	{
		"<leader>awv",
		require("plugins.copilotchat.utils.open_window").toggle_vertical_window,
		desc = "Vertical",
		mode = { "n", "v" },
	},
	{
		"<leader>awf",
		require("plugins.copilotchat.utils.open_window").toggle_inline_window,
		desc = "Float",
		mode = { "n", "v" },
	},

	-- List chat history
	{
		"<leader>ah",
		require("plugins.copilotchat.utils.chat_history.list").list_history,
		desc = "List chat history",
		mode = { "n", "v" },
	},

	--  Perplexity Search
	{
		"<leader>as",
		require("plugins.copilotchat.chats.search"),
		desc = "Perplexity Search",
		mode = { "n", "v" },
	},

	-- Code
	{ "<leader>ac", "", desc = "Code actions", mode = { "n", "v" } },
	{
		"<leader>aca",
		require("plugins.copilotchat.actions.code.analyze"),
		desc = "Analyze",
		mode = { "n", "v" },
	},
	{
		"<leader>acf",
		require("plugins.copilotchat.actions.code.fix_bugs"),
		desc = "Fix bug",
		mode = { "n", "v" },
	},
	{
		"<leader>ace",
		require("plugins.copilotchat.actions.code.explain"),
		desc = "Explain",
		mode = { "n", "v" },
	},
	{
		"<leader>acr",
		require("plugins.copilotchat.actions.code.review"),
		desc = "Review",
		mode = { "n", "v" },
	},

	-- Chats
	{ "<leader>aC", "", desc = "Chat", mode = { "n", "v" } },
	{
		"<leader>aCf",
		require("plugins.copilotchat.chats.free_chat"),
		desc = "Free chat",
		mode = { "n", "v" },
	},

	-- Git
	{ "<leader>ag", "", desc = "Git", mode = { "n", "v" } },
	{
		"<leader>agc",
		require("plugins.copilotchat.actions.git.commit"),
		desc = "Commit",
		mode = { "n", "v" },
	},
	{
		"<leader>agp",
		require("plugins.copilotchat.actions.git.pullrequest"),
		desc = "Pull Request",
		mode = { "n", "v" },
	},

	-- Utils
	{ "<leader>au", "", desc = "Utils", mode = { "n", "v" } },
	{
		"<leader>aus",
		require("plugins.copilotchat.actions.utils.spelling"),
		desc = "Spelling",
		mode = { "n", "v" },
	},
	{
		"<leader>aut",
		require("plugins.copilotchat.actions.utils.translate").translation_vertical,
		desc = "Translate",
		mode = { "n", "v" },
	},

	-- Output
	{ "<leader>ao", "", desc = "Output", mode = { "n", "v" } },
	{
		"<leader>aot",
		require("plugins.copilotchat.actions.output_template"),
		desc = "Template",
		mode = { "n", "v" },
	},
}
