---
name: responsive-engine
description: Design multi-device layouts with Container Queries, clamp() fluid typography, :has() selector, subgrid, and modern CSS units (dvh/svh/lvh). Use when user asks to make a layout responsive, handle mobile/tablet/desktop breakpoints, create fluid typography, or use Container Queries. Do NOT use for full-page layouts (use landing-craft), component design (use component-forge), or animation-specific responsive (use motion-craft).
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "2.0"
---

# Responsive Engine

CSS layouts that work across every screen size without breakpoint spaghetti.

## Core Principle

Responsive design is about containers, not viewports. Use Container Queries first, media queries only for global layout shifts.

## Container Queries (preferred over media queries)

```css
/* Define a containment context */
.card-grid {
  container-type: inline-size;
  container-name: card-grid;
}

/* Query by container width, NOT viewport */
@container card-grid (min-width: 600px) {
  .card {
    display: grid;
    grid-template-columns: 200px 1fr;
  }
}

@container card-grid (min-width: 900px) {
  .card {
    grid-template-columns: 1fr 1fr 1fr;
  }
}
```

### Container query length units

```css
.card {
  padding: 10cqw;      /* 10% of container width */
  font-size: 5cqi;     /* 5% of container inline size */
  margin-block: 2cqb;  /* 2% of container block size */
  border-radius: 1cqmin; /* 1% of container smaller side */
}
```

## Parent-Based Responsive with :has()

Detect parent size and style children accordingly:

```css
/* Sidebar mode: when parent has class .sidebar */
.sidebar:has(.card) .card {
  flex-direction: column;
  text-align: center;
}

/* Card layout changes based on number of siblings */
.grid:has(> :last-child:nth-child(3)) .item {
  grid-column: span 1;
}

.grid:has(> :last-child:nth-child(2)) .item {
  grid-column: span 1;
}
```

## Form Factor Detection

```css
/* Touch vs mouse */
@media (pointer: coarse) {
  .button { min-height: 48px; }
}

@media (hover: hover) {
  .card:hover { transform: scale(1.02); }
}

@media (hover: none) {
  .card:active { transform: scale(0.98); }
}
```

## Subgrid

```css
.card-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.card {
  display: grid;
  grid-template-rows: subgrid;  /* Align children across cards */
  grid-row: span 3;             /* Span 3 rows of the parent grid */
}
```

## Modern CSS Viewport Units

| Unit | Description | Use case |
|------|-------------|----------|
| `dvh` | Dynamic viewport height | Mobile (handles URL bar showing/hiding) |
| `svh` | Smallest viewport height | Fallback for dvh |
| `lvh` | Largest viewport height | Full-screen with URL bar hidden |
| `dvw` | Dynamic viewport width | Similar for width |
| `ic` | Advance measure of "水" glyph | Width-based on CJK characters |
| `cap` | Cap height of font | Aligning to font metrics |

```css
.hero {
  height: 100dvh;      /* Dynamic: adapts to URL bar on mobile */
  min-height: 100svh;   /* Fallback: never smaller than smallest viewport */
}
```

## Fluid Typography

```css
--text-sm: clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
--text-base: clamp(1rem, 0.9rem + 0.35vw, 1.25rem);
--text-lg: clamp(1.25rem, 1rem + 0.75vw, 1.75rem);
--text-xl: clamp(1.5rem, 1rem + 1.5vw, 2.5rem);
--text-display: clamp(2.5rem, 1.5rem + 4vw, 5rem);
```

### Fluid spacing

```css
--space-xs: clamp(0.25rem, 0.2rem + 0.25vw, 0.5rem);
--space-sm: clamp(0.5rem, 0.4rem + 0.5vw, 1rem);
--space-md: clamp(1rem, 0.8rem + 1vw, 2rem);
--space-lg: clamp(2rem, 1.5rem + 2vw, 4rem);
--space-xl: clamp(4rem, 3rem + 4vw, 8rem);
```

## Breakpoint System (for global layout only)

| Name | Width | Target |
|------|-------|--------|
| sm | 640px | Mobile portrait |
| md | 768px | Tablet portrait |
| lg | 1024px | Tablet landscape / small desktop |
| xl | 1280px | Desktop |
| 2xl | 1536px | Large desktop |

Use the minimum number of breakpoints. Never add one "just in case."

## Layout Strategy

- **Mobile**: single column, stacked, full-width touch targets
- **Tablet**: 2-column grid where content allows
- **Desktop**: multi-column with sidebars or full-width sections
- **Large**: max-width container (1280px) + centered

## Touch Targets

- Minimum 44x44px for all interactive elements
- Minimum 8px gap between touch targets
- No hover-dependent interactions on mobile
- Use `@media (pointer: coarse)` for touch-optimized sizing

## Testing Checklist

- [ ] Content does not overflow on 320px width
- [ ] No horizontal scroll on any breakpoint
- [ ] Text readable without zoom (min 16px body)
- [ ] Images scale correctly at all sizes
- [ ] Navigation usable at all breakpoints
- [ ] Forms not broken on mobile
- [ ] Tables have horizontal scroll or responsive variant
- [ ] Container Queries used over media queries where possible

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Media queries for component responsiveness | Container Queries |
| Fixed widths in px | Use clamp(), %, dvh/dvw, or cqi/cqw |
| Hover-only interactions on mobile | Add `@media (hover: hover)` guard |
| Touch targets < 44px | Interactive elements ≥ 44×44px |
| Body font < 16px | Minimum 16px, clamp() for fluid scaling |
| No :has() fallback | `@supports selector(:has(*))` guard |
| Deeply nested media queries | Container Queries eliminate most media queries |

## Workflow

| Step | Task | Method |
|------|------|--------|
| 1 | Set up containment | `container-type: inline-size` on section/components |
| 2 | Design mobile layout | Single column, full-width, 44px touch targets |
| 3 | Add container queries | `@container (min-width: ...)` before media queries |
| 4 | Apply fluid sizing | `clamp()` for typography, spacing, widths |
| 5 | Handle edge cases | `:has()` for parent-aware layouts, subgrid for aligned grids |
| 6 | Test breakpoints | 320px, 640px, 768px, 1024px, 1280px |
| 7 | Verify no overflow | No horizontal scroll, no clipped content at any width |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Horizontal scroll at 320px | Element wider than viewport | Check for fixed widths, overflow: hidden, or large margins |
| Container query not firing | Container missing `container-type` | Add `container-type: inline-size` to parent |
| :has() not working | Old browser | Add `@supports selector(:has(*))` guard with fallback |
| Subgrid items misaligned | Parent grid row count mismatch | Ensure all subgrid items have matching `grid-row: span N` |
| Mobile tap target too small | Button under 44px | Increase to min 48px height, full-width on mobile |
| Fluid text too large on desktop | clamp() max value excessive | Cap at reasonable max (e.g., 5rem for display) |
| dvh unit jumps on mobile scroll | Browser recalculates URL bar height | Use `100dvh` with `100svh` as min-height fallback |

## Sources

- CSS Container Queries (MDN)
- CSS :has() selector (MDN)
- CSS Subgrid (MDN)
- web.dev "Responsive and fluid typography with clamp()"
- New Viewport Units (dvh, svh, lvh) — web.dev
- Every Layout — responsive layout patterns
- MDN: Using media queries
