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
    })
  end,
}
