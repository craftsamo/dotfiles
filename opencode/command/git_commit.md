---
description: Commit the currently staged files
agent: build
model: github-copilot/gpt-4.1
---

Commit the **currently staged files**, paying attention to the following points:

**Rules**:

1. Run `git log -n 5` to understand the language (e.g., Japanese, English) and
   style used in recent commits. Identify which language is used for commit
   messages and follow it for consistency.
2. **DO NOT** ever stage files using `git add *`.
   - If there are no staged files, reply with "Please stage files." and abort.
3. Keep the Subject under 50 characters.
4. Wrap the Body at 72 characters per line.
5. Be sure to check @.cz-config.js if it exists.
6. Be sure to check @commitlint.config.js if it exists.

**Subject**:

The subject of the commit should summarize the changes by running
`git diff --staged`.

- Good examples:

  ```gitcommit
  docs: add a document describing instructions for AI agents
  ```

- Bad examples:
  ```gitcommit
  docs: add AGENTS.md
  ```

**Body (optional)**:

The body of the commit should describe the details of the changes. If you can
describe what you did and what the result will be, it will be even better.

- Good examples:

  ```gitcommit
  docs: add a document describing instructions for AI agents

  Added AGENTS.md to provide high-level instructions to each AI Agent.
  This will make it easier to maintain consistency with other team members.
  ```

- Bad examples:

  ```gitcommit
  docs: add AGENTS.md

  Added AGENTS.md to the root directory.
  ```
