local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")

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
		vim.ui.select(system_languages.names, { prompt = "Select content language> " }, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = system_languages.default
			end

			window.open_float(
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
