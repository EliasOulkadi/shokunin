---
name: motion-craft
description: Design GPU-accelerated animations with Web Animations API (WAAPI), Scroll-Driven Animations (ScrollTimeline/ViewTimeline), FLIP technique, easing systems, and accessibility (prefers-reduced-motion). Use when user asks to create animations, transitions, scroll effects, page transitions, or interactive motion for web UIs. Do NOT use for canvas-based animations (Three.js, PixiJS), video editing, or non-web (native mobile) motion design.
triggers:
  - "animation"
  - "transition"
  - "motion"
  - "scroll animation"
  - "page transition"
  - "WAAPI"
  - "Web Animations API"
  - "scroll-driven animation"
  - "FLIP animation"
  - "easing"
  - "animate"
  - "spring animation"
  - "stagger animation"
negatives:
  - "Three.js"
  - "canvas animation"
  - "video editing"
  - "native mobile animation"
  - "game animation"
  - "CSS only"
license: MIT
compatibility: opencode
metadata:
  workflow: frontend
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# Motion Craft

Animations that communicate, not decorate. Every frame must earn its place.

Inspired by Emil Kowalski (Linear, Sonner, Vaul), Paul Lewis (Google Chrome), and the CSS Animation Working Group.

## Workflow

## The Animation Decision Framework

Before writing any animation code, answer these four questions in order.

### 1. Should this animate at all?

| Frequency | Decision | Reason |
|-----------|----------|--------|
| 100+ times/day (keyboard shortcuts, command palette, search toggle) | No animation. Ever. | Animation makes frequent actions feel delayed. Raycast has no open/close animation. Optimal. |
| Tens of times/day (hover effects, list navigation) | Remove or drastically reduce | Users notice animation latency on repeated interactions |
| Occasional (modals, drawers, toasts) | Standard animation | The right place for motion |
| Rare / first-time (onboarding, confirmation, celebration) | Add delight | These moments earn longer, richer animations |

**Never animate keyboard-initiated actions.** These repeat hundreds of times daily.

### 2. What is the purpose?

Every animation must have a clear answer to "why does this animate?"

| Purpose | Example | Valid? |
|---------|---------|--------|
| Spatial consistency | Toast enters and exits from the same direction | ? |
| State indication | Button morphs to show "sent" | ? |
| Feedback | Button scales down on press, confirming the interface heard the user | ? |
| Preventing jarring changes | Elements fading in instead of appearing abruptly | ? |
| Explanation | Marketing animation showing how a feature works | ? |
| "It looks cool" AND the user sees it often | Gratuitous motion | ? |

### 3. What easing should it use?

| Scenario | Easing | CSS |
|----------|--------|-----|
| Element entering | ease-out (starts fast, feels responsive) | `cubic-bezier(0, 0, 0.2, 1)` |
| Element exiting | ease-in (starts slow, grabs attention briefly then accelerates away) | `cubic-bezier(0.4, 0, 1, 1)` |
| On-screen movement / morphing | ease-in-out | `cubic-bezier(0.4, 0, 0.2, 1)` |
| Hover / color change | ease | `cubic-bezier(0.25, 0.1, 0.25, 1)` |
| Constant motion (marquee, progress bar) | linear | `cubic-bezier(0, 0, 1, 1)` |
| UI interactions (buttons, tooltips, dropdowns) | strong ease-out | `cubic-bezier(0.23, 1, 0.32, 1)` |

**Critical: never use ease-in for UI entering animations.** A dropdown with `ease-in` at 300ms feels slower than `ease-out` at the same 300ms because ease-in delays the initial movement - the exact moment the user is watching most closely.

### 4. How fast should it be?

