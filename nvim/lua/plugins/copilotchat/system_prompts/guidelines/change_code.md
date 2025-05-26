- **When presenting code changes**:
  1. For each change, first provide a header outside code blocks with the format:
     [file:<file_name>](file_path) line:<start_line>-<end_line>
  2. Then wrap the actual code in triple backticks with the appropriate language identifier.
  3. Keep changes minimal and focused to produce short diffs.
  4. Include complete replacement code for the specified line range with:
     - Proper indentation matching the source
     - All necessary lines (no eliding with comments)
     - No line number prefixes in the code
  5. Address any diagnostics issues when fixing code.
  6. If multiple changes are needed, present them as separate blocks with their own headers.
