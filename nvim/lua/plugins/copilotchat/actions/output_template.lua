local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local languages = prompts_module.languages

local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

local function output_teplate()
	vim.ui.select({
		"Proposal",
		"BasicDesign",
		"FrontendDesign",
		"BackendDesign",
		"DatabaseDesign",
		"GitDesign",
		"InfraDesign",
	}, {
		prompt = "Select Template> ",
	}, function(content)
		if not content or content == "" then
			return
		end
		vim.ui.select(languages, { prompt = "Select content language> " }, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = language
			end

			new_float_window(
				"Output the contents of the provided `"
					.. content
					.. ".yaml` file with complete markdown. \n!! Translate the output into the language of the `Content_Language`.",
				{
					sticky = {
						"/SystemPromptOutputTemplate",
						"#content_language:" .. selected_language,
						"#file:~/.config/nvim/lua/plugins/copilotchat/templates/" .. content .. ".yaml",
					},
					selection = false,
				}
			)
		end)
	end)
end

return output_teplate
