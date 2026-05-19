---
name: component-forge
description: Build production-grade components for React, Vue 3, and Svelte 5 with all states (loading, empty, error, success, idle), TypeScript strict, WCAG 2.2 accessibility, server components (RSC), and compound component patterns. Includes scaffold script, reference patterns, and template files for React and Vue. Use when user asks to create a UI component, frontend module, or design system component. Do NOT use for page layouts (use landing-craft), routing, or state management architecture (global stores).
triggers:
  - "create component"
  - "build component"
  - "React component"
  - "Vue component"
  - "Svelte component"
  - "UI component"
  - "button component"
  - "modal component"
  - "form component"
  - "accessible component"
  - "compound component"
  - "component library"
negatives:
  - "page layout"
  - "routing"
  - "state management"
  - "global store"
  - "full page"
  - "landing page"
  - "design system colors"
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "4.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep Glob
---


# Component Forge

Build components that survive every state, at every screen size, under every edge case. Inspired by Heydon Pickering (Inclusive Components), React core team patterns, and Emil Kowalski's design engineering philosophy.

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
scripts/scaffold-component.sh Button react
scripts/scaffold-component.sh Modal vue
scripts/scaffold-component.sh Accordion svelte
```

> **Windows:** The scaffold script requires Git Bash or WSL. Not compatible with PowerShell or CMD.

Creates:
```
Button/
  Button.tsx
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

function Profile({ userId }: { userId: string }) {
  const [state, setState] = useState<State<User>>({ status: 'idle' })

  if (state.status === 'loading') return <LoadingSkeleton />
  if (state.status === 'error') return <ErrorState error={state.error} onRetry={fetch} />
  if (state.status === 'empty') return <EmptyState message="No user found" />
  if (state.status === 'success') return <UserProfile user={state.data} />
  return null
}
```

**Every data-fetching component renders all five states.**

### Step 4: Apply accessibility checklist

- [ ] All interactive elements keyboard reachable (Tab ? Enter/Space)
- [ ] ARIA labels on icon-only buttons
- [ ] Focus trap in modals and dialogs
- [ ] Loading state announced via `aria-live="polite"`
- [ ] Error state has `role="alert"`
- [ ] Color is not the only differentiator (add icon/text)
- [ ] Proper heading hierarchy (h1 ? h2 ? h3, no skips)
- [ ] Touch targets = 44-44px
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

---

## Button Architecture

Every button must feel responsive. Emil Kowalski's rule: `scale(0.97)` on press.

```css
.button {
  transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1);
}
.button:active {
  transform: scale(0.97);
}
```

Scale must be subtle: 0.95-0.98. Applied to all pressable elements.

### Button state transitions

| State | CSS |
|-------|-----|
| Default | `background: var(--color-primary)` |
| Hover | `transform: translateY(-1px)` 200ms |
| Active | `transform: scale(0.97)` 160ms |
| Focus | `outline: 2px solid var(--accent); outline-offset: 2px` |
| Disabled | `opacity: 0.5; cursor: not-allowed` |
| Loading | Replace text with spinner, keep width stable |

```tsx
function Button({ children, loading, ...props }: ButtonProps) {
  return (
    <button
      className="button"
      aria-busy={loading}
      aria-disabled={loading}
      {...props}
    >
      {loading ? <Spinner /> : children}
    </button>
  )
}
```

---

## Popover Architecture

Popovers scale from their trigger. Modals stay centered.

```css
/* Radix UI */
.popover {
  transform-origin: var(--radix-popover-content-transform-origin);
}

/* Base UI */
.popover {
  transform-origin: var(--transform-origin);
}

/* Modals - always centered */
.modal {
  transform-origin: center;
}
```

Whether the user notices individually does not matter. In the aggregate, unseen details compound.

---

## Tooltip Architecture

Tools must delay before appearing (prevent accidental activation). But once one tooltip is open, adjacent tooltips appear instantly with no animation.

```css
.tooltip {
  transition: transform 125ms ease-out, opacity 125ms ease-out;
  transform-origin: var(--transform-origin);
}

