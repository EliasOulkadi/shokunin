# Responsive Layout Patterns

Practical, repeatable layout patterns inspired by Every Layout and real-world component libraries.

---

## Pattern 1: Stack

Vertical rhythm with consistent spacing between children. The most fundamental layout primitive.

```css
.stack {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.stack > * + * {
  margin-block-start: var(--space, 1rem);
}

/* Recursive variant: also spaces nested stacks */
.stack-recursive,
.stack-recursive > .stack {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.stack-recursive > * + *,
.stack-recursive > .stack > * + * {
  margin-block-start: var(--space, 1rem);
}

/* Splitting: use auto margins to push elements apart */
.stack-split > :nth-last-child(2) {
  margin-block-end: auto;
}
```

### HTML

```html
<div class="stack" style="--space: 1.5rem">
  <h1>Title</h1>
  <p>Description text</p>
  <button>Action</button>
</div>
```

### When to use

- Article content, form fields, card bodies
- Anytime you need vertical rhythm without manual margin classes

---

## Pattern 2: Sidebar

A flexible sidebar layout that places a primary content area and a sidebar side by side, collapsing the sidebar below a threshold.

```css
.sidebar-layout {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 1rem);
}

.sidebar-layout > :first-child {
  flex-basis: var(--sidebar-width, 16rem);
  flex-grow: 1;
}

.sidebar-layout > :last-child {
  flex-basis: 0;
  flex-grow: 999;
  min-inline-size: 50%;
}

/* Reverse: sidebar on the right */
.sidebar-layout-reversed > :first-child {
  flex-basis: 0;
  flex-grow: 999;
  min-inline-size: 50%;
}

.sidebar-layout-reversed > :last-child {
  flex-basis: var(--sidebar-width, 16rem);
  flex-grow: 1;
}
```

### HTML

```html
<div class="sidebar-layout" style="--sidebar-width: 300px; --gutter: 2rem">
  <aside><!-- sidebar --></aside>
  <main><!-- content --></main>
</div>
```

### How it works

- `flex-grow: 999` on the content forces it to absorb all extra space
- `flex-basis: var(--sidebar-width)` on the sidebar defines its desired width
- `flex-wrap: wrap` allows the sidebar to drop below content when there isn't enough room
- `min-inline-size: 50%` ensures content never shrinks below half the container

### When to use

- Blog + sidebar, dashboard sidebar, product detail with aside

---

## Pattern 3: Grid

Autofitting grid with minimum column size. Replaces media query-based breakpoint systems.

```css
.grid {
  display: grid;
  grid-template-columns: repeat(
    var(--grid-placement, auto-fill),
    minmax(var(--grid-min-size, 16rem), 1fr)
  );
  gap: var(--gutter, 1rem);
}

/* Fixed column count variant */
.grid-columns {
  display: grid;
  grid-template-columns: repeat(var(--grid-columns, 3), 1fr);
  gap: var(--gutter, 1rem);
}

@media (max-width: 640px) {
  .grid-columns {
    grid-template-columns: 1fr;
  }
}

/* Grid with featured item spanning 2 columns */
.grid-featured {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr));
  gap: 1rem;
}

.grid-featured > :first-child {
  grid-column: 1 / -1;
}

@container (min-width: 600px) {
  .grid-featured > :first-child {
    grid-column: span 2;
  }
}

/* Responsive without media queries — natural autofill behavior */
.grid-auto {
  display: grid;
  gap: var(--gutter, 1rem);
  grid-template-columns: repeat(
    auto-fill,
    minmax(min(var(--grid-min-size, 16rem), 100%), 1fr)
  );
}
```

### The `min()` trick

```css
minmax(min(var(--grid-min-size, 16rem), 100%), 1fr)
```

This ensures the minimum column size never exceeds 100% of the container, preventing overflow on very small screens without media queries.

### HTML

```html
<div class="grid" style="--grid-min-size: 300px; --gutter: 1.5rem">
  <div class="card">Card 1</div>
  <div class="card">Card 2</div>
  <div class="card">Card 3</div>
</div>
```

### When to use

- Card grids, galleries, product listings, dashboard widget layouts

---

## Pattern 4: Centered Content

Content constrained to a readable width with optional full-bleed children.

