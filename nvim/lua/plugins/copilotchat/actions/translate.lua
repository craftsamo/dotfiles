local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local function traslation()
	vim.ui.select(languages, {
		prompt = "Select Language> ",
	}, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = language
		end

		require("CopilotChat").ask("Translate the contents of the given Selection with `Content_Language`.", {
			sticky = {
				"/SystemPromptTranslate",
				"#content_language:" .. selected_language,
			},
		})
	end)
end

return traslation
