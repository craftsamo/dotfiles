local M = {}

local utils = require("plugins.avante.actions.utils")

local base_commit_prompt = "After preparing with the following steps, create a commit with clear and concise content."

local base_commit_steps = [[
1. Look for `commitlint.config.js` or `.cz-config.js` to identify commit rules.
  - If the specified file is not found, run `git log -n 5` to refer to 5 previous commits to understand the rules.
  - Check past commits and follow the "commitzen convention" if the rules are still unclear.

2. Use the `git status` command to see what files are being committed.

3. Use the `git diff --cached` command to see what has changed.
]]

local function base_commit()
  local prompt = base_commit_prompt .. "\n\n" .. base_commit_steps
  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

local squash_commit_prompt =
  'Create the contents of the "Squash commit" with clear and concise content after preparing with the following steps.'

local squash_commit_steps = [[
1. Look for `commitlint.config.js` or `.cz-config.js` to identify commit rules.
  - If the specified file is not found, run `git log -n 5` to refer to 5 previous commits to understand the rules.
  - Check past commits and follow the "commitzen convention" if the rules are still unclear.

2. `git log <base_branch>..<current_branch> --reverse --pretty="%an -> %s"` to get the contents of the commit being aggregated.

3. Ensure the following format is added to the end of the commit message.
  - Values enclosed in `<>` are replaced appropriately.
  - `<>` with a final `? ` is optional and can be omitted if not set in the original commit.

```gitcommit
---
<username> --> <type>(<scope>?): <short_message> or <type>(<scope>?): <short_message>(#<pullrequest_number>?)
<... Include all commits retrieved with the command.>
---
```
]]

local function squash_commit()
  local prompt = squash_commit_prompt .. "\n\n" .. squash_commit_steps
  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

M.commit_group = utils.build_keymap("<leader>acc", base_commit, "Commit", "n")
M.base_commit = utils.build_keymap("<leader>accb", base_commit, "BaseCommit", "n")
M.squash_commit = utils.build_keymap("<leader>accs", squash_commit, "SquashCommit", "n")

return M
