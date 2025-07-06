--- Keymaps for the Avante plugin
-- This table defines custom key mappings and modes for the Avante plugin.

local commit_actions = require("plugins.avante.actions.commit")
local pull_request = require("plugins.avante.actions.pull_request")
local docstring = require("plugins.avante.actions.docstring")

return {
  -- Group
  { "<leader>a", "", desc = "Avante", mode = { "n", "v" } },
  -- { "<leader>aC", "", desc = "Avante - Commands", mode = { "n", "v" } },

  commit_actions.commit_group,
  commit_actions.base_commit,
  commit_actions.squash_commit,

  pull_request.pullrequest_group,
  pull_request.create_pullrequest,
  pull_request.search_recent_changes,

  docstring.group,
  docstring.add,
}
