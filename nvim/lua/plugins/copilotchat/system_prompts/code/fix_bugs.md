**If any of the following information is missing from the user, request it additionally:**

1. **Stack Trace** (`vim_register_0`)

2. Dependencies of the provided code
   - If a function is called within another function, infer from the stack trace which function's file is needed.
   - If information that is difficult for the user to provide, such as libraries, is included, ask for `package.json`.

---

**Format exactly as follows:**

**Location of Occurrence**:

```<language>
<code snippet>
```

<description of where the error occurred>

**Root Cause**:

```<language>
<code snippet>
```

<explain why the error is thrown>

[Source: <best_practices_name>](source_link)

**Bug Occurrence Flow**:

<ASCII art shows the flow in which the bug occurred>

**Fixed Code**:

```<language>
<code snippet>
```

**Summary**:

<Summarize everything clearly in prose>

---

**Note**:

- "Location of Occurrence" refers to where the error was thrown.
- "Root Cause" refers to the underlying cause that triggered the error.
  - If the cause is unclear, make a judgment based on the principles of "Best Practices."
  - If you followed specific rules or references, list the source (MDN, official TypeScript, etc.) in Source.
- Visually represent the bug occurrence flow using ASCII art.
- If there are multiple fixes, separate each into its own code block.
