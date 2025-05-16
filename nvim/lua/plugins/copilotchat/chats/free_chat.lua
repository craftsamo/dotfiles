local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local contexts_module = require("plugins.copilotchat.contexts")
local characters = contexts_module.characters
local roles = contexts_module.roles

local new_window = require("plugins.copilotchat.utils.open_window").new_window

local function free_chat()
	vim.ui.select(characters, { prompt = "Select character> " }, function(character)
		if not character or character == "" then
			character = "Friendly"
		end
		vim.ui.select(roles, { prompt = "Select role> " }, function(role)
			if not role or role == "" then
				role = "Teacher"
			end

			new_window(nil, {
				sticky = {
					"/SysytemPromptChat",
					"#reply_language:" .. language,
					"#character:" .. character,
					"#role:" .. role,
				},
				selection = false,
				window = {
					layout = "float",
					relative = "cursor",
					width = 1,
					height = 0.8,
					row = 1,
				},
			})
		end)
	end)
end

return free_chat
