---
description: Commit the currently staged files
agent: build
model: github-copilot/gpt-4.1
---

Make sure to properly format and output the commit message for squash merge
based on the given data.

**Rules**:

1. Be sure to check @.cz-config.js if it exists.
2. Be sure to check @commitlint.config.js if it exists.

**Context**:

```json
!`gh pr view --json title,number`
```

**Commits**:

```text
!`git log $(gh pr view --json baseRefName -q .baseRefName)..$(git rev-parse --abbrev-ref HEAD) --reverse --pretty="%an -> %s"`
```

**Type**: Apply the most appropriate value from the title field in the JSON of
the Context section.

**Output Format**:

```gitcommit
<type>(scope?): <context_title> (#<context_number>)

<summarize_commits?>

---
<commits>
---
```
