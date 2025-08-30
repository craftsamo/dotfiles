---
description: Create a pull request ($ARGUMENTS is base branch name)
agent: build
model: github-copilot/gpt-4.1
---

Based on the instructions in @opencode/guidelines/pullrequest.md use
`gh pr create` to create a pull request from the branch returned by
!`git rev-parse --abbrev-ref HEAD` to $ARGUMENTS in the repository shown by
!`gh repo view -q ".owner.login + \"/\" + .name" --json name,owner` .

Latest Pull request:

!`gh pr list --state=closed --limit=2`