```css
.centered-content {
  box-sizing: content-box;
  margin-inline: auto;
  max-inline-size: var(--content-max-width, 65ch);
  padding-inline: var(--content-padding, 1rem);
}

/* Full-bleed: children that break out of the centered constraint */
.centered-content-full-bleed {
  display: grid;
  grid-template-columns:
    [full-start]
    minmax(var(--content-padding, 1rem), 1fr)
    [content-start]
    minmax(0, var(--content-max-width, 65ch))
    [content-end]
    minmax(var(--content-padding, 1rem), 1fr)
    [full-end];
}

.centered-content-full-bleed > * {
  grid-column: content;
}

.centered-content-full-bleed > .full-bleed {
  grid-column: full;
}

/* Wrapper with max-width */
.wrapper {
  max-inline-size: var(--wrapper-max-width, 1280px);
  margin-inline: auto;
  padding-inline: var(--content-padding, 1rem);
}
```

### HTML

```html
<article class="centered-content-full-bleed">
  <h1>Article Title</h1>
  <p>Regular content stays centered.</p>
  <figure class="full-bleed">
    <img src="hero.jpg" alt="">
  </figure>
  <p>More content within the constraint.</p>
</article>
```

### When to use

- Article bodies, blog posts, documentation content
- Full-bleed hero images, pull quotes, wide tables

---

## Pattern 5: Reflow

Items reflow from a horizontal row to stacked vertical based on available space. Uses flexbox wrapping.

```css
.reflow {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 1rem);
  align-items: var(--reflow-align, center);
}

/* Evenly distributed reflow */
.reflow-even {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 1rem);
  justify-content: center;
}

.reflow-even > * {
  flex: 1 1 var(--reflow-min-size, 12rem);
}

/* Reflow with breakpoint control */
.reflow-controlled {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 1rem);
}

.reflow-controlled > * {
  flex: 1 1 var(--reflow-item-width, 200px);
}

/* Toolbar-style: items reflow, last item aligns to end */
.reflow-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 0.5rem);
  align-items: center;
}

.reflow-toolbar > :last-child {
  margin-inline-start: auto;
}

@media (max-width: 480px) {
  .reflow-toolbar > :last-child {
    margin-inline-start: 0;
  }
}
```

### HTML

```html
<div class="reflow" style="--gutter: 1.5rem">
  <button>Save</button>
  <button>Cancel</button>
  <button>Delete</button>
  <span>Status: Active</span>
</div>
```

### When to use

- Toolbars, button groups, form actions, tag lists, nav items
- Any horizontal list that should wrap on small screens

---

## Pattern 6: Off-Canvas

A sidebar or panel that slides in from the edge, common for mobile navigation and filter panels.

```css
.off-canvas {
  --off-canvas-transition: 300ms ease;
  --off-canvas-width: min(80vw, 20rem);
}

/* The overlay backdrop */
.off-canvas-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--off-canvas-transition);
  z-index: 998;
}

.off-canvas-backdrop[data-open] {
  opacity: 1;
  pointer-events: auto;
}

/* The panel itself */
.off-canvas-panel {
  position: fixed;
  inset-block: 0;
  inline-size: var(--off-canvas-width);
  background: var(--surface, #fff);
  overflow-y: auto;
  z-index: 999;
  transition: transform var(--off-canvas-transition);
}

/* Left-aligned panel */
.off-canvas-panel-start {
  inset-inline-start: 0;
  transform: translateX(-100%);
}

.off-canvas-panel-start[data-open] {
  transform: translateX(0);
}

/* Right-aligned panel */
.off-canvas-panel-end {
  inset-inline-end: 0;
  transform: translateX(100%);
}

.off-canvas-panel-end[data-open] {
  transform: translateX(0);
}

/* Top sheet */
.off-canvas-top {
  position: fixed;
  inset-inline: 0;
  block-size: var(--off-canvas-height, 50vh);
  background: var(--surface, #fff);
  z-index: 999;
  overflow-y: auto;
  transition: transform var(--off-canvas-transition);
  inset-block-start: 0;
  transform: translateY(-100%);
}

.off-canvas-top[data-open] {
  transform: translateY(0);
}

/* Bottom sheet */
.off-canvas-bottom {
  position: fixed;
  inset-inline: 0;
  block-size: var(--off-canvas-height, 40vh);
  background: var(--surface, #fff);
  z-index: 999;
  overflow-y: auto;
  transition: transform var(--off-canvas-transition);
  inset-block-end: 0;
  transform: translateY(100%);
}

.off-canvas-bottom[data-open] {
  transform: translateY(0);
  border-radius: 16px 16px 0 0;
}

/* Close button */
.off-canvas-close {
  position: absolute;
  inset-block-start: 0.75rem;
  inset-inline-end: 0.75rem;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
  font-size: 1.5rem;
  line-height: 1;
}

/* Responsive: show as persistent sidebar on large screens */
@media (min-width: 1024px) {
  .off-canvas-panel {
    position: static;
    transform: none !important;
    z-index: auto;
  }

  .off-canvas-backdrop {
    display: none;
  }
}
```

