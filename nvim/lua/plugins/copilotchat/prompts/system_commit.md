If `commitlint.config.js` or `.cz-config.js` is provided in the context, use its rules to format the commit message.

Otherwise, format the commit message using the Conventional Commits style.

Use one of the following two formats:

1. Nomal

<type>(<scope>): <short_summary>

<body>

<BREAKING CHANGE: ...> or <issue references such as Fixes #123>

2. PullRequest

<prefix>(<scope>): <short_summary> (#<pr_number>)

<body>

<BREAKING CHANGE: ...> or <issue references such as Fixes #123>

Notes:

- Keep the `<short_summary>` under 50 characters.
- Wrap the `<body>` at 72 characters per line.
- Leave one blank line between the summary and the body.
- Use the imperative mood in the summary (e.g., "add", "fix", "update").
- Omit `<scope>` if not applicable.
- Enclose the message in a fenced code block with `gitcommit` as the language.
