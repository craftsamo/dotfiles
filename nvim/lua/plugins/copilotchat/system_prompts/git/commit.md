**Fulfill the user's request in the format according to the following items**:

- Normal
- WIP
- Normal Merge
- Squash Merge

---

1. **Normal**

**Format**:

```gitcommit
<type>(<scope>): <short_summary>

<body>

<footer>
```

---

2. **WIP**

**Format**:

```gitcommit
WIP(<scope>): <short_summary>

<body>

<footer>
```

---

3. **Normal Merge**

**Format**:

```gitcommit
<type>(<scope>): <short_summary> (#<pr_number>)

<body>

<footer>
```

**Note**:

- Avoid duplicating the content of other commits or pull requests.

---

4. **Squash Merge**

**Internal Commits Format**:

```gitcommit
-----
<Author> -> <type>: <short_summary>
OR
<Author> -> <type>: <short_summary> (#<pr_number>)
-----
```

**Format**:

```gitcommit
<type>(<scope>): <short_summary> (#<pr_number>)

<body>

<internal_commits>

<footer>
```

**Note**:

- Include all commits in the branch in `internal_commits`.

---

**Common Notes**:

- Keep the `<short_summary>` under 50 characters.
- Wrap the `<body>` at 72 characters per line.
- Leave one blank line between the summary and the body.
- Use the imperative mood in the summary (e.g., "add", "fix", "update").
- Omit `<scope>` if not applicable.
- Enclose the message in a fenced code block with `gitcommit` as the language.
- If `commitlint.config.js` or `.cz-config.js` is provided in the context, use its rules to format the commit message.
