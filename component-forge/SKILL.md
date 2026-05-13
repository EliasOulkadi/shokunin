---
name: component-forge
description: Build production-grade components for React, Vue, Svelte, and Web Components covering all states (loading, empty, error, success, idle), a11y, TypeScript strict, and tests. Use when user asks to create a component, UI element, or frontend module. Do NOT use for page layout, routing, state management architecture, or styling/theming systems.
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "2.0"
---

# Component Forge

Build frontend components that handle every state, are accessible by default, and follow framework-specific best practices.

## Workflow

### Step 1: Determine component type

| Type | Description | Example |
|------|-------------|---------|
| Presentational | Pure rendering, props-driven | Button, Card, Badge |
| Composable | Wraps children with behavior | Modal, Tooltip, Accordion |
| Data-fetching | Reads from API/store | UserProfile, OrderList |
| Layout | Arranges children | Sidebar, Grid, Stack |
| Form | Input + validation | LoginForm, SearchInput |

### Step 2: Plan state coverage

Every data-fetching component handles all states:

```tsx
type State<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: T }
```

Render each state explicitly. Never default to a blank screen.

### Step 3: Define props interface

```tsx
export interface ButtonProps extends ComponentPropsWithoutRef<'button'> {
  variant: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  icon?: ReactNode
}
```

Rules:
- Use `interface` over `type` for public component props
- Extend native HTML attributes via framework-specific helpers
- Use discriminated unions for variant props
- Mark optional props with `?`

### Step 4: Check accessibility

- [ ] All interactive elements keyboard reachable (Tab, Enter, Escape)
- [ ] ARIA labels on icon-only buttons
- [ ] Focus trap in modals and dialogs
- [ ] Loading state announced via `aria-live="polite"`
- [ ] Error state has `role="alert"`
- [ ] Color is not the only differentiator (add icon or text)
- [ ] Proper heading hierarchy (h1 → h2 → h3, no skips)
- [ ] Touch targets ≥ 44×44px
- [ ] prefers-reduced-motion respected

### Step 5: Handle edge cases

- Overflow: long text truncation, many items virtualization
- Network retry on error with "Try again" button
- Stale data while refreshing (show old data + loading indicator)
- Race conditions: cancel in-flight requests on unmount
- Empty arrays vs null vs undefined — all are different states
- Floating promises: use framework-safe patterns

## React Patterns

### Composition API

```tsx
// Compound component pattern
function Select({ children }: { children: ReactNode }) {
  const [value, setValue] = useState('')
  return (
    <SelectContext.Provider value={{ value, setValue }}>
      <div role="listbox">{children}</div>
    </SelectContext.Provider>
  )
}

Select.Option = function Option({ value, children }: { value: string; children: ReactNode }) {
  const ctx = useSelectContext()
  return (
    <div
      role="option"
      aria-selected={ctx.value === value}
      onClick={() => ctx.setValue(value)}
    >
      {children}
    </div>
  )
}
```

### Server Components (RSC)

```tsx
// Server Component — runs on server, no hooks, no state
async function ProductList() {
  const products = await db.product.findMany()
  return (
    <ul>
      {products.map(p => (
        <li key={p.id}>
          {p.name} — <ProductPrice price={p.price} />
        </li>
      ))}
    </ul>
  )
}

// Client boundary — minimal, interactive wrapper
'use client'
function AddToCart({ productId }: { productId: string }) {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>Add to Cart ({count})</button>
}
```

Put interactive leaf components in `'use client'`, keep the rest as RSC.

## Vue Patterns (Composition API + `<script setup>`)

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { PropType } from 'vue'

const props = defineProps({
  variant: { type: String as PropType<'primary' | 'secondary'>, default: 'primary' },
  disabled: { type: Boolean, default: false },
})

const emit = defineEmits<{ click: [event: MouseEvent] }>()

const classes = computed(() => [
  'btn',
  `btn--${props.variant}`,
  { 'btn--disabled': props.disabled },
])
</script>

<template>
  <button :class="classes" :disabled="disabled" @click="emit('click', $event)">
    <slot />
  </button>
</template>
```

## Svelte Patterns (Runes syntax)

```svelte
<script lang="ts">
let { variant = 'primary', disabled = false, onclick }: {
  variant?: 'primary' | 'secondary'
  disabled?: boolean
  onclick?: (e: MouseEvent) => void
} = $props()

let count = $state(0)
</script>

<button class="btn" class:btn--primary={variant === 'primary'} {disabled} {onclick}>
  Clicked {count} times
  <slot />
</button>
```

## Component Structure

```
ComponentName/
  ComponentName.tsx         # Implementation
  ComponentName.types.tsx   # Type definitions
  ComponentName.test.tsx    # Tests
  ComponentName.stories.tsx # Storybook stories
  useComponentName.ts      # Custom hook
  index.ts                 # Re-export
```

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Default export | Named exports only |
| Prop drilling > 3 levels | Context, composition, or state management |
| `any` in props | Strict types, discriminated unions |
| Missing loading state | Every data-fetching component has loading → error → success |
| useEffect for derived state | `useMemo` or computed |
| Giant component > 200 lines | Split into smaller components |
| Inline handlers in render | Extract to `useCallback` or function declaration |
| Mixing server/client in same file without boundary | Clear `'use client'` / `'use server'` separation |

## Sources

- React Documentation (react.dev) — Composition vs Inheritance
- Vue 3 Composition API (vuejs.org)
- Svelte 5 Runes (svelte.dev)
- MDN ARIA Authoring Practices Guide
- Web Content Accessibility Guidelines (WCAG) 2.2
- Inclusive Components by Heydon Pickering
