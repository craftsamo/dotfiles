# TypeScript Coding Guidelines

This document outlines best practices and coding standards for TypeScript
development. For general code style, naming conventions, and best practices,
refer to @guidelines/javascript.md. The following points highlight
TypeScript-specific recommendations and differences.

---

## 1. Type Annotations

- Always annotate function parameters and return types, except when type
  inference is obvious and unambiguous.
- Prefer explicit types for public APIs and exported functions.

```ts
function add(a: number, b: number): number {
  return a + b;
}
```

---

## 2. Interfaces & Types

- Use `interface` for object shapes and public APIs; use `type` for unions,
  intersections, and primitives.
- Prefer `interface` for extensibility.

```ts
interface User {
  id: number;
  name: string;
}

type Status = "active" | "inactive";
```

---

## 3. Enums vs. Union Types

- Prefer union string literal types over enums for simple cases.
- Use `enum` only when you need auto-incrementing values or interoperability
  with other languages.

```ts
type Direction = "up" | "down" | "left" | "right";
```

---

## 4. Generics

- Use generics for reusable, type-safe code.
- Name generic type parameters with single uppercase letters (e.g., `T`, `U`,
  `K`, `V`).

```ts
function identity<T>(value: T): T {
  return value;
}
```

---

## 5. Type Assertions & Non-Null Assertions

- Avoid type assertions (`as Type`) unless necessary.
- Prefer type-safe code and proper type narrowing.
- Avoid non-null assertions (`!`) unless you are certain the value is not
  null/undefined.

---

## 6. Strictness

- Always enable `strict` mode in `tsconfig.json`.
- Avoid using `any`. If unavoidable, document the reason.
- Prefer `unknown` over `any` for values of uncertain type.

---

## 7. File Naming & Extensions

- Use `.ts` for TypeScript files, `.tsx` for files containing JSX/TSX.
- Use kebab-case or camelCase for file names, consistent with JavaScript
  guidelines.

---

## 8. Imports & Exports

- Use ES module syntax (`import`/`export`).
- Prefer named exports over default exports.

```ts
export function doSomething() {}
// import { doSomething } from './module';
```

---

## 9. Utility Types

- Use built-in utility types (`Partial`, `Pick`, `Omit`, `Record`, etc.) for
  type transformations.

```ts
type UserPreview = Pick<User, "id" | "name">;
```

---

## 10. Comments & Documentation

- Use TSDoc/JSDoc for documenting types, interfaces, and functions.
- Document complex types and generics for clarity.

```ts
/**
 * Represents a user in the system.
 */
interface User {
  id: number;
  name: string;
}
```

---

## 11. Example: Putting It All Together

```ts
/**
 * Calculate the area of a circle.
 * @param radius - The radius of the circle
 * @returns The area
 */
export function calcCircleArea(radius: number): number {
  const PI = 3.14159;
  return PI * radius * radius;
}
```

---

## 12. Additional Recommendations

- Use linters (e.g., ESLint with TypeScript plugin) and formatters (e.g.,
  Prettier).
- Keep types and interfaces close to where they are used, unless shared.
- Avoid using global types unless necessary.
- Write tests for type-critical logic.
