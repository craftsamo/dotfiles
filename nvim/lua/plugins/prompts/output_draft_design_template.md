# Template Formatter for System Design Documents

Please extract the `{{input}}` section from the `first_design.yaml` template file and convert it into a structured, editable Markdown document.

### Format Rules

1. **Heading Hierarchy**

   - Use consistent heading levels across the document:
     - Top-level categories → `#` (e.g., Proposal, Design, Specification)
     - Second-level items → `##`
     - Third-level items → `###`
     - Additional levels → `####` and beyond as needed
   - Ensure consistent depth regardless of original YAML nesting depth
   - Skip redundant headings:
     - If a parent and child share the same name, only show it once
     - If a parent key has just one child that serves as a wrapper, skip the parent

2. **Field Types**

   - For `type: text`:

     ```md
     ## <Title>

     <Description>

     <Instruction>

     **(Please fill in here)**
     ```

   - For `type: yes_no`:

     ```md
     ## <Title>

     <Description>

     <Instruction>

     - [ ] Yes
     - [ ] No
     - [ ] Not sure
     ```

   - For `type: options`:

     ```md
     ## <Title>

     <Description>

     <Instruction>

     - [ ] Option A
     - [ ] Option B
           ...
     ```

3. **Structure**

   - Maintain consistent heading levels across all sections
   - Top-level categories (e.g., Proposal, Design, Specification) should be at the same level
   - Use consistent formatting for all subsections of the same depth
   - Deep nesting in the YAML should not result in excessive heading levels

4. **Localization**

   - Use the `Response_Language` metadata to localize all headings and instructions

5. **Clean Output**
   - Do not include YAML syntax, comments, or any extra characters
   - Output must be clean and ready-to-edit Markdown

---

### Goal

Generate a user-editable system design document as Markdown with consistent heading levels regardless of the original YAML nesting structure. The output should be well-structured and easy to fill out within Neovim.
