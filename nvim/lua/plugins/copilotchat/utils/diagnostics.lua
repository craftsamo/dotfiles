local M = {}

--- Parse Copilot review response and return diagnostics table
--- @param response string: AI response text
--- @param source string: Label indicating the diagnosis source ("source: <message>")
--- @return table: diagnostics list
M.parse_review_response = function(source, response)
	local diagnostics = {}
	for line in response:gmatch("[^\r\n]+") do
		if line:find("^line=") then
			local start_line, end_line, message
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
					source = source or "Copilot Review",
				})
			end
		end
	end
	return diagnostics
end

return M