| Element | Duration | Easing |
|---------|----------|--------|
| Button press feedback (scale) | 100-160ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Tooltip enter / exit | 125-200ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Dropdown / select / popover | 150-250ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Hover transform (scale, lift) | 200ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Modal / dialog enter | 200-300ms | `cubic-bezier(0, 0, 0.2, 1)` |
| Modal / dialog exit | 150-200ms | `cubic-bezier(0.4, 0, 1, 1)` |
| Drawer / sheet enter | 200-400ms | `cubic-bezier(0.32, 0.72, 0, 1)` (iOS-like) |
| Toast enter | 300-400ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Toast exit | 200-300ms | `cubic-bezier(0.4, 0, 1, 1)` |
| Page transition | 300-400ms | `cubic-bezier(0.4, 0, 0.2, 1)` |
| Scroll reveal (fade + slide up) | 400-800ms | `cubic-bezier(0.16, 1, 0.3, 1)` |
| Loading shimmer | 1000-1500ms (infinite) | linear |
| Hold-to-delete (press) | 2000ms | linear (deliberate) |
| Hold-to-delete (release) | 200ms | `cubic-bezier(0.23, 1, 0.32, 1)` (snappy) |
| Marketing / explanatory | 800-3000ms | variable, depends on narrative |

**Rule: UI animations should stay under 300ms.** A 180ms dropdown feels noticeably more responsive than a 400ms one.

### Custom easing curves

The built-in CSS `ease` / `ease-in` / `ease-out` are too weak. Use these stronger custom variants:

```css
:root {
  --ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1);     /* UI interactions, Emil's signature */
  --ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1);  /* On-screen movement */
  --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);          /* iOS-like drawer */
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);         /* Slow reveals, dramatic */
  --ease-out-quint: cubic-bezier(0.22, 1, 0.36, 1);       /* Alternative strong ease-out */
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);       /* Slight overshoot, sparingly */
}
```

