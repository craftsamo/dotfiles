local prompts_module = require("plugins.copilotchat.prompts")
local languages = prompts_module.languages

local open_window = require("plugins.copilotchat.utils.open_window")

---@param style "vertical" | "float"
local function traslation(style)
	vim.ui.select(languages, {
		prompt = "Select Language> ",
	}, function(selected_language)
		if not selected_language or selected_language == "" then
			return
		end

		local prompt = "Translate the contents of the given Selection with `Content_Language`."
		local sticky = {
			"/SystemPromptTranslate",
			"#content_language:" .. selected_language,
		}

		if style == "vertical" then
			open_window.new_vertical_window(prompt, {
				sticky = sticky,
			})
		elseif style == "float" then
			open_window.new_float_window(prompt, {
				sticky = sticky,
			})
		end
	end)
end

local function traslation_vertical()
	traslation("vertical")
end

local function traslation_float()
	traslation("float")
end

return {
	traslation = traslation,
	traslation_vertical = traslation_vertical,
	traslation_float = traslation_float,
}
