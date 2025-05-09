Convert the YAML structure into clean, editable Markdown by following these rules:

**Heading Levels**:

- Heading level is determined _only_ by the `type` field, not by YAML nesting.
- `type: h1` → `#`
- `type: h2` → `##`
- `type: h3` → `###`
- `type: label`, `type: table` → do **not** use heading syntax. Use bolded field label like: `**<label>**:`

**For each section or field, output in the following structure**:

<heading> ← based on `type`

<description>

<!--

instruction: <instruction>

example: <example>

-->

- If example is multiline, preserve line breaks.

<heading> ← based on `type`

<description>

<!--

instruction: <instruction>

example:
<example>

-->

**Field Formatting by Type**:

1. `type: text`: Use the base format.

2. `type: options`:

- [ ] Option A
- [ ] Option B
- [ ] Option C

3. `type: table`:

**<heading>**:

| column1 | column2 | column3 |
| ------- | ------- | ------- |
| rows1-1 | rows1-2 | rows1-3 |
| rows2-1 | rows2-2 | rows2-3 |
| rows3-1 | rows3-2 | rows3-3 |

**Important Notes**:

- Do not generate nested headings unless explicitly specified via type.
- Tables and field labels (type: table, type: label) should never use headings like ###.
- Output must be clean Markdown — no YAML syntax, keys, or artifacts.
