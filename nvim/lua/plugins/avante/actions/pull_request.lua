local utils = require("plugins.avante.actions.utils")

local M = {}

local common_notes = [[
**NOTE**:
- Please prioritize using the `execute_command` tool of use_mcp_tool.
]]

--############################################################################
--                            Create PullRequest
--############################################################################

local create_prompt =
  "Prepare the following steps and then create a Pull Request to merge {{current_branch}} into {{base_branch}}."

local create_steps = [[
1. Think about the title of the Pull Request, keeping the following points in mind:
  - The title must be no longer than 50 characters.
  - Start with a verb (e.g., Add xx, Fix xx, Enable xx).
  - Summarize the overall purpose of the changes in `git diff {{base_branch}}`.

2. Locate the `PULL_REQUEST_TEMPLATE` or `pull_request_template` file (.md or .yaml or .yml) to understand the rules.
  - It is most likely located in the `.github` directory.
  - Occasionally, it might be found in the `docs` directory.
  - If the template is still unclear, refer to the last 5 Pull Requests for guidance.
  - If you still can’t understand the template from the last 5 Pull Requests, use the following structure:
    - Summary: `text`
    - Changes: `text`
    - References to related Issues, Pull Requests, or Discussions: `list`
    - Breaking changes: checkbox (Yes or No)

3. Consider which language is most appropriate for creating the title and body of the Pull Request.
  - If there is insufficient information, refer to the most recent 5 Pull Requests for guidance.

4. Consider the body of the Pull Request.
  - Strictly adhere to the above Pull Request template.
    - You may omit commented-out sections.
    - Do not omit any sections under any circumstances.
    - Do not omit items within sections, such as checkboxes, even if you do not plan to check them.
  - Carefully analyze the content of `git diff {{base_branch}}` and write the body based on it.

5. Create a new Pull Request with the content you thought of.
  - owner: {{owner}}
  - repo: {{repo}}
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
    owner = utils.get_repository_owner(),
    repo = utils.get_repository(),
  })

  local prompt = title .. "\n\n" .. steps .. "\n\n" .. common_notes

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

M.pullrequest_group = utils.build_keymap("<leader>aP", nil, "PullRequest", "n")
M.create_pullrequest = utils.build_keymap("<leader>aPc", create_pullrequest, "Create", "n")
M.search_recent_changes = utils.build_keymap("<leader>aPr", search_recent_changes, "Search recent changes", "n")

return M
