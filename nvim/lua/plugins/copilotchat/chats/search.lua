local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function perplexity_search()
	local input = vim.fn.input("Search: ")
	if input == "" then
		return
	end

	new_window(input, {
		agent = "perplexityai",
		sticky = {
			"#reply_language:" .. language,
			"#character:Sociable",
			"#role:Teacher",
		},
		selection = false,
	})
end

return perplexity_search
