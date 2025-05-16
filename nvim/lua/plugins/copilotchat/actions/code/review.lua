local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

local function review_code()
	new_vertical_window('Review the "selected code".', {
		sticky = {
			"/SystemPromptReview",
			"#reply_language:" .. language,
		},
	})
end

return review_code
