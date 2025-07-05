local M = {}

local utils = require("plugins.avante.actions.utils")

local common_notes = [[
**NOTE**:
- Please prioritize using the `execute_command` tool of use_mcp_tool.
]]

local base_commit_prompt =
  "After preparing with the following steps, execute the commit with clear and concise content."

local base_commit_steps = [[
0. Prefer using the `execute_command` tool from use_mcp_tool.

1. Check for `commitlint.config.js` or `.cz-config.js` to identify the commit rules.
   - If the file isn’t found, run `git log -n 5` to review the last 5 commits and infer the rules.
   - If the rules are still unclear, follow the "commitzen convention" based on past commits.

2. Run `git status` to see the files staged for commit.

3. Use `git diff --cached` to review the staged changes.

4. Commit the changes with `git commit` based on the gathered information.
   - **DO NOT** use `\n` for line breaks after the second line! Instead, use the `-m` option.
     - GOOD: `git commit -m <type>: <short_message> -m <message> -m <message>`
     - BAD: `git commit -m <type>: <short_message>\n\n<message>\n\n<message>`

5. Ensure the commit format is valid and adheres to the rules.
]]

local function base_commit()
  local prompt = base_commit_prompt .. "\n\n" .. base_commit_steps .. "\n\n" .. common_notes
  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

local squash_commit_prompt =
  'Output clear and concise "Squash commit" content after preparation in the following steps.'

local squash_commit_steps = [[
0. Prefer using the `execute_command` tool from use_mcp_tool.

1. Check for `commitlint.config.js` or `.cz-config.js` to identify the commit rules.
   - If the file isn’t found, run `git log -n 5` to review the last 5 commits and infer the rules.
   - If the rules are still unclear, follow the "commitzen convention" based on past commits.

2. Use `git log {{base_branch}}..{{current_branch}} --reverse --pretty="%an -> %s"` to review the commit messages being aggregated.

3. Run `git diff {{base_branch}}` to examine the differences from the SquashMerge target and understand the changes.

4. Identify relevant pull requests based on the collected information.
  - Ensure the pull request is currently open.

5. At this stage, carefully consider the commit content.
  - Focus on the consolidated message, keeping in mind that multiple commits will be merged into a single commit.

6. Ensure the final formatting adheres to the following structure:
  - Replace values enclosed in `< >` appropriately.
  - `< >` with a trailing `?` is optional and can be omitted if not applicable in the original commit.

```gitcommit
<type>(<scope>?): <short_message>(#pullrequest_number>?)

<header>

---
<username> --> <type>(<scope>?): <short_message> or <type>(<scope>?): <short_message>(#<pullrequest_number>?)
<... Include all commits retrieved with the command.>
---
```
]]

local function squash_commit()
  local selected_branch = utils.select_branch()
  if not selected_branch then
    return
  end

  local steps = utils.interpolate(squash_commit_steps, {
    current_branch = utils.get_current_branch(),
    base_branch = selected_branch,
  })

  local prompt = squash_commit_prompt .. "\n\n" .. steps .. "\n\n" .. common_notes
  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

M.commit_group = utils.build_keymap("<leader>aC", nil, "Commit", "n")
M.base_commit = utils.build_keymap("<leader>aCb", base_commit, "BaseCommit", "n")
M.squash_commit = utils.build_keymap("<leader>aCs", squash_commit, "SquashCommit", "n")

return M
