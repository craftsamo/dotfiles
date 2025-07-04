local M = {}

local utils = require("plugins.avante.actions.utils")

local base_commit_prompt =
  "After preparing with the following steps, execute the commit with clear and concise content."

local base_commit_steps = [[
0. use_mcp_tool's `execute_command` tool as preferred.

1. Look for `commitlint.config.js` or `.cz-config.js` to identify commit rules.
  - If the specified file is not found, run `git log -n 5` to refer to 5 previous commits to understand the rules.
  - Check past commits and follow the "commitzen convention" if the rules are still unclear.

2. Use the `git status` command to see what files are being committed.

3. Use the `git diff --cached` command to see what has changed.

4. Commit your changes with the `git commit` command based on the information you have obtained.
  - **DO NOT** use `\n` for line breaks after the second line! Use the `-m` option!

5. Verify that the executed commit is not in an invalid format.
]]

local function base_commit()
  local prompt = base_commit_prompt .. "\n\n" .. base_commit_steps
  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

local squash_commit_prompt =
  'Output clear and concise "Squash commit" content after preparation in the following steps.'

local squash_commit_steps = [[
0. use_mcp_tool's `execute_command` tool as preferred.

1. Look for `commitlint.config.js` or `.cz-config.js` to identify commit rules.
  - If the specified file is not found, run `git log -n 5` to refer to 5 previous commits to understand the rules.
  - Check past commits and follow the "commitzen convention" if the rules are still unclear.

2. `git log <base_branch>..<current_branch> --reverse --pretty="%an -> %s"` to get the contents of the commit being aggregated.

3. Run `git diff <base_branch>` to get the differences from the SquashMerge target and understand the changes.

4. Finally, to ensure the following formatting.
  - Values enclosed in `<>` are replaced appropriately.
  - `<>` with a final `? ` is optional and can be omitted if not set in the original commit.

```gitcommit
... <commitments considered based on previous content>

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

M.commit_group = utils.build_keymap("<leader>aC", base_commit, "Commit", "n")
M.base_commit = utils.build_keymap("<leader>aCb", base_commit, "BaseCommit", "n")
M.squash_commit = utils.build_keymap("<leader>aCs", squash_commit, "SquashCommit", "n")

return M
