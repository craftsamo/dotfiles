return {

	--  Perplexity Search
	perplexity_search = vim.keymap.set({ "n", "v" }, "<leader>acs", function()
		local input = vim.fn.input("Perplexity: ")
		if input ~= "" then
			require("CopilotChat").ask(input, {
				agent = "perplexityai",
				sticky = { "/SystemPromptInstructions", "#reply_language:" .. language },
				selection = false,
			})
		end
	end, { desc = "CopilotChat - Search" }),
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

	-- Chat
	chat = vim.keymap.set(
		{ "n", "v" },
		"<leader>acch",
		require("plugins.copilotchat.actions.free_chat"),
		{ desc = "CopilotChat - Chat" }
	),


	-- Translation
	translation = vim.keymap.set(
		{ "n", "v" },
		"<leader>act",
		require("plugins.copilotchat.actions.translate"),
		{ desc = "CopilotChat - Translation Selection" }
	),
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

	-- Output Template
	output_template = vim.keymap.set(
		{ "n", "v" },
		"<leader>aco",
		require("plugins.copilotchat.actions.output_template"),
		{ desc = "CopilotChat - Output template" }
	),


	-- Fix bugs
	fix_bugs = vim.keymap.set(
		{ "n", "v" },
		"<leader>acf",
		require("plugins.copilotchat.actions.fix_bugs"),
		{ desc = "CopilotChat - Fix bugs" }
	),

	-- Analize Code
	analize_code = vim.keymap.set(
		{ "n", "v" },
		"<leader>aca",
		require("plugins.copilotchat.actions.analize_code"),
		{ desc = "CopilotChat - Analize code" }
	),
}