### HTML

```html
<div class="off-canvas">
  <button data-toggle="nav-panel">☰ Menu</button>

  <div class="off-canvas-backdrop" id="nav-backdrop"></div>

  <nav class="off-canvas-panel off-canvas-panel-start" id="nav-panel">
    <button class="off-canvas-close" data-close="nav-panel">✕</button>
    <ul><!-- nav links --></ul>
  </nav>
</div>

<script>
  document.querySelectorAll('[data-toggle]').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.toggle;
      document.getElementById(id)?.toggleAttribute('data-open');
      document.getElementById(id + '-backdrop')?.toggleAttribute('data-open');
    });
  });

  document.querySelectorAll('[data-close]').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.close;
      document.getElementById(id)?.removeAttribute('data-open');
      document.getElementById(id + '-backdrop')?.removeAttribute('data-open');
    });
  });
</script>
```

### When to use

- Mobile navigation menus
- Filter/sort panels on product listing pages
- Bottom sheets for share menus, action sheets
- Persistent sidebar on desktop that collapses on mobile

---

## Pattern 7: Cluster

A horizontal list that wraps naturally with controlled gaps. Good for tags, badges, and metadata.

```css
.cluster {
  display: flex;
  flex-wrap: wrap;
  gap: var(--cluster-gap, 0.5rem);
  align-items: var(--cluster-align, center);
  justify-content: var(--cluster-justify, flex-start);
}
```

### HTML

```html
<div class="cluster" style="--cluster-gap: 0.5rem">
  <span class="tag">HTML</span>
  <span class="tag">CSS</span>
  <span class="tag">JavaScript</span>
  <span class="tag">Accessibility</span>
</div>
```

---

## Pattern 8: Switcher

Switches between horizontal and vertical layouts at a specific container width threshold.

```css
.switcher {
  display: flex;
  flex-wrap: wrap;
  gap: var(--gutter, 1rem);
}

.switcher > * {
  flex-grow: 1;
  flex-basis: calc(
    (var(--switcher-threshold, 30rem) - 100%) * 999
  );
}

/* All items are at least the threshold width,
   so if the container is narrower than the threshold,
   each item flexes down to 0 and they stack vertically */
```

### How it works

- `(var(--switcher-threshold) - 100%) * 999` produces a very large positive number when the container is narrower than the threshold, and a very large negative number when wider
- `flex-basis` clamps to `0` for negative values, so items snap to equal widths above the threshold
- All items become the same width — use `.sidebar-layout` if you want unequal widths

### HTML

```html
<div class="switcher" style="--switcher-threshold: 40rem; --gutter: 2rem">
  <div><!-- panel 1 --></div>
  <div><!-- panel 2 --></div>
</div>
```

### When to use

- Two-state layouts: stacked on mobile, side-by-side on desktop
- Form with label + input switching row/column

---

## Combining Patterns

Patterns compose naturally:

```html
<!-- Centered page with sidebar + card grid inside -->
<div class="wrapper">
  <div class="sidebar-layout" style="--sidebar-width: 250px">
    <aside><!-- sidebar --></aside>
    <main class="stack" style="--space: 2rem">
      <h1>Products</h1>
      <div class="grid" style="--grid-min-size: 280px">
        <div class="card stack"><!-- card --></div>
        <div class="card stack"><!-- card --></div>
        <div class="card stack"><!-- card --></div>
      </div>
    </main>
  </div>
</div>
```

## Pattern Reference

| Pattern | Purpose | Key property |
|---------|---------|-------------|
| Stack | Vertical rhythm | `flex-direction: column` + `* + *` |
| Sidebar | Flexible content + aside | `flex-grow: 999` on content |
| Grid | Auto-fitting cards | `repeat(auto-fill, minmax(...))` |
| Centered | Constrained readability | `max-inline-size: 65ch` |
| Reflow | Wrapping horizontal items | `flex-wrap: wrap` |
| Off-canvas | Slide-in panels | `transform: translate()` |
| Cluster | Tag/chip lists | `flex-wrap: wrap` + `gap` |
| Switcher | Stack ↔ side-by-side | `flex-basis: calc((threshold - 100%) * 999)` |
