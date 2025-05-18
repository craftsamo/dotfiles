local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language

local prompt = [[
Generate a concise and natural-sounding title in %s that accurately describes the purpose or functionality of the following conversation.

Requirements:
- Start the title with an appropriate action verb (e.g., “explain”, “generate”, “improve”, “analyze”, etc.) that best summarizes what is being done in the content. Choose the action verb **based on the content itself**, not from a fixed list.
- Use the following format: `Action: Contents`
- Use natural, descriptive language instead of keyword lists.
- Keep the entire title within 10 words (including the action).
- Use hyphens (-) to join words in the "Contents" part so it is safe for filenames.
- Do not include characters other than hyphens in the filename part.
- Output only the title — no explanations or formatting like code blocks.

Conversation:
```
%s
```
]]

---@param response string
---@param source CopilotChat.source
local function save_chat(response, source)
	local chat = require("CopilotChat")

	if vim.g.copilot_chat_title then
		chat.save(vim.g.copilot_chat_title)
		return
	end

	-- Use AI to generate prompt title based on first AI response to user question
	chat.ask(vim.trim(prompt:format(language, response)), {
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
