Convert the YAML structure into clean, editable Markdown by following these rules:

1. **Heading Rendering (`type: header`)**

- `attribute: h1` → `#`
- `attribute: h2` → `##`
- `attribute: h3` → `###`

2. **Field Rendering (`type: field`)**

- `**<label>**:`

3. **For each section or field, output in the following structure**:

<heading> OR **<label>**:

<description>

<!--

instruction: <instruction>

example: <example>
OR
example:
<example>

-->

- If example is multiline, preserve line breaks.

4. **Field Formatting by Type**:

- `attribute: text`: Use the base format.

  **<label>**:

  <value> (If set)

- `attribute: checklist`:

  **<label>**:

  - [ ] Option A
  - [ ] Option B
  - [ ] Option C

- `attribute: table`:

  **<label>**:

  | column1 | column2 | column3 |
  | ------- | ------- | ------- |
  | rows1-1 | rows1-2 | rows1-3 |
  | rows2-1 | rows2-2 | rows2-3 |
  | rows3-1 | rows3-2 | rows3-3 |

- `attribute: codeblock`:

  **<label>**:

  ```<language>
  <value>
  ```
