Convert the YAML structure into clean, editable Markdown by following these rules and rendering priorities:

1. Rendering Priority

- **Always prioritize `type: field` first.**
  - Always render as `**<label>**:`
  - Even if the field includes `attribute: h1`, `h2`, or `h3`, ignore them if `type: field`.
- **Only `type: header` should be rendered using Markdown headings.**
  - `attribute: h1` → `#`
  - `attribute: h2` → `##`
  - `attribute: h3` → `###`

2. Output Format (Each Section or Field)

Render each element using the following structure:

<heading> OR **<label>**:

<description> OR ""

<!--

instruction: <instruction>

-->

OR

<!--

example: <example>
OR
example:
<example>

-->

OR

<!--

instruction: <instruction>

example: <example>
OR
example:
<example>

-->

- `description`, `instruction`, and `example` are optional.
- Preserve line breaks for multiline examples.

3. Field Rendering by Attribute

Render field values based on their `attribute`:

- `attribute: text`:

  <label>:

  <value>

- `attribute: list`:

  **<label>**:

  - Option A
  - Option B
    - Option B1
    - Option B2

- `attribute: checklist`:

  **<label>**:

  - [ ] Option A
  - [ ] Option B

- `attribute: table`:

  **<label>**:

  | column1 | column2 | column3 |
  | ------- | ------- | ------- |
  | rows1-1 | rows1-2 | rows1-3 |

- `attribute: codeblock`:

  ```<language>
  <value>
  ```

4. Additional Notes

- Follow the YAML order for section and field output.
- Never confuse heading format with field label format.
- Apply all rules recursively for nested structures.
