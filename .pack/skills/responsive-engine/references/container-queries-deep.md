# Container Queries Deep Reference

## Overview

CSS Container Queries allow components to respond to their parent container's size rather than the viewport. This is the foundation of component-driven responsive design.

Browser support: Chrome 105+, Firefox 110+, Safari 16+, Edge 105+

---

## 1. Setting Up a Containment Context

Before querying a container, it must establish a containment context. This is done with the `container-type` property.

### container-type

```css
.container {
  container-type: inline-size; /* most common — queries inline axis (width in horizontal writing) */
  container-type: size;        /* queries both axes — beware: applies block-size containment too */
  container-type: normal;      /* no size containment, only style queries */
}
```

| Value | Containment applied | Use case |
|-------|-------------------|----------|
| `inline-size` | inline-axis layout + style | Default for responsive components |
| `size` | both-axis layout + inline + block | Layouts that need both dimensions (rare) |
| `normal` | style only | Style queries, not size queries |

**Performance note:** `size` applies block-size containment, meaning children cannot grow the container's block dimension by their intrinsic size. This often causes unexpected overflow. Prefer `inline-size` unless you fully understand the implications.

### container-name

```css
.card-grid {
  container-type: inline-size;
  container-name: sidebar-card-grid;
}

/* Shorthand combining both */
.sidebar {
  container: sidebar / inline-size;
}

.dashboard-widget {
  container: widget / inline-size;
}
```

Names prevent collisions when containers are nested.

---

## 2. The @container Syntax

```css
@container [name] (condition) {
  /* styles applied when the condition is true */
}
```

### Size conditions

```css
/* Min-width query (most common) */
@container card (min-width: 400px) { ... }

/* Max-width query */
@container card (max-width: 600px) { ... }

/* Range syntax (cleaner for multiple conditions) */
@container card (400px <= width < 800px) { ... }

/* Both axes — only works with container-type: size */
@container sidebar (min-width: 300px) and (min-height: 500px) { ... }
```

### Unnamed containers

When no name is given, the query targets the **nearest** ancestor with a containment context:

```css
@container (min-width: 400px) {
  .card { grid-template-columns: 1fr 1fr; }
}
```

This queries the closest containment ancestor.

### Nested containers

Containers can nest. A named `@container` only matches containers with that exact name, preventing ambiguity:

```css
.widget {
  container: widget / inline-size;
}

.widget .card {
  container: card / inline-size;
}

/* Targets only .widget containers */
@container widget (min-width: 500px) {
  .card { font-size: 1.25rem; }
}

/* Targets only .card containers */
@container card (min-width: 300px) {
  .card-title { font-size: 1.1rem; }
}
```

---

## 3. Container Query Length Units

Container query length units are relative to the **query container's** dimensions, not the viewport.

### Available units

| Unit | Relative to |
|------|-------------|
| `cqw` | 1% of container width |
| `cqh` | 1% of container height |
| `cqi` | 1% of container inline size |
| `cqb` | 1% of container block size |
| `cqmin` | 1% of container's smaller dimension |
| `cqmax` | 1% of container's larger dimension |

### Practical examples

```css
/* Typography scales with container inline-size */
.card-title {
  font-size: clamp(1rem, 4cqi, 2rem);
}

/* Padding proportional to container */
.card-body {
  padding: 2cqi;
}

/* Avatar sized relative to container inline-size */
.avatar {
  width: 8cqi;
  height: 8cqi;
  border-radius: 50%;
}

/* Minimum of width and height */
.modal {
  container-type: size;
  max-inline-size: 80cqmin;
}

/* Icon scales with the larger side */
.hero-icon {
  width: 15cqmax;
  height: 15cqmax;
}

/* Spacing relative to block dimension */
.stack > * + * {
  margin-block-start: 3cqb;
}
```

### Comparison: cqi vs cqw

- `cqi` — inline axis (respects writing mode: width in horizontal, height in vertical)
- `cqw` — always refers to physical width regardless of writing mode

Prefer `cqi`/`cqb` over `cqw`/`cqh` for writing-mode-aware layouts.

---

## 4. Style Queries (Advanced)

Style queries check a container's computed styles rather than its dimensions. Support: Chrome 111+.

```css
/* Check if container has a custom property set */
@container style(--theme: dark) {
  .card {
    background: #1a1a2e;
    color: #e0e0e0;
  }
}

@container style(--compact: true) {
  .card {
    padding: 0.5rem;
    gap: 0.25rem;
  }
}
```

Style queries enable theme-aware components that respond to their parent's context without prop-drilling or CSS class dependencies.

### Style query limitations

- Only custom properties can be queried, not standard CSS properties
- Only exact value matching works (no range conditions)
- The custom property must be set on the container element's style, not inherited

```css
/* ✅ Works */
.parent {
  --variant: primary;
  container-type: normal;
}
@container style(--variant: primary) { ... }

/* ❌ Does NOT work — inherited, not on container */
.parent { --variant: primary; }
.child-with-container { container-type: normal; }
@container style(--variant: primary) { ... } /* won't match */
```

