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


	-- Chats
	{ "<leader>ac", "", desc = "Chat", mode = { "n", "v" } },
	{
		"<leader>acf",
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

	-- Output Template
	output_template = vim.keymap.set(
		{ "n", "v" },
		"<leader>aco",
		require("plugins.copilotchat.actions.output_template"),
		{ desc = "CopilotChat - Output template" }
	),
	-- Translation
	{ "<leader>at", "", desc = "Translation", mode = { "n", "v" } },
	{
		"<leader>atv",
		require("plugins.copilotchat.actions.translate").traslation_vertical,
		desc = "Vertical",
		mode = { "n", "v" },
	},
	{
		"<leader>atf",
		require("plugins.copilotchat.actions.translate").traslation_float,
		desc = "Float",
		mode = { "n", "v" },
	},

	-- Fix
	{ "<leader>af", "", desc = "Fix", mode = { "n", "v" } },
	{
		"<leader>afb",
		require("plugins.copilotchat.actions.fix_bugs"),
		desc = "Bug",
		mode = { "n", "v" },
	},

	-- Analize
	{ "<leader>aa", "", desc = "Analize", mode = { "n", "v" } },
	{
		"<leader>aac",
		require("plugins.copilotchat.actions.analize_code"),
		desc = "Code",
		mode = { "n", "v" },
	},
}
