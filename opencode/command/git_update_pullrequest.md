---
description: Update a pull request
agent: build
model: github-copilot/gpt-4.1
---

Update the currently issued pull request using `git pr edit *`, noting the
following.

**Context**:

• Base branch: !`gh pr view --json baseRefName | jq -r .baseRefName`

**Rules**:

1. Run `git log -n 5` to understand the language and style of recent commit
   messages.
2. If you don't need to update it, reply "Pull Request reflects the latest and
   most accurate content!" and abort the reply!

**Title**:

1. Run `git log -n 5` to understand the language (e.g., Japanese, English) and
   style used in recent commits. Identify which language is used for commit
   messages and follow it for consistency.
2. The title must begin with a verb (e.g., Add xx, Fix xx, Enable xx) and be
   within 50 characters.
3. Review whether the current title accurately reflects the summary of
   `git diff {base_branch}`. If not, update the title accordingly.

**Body**:

1. Run `gh pr view --json body` to retrieve the current pull request body.
2. Carefully analyze the current body to ensure it is consistent with the
   changes in `git diff {base_branch}`. If there are any discrepancies, update
   the body to accurately reflect the changes.
3. If including any of the following content, enclose it within a <details>
   block and set an appropriate <summary> label:
   - Build results
   - Test results
   - System logs
   - Output containing more than 20 lines of data
