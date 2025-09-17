# JavaScript Guidelines

This document summarizes best practices and coding standards for JavaScript
development. It is intended as a guide for everyone, from beginners to advanced
developers, to write consistent and high-quality code.

---

## 1. Code Style

### Indentation

- Use 2 spaces for indentation.

```js
function greet(name) {
  console.log("Hello, " + name);
}
```

### Semicolons

- Always use semicolons at the end of statements.

```js
let x = 1;
console.log(x);
```

### Quotes

- Use single quotes `'` for strings.
- Use backticks `` ` `` for template literals.

```js
const name = "Taro";
const message = `Hello, ${name}!`;
```

### Braces

- Always use braces `{}` for blocks, even for single-line statements.

```js
if (isValid) {
  doSomething();
}
```

### Spaces

- Add spaces around operators and after commas.

```js
let total = a + b;
callFunc(arg1, arg2);
```

---

## 2. Naming Conventions

### Variables & Functions

- Use camelCase for variable and function names (e.g., userName, getUserInfo).

```js
let userName = "Taro";
function getUserInfo() {}
```

### Classes & Constructors

- Use PascalCase for class names (e.g., UserProfile).

```js
class UserProfile {}
```

### Constants

- Use UPPER_CASE with underscores for constants.

```js
const MAX_COUNT = 10;
```

### File Names

- Use kebab-case or camelCase for file names.
  - e.g., user-profile.js, userProfile.js

---

## 3. Best Practices

- Prefer `const` and `let` over `var`.
- Use `const` by default; use `let` only if reassignment is needed.

```js
const user = { name: "Taro" };
let count = 0;
```

- Use arrow functions for anonymous functions.

```js
const items = [1, 2, 3].map((x) => x * 2);
```

- Prefer destructuring for objects and arrays.

```js
const { name, age } = user;
const [first, second] = items;
```

- Use template literals for string concatenation.

```js
const message = `Hello, ${userName}!`;
```

- Avoid magic numbers and strings; use named constants instead.

---

## 4. ES6+ Features

- Use modern syntax (ES6+) wherever possible.
  - Arrow functions
  - Destructuring
  - Spread/rest operators
  - Default parameters
  - Classes
  - Modules (import/export)

```js
import { getUser } from "./api";

const sum = (...nums) => nums.reduce((a, b) => a + b, 0);
```

---

## 5. Comments

- Write comments in English as appropriate.
- Use JSDoc for function/method documentation.

```js
/**
 * Add two numbers.
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
function add(a, b) {
  return a + b;
}
```

- Avoid obvious comments.

---

## 6. File & Project Organization

- Group related functions and classes into modules.
- Use index.js for module entry points.
- Separate business logic, UI, and configuration files.

**Example directory structure:**

```
/src
  /components
    Button.js
    Header.js
  /utils
    formatDate.js
  index.js
```

---

## 7. Anti-Patterns

- Avoid global variables.
- Do not use `eval()`.
- Avoid deeply nested code.
- Do not mutate function arguments.
- Avoid callback hell; use Promises or async/await.

```js
// Good
async function fetchData() {
  const response = await fetch(url);
  return response.json();
}
```

---

## 8. Miscellaneous

- Use linters (e.g., ESLint) and formatters (e.g., Prettier) to maintain code
  quality.
- Write tests for critical logic.

---

## 9. Example: Putting It All Together

```js
/**
 * Calculate the area of a circle.
 * @param {number} radius
 * @returns {number}
 */
export function calcCircleArea(radius) {
  const PI = 3.14159;
  return PI * radius * radius;
}
```
