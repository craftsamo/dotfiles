**Fulfill the user's request in the format according to the following items**:

- Track variables

---

1. **Track variables**

**Format**:

Tracking target: <tracking_targets>

Initialization locations:

- [file:<file_name>](file_path) line:<line>
- Type: <type>
- Initial value: <initial_value>

Usage locations:

- [file:<file_name>](file_path) line:<line>
  - Operation type: <operation_type>
  - Final value type: <type>
  - Final value or reference: <assigned_value>

Variable tracking flow:

<ASCII art shows the flow in which the bug occurred>

**Notes**:

- Determine if Selection is a variable.
- Types of variable operations:
  - Assignment: Operation that assigns a value to a variable
  - Update: Operation that changes the value of a variable
    - Addition: Operation that adds a number to the value of a variable
    - Subtraction: Operation that subtracts a number from the value of a variable
    - Multiplication: Operation that multiplies the value of a variable by a number
    - Division: Operation that divides the value of a variable by a number
    - Deletion: Operation that deletes a variable
- If there are multiple locations where the variable is used, list all of them.
- The variable tracking flow should represent the flow from initialization to usage in ASCII art.

**ASCII art format**:

1. Flow Direction:

```text
[init]
  │
  ▼
<Variable>
  │
  ├─► <file_name>: <file_line>
  │
  ├─► <file_name>: <file_line>
  │
  ▼
<Selection>
```

2. If structuring is required:

- if statement

```text
[init]
  │
  ▼
<Variable>
  │
  ├─► <file_name>: <file_line>
  │     ├─► if (condition)
  │     │     └─► <Variable> = <reference>OR<value>
  │     └─► else:
  │           └─► <Variable> = <reference>OR<value>
  │
  ▼
<letest>
```

- for statement

```text
[init]
  │
  ▼
<Variable>
  │
  ├─► <file_name>: <file_line>
  │     └─► for (param of params):
  │           └─► <variable> = <reference>OR<value>
  ▼
<letest>
```

- When combined

```text
[init]
  │
  ▼
<Variable>
  │
  ├─► <file_name>: <file_line>
  │     └─► for (condition):
  │           ├─► if (condition):
  │           │     └─► for (condition):
  │           │           └─► <variable> = <reference>OR<value>
  │           └─► else:
  │                 ├─► if (condition):
  │                 │     └─► <variable> = <reference>OR<value>
  │                 ├─► else:
  │                 │     └─► <variable> = <reference>OR<value>
  │                 │
  │                 └─► <variable> = <reference>OR<value>
  │
  ▼
<letest>
```

**Note**:

- `file_name`: The name of the file where the variable is used.
  - If multiple files with the same name exist, include a relative path (e.g., `src/utils/helpers.ts`) to disambiguate.
- `file_line`: The line number within the file where the variable is used.
- `file_path`: The relative or absolute path to the file from the project root or current working directory.
