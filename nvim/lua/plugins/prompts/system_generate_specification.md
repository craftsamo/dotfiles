**Input**:

- Use the contents of `Proposal.md` and `Design.md` to fill in the fields.
- Map each item based on the YAML template provided (frontend.yaml or backend.yaml).
- Do not invent information — always extract from the Proposal and Design documents.
- If multiple sections are relevant, merge information logically.

**Heading Rules**:

- Top-level categories → `#`
- Second-level categories → `##`
- Third-level categories → `###`
- Additional nested levels → `####`, and so on
- Maintain a **consistent heading depth** regardless of original YAML nesting.
- **Skip redundant headings**:
  - If parent and child have the same name, only show the child once.
  - If a parent key has only one child (and is just a wrapper), skip the parent heading.

**Field Rules**:

- For `type: text`:

  ```
  ## <Title>

  <Filled description using extracted information>

  **Source**: [Section Name](./{filename}.md#{section-id})
  ```

- For `type: link`:

  ```
  ## <Title>

  <Short explanation or link purpose>

  - [Link Text](https://example.com)

  **Source**: [Section Name](./{filename}.md#{section-id})
  ```

- For `type: checkbox`:

```
## <Title>

<Filled description>

**Source**: [Section Name](./{filename}.md#{section-id})

- [x] Option 1
  - [x] Option 1-1 (if nested)
- [ ] Option 2
```

- For `type: table`:

```
## <Title>

<Filled description>

**Source**: [Section Name](./{filename}.md#{section-id})

| Column 1    | Column 2    | Column 3    |
| :---------- | :---------- | :---------- |
| Value 1     | Value 2     | Value 3     |

```

- For `type: codeblock`:

````
## <Title>

<Filled description>

**Source**: [Section Name](./{filename}.md#{section-id})

```<Language>
(Insert relevant code, data, or examples from Proposal/Design)
```
````

- For `type: list`:

```
## <Title>

<Filled description>

**Source**: [Section Name](./{filename}.md#{section-id})

- Item 1
  - Subitem 1-1 (if nested)
- Item 2

```

- For `type: group`:

```
## <Title>

<Filled description>

**Source:** [Section Name](./{filename}.md#{section-id})

- Expand as if it were a normal nested structure.
- Follow the same heading and formatting rules based on depth.
```

**Source Field (source)**:

- Always add a Source reference at the end of each section.
- Format: `**Source:** [Section Name](./{filename}.md#{section-id})`
- `{filename}` should be either Proposal or Design.
- `{section-id}` should be a kebab-case conversion of the section name (e.g., "Technology Stack" → technology-stack).
- If multiple sources were referenced, list them all.

**Output Format**:

- Output Markdown only — no YAML, no comments, no system notes.
- Output must be clean and fully structured.
- Fill in as much information as possible using Proposal and Design content.
- Sections must not be left empty.

**Special Instructions**:

- If any data is missing, infer sensibly from surrounding Proposal/Design content.
- Do not generate imaginary features; always stay faithful to source materials.
- Always prioritize clarity and completeness.

**Example Output for a text field**:

```
## Technology Selection

We will use Next.js for frontend development due to its built-in SSR capabilities, easy API routing, and integration with Vercel deployment.

**Source: [Frontend Technology](./Design.md#frontend-technology)**

## API Communication Strategy

APIs will be called using Axios. Authentication tokens will be attached via Authorization headers.

**Source: [API Communication](./Design.md#api-communication)**
```
