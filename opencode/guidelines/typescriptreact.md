# TypeScriptReact (TSX) Coding Guidelines

This document outlines best practices for using TypeScript with React. For
general code style, naming conventions, and TypeScript usage, refer to
[@opencode/guidelines/javascript.md](./javascript.md) and
[@opencode/guidelines/typescript.md](./typescript.md). The following points
highlight React-specific recommendations and idioms for TypeScript.

---

## 1. Component Typing

- Always type props explicitly.
- Prefer explicit function signatures for components over `React.FC` unless you
  need `children` or defaultProps.

```tsx
// Preferred
interface ButtonProps {
  label: string;
  onClick: () => void;
}

function Button({ label, onClick }: ButtonProps) {
  return <button onClick={onClick}>{label}</button>;
}

// If you need children:
interface CardProps {
  children: React.ReactNode;
}

const Card: React.FC<CardProps> = ({ children }) => <div>{children}</div>;
```

---

## 2. Typing State, Refs, and Hooks

- Always provide type arguments to `useState`, `useRef`, etc., when type
  inference is insufficient.

```tsx
const [count, setCount] = useState<number>(0);
const inputRef = useRef<HTMLInputElement>(null);
```

---

## 3. Event Types

- Use React's built-in event types for event handlers.

```tsx
function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
  // ...
}

<button onClick={(e: React.MouseEvent<HTMLButtonElement>) => {}} />;
```

---

## 4. Children Typing

- Use `React.ReactNode` for children props.

```tsx
interface Props {
  children: React.ReactNode;
}
```

---

## 5. Optional and Default Props

- Use optional properties (`prop?: Type`) for optional props.
- For default values, set them in the function body or use default parameters.

```tsx
interface AvatarProps {
  src?: string;
  size?: number;
}

function Avatar({ src = "default.png", size = 40 }: AvatarProps) {
  // ...
}
```

---

## 6. Generics in Components

- Use generics for reusable, type-safe components.

```tsx
interface ListProps<T> {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
}

function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map(renderItem)}</ul>;
}
```

---

## 7. File Naming & Extensions

- Use `.tsx` for files containing JSX/TSX.
- Use kebab-case or camelCase for file names, consistent with other guidelines.

---

## 8. Imports & Exports

- Use ES module syntax (`import`/`export`).
- Prefer named exports over default exports.

---

## 9. Example: Putting It All Together

```tsx
interface UserCardProps {
  name: string;
  age?: number;
}

/**
 * Displays user information.
 */
export function UserCard({ name, age = 18 }: UserCardProps) {
  return (
    <div>
      <h2>{name}</h2>
      <p>Age: {age}</p>
    </div>
  );
}
```

---

## 10. Additional Recommendations

- Use linters (e.g., ESLint with TypeScript and React plugins) and formatters
  (e.g., Prettier).
- Keep prop and state types close to their components.
- Avoid using `any`; prefer strict typing.
- Write tests for critical UI logic.

