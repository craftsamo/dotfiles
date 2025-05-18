local prompt = [[
Generate chat title in short (maximum 10 words) filepath-friendly format for:

```
%s
```

Output only the title and nothing else in your response.
  ]]

local function save_chat(response)
	local chat = require("CopilotChat")

	if vim.g.copilot_chat_title then
		chat.save(vim.g.copilot_chat_title)
		return
	end

	-- Use AI to generate prompt title based on first AI response to user question
	chat.ask(vim.trim(prompt:format(response)), {
		callback = function(gen_response)
			-- Generate timestamp in format YYYYMMDD_HHMMSS
			local timestamp = os.date("%Y%m%d_%H%M%S")
			-- Encode the generated title to make it safe as a filename
			local safe_title = vim.base64.encode(gen_response):gsub("/", "_"):gsub("+", "-"):gsub("=", "")
			vim.g.copilot_chat_title = timestamp .. "_" .. vim.trim(safe_title)
			chat.save(vim.g.copilot_chat_title)
			return gen_response
		end,
		headless = true, -- Disable updating chat buffer and history with this question
	})
end

return save_chat
