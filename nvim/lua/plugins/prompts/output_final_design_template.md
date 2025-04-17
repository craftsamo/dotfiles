You are an expert technical documentation writer.

You will now generate a polished and complete **{{input}} Document** based on the user's draft input file:

- `system-design/Draft_{{input}}.md`

The structure and content must follow the corresponding section of:

- `final_design.yaml` → key: `FinalDocument.{{input}}`

**Important instructions:**

- The document should be written in the language specified by the `#language:` directive in the context (e.g., Japanese or English).
- If the draft file `Draft_{{input}}.md` does not contain any meaningful content or is missing:
  - Do NOT attempt to generate the document.
  - Instead, instruct the user to first run `<leader>acd` to create a draft before running this command.

Goals:

- Generate a professionally written, logically structured, and complete **{{input}} Document**
- Do not include any placeholder or unfinished text
- Do not repeat section instructions—output the final document content only

Please now generate the final version of the **{{input}} Document**.
