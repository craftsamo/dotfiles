return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    -- debug = true,
    -- log_level = "debug",
    show_help = "yes",
    highlight_headers = false,
    separator = "---",
    error_header = "> [!ERROR] Error",

    dependencies = {
      { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
      { "ibhagwan/fzf-lua" },
    },
    build = "make tiktoken", -- Only on MacOS or Linux

    opts = function(_, options)
      ---@param response string
      options.callback = function(response)
        require("plugins.copilotchat.utils.chat_history").save(response, {
          used_prompt = nil,
          tag = "NewChat",
        })
        return response
      end
      options.providers = require("plugins.copilotchat.providers").providers
      options.prompts = require("plugins.copilotchat.prompts").prompts
      options.contexts = require("plugins.copilotchat.contexts").contexts
      options.window = require("plugins.copilotchat.window").window
    end,

    keys = require("plugins.copilotchat.keymaps").keymaps,
  },
}
