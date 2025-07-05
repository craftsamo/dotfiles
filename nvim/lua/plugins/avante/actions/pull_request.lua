local utils = require("plugins.avante.actions.utils")

local M = {}

local common_notes = [[
**NOTE**:
- Please prioritize using the `execute_command` tool of use_mcp_tool.
]]

local create_prompt =
  "Prepare the following steps and then create a Pull Request to merge {{current_branch}} into {{base_branch}}."

local create_steps = [[
1. Think about the title of the Pull Request, keeping the following points in mind:
  - The title must be no longer than 50 characters.
  - Start with a verb (e.g., Add xx, Fix xx, Enable xx).
  - Summarize the overall purpose of the changes in `git diff {{base_branch}}`.

2. Locate the `PULL_REQUEST_TEMPLATE.*` or `pull_request_template.*` file to understand the rules.
  - It is most likely located in the `.github` directory.
  - Occasionally, it might be found in the `docs` directory.
  - If the template is still unclear, refer to the last 5 Pull Requests for guidance.
  - If you still can’t understand the template from the last 5 Pull Requests, use the following structure:
    - Summary: `text`
    - Changes: `text`
    - References to related Issues, Pull Requests, or Discussions: `list`
    - Breaking changes: checkbox (Yes or No)

3. At this point, take a moment to consider the following:
  - The language to use for the Pull Request title and description.
    - If there is not enough information, refer to the most recent 5 Pull Requests.
  - Strictly follow the above Pull Request template.
    - Do not omit items.
    - Do not omit items in checkboxes that are not selected.
    - Comment out can be omitted.
  - Carefully analyze the content of `git diff {{base_branch}}` and write the body based on it.

4. Create a new Pull Request with the content you thought of.
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

M.pullrequest_group = utils.build_keymap("<leader>aP", nil, "PullRequest", "n")
M.create_pullrequest = utils.build_keymap("<leader>aPc", create_pullrequest, "Create", "n")

return M
