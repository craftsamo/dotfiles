return {
  "ravitemer/mcphub.nvim",

  build = "npm install -g mcp-hub@latest",

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    require("mcphub").setup({
      native_servers = {},
      extensions = {
        avante = {
          make_slash_commands = true, -- make /slash commands from MCP server prompts
        },
      },

      ---@type boolean | fun(parsed_params: MCPHub.ParsedParams): boolean | nil | string  Function to determine if a call should be auto-approved
      auto_approve = function(params)
        -- Some `execute_command` skips confirmation.
        if params.server_name == "neovim" and params.tool_name == "execute_command" then
          local command = params.arguments.command or ""
          if
            string.match(command, "^git status") -- git status *
            or string.match(command, "^git diff") -- git diff *
            or string.match(command, "^git log") -- git log *
          then
            return true
          end
        end

        -- Check if tool is configured for auto-approval in servers.json
        if params.is_auto_approved_in_server then
          return true -- Respect servers.json configuration
        end

        -- Show confirmation prompt
        return false
      end,
    })
  end,
}
