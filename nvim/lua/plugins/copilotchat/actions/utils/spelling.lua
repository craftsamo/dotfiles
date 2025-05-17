local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

local function spelling()
	new_vertical_window("Check the spelling of the characters contained in the selected range.", {
		sticky = {
			"/SystemPromptSpelling",
		},
	})
end

return spelling
