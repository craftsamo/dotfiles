local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local contexts_module = require("plugins.copilotchat.contexts")
local characters = contexts_module.characters
local roles = contexts_module.roles

local function free_chat()
	vim.ui.select(characters, {
		prompt = "Select character> ",
	}, function(character)
		if not character or character == "" then
			character = "Friendly"
		end
		vim.ui.select(roles, {
			prompt = "Select character> ",
		}, function(role)
			if not role or role == "" then
				role = "Teacher"
			end

			local input = vim.fn.input("Chat: ")
			if not input or input == "" then
				return
			end

			require("CopilotChat").ask(input, {
				sticky = {
					"/SysytemPromptChat",
					"#reply_language:" .. language,
					"#character:" .. character,
					"#role:" .. role,
				},
				selection = false,
			})
		end)
	end)
end

return free_chat
