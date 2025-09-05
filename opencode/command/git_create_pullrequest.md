---
description: Create a pull request ($ARGUMENTS is base branch name)
agent: build
model: github-copilot/gpt-4.1
---

Pay close attention to the following points, and use the `gh pr create *`
command to create a pull request from the branch given by
!`git rev-parse --abbrev-ref HEAD` (the source/head branch) into $ARGUMENTS (the
target/base branch) in the repository shown by
!`gh repo view -q ".owner.login + \"/\" + .name" --json name,owner`.

**Rules**:

1. Run `git log -n 5` to understand the language used in recent commits.
2. If the base branch is not specified, reply with "$ARGUMENTS must be
   specified." and abort.

**Format**:

1. If @.github/PULL_REQUEST_TEMPLATE.md or @.github/pull_request_template.md
   exists, complete the content according to that file.
2. If it does not exist, execute `gh pr list --state=closed --limit=3` and
   `gh pr view {pr_number} --json body` to refer to the three most recent Pull
   Requests and determine the most appropriate format.

**Title**:

1. Must summarize the result of `git diff {base_branch}`
2. Must begin with a verb (e.g., Add xx, Fix xx, Enable xx), be within 50
   characters.

**Body**:

1. The body of the Pull Request should be carefully analyzed based on the
   content of `git diff {base_branch}` and written accordingly.
2. If including any of the following content, enclose it within a <details>
   block and set an appropriate <summary> label:
   - Build results
   - Test results
   - System logs
   - Output containing more than 20 lines of data
