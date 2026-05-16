# Accessibility Patterns

## ARIA Roles & Properties Reference

### Landmark Roles

| Role | When to use | HTML equivalent |
|------|-------------|-----------------|
| `banner` | Site-wide header content | `<header>` (not nested in `<main>`) |
| `navigation` | Navigation block | `<nav>` |
| `main` | Primary content | `<main>` |
| `complementary` | Sidebar, aside | `<aside>` |
| `contentinfo` | Footer with copyright/privacy | `<footer>` (not nested in `<main>`) |
| `form` | Form that collects data | N/A — prefer native `<form>` |
| `region` | Section worth bookmarking | `<section>` with accessible name |

### Widget Roles

| Role | Keyboard interaction | ARIA attributes |
|------|---------------------|-----------------|
| `button` | Enter/Space to activate | — |
| `link` | Enter to navigate | — |
| `tab` | Arrow keys, Enter/Space to activate | `aria-selected`, `aria-controls` |
| `tabpanel` | — | `aria-labelledby` (points to tab) |
| `dialog` | Escape to close, focus trap | `aria-modal`, `aria-labelledby` |
| `alertdialog` | Same as dialog, announced on mount | `aria-describedby` for message |
| `tooltip` | Hover/focus to show, Escape to hide | — |
| `switch` | Arrow keys or Enter to toggle | `aria-checked` |

### Live Region Roles

| Role | When to use | Announcement behavior |
|------|-------------|----------------------|
| `alert` | Error or important status | Interrupts, announced immediately |
| `status` | Non-critical status updates | Waits for idle |
| `log` | Chat, log, game history | Appends only new content |
| `marquee` | Scrolling ticker text | Not recommended, use `aria-live` instead |
| `timer` | Countdown timer | Periodic updates |
| `progressbar` | Progress indicator | Updates with `aria-valuenow` |

### `aria-live` values

| Value | Behavior |
|-------|----------|
| `off` | Default, no announcement |
| `polite` | Waits for user to finish current action |
| `assertive` | Interrupts immediately |

## Keyboard Interaction Patterns

### Roving Tabindex

Single tab stop for a group; arrow keys move focus within. Use for: menu, toolbar, tablist, radiogroup, listbox.

```tsx
'use client'

import { useRef, useCallback, type KeyboardEvent, type ReactNode } from 'react'

interface RovingFocusOptions {
  orientation: 'horizontal' | 'vertical'
}

export function useRovingFocus({ orientation }: RovingFocusOptions) {
  const containerRef = useRef<HTMLDivElement>(null)

  const getItems = useCallback(() => {
    if (!containerRef.current) return []
    return Array.from(
      containerRef.current.querySelectorAll<HTMLElement>('[role="tab"]:not([disabled])')
    )
  }, [])

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const items = getItems()
      const currentIndex = items.findIndex((el) => el === document.activeElement)

      const prevKey = orientation === 'horizontal' ? 'ArrowLeft' : 'ArrowUp'
      const nextKey = orientation === 'horizontal' ? 'ArrowRight' : 'ArrowDown'

      let nextIndex: number | null = null

      if (e.key === prevKey) {
        e.preventDefault()
        nextIndex = (currentIndex - 1 + items.length) % items.length
      } else if (e.key === nextKey) {
        e.preventDefault()
        nextIndex = (currentIndex + 1) % items.length
      } else if (e.key === 'Home') {
        e.preventDefault()
        nextIndex = 0
      } else if (e.key === 'End') {
        e.preventDefault()
        nextIndex = items.length - 1
      }

      if (nextIndex !== null && items[nextIndex]) {
        items[nextIndex].focus()
      }
    },
    [getItems, orientation]
  )

  return { containerRef, handleKeyDown }
}

// Usage:
function TabList({ children }: { children: ReactNode }) {
  const { containerRef, handleKeyDown } = useRovingFocus({ orientation: 'horizontal' })

  return (
    <div ref={containerRef} role="tablist" onKeyDown={handleKeyDown}>
      {children}
    </div>
  )
}

function Tab({ isSelected, ...props }: { isSelected: boolean } & JSX.IntrinsicElements['button']) {
  return (
    <button
      role="tab"
      tabIndex={isSelected ? 0 : -1}
      aria-selected={isSelected}
      {...props}
    />
  )
}
```

### Common Keyboard Conventions

| Component | Keys |
|-----------|------|
| Menu / Menubar | Arrow keys navigate, Enter opens submenu, Escape closes, Home/End go to first/last |
| Combobox / Listbox | Arrow keys change option, Enter/Tab selects, Escape closes |
| Tree / Treegrid | Arrow keys navigate, Right/Left expand/collapse, Enter activates |
| Slider | Arrow keys (increment 1), PageUp/PageDown (increment 10), Home/End (min/max) |
| Grid / DataGrid | Arrow keys navigate cells, Tab enters/leaves, Ctrl+Arrow to move focus without moving cell selection |

## Focus Management

### Focus Trap

Required for modals, dialogs, popovers, side panels. Traps Tab cycling within the container.

