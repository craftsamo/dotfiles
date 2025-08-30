# Git Commit Guidelines

## Rules

1. Run `git log -n 5` to understand the language used in recent commits.

2. **DO NOT** ever stage files using `git add *`.

   - If there are no staged files, reply with "Please stage files." and abort.

3. Keep the Subject under 50 characters.

4. Wrap the Body at 72 characters per line.

5. Be sure to check [.cz-config.js](.cz-config.js) if it exists.

6. Be sure to check [commitlint.config.js](commitlint.config.js) if it exists.

## Subject

The subject of the commit should summarize the changes by running
`git diff --cached`.

### Examples

When `AGENTS.md` is added.

- Good:

  ```gitcommit
  docs: add a document describing instructions for AI agents
  ```

- Bad:

  ```gitcommit
  docs: add AGENTS.md
  ```

## Body (optional)

The body of the commit should describe the details of the changes.

If you can describe what you did and what the result will be, it will be even
better.

### Examples

When `AGENTS.md` is added.

- Good:

  ```gitcommit
  docs: add a document describing instructions for AI agents

  Added AGENTS.md to provide high-level instructions to each AI Agent.
  This will make it easier to maintain consistency with other team members.
  ```

- Bad:

  ```gitcommit
  docs: add AGENTS.md

  Added AGENTS.md to the root directory.
  ```