Sources: [easing.dev](https://easing.dev/), [easings.co](https://easings.co/)

---

## The 60fps Golden Rule

16.67ms per frame. Verify with Chrome DevTools Performance tab. Only animate `transform` and `opacity`.

| Property | GPU composite? | Triggers |
|----------|:--:|----------|
| `transform` (translate, scale, rotate) | ? Yes | Composite only |
| `opacity` | ? Yes | Composite only |
| `filter` | ?? Sometimes | Paint + Composite |
| `clip-path` | ?? Sometimes | Paint + Composite |
| `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width` | ? No | Layout + Paint + Composite |
| `box-shadow` | ? No | Paint + Composite |
| `color`, `background-color` | ? No | Paint only |

## Review Format (Required)

When reviewing UI animation code, you MUST use a markdown table with Before | After | Why columns. Do NOT use a list with "Before:" and "After:" on separate lines.

### Correct format:

| Before | After | Why |
|--------|-------|-----|
| `transition: all 300ms` | `transition: transform 200ms ease-out` | Specify exact properties; avoid `all` which triggers layout recalculation |
| `transform: scale(0)` | `transform: scale(0.95); opacity: 0` | Nothing in the real world appears from nothing |
| `ease-in` on dropdown | `cubic-bezier(0.23, 1, 0.32, 1)` | `ease-in` starts slow - feels sluggish. Strong ease-out gives instant feedback |
| No `:active` state on button | `transform: scale(0.97)` on `:active` | Buttons must feel responsive to press |
| `transform-origin: center` on popover | `transform-origin: var(--radix-popover-content-transform-origin)` | Popovers should scale from their trigger. Modals stay centered. |
| `transition: 300ms` without `prefers-reduced-motion` | `@media (prefers-reduced-motion: reduce) { transition-duration: 0.01ms }` | WCAG 2.1 requires reduced-motion support |
| `animate={{ x: 100 }}` in Framer Motion | `animate={{ transform: "translateX(100px)" }}` | Framer Motion `x`/`y` are NOT hardware-accelerated. Use `transform` string for GPU. |

**Wrong format (never do this):**
```
Before: transition: all 300ms
After: transition: transform 200ms ease-out
```

---

## CSS Transitions (preferred for UI)

CSS transitions are interruptible - they can be retargeted mid-animation. Keyframes restart from zero. For any interaction that can be triggered rapidly (toasts, toggles, dropdowns), transitions produce smoother results.

```css
.button {
  transition: transform 160ms ease-out;
}
.button:active {
  transform: scale(0.97);
}

.tooltip {
  transition: transform 125ms ease-out, opacity 125ms ease-out;
  transform-origin: var(--transform-origin);
}
```

### Asymmetric enter / exit timing

Enter can be slower (user is deciding), exit must be fast (system responding):

```css
.overlay {
  transition: clip-path 200ms ease-out;  /* release: fast */
}
.button:active .overlay {
  transition: clip-path 2s linear;       /* press: slow and deliberate */
}
```

### Tooltips: skip delay on subsequent hovers

```css
.tooltip {
  transition: transform 125ms ease-out, opacity 125ms ease-out;
  transform-origin: var(--transform-origin);
}
.tooltip[data-instant] {
  transition-duration: 0ms;
}
```

### Enter states with @starting-style (Chrome-only as of 2026, not yet Baseline)

```css
.toast {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 400ms ease-out, transform 400ms ease-out;

  @starting-style {
    opacity: 0;
    transform: translateY(100%);
  }
}
```

> Note: `@starting-style` and scroll-driven animations (`animation-timeline: view()`, `animation-timeline: scroll()`) are Chrome-only as of 2026. Use JavaScript fallbacks for cross-browser support.

### Hold-to-delete pattern

```css
.overlay {
  clip-path: inset(0 100% 0 0);
  transition: clip-path 200ms ease-out;   /* release: fast */
}
.button:active .overlay {
  clip-path: inset(0 0 0 0);
  transition: clip-path 2s linear;        /* press: slow and deliberate */
}
```

---

## BUTTONS - Tactile Feedback

Every pressable element needs physical response.

```css
.button {
  transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1);
}
.button:active {
  transform: scale(0.97);
}
```

The scale must be subtle (0.95-0.98). Applied to all pressable elements - buttons, cards, list items, tabs.

---

## POPOVERS - Origin-Aware

Popovers scale from their trigger, not center. Modals stay centered.

```css
/* Radix UI */
.popover {
  transform-origin: var(--radix-popover-content-transform-origin);
}
/* Base UI */
.popover {
  transform-origin: var(--transform-origin);
}
/* Modals (always centered) */
.modal {
  transform-origin: center;
}
```

Whether the user notices individually does not matter. In the aggregate, unseen details compound.

---

## Stagger Animations

When multiple elements enter together, stagger their appearance.

```css
.item {
  opacity: 0;
  transform: translateY(8px);
  animation: fadeIn 300ms ease-out forwards;
}
.item:nth-child(1) { animation-delay: 0ms; }
.item:nth-child(2) { animation-delay: 50ms; }
.item:nth-child(3) { animation-delay: 100ms; }
.item:nth-child(4) { animation-delay: 150ms; }

@keyframes fadeIn {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

Keep stagger delays short (30-80ms between items). Never block interaction while stagger plays.

---

## CSS Animations (keyframes)

Use for predetermined, non-dynamic animations. Keyframes restart from zero on interruption - avoid for UI.

```css
@keyframes enter-right {
  from { opacity: 0; transform: translateX(16px); }
  to   { opacity: 1; transform: translateX(0); }
}
.enter {
  animation: enter-right 300ms ease-out forwards;
}
```

---

## Spring Animations

Springs feel more natural than duration-based animations because they simulate real physics. They maintain velocity when interrupted.

### When to use springs

- Drag interactions with momentum
- Elements that feel "alive" (Apple Dynamic Island style)
- Gestures that can be interrupted mid-animation
- Decorative mouse-tracking interactions

### Apple approach (recommended - easier to reason about)

```js
{ type: "spring", duration: 0.5, bounce: 0.2 }
```

### Traditional physics (more control)

```js
{ type: "spring", stiffness: 100, damping: 10, mass: 1 }
```

Keep bounce subtle (0.1-0.3). Avoid bounce in most UI. Use for drag-to-dismiss and playful interactions only.

### Spring-based mouse interactions

```jsx
import { useSpring } from 'framer-motion'

const springX = useSpring(mouseX * 0.1, { stiffness: 100, damping: 10 })
```

Without spring: feels artificial, instant. With spring: feels natural, has momentum.

---

## WEB ANIMATIONS API (WAAPI)

Programmatic CSS animations. Hardware-accelerated, interruptible, no library needed.

```javascript
const element = document.querySelector('.card')

const animation = element.animate([
  { transform: 'scale(1)', opacity: 1 },
  { transform: 'scale(0.95)', opacity: 0.7 },
], {
  duration: 200,
  easing: 'cubic-bezier(0.23, 1, 0.32, 1)',
  fill: 'both',
})

animation.pause()
animation.play()
animation.reverse()
animation.finish()
animation.finished.then(() => console.log('done'))
```

WAAPI beats Framer Motion under heavy load - it runs off the main thread. Use for dynamic, interruptible animations where CSS keyframes fall short.

---

## SCROLL-DRIVEN ANIMATIONS

**Browser support note:** Scroll-driven animations (`animation-timeline: view()` and `scroll()`) are Chrome/Edge-only as of 2026, not yet Baseline. Provide JS fallbacks via IntersectionObserver for Firefox/Safari.

### ViewTimeline (element enters/leaves viewport)

```css
@keyframes fade-up {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}
.reveal {
  animation: fade-up 600ms linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
```

### ScrollTimeline (page scroll position)

```css
@keyframes shrink {
  from { height: 80px; }
  to   { height: 50px; }
}
.site-header {
  animation: shrink 300ms linear both;
  animation-timeline: scroll();
  animation-range: 0 200px;
}
```

### Scroll-linked parallax (vanilla JS)

```js
const layers = document.querySelectorAll('[data-parallax]')
window.addEventListener('scroll', () => {
  const scrollY = window.scrollY
  layers.forEach(layer => {
    const speed = parseFloat(layer.dataset.parallax) || 0.3
    layer.style.transform = `translateY(${scrollY * speed}px)`
  })
})
```

---

## FLIP Technique

For layout animations - animating elements that change position/size.

```javascript
function animateLayout(element, callback) {
  const first = element.getBoundingClientRect()
  callback()
  const last = element.getBoundingClientRect()

  const dx = first.left - last.left
  const dy = first.top - last.top
  const dw = first.width / last.width
  const dh = first.height / last.height

  element.animate([
    { transform: `translate(${dx}px, ${dy}px) scale(${dw}, ${dh})` },
    { transform: 'translate(0, 0) scale(1, 1)' },
  ], {
    duration: 300,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
  })
}
```

---

## CLIP-PATH for Animation

One of the most powerful animation tools in CSS. Hardware-accelerated.

```css
.overlay {
  clip-path: inset(0 100% 0 0);
  transition: clip-path 200ms ease-out;
}
.visible {
  clip-path: inset(0 0 0 0);
}
```

Use for: hold-to-delete, image reveals on scroll, comparison sliders, seamless color transitions on tabs.

---

## PERCEIVED PERFORMANCE

Speed in animation directly affects how users perceive your app:

| Effect | Mechanism |
|--------|-----------|
| Fast-spinning spinner | Makes loading feel faster (same load time, different perception) |
| 180ms select vs 400ms select | Shorter animation = perceived responsiveness jump |
| Instant tooltips after first one | Skip delay + animation on subsequent tooltips |
| Fast exit animations | Exit must be faster than enter (200ms enter, 150ms exit) |
| `ease-out` vs `ease-in` at same 200ms | ease-out feels faster because user sees immediate movement |

---

## PERFORMANCE RULES

### Only animate transform and opacity

These skip layout and paint, running on GPU.

### CSS variables are inheritable - avoid for animation

```js
// Bad: triggers recalculation on all children
element.style.setProperty('--swipe-amount', `${distance}px`)

// Good: only affects this element
element.style.transform = `translateY(${distance}px)`
```

### CSS animations beat JS under load

When the browser is busy loading a new page, Framer Motion animations (using `requestAnimationFrame`) drop frames. CSS animations remain smooth - they run off the main thread.

### Framer Motion: use `transform` string, not shorthand

```jsx
// NOT hardware accelerated (requestAnimationFrame on main thread)
<motion.div animate={{ x: 100 }} />

// Hardware accelerated (GPU, stays smooth even under load)
<motion.div animate={{ transform: "translateX(100px)" }} />
```

### will-change: use sparingly

```css
.will-animate {
  will-change: transform, opacity;
}
```

Each `will-change` creates a new compositor layer, consuming GPU memory. Apply before animation, remove after.

---

## ACCESSIBILITY

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

WCAG 2.1 Success Criterion 2.3.3 - Animation from Interactions.

For fine-grained control:

```javascript
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
const userPrefersReduced = localStorage.getItem('reduced-motion') === 'true'
const shouldReduce = prefersReduced || userPrefersReduced
```

### Touch device hover states

```css
@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); }
}
```

Touch devices trigger hover on tap. Gate hover animations behind this media query.

---

## DEBUGGING ANIMATIONS

### Slow motion testing

Play animations at reduced speed to spot issues invisible at full speed. Temporarily increase duration to 2-5x normal, or use browser DevTools animation inspector.

Things to look for:

- Do colors transition smoothly, or do you see two distinct states overlapping?
- Does the easing feel right, or does it start/stop abruptly?
- Is the transform-origin correct?
- Are multiple animated properties (opacity, transform, color) in sync?

### Frame-by-frame inspection

Chrome DevTools Animations panel. Step frame by frame. Reveals timing issues between coordinated properties invisible at full speed.

### Test on real devices

For touch interactions (drawers, swipe gestures), test on physical devices. Connect phone via USB, visit local dev server by IP address, use Safari remote devtools.

---

## REVIEW CHECKLIST

| Issue | Fix |
|-------|-----|
| `transition: all` | Specify exact properties: `transition: transform 200ms ease-out` |
| `scale(0)` entry animation | Start from `scale(0.95)` with `opacity: 0` |
| `ease-in` on UI element | Switch to strong ease-out or custom curve |
| `transform-origin: center` on popover | Set to trigger location (modals exempt) |
| Animation on keyboard action | Remove entirely |
| Duration > 300ms on UI element | Reduce to 150-250ms |
| Hover animation without media query | Add `@media (hover: hover) and (pointer: fine)` |
| Keyframes on rapidly-triggered element | Use CSS transitions for interruptibility |
| Framer Motion `x`/`y` props under load | Use `transform: "translateX()"` |
| Same enter/exit transition speed | Exit must be faster (e.g. enter 2s, exit 200ms) |
| Elements all appear at once | Stagger with 30-80ms between items |
| No `prefers-reduced-motion` fallback | Required by WCAG 2.1 |
| `will-change` left on after animation | Remove or set to `auto` when done |
| JS scroll listeners for scroll effects | Use ViewTimeline / IntersectionObserver |
| CSS `ease` default | Replace with custom cubic-bezier |

---

## PRE-FLIGHT CHECKLIST

Before delivering animated UI code:

- [ ] No animation on keyboard-initiated actions
- [ ] Every animation has a stated purpose (why does this animate?)
- [ ] Easing curve matches scenario (entering ? ease-out, exiting ? ease-in)
- [ ] UI duration under 300ms (button 100-160ms, dropdown 150-250ms, modal 200-300ms)
- [ ] Exit faster than enter (asymmetric timing)
- [ ] Only `transform` and `opacity` animated (GPU composite)
- [ ] `prefers-reduced-motion` respected
- [ ] Hover animations gated behind `@media (hover: hover)`
- [ ] Touch targets 44x44mm minimum
- [ ] No `scale(0)` entries - start from `scale(0.95)`
- [ ] Popover `transform-origin` anchors to trigger
- [ ] Stagger delays under 80ms
- [ ] No `transition: all` - exact properties only
- [ ] Framer Motion: `transform` string over `x`/`y` shorthand
- [ ] `will-change` removed after animation completes
- [ ] Button press: `scale(0.97)` on `:active`
- [ ] Tested on real device for touch interactions

---

## Anti-Patterns

## BANNED PATTERNS

| Banned | Because |
|--------|---------|
| `transition: all` | Triggers layout recalculation on every frame |
| `ease-in` on entering UI | Delays initial movement - feels sluggish |
| `scale(0)` entry | Nothing disappears and reappears completely in the real world |
| Animating `width`, `height`, `top`, `left` | Layout thrashing - use `transform` |
| `requestAnimationFrame` for scroll effects | Blocking - use ScrollTimeline or IntersectionObserver |
| Bounce / elastic easing on functional UI | Unprofessional - reserve for playful interactions only |
| Duration > 500ms on functional UI | Feels slow - users notice and get frustrated |
| Auto-playing carousels without pause | WCAG accessibility violation |
| Framer Motion `x`/`y` props under load | Not hardware-accelerated - frames drop during page loads |
| No `prefers-reduced-motion` | WCAG 2.1 failure |
| `will-change` on everything | GPU memory waste - creates compositor layers |
| `translateZ(0)` on every element | Too many GPU layers - memory overhead |
| Keyframes for dynamic UI | Not interruptible - use CSS transitions |
| `transform-origin: center` on popovers | Breaks spatial consistency with trigger |
| Same speed enter and exit | Exit should always be faster |

---

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `transition: all` causes jank on unrelated property changes | Browser recalculates layout for every animated frame; `all` triggers layout on properties that don't need it | Specify exact properties: `transition: transform 200ms ease-out, opacity 200ms ease-out` |
| Framer Motion `x`/`y` props drop frames during page loads | `x`/`y` use `requestAnimationFrame` on the main thread, competing with React renders | Use `animate={{ transform: "translateX(100px)" }}` string — hardware-accelerated, GPU composite |
| Animation stutters on mobile Safari | iOS Safari throttles `requestAnimationFrame` in low-power mode; non-composited properties force layout | Only animate `transform` and `opacity`. Test on physical iOS devices via USB remote debugging. |
| Popover scales from wrong origin | Default `transform-origin: center` breaks spatial consistency with the trigger element | Set `transform-origin: var(--radix-popover-content-transform-origin)` for Radix; `var(--transform-origin)` for Base UI |
| Staggered list items flash all at once then disappear | `animation-delay` applied but items are visible by default before animation starts | Set initial state: `opacity: 0; transform: translateY(8px)`. Animation resolves to visible. |
| CSS keyframes restart on re-trigger instead of continuing | Keyframes run from frame 0 every time `animation-name` is applied | Use CSS transitions for interruptible UI (toasts, toggles, dropdowns). Keyframes only for predetermined, fire-once animations. |
| `@starting-style` doesn't work in Firefox/Safari | `@starting-style` is Chrome-only as of 2026, not yet Baseline | Provide JS fallback: set initial inline styles, then remove them on next frame to trigger transition. |
| Scroll-driven animation has no effect in Firefox | `animation-timeline: view()` and `scroll()` are not supported outside Chrome/Edge | Provide `IntersectionObserver` fallback that toggles a CSS class for animation. |
| `will-change: transform` never removed | Browser allocates GPU memory for the compositor layer indefinitely | Remove `will-change` or set to `auto` after animation completes. Use sparingly — each layer costs GPU memory. |
| Magnetic button causes continuous React re-renders | `useState` for cursor position triggers re-render at 60fps | Use Framer Motion `useMotionValue` + `useTransform` — updates outside React render cycle. |
| Scroll parallax jank from `scroll` event listener | `window.addEventListener('scroll')` fires on main thread, competing with rendering | Use `ScrollTimeline` (Chrome) or throttled `IntersectionObserver` with `requestAnimationFrame` debounce. |
| Touch device fires hover state on tap, then hover state persists | Mobile browsers synthesize hover on first tap and keep it until another tap elsewhere | Gate hover animations behind `@media (hover: hover) and (pointer: fine)`. |
| Auto-playing carousel without pause button | WCAG 2.2.2 violation: moving content must be pausable | Add pause/play button. Respect `prefers-reduced-motion`. Allow keyboard control. |

## Checklist

- [ ] Animation uses compositor-only properties (transform, opacity) where possible
- [ ] `prefers-reduced-motion` respected — fallback to static or reduced variant
- [ ] Easing curve appropriate for the motion type (spring for UI, ease for enter/exit)
- [ ] Before/After states compared — animation solves a real UX problem
- [ ] Tested on mobile and with throttled CPU to verify 60fps

## Sources

- Emil Kowalski - animations.dev, Sonner, Vaul (Linear team)
- Paul Lewis - "Stick to compositor-only properties" (Google Chrome)
- Web Animations API Specification (W3C)
- CSS Scroll-Driven Animations Specification (W3C)
- WCAG 2.1 Guideline 2.3.3 - Animation from Interactions
- easing.dev, easings.co - custom easing curve builders
- motion.dev - Animation reference
- Framer Motion documentation
