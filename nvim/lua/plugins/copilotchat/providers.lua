-- Define local providers for CopilotChat
local M = {}

M.providers = {

	-- Local Ollama
	ollama = {

		-- for i = #inputs, 1, -1 do
		-- 	if inputs[i].role == "user" then
		-- 		inputs[i].content = '"/no_think"' .. "\n\n" .. inputs[i].content
		-- 		break
		-- 	end
		-- end
		prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,

		-- Remove <think> tags and leading whitespace from the content string, if present.
		-- if content then
		-- 	content = content:gsub("<think>", ""):gsub("</think>", "")
		-- end
		prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,

		get_models = function(headers)
			local response, err = require("CopilotChat.utils").curl_get("http://localhost:11434/v1/models", {
				headers = headers,
				json_response = true,
			})

			if err then
				error(err)
			end

			return vim.tbl_map(function(model)
				return {
					id = model.id,
					name = model.id,
				}
			end, response.body.data)
		end,

		embed = function(inputs, headers)
			local response, err = require("CopilotChat.utils").curl_post("http://localhost:11434/v1/embeddings", {
				headers = headers,
				json_request = true,
				json_response = true,
				body = {
					input = inputs,
					model = "all-minilm",
				},
			})

			if err then
				error(err)
			end

			return response.body.data
		end,

		get_url = function()
			return "http://localhost:11434/v1/chat/completions"
		end,
	},
}

return M
