Format Rules:

- **Heading Hierarchy**
- Use consistent heading levels across the document:
  - Top-level categories → `#` (e.g., Proposal, Design, Specification)
  - Second-level items → `##`
  - Third-level items → `###`
  - Additional levels → `####` and beyond as needed
- Ensure consistent depth regardless of original YAML nesting depth
- Skip redundant headings:

  - If a parent and child share the same name, only show it once
  - If a parent key has just one child that serves as a wrapper, skip the parent

- **Field Types**

  - For `type: text`:

    ```md
    ## <Title>

    <Description>

    **(<instruction>)**
    ```

  - For `type: yes_no`:

    ```md
    ## <Title>

    <Description>

    - [ ] Yes
    - [ ] No
    - [ ] Not sure
    ```

  - For `type: options`:

    ```md
    ## <Title>

    <Description>

    - [ ] Option A
    - [ ] Option B
          ...
    ```

**Structure**:

- Maintain consistent heading levels across all sections
- Top-level categories (e.g., Proposal, Design, Specification) should be at the same level
- Use consistent formatting for all subsections of the same depth
- Deep nesting in the YAML should not result in excessive heading levels

**Clean Output**:

- Do not include YAML syntax, comments, or any extra characters - Output must be clean and ready-to-edit Markdown