.tooltip[data-instant] {
  transition-duration: 0ms;
}
```

```tsx
function Tooltip({ children, content }: TooltipProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [isInstant, setIsInstant] = useState(false)

  return (
    <TooltipRoot
      delayDuration={isInstant ? 0 : 500}
      onOpenChange={(open) => {
        setIsOpen(open)
        if (!open) setIsInstant(false)
      }}
    >
      <TooltipTrigger
        onPointerEnter={() => { if (isAnyTooltipOpen()) setIsInstant(true) }}
      >
        {children}
      </TooltipTrigger>
      <TooltipContent data-instant={isInstant || undefined}>
        {content}
      </TooltipContent>
    </TooltipRoot>
  )
}
```

---

## Modal Architecture

### Enter / exit animation timings

| Phase | Duration | Easing |
|-------|----------|--------|
| Enter | 200-300ms | `cubic-bezier(0, 0, 0.2, 1)` |
| Exit | 150-200ms | `cubic-bezier(0.4, 0, 1, 1)` |

Exit must ALWAYS be faster than enter.

### Focus trap

```tsx
function Modal({ open, onClose, children }: ModalProps) {
  const overlayRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return

    const previouslyFocused = document.activeElement as HTMLElement
    const overlay = overlayRef.current

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { onClose(); return }

      if (e.key === 'Tab') {
        const focusable = overlay!.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )
        const first = focusable[0]
        const last = focusable[focusable.length - 1]

        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault(); last.focus()
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault(); first.focus()
        }
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      previouslyFocused?.focus()
    }
  }, [open, onClose])

  if (!open) return null

  return (
    <div className="modal-overlay" ref={overlayRef} role="dialog" aria-modal="true">
      <AnimatePresence>
        {children}
      </AnimatePresence>
    </div>
  )
}
```

---

## Skeleton Loading States

Skeleton loaders must match the layout dimensions of the content they replace.

```tsx
function UserCardSkeleton() {
  return (
    <div className="card" aria-hidden="true">
      <div className="skeleton skeleton-avatar" style={{ width: 48, height: 48, borderRadius: '50%' }} />
      <div className="skeleton skeleton-text" style={{ width: '60%', height: 16, marginTop: 12 }} />
      <div className="skeleton skeleton-text" style={{ width: '40%', height: 12, marginTop: 8 }} />
    </div>
  )
}
```

```css
.skeleton {
  background: linear-gradient(
    90deg,
    var(--skeleton-base) 25%,
    var(--skeleton-shine) 50%,
    var(--skeleton-base) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s linear infinite;
}

@keyframes shimmer {
  from { background-position: 200% 0; }
  to   { background-position: -200% 0; }
}
```

---

## Stagger Children

When multiple children enter, stagger their appearance.

```tsx
function List({ items }: { items: Item[] }) {
  return (
    <ul>
      {items.map((item, i) => (
        <motion.li
          key={item.id}
          initial={{ opacity: 0, transform: 'translateY(8px)' }}
          animate={{ opacity: 1, transform: 'translateY(0)' }}
          transition={{ delay: i * 0.05, duration: 0.3, ease: [0.23, 1, 0.32, 1] }}
        >
          <ItemCard item={item} />
        </motion.li>
      ))}
    </ul>
  )
}
```

Keep stagger delays 30-80ms. Never block interaction while stagger plays.

---

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Component crashes on missing prop | Missing default value | Add `defaultProps` or default parameter |
| Infinite re-render | Missing dependency array | Add deps to useEffect/useMemo |
| Flash of unstyled content | CSS not loaded | Inline critical CSS, use CSS-in-JS or preload |
| ARIA live region not announcing | Wrong role/value | Use `role="status"` for loading, `role="alert"` for errors |
| Focus trap not working | Missing focusable element | Ensure at least one focusable child in trap |
| Skeleton layout shift | Skeleton doesn't match content dimensions | Match exact width/height. Use `min-height` blocks. |
| Stagger blocks interaction | Long delay on large lists | Cap total stagger at 400ms. Show remaining items instantly. |
| Modal focus lost after close | Focus not restored | Save `document.activeElement` before opening, restore after closing |

---

## Review Format (Required)

When reviewing component code, use a Before/After table:

| Before | After | Why |
|--------|-------|-----|
| Missing loading state | `{ status: 'loading' }` ? `<Skeleton />` | Users see a blank screen otherwise |
| `aria-label` missing on icon button | `aria-label="Close dialog"` | Screen reader announces "button" with no context |
| `ease-in` on modal enter | `cubic-bezier(0, 0, 0.2, 1)` 250ms | Ease-in starts slow, feels sluggish on entering UI |
| No `:active` state on button | `transform: scale(0.97)` 160ms ease-out | Buttons must feel responsive to press |
| `setState` after unmount | `useEffect` cleanup + `AbortController` | Race condition - stale data overwrites fresh state |
| `h-screen` for hero | `min-h-[100dvh]` | `100vh` breaks on iOS Safari with URL bar visible |
| 500ms modal enter | 250ms | UI animations over 300ms feel slow |
| Focus not trapped in modal | Implement focus loop (Tab/Shift+Tab) | Keyboard users escape modal and get lost |

---

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
- [ ] Button: `scale(0.97)` on `:active`, 160ms ease-out
- [ ] Popover: `transform-origin` anchors to trigger
- [ ] Modal: enter 200-300ms, exit 150-200ms, exit faster than enter
- [ ] Tooltip: delay on first, instant on adjacent
- [ ] Skeleton: matches content dimensions exactly
- [ ] Stagger: 30-80ms delay, max 400ms total
- [ ] Focus: restored to trigger after modal/tooltip close
- [ ] `100dvh` used instead of `100vh` for full-screen
- [ ] Touch targets = 44-44px
- [ ] `prefers-reduced-motion` respected

---

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Default export | Named exports only |
| `any` in props | Strict types, discriminated unions |
| Missing loading state | Every data-fetching component renders loading ? error ? success |
| useEffect for derived state | `useMemo` or computed property |
| Giant component > 200 lines | Split into sub-components |
| Inline handlers in render | Extract to `useCallback` |
| Mixing server/client without boundary | Clear `'use client'` / `'use server'` |
| Prop drilling > 3 levels | Context or composition |
| `ease-in` on entering UI | Strong ease-out (`cubic-bezier(0.23, 1, 0.32, 1)`) |
| Modal exit same speed as enter | Exit must be faster |
| Skeleton different shape from content | Match dimensions exactly |
| Focus not restored after overlay close | Save and restore `document.activeElement` |
| `h-screen` on mobile | `min-h-[100dvh]` |
| Gray text on gray background | WCAG AA 4.5:1 minimum |
| Touch targets under 44px | Minimum 44-44px |

---

## Sources

- Emil Kowalski - Design engineering philosophy (Sonner, Vaul, Linear)
- Heydon Pickering - Inclusive Components
- React docs (react.dev) - Composition vs Inheritance
- Vue 3 docs (vuejs.org) - Composition API
- Svelte 5 docs (svelte.dev) - Runes
- MDN ARIA Authoring Practices Guide
- WCAG 2.2 - Accessibility guidelines
- Radix UI - Focus trap, popover, tooltip patterns
- Base UI - Transform origin variables

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
