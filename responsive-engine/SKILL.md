---
name: responsive-engine
description: Design multi-device layouts with fluid typography
---


# Responsive Engine

Generates CSS and layout strategies that work across mobile, tablet, desktop, and large screens without breakpoint spaghetti.

## Breakpoint System

| Name | Width | Target |
|------|-------|--------|
| sm | 640px | Mobile portrait |
| md | 768px | Mobile landscape / tablet |
| lg | 1024px | Tablet landscape / small desktop |
| xl | 1280px | Desktop |
| 2xl | 1536px | Large desktop |

Use the minimum number of breakpoints needed. Never add one "just in case."

## Fluid Typography

```css
/* Use clamp() for all text sizes */
--text-sm: clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
--text-base: clamp(1rem, 0.9rem + 0.35vw, 1.25rem);
--text-lg: clamp(1.25rem, 1rem + 0.75vw, 1.75rem);
--text-xl: clamp(1.5rem, 1rem + 1.5vw, 2.5rem);
--text-display: clamp(2.5rem, 1.5rem + 4vw, 5rem);
```

## Layout Strategy

- **Mobile**: single column, stacked
- **Tablet**: 2-column grid where content allows
- **Desktop**: multi-column with sidebars or full-width sections
- **Large**: max-width container (1280px) + centered

## Patterns

### Stack (default)
```css
.stack { display: flex; flex-direction: column; gap: var(--space); }
```

### Sidebar
```css
.sidebar-layout {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-lg);
}
@media (min-width: 768px) {
  .sidebar-layout {
    grid-template-columns: 280px 1fr;
  }
}
```

### Full-width hero with constrained content
```css
.hero {
  width: 100%;
}
.hero-content {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 var(--space-md);
}
```

## Touch Targets

- Minimum 44x44px for all interactive elements
- Minimum 8px gap between touch targets
- No hover-dependent interactions on mobile

## Testing Checklist

- [ ] Content does not overflow on 320px width
- [ ] No horizontal scroll on any breakpoint
- [ ] Text is readable without zoom (min 16px body)
- [ ] Images scale correctly at all sizes
- [ ] Navigation usable at all breakpoints
- [ ] Forms are not broken on mobile
- [ ] Tables have horizontal scroll or responsive variant

## Sources
- MDN Responsive Design
- CSS-Tricks responsive patterns
- web.dev








