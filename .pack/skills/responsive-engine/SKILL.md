---
name: responsive-engine
description: Design multi-device layouts with Container Queries, clamp() fluid typography, :has() selector, subgrid, and modern CSS units (dvh/svh/lvh). Use when user asks to make a layout responsive, handle mobile/tablet/desktop breakpoints, create fluid typography, or use Container Queries. Do NOT use for full-page layouts (use landing-craft), component design (use component-forge), or animation-specific responsive (use motion-craft).
triggers:
  - "responsive design"
  - "responsive layout"
  - "mobile layout"
  - "container queries"
  - "fluid typography"
  - "clamp"
  - "mobile responsive"
  - "responsive grid"
  - "multi-device"
  - "subgrid"
  - ":has()"
  - "viewport units"
negatives:
  - "page layout"
  - "full landing page"
  - "components"
  - "animations"
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# Responsive Engine

Layouts that work at every screen size without breakpoint spaghetti. Inspired by Ahmad Shadeed (Container Queries), Jen Simmons (Intrinsic Web Design), and the CSS Working Group.

## Core Principle

Responsive design is about containers, not viewports. Use Container Queries first, media queries only for global layout shifts and form factor detection.

---

## Container Queries (preferred over media queries)

```css
.card-grid {
  container-type: inline-size;
  container-name: card-grid;
}

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

---

## Form Factor Detection

Detect the device type, not just width.

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

/* Portrait vs landscape */
@media (orientation: portrait) {
  .hero-grid { grid-template-columns: 1fr; }
}
```

---

## Viewport Unit Decision Tree

| Use case | Unit | Why |
|----------|------|-----|
| Full-screen hero | `min-h-[100dvh]` | Adapts to URL bar on mobile. Never `100vh` — iOS Safari viewport jumps. |
| Minimum safe height | `min-height: 100svh` | Small viewport height. Fallback for when URL bar is visible. |
| Large viewport design | `100lvh` | Maximum when URL bar hidden. Only for desktop-like experiences. |
| Width-based | `dvw` | Dynamic viewport width. Avoid on scroll-zooming mobile pages. |

```css
.hero {
  height: 100dvh;
  min-height: 100svh;  /* Fallback: never smaller than smallest viewport */
}
```

### The `h-screen` ban

`h-screen` equals `100vh` which equals disaster on iOS Safari. The URL bar entering/exiting causes catastrophic layout jumps. Always use `min-h-[100dvh]`.

---

## Fluid Typography

```css
:root {
  --text-sm:      clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
  --text-base:    clamp(1rem, 0.9rem + 0.35vw, 1.25rem);
  --text-lg:      clamp(1.25rem, 1rem + 0.75vw, 1.75rem);
  --text-xl:      clamp(1.5rem, 1rem + 1.5vw, 2.5rem);
  --text-2xl:     clamp(1.75rem, 1.25rem + 2vw, 3rem);
  --text-3xl:     clamp(2rem, 1.5rem + 3vw, 4rem);
  --text-display: clamp(2.5rem, 1.5rem + 5vw, 6rem);
}
```

### Fluid spacing

```css
:root {
  --space-xs: clamp(0.25rem, 0.2rem + 0.25vw, 0.5rem);
  --space-sm: clamp(0.5rem, 0.4rem + 0.5vw, 1rem);
  --space-md: clamp(1rem, 0.8rem + 1vw, 2rem);
  --space-lg: clamp(2rem, 1.5rem + 2vw, 4rem);
  --space-xl: clamp(3rem, 2rem + 3vw, 6rem);
  --space-2xl: clamp(4rem, 3rem + 5vw, 10rem);
}
```

---

## Subgrid

```css
.card-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.card {
  display: grid;
  grid-template-rows: subgrid;
  grid-row: span 3;
}
```

All children across cards align to the same row heights.

---

## Parent-Based Responsive with :has()

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