```tsx
'use client'

import { useRef, useEffect, type ReactNode } from 'react'

interface FocusTrapProps {
  children: ReactNode
  active?: boolean
  onEscape?: () => void
}

export function FocusTrap({ children, active = true, onEscape }: FocusTrapProps) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!active || !containerRef.current) return

    const container = containerRef.current
    const focusableSelector = [
      'a[href]',
      'button:not([disabled])',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])',
    ].join(', ')

    function getFocusableElements() {
      return Array.from(container.querySelectorAll<HTMLElement>(focusableSelector))
    }

    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        onEscape?.()
        return
      }

      if (e.key !== 'Tab') return

      const focusable = getFocusableElements()
      if (focusable.length === 0) {
        e.preventDefault()
        return
      }

      const first = focusable[0]
      const last = focusable[focusable.length - 1]

      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }

    // Auto-focus first focusable element
    const firstFocusable = getFocusableElements()[0]
    firstFocusable?.focus()

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [active, onEscape])

  return <div ref={containerRef}>{children}</div>
}
```

### Focus Restoration

Save and restore focus when a component (dialog, sidebar, menu) opens and closes.

```tsx
'use client'

import { useRef, useEffect } from 'react'

export function useFocusRestoration(active: boolean) {
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (active) {
      previousFocusRef.current = document.activeElement as HTMLElement
    } else if (previousFocusRef.current) {
      previousFocusRef.current.focus()
      previousFocusRef.current = null
    }
  }, [active])
}

// Usage:
function Dialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  useFocusRestoration(open)
  if (!open) return null
  return <div role="dialog">...</div>
}
```

### `focus-within` CSS

Highlight a container when any child has focus — excellent for card selection, form groups, data table rows.

```css
.card:focus-within {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

.form-group:focus-within .form-label {
  color: var(--color-primary);
}

/* Stacked: only visible when an interactive child is focused */
.toolbar-actions {
  opacity: 0.3;
  transition: opacity 0.15s;
}
tr:hover .toolbar-actions,
tr:focus-within .toolbar-actions {
  opacity: 1;
}
```

## Screen Reader Testing

### VoiceOver (macOS)

| Command | Action |
|---------|--------|
| `⌘F5` | Toggle VoiceOver |
| `Ctrl+Option+U` | Open rotor (headings, links, landmarks) |
| `Ctrl+Option+→/←` | Navigate next/previous item |
| `Ctrl+Option+Shift+↓` | Enter a group |
| `Ctrl+Option+Shift+↑` | Exit a group |
| `Ctrl+Option+Space` | Activate element |

### NVDA (Windows)

| Command | Action |
|---------|--------|
| `Insert+F7` | Element list (headings, links, landmarks) |
| `Insert+Space` | Toggle browse/focus mode |
| `↓/↑` | Navigate by line (browse mode) |
| `Tab` | Navigate by focusable element |
| `H` | Next heading |
| `D` | Next landmark |
| `K` | Next link |
| `G` | Next graphic |

### JAWS (Windows)

| Command | Action |
|---------|--------|
| `Insert+F3` | List of elements |
| `Insert+F5` | Form fields list |
| `Insert+F6` | Headings list |
| `Insert+F7` | Links list |
| `H` | Next heading |
| `T` | Next table |
| `M` | Next frame |
| `Q` | Next quote block |

### Testing checklist

- [ ] Navigate the entire page using only Tab (focusable elements)
- [ ] Navigate using only arrow keys (lists, menus, sliders)
- [ ] All images have meaningful `alt` text (or `alt=""` for decorative)
- [ ] Error messages are linked to inputs via `aria-describedby`
- [ ] Dynamic updates are announced (`aria-live`, `role="alert"`)
- [ ] Focus order matches visual order (DOM order)
- [ ] No focus trap without escape hatch (Escape should always release)
- [ ] Touch targets are at least 44×44px (WCAG 2.5.8)

## Color Contrast Ratios

| WCAG level | Normal text | Large text (≥18px bold or ≥24px) | UI components & graphics |
|-----------|-------------|----------------------------------|--------------------------|
| AA | 4.5:1 | 3:1 | 3:1 |
| AAA | 7:1 | 4.5:1 | N/A |

### Quick reference

| Contrast ratio | Example pair | Passes AA normal text? |
|---------------|-------------|------------------------|
| 21:1 | `#000` on `#FFF` | ✓ |
| 13.3:1 | `#1a1a1a` on `#f5f5f5` | ✓ |
| 7:1 | `#333` on `#FFF` | ✓ |
| 5.6:1 | `#595959` on `#FFF` | ✓ |
| 4.5:1 | `#767676` on `#FFF` | ✓ (minimum AA) |
| 3.7:1 | `#999` on `#FFF` | ✗ (AA fail) |
| 2.3:1 | `#BBB` on `#FFF` | ✗ |
| 1.25:1 | `#E0E0E0` on `#FFF` | ✗ |

### Common pitfalls

- **Disabled text**: minimum 3:1 against background (WCAG 2.1 pass-through for disabled controls)
- **Placeholder text**: needs 4.5:1 — use helper text below the field instead
- **Focus indicators**: 3:1 against adjacent colors, minimum 2px thickness
- **Hover states**: color change alone is insufficient — pair with underline, icon, or background

### Color contrast ratio formula

```
L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  (where R, G, B are sRGB linearized)
contrast = (L1 + 0.05) / (L2 + 0.05)
  (L1 = lighter color, L2 = darker color)
```
