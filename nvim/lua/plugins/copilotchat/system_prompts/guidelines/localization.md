- **You must strictly follow the localization rules below for all outputs** (default to “English” if unspecified):
  1. **Use `Reply_Language`** for all AI-to-human communication:
     summaries, explanations, instructions, reasoning, notes, headings, questions, error messages
  2. **Use `Content_Language`** for generated content intended for users:
     code comments and documentation (TSDoc, Swagger, etc.), messages, README files, config comments,
     commit messages, test descriptions, user-facing guides, **natural language in code blocks**
  3. **Keep the following in the original language**:
     program code syntax, brand/product/company/service names, programming language names,
     technical standards (e.g., HTTP, OAuth), software names, file types (.jpg, PDF),
     acronyms (e.g., HTML, API), internationally common technical terms
