---
name: component-forge
description: Build production-grade components for React, Vue 3, and Svelte 5 with all states (loading, empty, error, success, idle), TypeScript strict, WCAG 2.2 accessibility, server components (RSC), and compound component patterns. Includes scaffold script, reference patterns, and template files for React and Vue. Use when user asks to create a UI component, frontend module, or design system component. Do NOT use for page layouts (use landing-craft), routing, or state management architecture (global stores).
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep Glob
---

# Component Forge

Build frontend components that handle every state, are accessible by default, TypeScript strict, and follow framework-specific best practices.

## Workflow

### Step 1: Determine component type

| Type | Description | Example |
|------|-------------|---------|
| Presentational | Pure rendering, props-driven | Button, Card, Badge |
| Composable | Wraps children with behavior | Modal, Tooltip, Accordion |
| Data-fetching | Reads from API/store | UserProfile, OrderList |
| Layout | Arranges children | Sidebar, Grid, Stack |
| Form | Input + validation | LoginForm, SearchInput |

### Step 2: Scaffold component

```bash
# React
scripts/scaffold-component.sh Button react
# Vue
scripts/scaffold-component.sh Modal vue
# Svelte
scripts/scaffold-component.sh Accordion svelte
```

This creates the full directory structure:
```
Button/
  Button.tsx       # See assets/react-component.template.tsx
  Button.types.ts
  Button.test.tsx
  index.ts
```

### Step 3: Implement states with discriminated union

```tsx
type State<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: T }

// Render every state explicitly:
function Profile({ userId }: { userId: string }) {
  const [state, setState] = useState<State<User>>({ status: 'idle' })

  if (state.status === 'loading') return <LoadingSkeleton />
  if (state.status === 'error') return <ErrorState error={state.error} onRetry={fetch} />
  if (state.status === 'empty') return <EmptyState message="No user found" />
  if (state.status === 'success') return <UserProfile user={state.data} />
  return null
}
```

### Step 4: Apply accessibility checklist

- [ ] All interactive elements keyboard reachable (Tab → Enter/Space)
- [ ] ARIA labels on icon-only buttons
- [ ] Focus trap in modals and dialogs
- [ ] Loading state announced via `aria-live="polite"`
- [ ] Error state has `role="alert"`
- [ ] Color is not the only differentiator (add icon/text)
- [ ] Proper heading hierarchy (h1 → h2 → h3, no skips)
- [ ] Touch targets ≥ 44×44px
- [ ] `prefers-reduced-motion` respected

See [references/a11y-patterns.md](references/a11y-patterns.md) for roving tabindex, focus management, screen reader testing, and contrast ratios.

### Step 5: Handle edge cases

| Edge case | Symptom | Fix |
|-----------|---------|-----|
| Long text | Layout break | `text-overflow: ellipsis`, `overflow-wrap: anywhere` |
| Many items (100+) | Slow rendering | Virtualize (react-window, FlashList) |
| Network retry | Stale data | Show old data + loading indicator |
| Race condition | Wrong data after fast re-fetch | AbortController, cancel on unmount |
| null vs undefined vs [] | Wrong empty check | Handle all three explicitly |

See [references/react-patterns.md](references/react-patterns.md) for compound components, RSC patterns, error boundaries, and suspense.

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Component crashes on missing prop | Missing default value | Add `defaultProps` or default parameter |
| Infinite re-render | Missing dependency array | Add deps to useEffect/useMemo |
| Flash of unstyled content | CSS not loaded | Inline critical CSS, use CSS-in-JS or preload |
| ARIA live region not announcing | Wrong role/value | Use `role="status"` for loading, `role="alert"` for errors |
| Focus trap not working | Missing focusable element | Ensure at least one focusable child in trap |

## Production Checklist

- [ ] Every component has typed props (interface, not type)
- [ ] All states rendered (loading, empty, error, success, idle)
- [ ] Accessibility checklist passed
- [ ] Edge cases handled (overflow, retry, race conditions)
- [ ] Named exports only (no default exports)
- [ ] Co-located tests in same directory
- [ ] One component per file
- [ ] Custom hook extracted for non-rendering logic
- [ ] Tests for every state transition

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Default export | Named exports only |
| `any` in props | Strict types, discriminated unions |
| Missing loading state | Every data-fetching component renders loading → error → success |
| useEffect for derived state | `useMemo` or computed property |
| Giant component > 200 lines | Split into sub-components |
| Inline handlers in render | Extract to `useCallback` |
| Mixing server/client without boundary | Clear `'use client'` / `'use server'` |
| Prop drilling > 3 levels | Context or composition |

## Sources

- React docs (react.dev) — Composition vs Inheritance
- Vue 3 docs (vuejs.org) — Composition API
- Svelte 5 docs (svelte.dev) — Runes
- MDN ARIA Authoring Practices Guide
- WCAG 2.2 — Accessibility guidelines
- Inclusive Components (Heydon Pickering)
