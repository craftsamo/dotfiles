local utils = require("plugins.avante.actions.utils")

local M = {}

local common_notes = [[
**NOTE**:
- When using basic commands, use `execute_command` of use_mcp_tool.
- When running `git diff {{base_branch}}`, be careful not to include files such as `package-lock.json` or `yarn.lock`.
]]

--############################################################################
--                            Create PullRequest
--############################################################################

local create_prompt =
  "Think about the content of a Pull Request to merge from {{current_branch}} into {{base_branch}} and create it with use_mcp_tool."

local create_steps = [[
1. The title must begin with a verb (e.g., Add xx, Fix xx, Enable xx), be within 50 characters, and summarize the result of `git diff {{base_branch}}`

2. If `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md` exists, complete the content according to that file.

2-1. If it does not exist, execute `list_pull_requests` to refer to the three most recent Pull Requests and determine the most appropriate format.

3. Run `git log -n 5` and, based on the last 5 commit histories, appropriately determine the language to use for the Pull Request content.

4. The body of the Pull Request should be carefully analyzed based on the content of `git diff {{base_branch}}` and written accordingly.

5. Execute `create_pull_request` to issue the Pull Request:
  - base: {{base_branch}}
  - head: {{current_branch}}
  - owner: {{owner}}
  - repo: {{repo}}
  - title: <Based on step 1, what you think>
  - body: <Based on step 4, what you think>
]]

local function create_pullrequest()
  local selected_branch = utils.select_branch()
  if not selected_branch then
    return
  end

  local title = utils.interpolate(create_prompt, {
    current_branch = utils.get_current_branch(),
    base_branch = selected_branch,
  })

  local steps = utils.interpolate(create_steps, {
    base_branch = selected_branch,
    current_branch = utils.get_current_branch(),
    owner = utils.get_repository_owner(),
    repo = utils.get_repository(),
  })

  local prompt = title .. "\n\n" .. steps .. "\n" .. common_notes

  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

--############################################################################
--                            Search Recent Changes
--############################################################################

local search_recent_changes_prompt =
  'Follow the steps below to investigate the most recent {{number_of_changes}} changes in "{{repository}}" and create a report in Markdown format.'

local search_recent_changes_steps = [[
1. Identify the exact repository name and the owner of the repository from "{{repository}}".
  - When using `search_repositories`, retrieve one page at a time.

2. Retrieve the most recent "{{number_of_changes}}" Pull Requests from GitHub.
  - If any related issues exist, also retrieve their details.

3. Organize the information from the retrieved "{{number_of_changes}}" Pull Requests while paying attention to the following:
  - Infer the purpose of the changes (e.g., adding a feature, improving a feature, fixing a bug, deprecating a feature).
  - Consider the impact these changes have on the users of the library or service.
  - Think about the impact these changes have on the developers of the library.

4. Identify the language the user is using and consider which natural language is most suitable for creating the report.

5. Format the organized information as shown below and save it to `./recent_changes/<date_time>_{{repository}}.md`.
  - Replace values enclosed in `< >` appropriately.

```markdown
# CreatedAt: <date>

Target Repository: {{repository}}

Number of Changes Reviewed: {{number_of_changes}}

---

## <date_adapted>

<Purpose of Change>

[Commit: <hash>](<link>)

[Pull Request: <title>](<link>)

[Issue: <title>](<link>)

## Reason for adapting the change

<Explanation>

## Changes

<Explanation>

## Benefits Gained from the Changes

<Explanation>

---

... <Repeat until the last change>
```
]]

local function search_recent_changes()
  local repository = vim.fn.input("Prompt: repository name")
  if not repository then
    return
  end

  local number_of_changes = vim.fn.input("Prompt: number of changes (1-10)")
  if not number_of_changes then
    return
  end
  if tonumber(number_of_changes) == 0 or tonumber(number_of_changes) > 10 then
    print("The number of cases to be investigated should range from 1 to 10")
    return
  end

  local title = utils.interpolate(search_recent_changes_prompt, {
    repository = repository,
    number_of_changes = number_of_changes,
  })

  local steps = utils.interpolate(search_recent_changes_steps, {
    repository = repository,
    number_of_changes = number_of_changes,
  })

  local prompt = title .. "\n\n" .. steps .. "\n\n" .. common_notes

  local opts = { question = prompt, new_chat = true, without_selection = true }
  require("avante.api").ask(opts)
end

--############################################################################
--                               Export section
--############################################################################

M.group = utils.build_keymap("<leader>aP", nil, "PullRequest", "n")
M.create = utils.build_keymap("<leader>aPc", create_pullrequest, "Create", "n")
M.search_recent_changes = utils.build_keymap("<leader>aPr", search_recent_changes, "Search recent changes", "n")

return M
