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

	-- Chat
	chat = vim.keymap.set(
		{ "n", "v" },
		"<leader>acch",
		require("plugins.copilotchat.actions.free_chat"),
		{ desc = "CopilotChat - Chat" }
	),

	-- Commit
	commit = vim.keymap.set(
		{ "n", "v" },
		"<leader>acco",
		require("plugins.copilotchat.actions.commit"),
		{ desc = "CopilotChat - Commit" }
	),

	-- Translation
	translation = vim.keymap.set(
		{ "n", "v" },
		"<leader>act",
		require("plugins.copilotchat.actions.translate"),
		{ desc = "CopilotChat - Translation Selection" }
	),

	-- Output Template
	output_template = vim.keymap.set(
		{ "n", "v" },
		"<leader>aco",
		require("plugins.copilotchat.actions.output_template"),
		{ desc = "CopilotChat - Output template" }
	),

	-- Generate Pull Request
	generate_pr = vim.keymap.set(
		{ "n", "v" },
		"<leader>acgp",
		require("plugins.copilotchat.actions.generate_pullrequest"),
		{ desc = "CopilotChat - Generate Pull Request" }
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
