local copilot_chat_ns = vim.api.nvim_create_namespace("copilot-chat-diagnostics")
local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

local function review_code()
	new_vertical_window('Review the "selected code".', {
		sticky = {
			"/SystemPromptReview",
			"#reply_language:" .. language,
		},
		callback = function(response, source)
			local diagnostics = {}
			for line in response:gmatch("[^\r\n]+") do
				if line:find("^line=") then
					local start_line = nil
					local end_line = nil
					local message = nil
					local single_match, message_match = line:match("^line=(%d+): (.*)$")
					if not single_match then
						local start_match, end_match, m_message_match = line:match("^line=(%d+)-(%d+): (.*)$")
						if start_match and end_match then
							start_line = tonumber(start_match)
							end_line = tonumber(end_match)
							message = m_message_match
						end
					else
						start_line = tonumber(single_match)
						end_line = start_line
						message = message_match
					end

					if start_line and end_line then
						table.insert(diagnostics, {
							lnum = start_line - 1,
							end_lnum = end_line - 1,
							col = 0,
							message = message,
							severity = vim.diagnostic.severity.WARN,
							source = "Copilot Review",
						})
					end
				end
			end
			vim.diagnostic.set(copilot_chat_ns, source.bufnr, diagnostics)
			return response
		end,
	})
end

return review_code
