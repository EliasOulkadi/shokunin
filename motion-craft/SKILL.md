---
name: motion-craft
description: Design GPU-accelerated animations with accessibility
---


# Motion Craft

Generates animation code that serves a purpose: guide attention, provide feedback, create hierarchy. Every animation must answer "what does this communicate?" Based on research from MDN, web.dev, Josh Collinsworth, CSS-Zone, and motion.dev (2025-2026).

## The 60fps Golden Rule

For smooth animations, maintain 60 frames per second. Each frame must render in under 16.67ms. Chrome DevTools Performance tab confirms whether you hit this (source: web.dev, CSS-Zone 2026).

## GPU-Composited Properties (only these)

| Property | GPU? | Triggers |
|----------|------|----------|
| `transform` (translate, scale, rotate) | Yes | Composite only |
| `opacity` | Yes | Composite only |
| `filter` | Sometimes | Paint + Composite |
| `clip-path` | Sometimes | Paint + Composite |
| `width`, `height`, `top`, `left` | No | Layout + Paint + Composite |

**Rule**: only animate `transform` and `opacity`. Everything else triggers expensive layout recalculations (source: web.dev, MDN, CSS Animation Performance Cheatsheet 2025).

## Easing System

```css
/* Material Design standard easing */
--ease-emphasized: cubic-bezier(0.4, 0.0, 0.2, 1);
--ease-accelerate: cubic-bezier(0.4, 0.0, 1, 1);
--ease-decelerate: cubic-bezier(0.0, 0.0, 0.2, 1);
--ease-linear: cubic-bezier(0, 0, 1, 1);
```

Never use the CSS default `ease` â€” it looks cheap. Custom cubic-bezier curves are the difference between amateur and professional motion (source: Josh Collinsworth, "Ten tips for better CSS transitions").

## Duration Guide

| Element | Duration | Easing |
|---------|----------|--------|
| Hover state | 150-200ms | --ease-decelerate |
| Page transition | 300-400ms | --ease-emphasized |
| Modal enter | 250ms | --ease-decelerate |
| Modal exit | 200ms | --ease-accelerate |
| Loading shimmer | 1000ms (infinite) | --ease-linear |
| Scroll reveal | 400-600ms | --ease-emphasized |

## Scroll Effects

| Effect | Implementation | Performance |
|--------|---------------|-------------|
| Fade in | IntersectionObserver + opacity | Excellent |
| Parallax | `transform: translateY(scale(0.5))` | Good (GPU) |
| Stagger | Incremental `animation-delay` | Good |
| Reveal | `clip-path` animation | Moderate |
| Scale on scroll | `transform: scale()` with scroll position | Good |

Use `IntersectionObserver` for scroll-triggered animations. Avoid `scroll` event listeners (they run on main thread). Source: MDN IntersectionObserver API.

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Required by WCAG 2.1 Success Criterion 2.3.3. Never omit this (source: WCAG, MDN).

## will-change Property

```css
.will-animate {
  will-change: transform, opacity;
}
```

Use sparingly. Each `will-change` creates a new compositor layer, consuming GPU memory. Apply before animation starts, remove after. Source: web.dev, MDN.

## Anti-Patterns

- `translateZ(0)` or `translate3d(0,0,0)` on every element (creates too many layers, consumes GPU memory â€” source: Stack Overflow, Aerotwist)
- Animating `width`, `height`, `box-shadow` (layout thrashing)
- Auto-playing carousels without pause (accessibility violation)
- duration > 500ms for functional UI (feels slow)
- No `prefers-reduced-motion` fallback (accessibility failure)

## Sources

- MDN "CSS and JavaScript animation performance" (developer.mozilla.org)
- web.dev "Stick to compositor-only properties" (Paul Lewis, Google)
- Josh Collinsworth "Ten tips for better CSS transitions and animations" (2025)
- CSS-Zone "CSS Animations Best Practices 2026" (Feb 2026)
- motion.dev "Animation performance guide" (2026)
- Pratik Sharma "CSS Animation Performance CheatSheet" (2025)
- W3C WCAG 2.1 Guideline 2.3.3 â€” Animation from Interactions