---

## 5. Real-World Patterns

### Pattern 1: Card Grid

A card component that changes layout based on available container width.

```css
.card-grid {
  container: card-grid / inline-size;
  display: grid;
  gap: 1rem;
  grid-template-columns: 1fr;
}

/* Vertical stacked card below 400px */
@container card-grid (max-width: 399px) {
  .card {
    display: flex;
    flex-direction: column;
  }
  .card-image {
    width: 100%;
    aspect-ratio: 16 / 9;
  }
}

/* Horizontal card at 400px+ */
@container card-grid (400px <= width < 700px) {
  .card {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 1rem;
  }
  .card-image {
    height: 100%;
    aspect-ratio: auto;
  }
}

/* Multi-column layout at 700px+ */
@container card-grid (min-width: 700px) {
  .card-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  .card {
    display: flex;
    flex-direction: column;
  }
  .card-image {
    width: 100%;
    aspect-ratio: 1;
  }
}
```

### Pattern 2: Dashboard Widgets

Widgets that adapt to their grid cell size in a dashboard layout.

```css
.dashboard {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.widget {
  container: widget / inline-size;
  padding: 1rem;
  border-radius: 8px;
  background: var(--surface);
}

/* Compact: single row, small chart */
@container widget (max-width: 350px) {
  .widget-header {
    flex-direction: column;
    align-items: flex-start;
  }
  .widget-chart {
    height: 100px;
  }
  .widget-meta {
    display: none;
  }
}

/* Medium: side-by-side layout */
@container widget (350px <= width < 600px) {
  .widget-body {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 1rem;
  }
  .widget-chart {
    height: 150px;
  }
}

/* Expanded: full data with table */
@container widget (min-width: 600px) {
  .widget-body {
    display: grid;
    grid-template-columns: 1fr 2fr 1fr;
    gap: 1rem;
  }
  .widget-table {
    display: block;
    grid-column: 1 / -1;
  }
  .widget-chart {
    height: 200px;
  }
}
```

### Pattern 3: Sidebar Layout

A sidebar that reflows its content from icon-only to expanded to docked.

```css
.sidebar {
  container: sidebar / inline-size;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

/* Icon-only sidebar (collapsed) */
@container sidebar (max-width: 80px) {
  .sidebar-link {
    justify-content: center;
    padding: 0.75rem;
  }
  .sidebar-link span {
    display: none;
  }
  .sidebar-label {
    display: none;
  }
}

/* Semi-expanded with labels */
@container sidebar (80px < width < 200px) {
  .sidebar-link {
    gap: 0.75rem;
    padding: 0.5rem 0.75rem;
  }
  .sidebar-link span {
    font-size: 0.875rem;
  }
}

/* Fully expanded */
@container sidebar (min-width: 200px) {
  .sidebar-section {
    padding: 1rem;
  }
  .sidebar-link {
    padding: 0.625rem 1rem;
    border-radius: 6px;
  }
}
```

### Pattern 4: Split Panels

A dual-pane editor/viewer that adapts both panes based on overall container size.

```css
.split-panel {
  container: split / inline-size;
  display: grid;
  gap: 2px;
  background: var(--border);
}

/* Stacked vertically on narrow containers */
@container split (max-width: 500px) {
  .split-panel {
    grid-template-columns: 1fr;
  }
  .panel {
    min-height: 300px;
  }
}

/* Side-by-side on wider containers */
@container split (min-width: 500px) {
  .split-panel {
    grid-template-columns: 1fr 1fr;
  }
  .panel {
    min-height: auto;
  }
}

/* Uneven split on very wide */
@container split (min-width: 1000px) {
  .split-panel {
    grid-template-columns: 1fr 2fr;
  }
}
```

---

## 6. Performance & Best Practices

### Do's

- Use `container-type: inline-size` by default — avoids block-containment surprises
- Name your containers on complex pages to prevent query collisions
- Use container query units (`cqi`, `cqb`) for component-internal spacing
- Combine with `:has()` for parent-aware styling without JS

### Don'ts

- Don't use `container-type: size` unless you specifically need both axes
- Don't nest containers deeper than 3 levels without strong justification
- Don't query by extremely narrow ranges (e.g., `@container (575px <= width < 576px)`)
- Don't use container queries for global page layout — that's what media queries are for

### Debugging

```css
/* Outline all containment contexts for debugging */
*:where([style*="container-type"], [style*="container:"]) {
  outline: 2px dashed hotpink;
}
```

In DevTools: Elements → Computed → look for "Containment" and "Container" sections.

---

## 7. Polyfill / Fallback

For older browsers, provide fallbacks using the `@supports` at-rule:

```css
@supports (container-type: inline-size) {
  .card-grid {
    container-type: inline-size;
  }

  @container (min-width: 400px) {
    .card { flex-direction: row; }
  }
}

@supports not (container-type: inline-size) {
  .card {
    flex-direction: column;
  }

  @media (min-width: 768px) {
    .card { flex-direction: row; }
  }
}
```
