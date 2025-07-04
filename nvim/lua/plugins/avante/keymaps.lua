--- Keymaps for the Avante plugin
-- This table defines custom key mappings and modes for the Avante plugin.

local commit_actions = require("plugins.avante.actions.commit")
local docstring = require("plugins.avante.actions.docstring")

return {
  -- Group
  { "<leader>a", "", desc = "Avante", mode = { "n", "v" } },
  { "<leader>ac", "", desc = "Avante - Commands", mode = { "n", "v" } },

  commit_actions.commit_group,
  commit_actions.base_commit,
  commit_actions.squash_commit,
  docstring.add,
}