/* Detect empty state */
.container:has(.empty-state) {
  justify-content: center;
}
```

Fallback check:
```css
@supports not selector(:has(*)) {
  .grid .item { grid-column: span 1; } /* fallback */
}
```

---

## Touch Target Physics

| Element | Minimum | Recommended |
|---------|---------|-------------|
| Button | 44×44px | 48×48px |
| Link in nav | 44×44px | 48×48px |
| Checkbox / radio | 24×24px | 32×32px (invisible hit area) |
| Input field | 44px height | 48px height |
| Gap between touchable | 8px | 12px |

```css
.interactive {
  min-width: 44px;
  min-height: 44px;
}

/* Invisible hit area for small controls */
.small-control::after {
  content: '';
  position: absolute;
  inset: -8px;  /* expands hit area without visual change */
}
```

---

## Layout Strategy by Device

Each layout archetype needs a mobile collapse rule.

| Desktop layout | Mobile collapse |
|---------------|-----------------|
| 3 columns | 1 column stack (`grid-cols-1`) |
| Split screen 50/50 | Full-width stack (`w-full`) |
| Asymmetric grid (2fr 1fr) | `grid-template-columns: 1fr`, remove all `col-span` overrides |
| Horizontal scroll | Preserve if content is images/cards, restack if text |
| Overlapping elements | Remove all negative margins and rotations below `768px` |
| Sidebar + content | Stack: sidebar collapses to top (or hamburger) |

```css
/* Universal mobile collapse */
@media (max-width: 767px) {
  .split-layout { grid-template-columns: 1fr; }
  .asymmetric-grid { grid-template-columns: 1fr; }
  .overlap-card { margin-top: 0; transform: none; }
  [class*="col-span"] { grid-column: span 1; }
}
```

---

## Breakpoint System (global layout only)

| Name | Width | Target |
|------|-------|--------|
| sm | 640px | Mobile landscape |
| md | 768px | Tablet portrait |
| lg | 1024px | Tablet landscape / small desktop |
| xl | 1280px | Desktop |
| 2xl | 1536px | Large desktop |

Never add a breakpoint "just in case." If you have more than 4 breakpoints, refactor to Container Queries.

---

## Testing Checklist

- [ ] Content does not overflow on 320px width
- [ ] No horizontal scroll on any breakpoint
- [ ] Text readable without zoom (min 16px body)
- [ ] Images scale correctly at all sizes
- [ ] Navigation usable at all breakpoints
- [ ] Forms not broken on mobile
- [ ] Tables have horizontal scroll or responsive variant
- [ ] Container Queries used over media queries where possible
- [ ] `h-screen` replaced with `min-h-[100dvh]` everywhere
- [ ] Touch targets ≥ 44×44px with 8px gap
- [ ] Fixed widths in px replaced with `clamp()`, `%`, `cqi`
- [ ] Asymmetric layouts collapse to 1 column below `768px`
- [ ] Overlapping elements separated on mobile
- [ ] `:has()` guarded with `@supports` fallback

---

## Error Handling

| Problem | Cause | Fix |
|---------|-------|-----|
| Horizontal scrollbar on mobile | Fixed-width element > viewport | Replace px with `clamp()`, `%`, or `100%` |
| Layout jump on iOS Safari | `h-screen` used | Replace with `min-h-[100dvh]` |
| Text unreadable on mobile | Body font < 16px | Minimum 16px, scale with clamp() |
| Touch target too small | Clickable < 44px | Expand hit area with padding or `::after` |
| Container Query not working | Missing `container-type` | Set `container-type: inline-size` on parent |
| Subgrid rows not aligned | Missing `grid-template-rows: subgrid` | Verify parent has explicit rows |
| `100vh` causes scroll | Didn't account for URL bar | Use `dvh` or `svh` |
| Hover effect fires on touch | No `@media (hover: hover)` guard | Gate hover behind pointer media query |

---

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Media queries for component responsiveness | Container Queries |
| Fixed widths in px | `clamp()`, `%`, `dvw`, or `cqi`/`cqw` |
| Hover-only interactions on mobile | Add `@media (hover: hover)` guard |
| Touch targets < 44px | Interactive elements ≥ 44×44px |
| Body font < 16px | Minimum 16px, clamp() for fluid scaling |
| No :has() fallback | `@supports selector(:has(*))` guard |
| Deeply nested media queries | Container Queries eliminate most |
| `h-screen` for full-height | `min-h-[100dvh]` |
| Same layout at all sizes | Layout must collapse on mobile |
| Asymmetric layout stays asymmetric on mobile | Force 1-column below `768px` |
| Overlapping elements on touch | Separate on mobile. Touch layers cause mis-taps. |
| `calc()` with mixed units for grid | Use CSS Grid `fr` units + `minmax()` |
| Complex flexbox math (`w-[calc(33%-1rem)]`) | CSS Grid `grid-cols-3` with `gap` |
| Testing only at desktop width | Test at 320px, 375px, 768px, 1024px, 1440px |

---

## Pre-Flight Checklist

Before delivering responsive layout code:

- [ ] No horizontal scroll at any width (tested at 320px)
- [ ] `min-h-[100dvh]` used instead of `h-screen`
- [ ] Body font ≥ 16px at all widths
- [ ] Touch targets ≥ 44×44px, gap ≥ 8px
- [ ] Media queries only for global layout shifts
- [ ] Container Queries for component responsiveness
- [ ] Asymmetric layouts collapse to single column below 768px
- [ ] Overlapping elements separated on mobile
- [ ] Hover interactions gated behind `@media (hover: hover)`
- [ ] Images have `width`/`height` attributes + `object-fit` or `aspect-ratio`
- [ ] Forms single-column on mobile, large inputs (44px+)
- [ ] `:has()` fallbacks defined
- [ ] No `px`-only spacing — use fluid or relative units
- [ ] Grid used instead of complex flexbox math
- [ ] Table has responsive wrapper or data-label approach
- [ ] Navigation is usable via touch at all widths

---

## Sources

- Ahmad Shadeed — Container Queries deep dive (ishadeed.com)
- Jen Simmons — Intrinsic Web Design
- CSS Container Queries (MDN)
- CSS :has() selector (MDN)
- CSS Subgrid (MDN)
- web.dev — Responsive and fluid typography with clamp()
- New Viewport Units (dvh, svh, lvh) — web.dev
- Every Layout — responsive layout patterns
- WCAG 2.2 — Touch target size
- iOS Safari viewport bug documentation (WebKit blog)

## Workflow

### Step 1: Audit existing layout

Before writing any CSS, identify what's broken:
- Open Chrome DevTools Device Toolbar (Ctrl+Shift+M)
- Test at 320px, 375px, 768px, 1024px, 1440px
- Flag: horizontal scrollbars, overflowing content, text < 16px, touch targets < 44px
- Screenshot at each breakpoint for before/after comparison

### Step 2: Establish container query boundaries

1. Identify components needing independent responsiveness (cards, sidebars, grid items)
2. Set `container-type: inline-size` on their direct parent
3. Name containers with `container-name` for complex nested layouts
4. Replace any media queries targeting those components with `@container` rules

### Step 3: Replace fixed units with fluid units

1. Find all `px` values for widths, font sizes, spacing
2. Convert fonts to `clamp()` (minimum, preferred, maximum)
3. Convert spacing to `clamp()` or relative units (`%`, `cqi`, `cqw`)
4. Replace `h-screen` with `min-h-[100dvh]` everywhere

### Step 4: Write mobile collapse rules

1. Identify asymmetric layouts, overlapping elements, multi-column grids
2. Write `@media (max-width: 767px)` block collapsing everything to single column
3. Remove negative margins and rotations on mobile
4. Ensure touch targets >= 44x44px with 8px gap between interactive elements

### Step 5: Add form factor and accessibility guards

1. Gate hover effects behind `@media (hover: hover)`
2. Gate fine-pointer interactions behind `@media (pointer: fine)`
3. Add `@supports selector(:has(*))` fallbacks for all `:has()` selectors
4. Respect `prefers-reduced-motion` on all animations
5. Set minimum body font-size to 16px

### Step 6: Verify across devices

1. No horizontal scroll at any width from 320px to 2560px
2. `min-h-[100dvh]` replaces all `h-screen` instances
3. Touch targets >= 44x44px with 8px gap
4. Container Queries used for component responsiveness
5. Asymmetric layouts collapse to single column below 768px
6. All `:has()` selectors guarded with `@supports` fallback

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
