---
name: component-forge
description: Build production React/Vue components with states, a11y, types, tests
---


# Component Forge

Generates frontend components that handle every state: loading, empty, error, success, and edge cases. Accessible by default, typed with TypeScript, and testable.

## Core Principles

- **Single responsibility**: one component, one concern
- **All states covered**: loading, empty, error, success, and idle
- **Accessibility first**: keyboard navigation, screen reader support, focus management
- **TypeScript strict**: no `any`, precise prop types, discriminated unions for states

## Component Structure

```
ComponentName/
  ComponentName.tsx
  ComponentName.types.ts
  ComponentName.test.tsx
  ComponentName.stories.tsx
  useComponentName.ts
  index.ts
```

## State Pattern

Every data-fetching component follows this pattern:

```tsx
type State<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: T }
```

Render each state explicitly. Never default to a blank screen.

## Props Interface

- Use `interface` over `type` for public component props (better extensibility)
- Extend native HTML attributes via `ComponentPropsWithoutRef`
- Mark optional props clearly with `?`
- Use discriminated unions for variant props
- Document complex props with JSDoc

```tsx
export interface ButtonProps extends ComponentPropsWithoutRef<'button'> {
  variant: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  icon?: ReactNode
}
```

## Accessibility Checklist

- [ ] All interactive elements keyboard reachable
- [ ] ARIA labels on icon-only buttons
- [ ] Focus trap in modals and dialogs
- [ ] Loading state announced via `aria-live`
- [ ] Error state has `role="alert"`
- [ ] Color not the only differentiator
- [ ] Proper heading hierarchy

## Edge Cases

- Overflow handling (long text, many items)
- Network retry on error
- Stale data while refreshing
- Race conditions on fast re-fetches
- Empty arrays vs null vs undefined
- Floating promises (cancel on unmount)

## Conventions

- Named exports only (no default exports)
- PascalCase for component files
- co-locate tests and stories with component
- One component per file
- Custom hooks extract logic from presentation
## Sources

- React documentation "Composition vs Inheritance" (react.dev)
- Dan Abramov "Presentational and Container Components" (2015, still foundational)
- SitePoint "5 React Architecture Best Practices"
- Bacancy "React Architecture Patterns and Best Practices for 2026"
- GeeksforGeeks "React Architecture Pattern and Best Practices in 2025"
- Roman Kozak "Building Reusable React Components in 2026"
- QCode "React System Design and Architecture: The Complete 2026 Guide"







