---
name: motion-craft
description: Design GPU-accelerated animations with Web Animations API (WAAPI), Scroll-Driven Animations (ScrollTimeline/ViewTimeline), FLIP technique, easing systems, and accessibility (prefers-reduced-motion). Use when user asks to create animations, transitions, scroll effects, page transitions, or interactive motion for web UIs. Do NOT use for canvas-based animations (Three.js, PixiJS), video editing, or non-web (native mobile) motion design.
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "2.0"
---

# Motion Craft

Animations that guide attention, provide feedback, and create hierarchy. Every animation must answer "what does this communicate?"

## The 60fps Golden Rule

For smooth animations, maintain 60 frames per second. Each frame renders in under 16.67ms. Verify with Chrome DevTools Performance tab.

## GPU-Composited Properties (only these)

| Property | GPU? | Triggers |
|----------|------|----------|
| `transform` (translate, scale, rotate) | Yes | Composite only |
| `opacity` | Yes | Composite only |
| `filter` | Sometimes | Paint + Composite |
| `clip-path` | Sometimes | Paint + Composite |
| `width`, `height`, `top`, `left` | No | Layout + Paint + Composite |

Rule: only animate `transform` and `opacity`. Everything else triggers expensive layout recalculations.

## Easing System

```css
--ease-emphasized: cubic-bezier(0.4, 0.0, 0.2, 1);
--ease-accelerate: cubic-bezier(0.4, 0.0, 1, 1);
--ease-decelerate: cubic-bezier(0.0, 0.0, 0.2, 1);
--ease-linear: cubic-bezier(0, 0, 1, 1);
```

Never use CSS default `ease` — custom cubic-bezier curves differentiate professional from amateur motion.

## Duration Guide

| Element | Duration | Easing |
|---------|----------|--------|
| Hover state | 150-200ms | decelerate |
| Page transition | 300-400ms | emphasized |
| Modal enter | 250ms | decelerate |
| Modal exit | 200ms | accelerate |
| Loading shimmer | 1000ms (infinite) | linear |
| Scroll reveal | 400-600ms | emphasized |

## Web Animations API (WAAPI)

For programmatic control beyond CSS:

```javascript
const element = document.querySelector('.card')

const animation = element.animate([
  { transform: 'scale(1)', opacity: 1 },
  { transform: 'scale(0.95)', opacity: 0.7 },
], {
  duration: 200,
  easing: 'cubic-bezier(0.4, 0.0, 0.2, 1)',
  fill: 'both',
})

// Control
animation.pause()
animation.play()
animation.reverse()
animation.finish()
animation.cancel()
// On done
animation.finished.then(() => console.log('done'))
```

## Scroll-Driven Animations (CSS)

Use CSS ScrollTimeline and ViewTimeline instead of IntersectionObserver + JS:

```css
/* View-timeline: triggers when element enters/leaves viewport */
@keyframes fade-in {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.reveal {
  animation: fade-in 600ms linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
  /* Starts fading in when element bottom enters viewport,
     completes when element top reaches center */
}
```

### Scroll-timeline (page scroll)

```css
@keyframes shrink-header {
  from { height: 80px; }
  to { height: 50px; }
}

.site-header {
  animation: shrink-header 300ms linear both;
  animation-timeline: scroll();
  animation-range: 0 200px;
}
```

## FLIP Technique

For layout animations (animating elements that change position/size):

```javascript
function animateLayout(element, callback) {
  // First: record current position
  const first = element.getBoundingClientRect()

  // Last: apply change
  callback()

  // Invert: calculate delta
  const last = element.getBoundingClientRect()
  const dx = first.left - last.left
  const dy = first.top - last.top
  const dw = first.width / last.width
  const dh = first.height / last.height

  // Play: animate from delta to identity
  element.animate([
    { transform: `translate(${dx}px, ${dy}px) scale(${dw}, ${dh})` },
    { transform: 'translate(0, 0) scale(1, 1)' },
  ], {
    duration: 300,
    easing: 'cubic-bezier(0.4, 0.0, 0.2, 1)',
  })
}
```

## Scroll Effects

| Effect | Implementation | Performance |
|--------|---------------|-------------|
| Fade in | CSS View-timeline or IntersectionObserver + opacity | Excellent |
| Parallax | `transform: translateY(calc(var(--scroll) * 0.5))` | Good (GPU) |
| Stagger | `animation-delay` incremental | Good |
| Reveal | `clip-path` animation | Moderate |
| Scale on scroll | `transform: scale()` with scroll position | Good |

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

Required by WCAG 2.1 Success Criterion 2.3.3 (Animation from Interactions).

For fine-grained control, expose a reduced-motion toggle:

```javascript
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
const userPrefersReduced = localStorage.getItem('reduced-motion') === 'true'
const shouldReduce = prefersReduced || userPrefersReduced

// Skip non-essential animations, keep essential ones (loading, progress)
```

## will-change Property

```css
.will-animate {
  will-change: transform, opacity;
}
```

Use sparingly. Each `will-change` creates a new compositor layer, consuming GPU memory. Apply before animation starts, remove after.

## Anti-Patterns

- `translateZ(0)` on every element — creates too many layers, consumes GPU memory
- Animating `width`, `height`, `box-shadow` — layout thrashing
- Auto-playing carousels without pause — accessibility violation
- duration > 500ms for functional UI — feels slow
- No `prefers-reduced-motion` fallback — accessibility failure
- JS scroll listeners for scroll effects — use ViewTimeline/IntersectionObserver
- Animating in from off-screen without `will-change` — avoid re-layout on entrance

## Workflow

| Step | Task | Technique |
|------|------|-----------|
| 1 | Identify animation purpose | Feedback, attention, hierarchy, or delight |
| 2 | Choose property | Only `transform` and `opacity` for GPU compositing |
| 3 | Set timing | Duration from Duration Guide table |
| 4 | Apply easing | Custom cubic-bezier, never CSS default `ease` |
| 5 | Implement method | CSS transition, WAAPI, or Scroll-Driven |
| 6 | Add accessibility | `prefers-reduced-motion: reduce` fallback |
| 7 | Profile performance | Chrome DevTools Performance tab, verify 60fps |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Animation jank (dropped frames) | Animating non-GPU property | Switch to `transform` and `opacity` only |
| Scroll animation not working | Browser doesn't support ScrollTimeline | Fallback to IntersectionObserver |
| FLIP animation flashes | Invert transform calculated before layout | Use `requestAnimationFrame` or double-check rect timing |
| Reduced motion not respected | No `prefers-reduced-motion` media query | Add the standard block (see section above) |
| Too many compositor layers | Excessive `will-change` or `translateZ(0)` | Remove `will-change` after animation; use only where needed |
| Animation too slow | Duration > 500ms for UI feedback | Reduce to 150-300ms; save long durations for scroll reveals |
| Layout thrashing in JS | Reading then writing layout in same frame | Batch reads first, writes second; or use FLIP pattern |

## Sources

- MDN "CSS and JavaScript animation performance"
- web.dev "Stick to compositor-only properties" (Paul Lewis, Google)
- web.dev "Scroll-driven animations"
- W3C CSS Scroll-Driven Animations Specification
- WCAG 2.1 Guideline 2.3.3 — Animation from Interactions
- Josh Collinsworth "Ten tips for better CSS transitions and animations"
- FLIP technique by Paul Lewis (aerotwist.com)
- motion.dev Animation guide
