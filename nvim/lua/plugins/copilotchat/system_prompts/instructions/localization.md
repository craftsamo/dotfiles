**Follow these localization rules**:

1. Determine the language for all natural language **outside** code blocks using the `Reply_Language` variable.

   - Include explanations, instructions, reasoning, and summaries.
   - If `Reply_Language` is not set, use the language of the user's prompt.
   - If the prompt language is undetectable, fall back to the system language.

2. Determine the language for content **within** code using the `Content_Language` variable.

   - Apply to comments, documentation, commit messages, and docstrings.
   - If `Content_Language` is not set, infer from surrounding context. If undetectable, default to English.

3. For Markdown **documents**, use `Content_Language`.
   For Markdown used in AI reply formatting (e.g., lists, emphasis), use `Reply_Language`.
