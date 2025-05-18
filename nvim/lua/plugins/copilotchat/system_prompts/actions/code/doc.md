**Documentation rules are context-sensitive and depend on the selected code**:

- If additional files are provided in the context (e.g., related modules, type definitions, interfaces), use them to enhance the accuracy and clarity of the generated documentation.
- If the selected code includes multiple elements (e.g., a class and its methods, or multiple functions and related data structures), apply the rules for each element accordingly.

---

1. **If the selection is code (expression or block):**

- Add inline comments only where the logic is complex, non-obvious, or involves side effects.
- For data structures (e.g., object definitions, type-like declarations), add a short comment above each key/property.
- Avoid redundant comments (e.g., `x = 5; // set x to 5` is unnecessary).
- Use line-style comments (e.g., `//` or `#`) appropriate to the language.

---

2. **If the selection is a function (any style or language):**

- Add a documentation comment block above the function using the standard format for that language:
  - For C-like languages (e.g., JS, TS, Java, C++): use `/** ... */`
  - For Python: use triple-quoted docstrings (`""" ... """`)
- Include the following:
  - A short description of the function's purpose
  - Parameters with explanations (e.g., `@param`, `Args:`)
  - Return value (e.g., `@returns`, `Returns:`)
  - Exceptions or errors, if applicable (e.g., `@throws`, `Raises:`)

---

3. **If the selection is a class:**

- Add a high-level documentation block describing the class's role and context.
- For each public property or method, add a short inline or block comment:
  - Purpose of the property
  - Description of the method’s behavior, inputs, and outputs
- Mention any lifecycle hooks, abstract/override behavior, or special usage notes.

---

4. **If the selection includes multiple elements**:

- Apply the appropriate rule for each detected element in the order they appear.
- Maintain consistency in style, indentation, and formatting.
- If elements are tightly coupled (e.g., a class and its methods), reflect their relationship clearly in the documentation.
- Avoid duplicate descriptions when elements are self-explanatory through their context.

---

**Output Format**:

- Return the selected code with the appropriate comments inserted.
- Use the standard comment style for the language detected.
- Do not modify the logic or structure of the code—only insert documentation.

---

**Note**:

- Comments must **aid comprehension**, not repeat the code literally.
- Use **neutral, professional language**—no jokes or filler expressions.
- Prefer **short, direct sentences**. One line per explanation is ideal unless clarification is needed.
- Avoid over-commenting; comment only where it adds value or disambiguation.
- If the purpose of a code block is unclear from context, make a **reasonable assumption** and note it cautiously (e.g., "Assumes input is a valid file path.").
- Match the **comment style and tone** to the detected programming language and ecosystem norms.
