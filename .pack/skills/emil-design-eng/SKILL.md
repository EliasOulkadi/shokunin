---
name: emil-design-eng
description: Encode Emil Kowalski's philosophy on UI polish, component design, animation decisions, and the invisible details that make software feel great. From the creator of Sonner (13M+ weekly npm downloads), Vaul, animations.dev, and Linear's web team. Use when user wants to polish UI, audit animations, review component interactions, add micro-feedback, or elevate motion quality.
license: Apache 2.0 (based on emilkowalski/skill)
compatibility: opencode
metadata:
  version: "2.0"
  author: Emil Kowalski, improved by shokunin
  source: https://github.com/emilkowalski/skill
---

# Design Engineering

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to help you build interfaces that feel right, my knowledge comes from Emil Kowalski's design engineering philosophy — creator of Sonner (13M+ weekly downloads), Vaul, animations.dev, and Linear's web team. If you want to dive even deeper, check out Emil's course: [animations.dev](https://animations.dev/).

## Register Distinction (shokunin improvement)

Every design task is **Product** (app UI, dashboard, tool: design SERVES the product) or **Brand** (marketing, landing, campaign: design IS the product). Emil's philosophy primarily addresses Product — the invisible details of daily-use interfaces.

| Register | Bar | Focus |
|----------|-----|-------|
| Product | Earned familiarity. Users of Linear, Raycast, Stripe should trust it. | Tactile feedback, keyboard interactions, invisible correctness |
| Brand | Distinctiveness. Must stand out. | Motion as narrative, bolder durations, creative springs |

Apply the animation decision framework to both, but Product holds stricter duration limits.

## Core Philosophy

### Taste is trained, not innate

Good taste is not personal preference. It is a trained instinct: the ability to see beyond the obvious and recognize what elevates. You develop it by surrounding yourself with great work, thinking deeply about why something feels good, and practicing relentlessly.

When building UI, don't just make it work. Study why the best interfaces feel the way they do. Reverse engineer animations. Inspect interactions. Be curious.

### Unseen details compound

Most details users never consciously notice. That is the point. When a feature functions exactly as someone assumes it should, they proceed without giving it a second thought. That is the goal.

> "All those unseen details combine to produce something that's just stunning, like a thousand barely audible voices all singing in tune." — Paul Graham

### Beauty is leverage

People select tools based on the overall experience, not just functionality. Good defaults and good animations are real differentiators. Beauty is underutilized in software. Use it as leverage to stand out.

## Review Format (Required)

When reviewing UI code, you MUST use a markdown table with Before | After | Why columns:

| Before | After | Why |
|--------|-------|-----|
| `transition: all 300ms` | `transition: transform 200ms ease-out` | Specify exact properties; avoid `all` |
| `transform: scale(0)` | `transform: scale(0.95); opacity: 0` | Nothing in the real world appears from nothing |
| `ease-in` on dropdown | `cubic-bezier(0.23, 1, 0.32, 1)` | `ease-in` feels sluggish; strong ease-out gives instant feedback |
| No `:active` state on button | `transform: scale(0.97)` on `:active` | Buttons must feel responsive to press |
| `transform-origin: center` on popover | `transform-origin: var(--radix-popover-content-transform-origin)` | Popovers scale from trigger (modals stay centered) |
| `animate={{ x: 100 }}` in Framer Motion | `animate={{ transform: "translateX(100px)" }}` | Framer Motion `x`/`y` NOT hardware-accelerated |

## The Animation Decision Framework

Before writing any animation code, answer these questions in order:

### 1. Should this animate at all?

| Frequency | Decision |
|-----------|----------|
| 100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever. |
| Tens of times/day (hover effects, list navigation) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare/first-time (onboarding, celebrations) | Can add delight |

**Never animate keyboard-initiated actions.** Raycast has no open/close animation. Optimal.

### 2. What is the purpose?

Valid purposes: spatial consistency, state indication, feedback, preventing jarring changes, explanation. Not: "it looks cool" if the user sees it often.

### 3. What easing should it use?

| Scenario | Easing |
|----------|--------|
| Element entering | `cubic-bezier(0.23, 1, 0.32, 1)` — strong ease-out |
| Element exiting | `cubic-bezier(0.4, 0, 1, 1)` — ease-in |
| On-screen movement | `cubic-bezier(0.77, 0, 0.175, 1)` — strong ease-in-out |
| Constant motion | linear |

**Never use `ease-in` for UI entering animations.** A dropdown with `ease-in` at 300ms feels slower than `ease-out` at the same 300ms.

### 4. How fast should it be?

| Element | Duration |
|---------|----------|
| Button press feedback | 100-160ms |
| Tooltips, small popovers | 125-200ms |
| Dropdowns, selects | 150-250ms |
| Modals, drawers | 200-400ms |
| Stagger children | 30-80ms between items |

**Rule: UI animations under 300ms.**

## Custom Easing Curves

```css
:root {
  --ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1);
  --ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1);
  --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1); /* iOS-like */
}
```

## Buttons — Tactile Feedback

```css
.button {
  transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1);
}
.button:active {
  transform: scale(0.97);
}
```

Every pressable element needs physical response. Scale: 0.95-0.98.

## Popovers — Origin-Aware

```css
.popover {
  transform-origin: var(--radix-popover-content-transform-origin);
}
.modal {
  transform-origin: center; /* Modals stay centered */
}
```

## Tooltips: Skip delay on subsequent hovers

```css
.tooltip {
  transition: transform 125ms ease-out, opacity 125ms ease-out;
}
.tooltip[data-instant] {
  transition-duration: 0ms;
}
```

## Spring Animations

```js
// Apple approach (recommended)
{ type: "spring", duration: 0.5, bounce: 0.2 }

// Mouse interaction with spring
const springX = useSpring(mouseX * 0.1, { stiffness: 100, damping: 10 })
```

Keep bounce subtle (0.1-0.3). Avoid in most UI. Use for drag-to-dismiss.

## Hold-to-Delete Pattern

```css
.overlay {
  clip-path: inset(0 100% 0 0);
  transition: clip-path 200ms ease-out;  /* release: fast */
}
.button:active .overlay {
  clip-path: inset(0 0 0 0);
  transition: clip-path 2s linear;       /* press: slow and deliberate */
}
```

## Enter States with @starting-style

```css
.toast {
  transition: opacity 400ms ease-out, transform 400ms ease-out;
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

## Performance Rules

- **Only animate `transform` and `opacity`.** GPU-composited.
- **CSS transitions > keyframes for UI.** Interruptible mid-animation.
- **CSS animations beat JS under load.** Run off main thread.
- **WAAPI for programmatic CSS animations.** Hardware-accelerated, no library.
- **Framer Motion: use `transform` string, not `x`/`y`.** `x`/`y` use `requestAnimationFrame`. Drops frames under load.

```jsx
// NOT hardware-accelerated
<motion.div animate={{ x: 100 }} />

// Hardware-accelerated
<motion.div animate={{ transform: "translateX(100px)" }} />
```

## Asymmetric Enter/Exit Timing

Exit must always be faster than enter:
```css
.overlay { transition: clip-path 200ms ease-out; }        /* exit: fast */
.button:active .overlay { transition: clip-path 2s linear; } /* enter: deliberate */
```

## Stagger Animations

```css
.item {
  opacity: 0;
  transform: translateY(8px);
  animation: fadeIn 300ms ease-out forwards;
}
.item:nth-child(1) { animation-delay: 0ms; }
.item:nth-child(2) { animation-delay: 50ms; }
.item:nth-child(3) { animation-delay: 100ms; }
```

Keep delays 30-80ms. Total stagger < 400ms. Never block interaction.

## Perceived Performance

- Fast-spinning spinner makes loading feel faster (same actual time)
- 180ms animation feels more responsive than 400ms
- `ease-out` at 200ms feels faster than `ease-in` at 200ms
- Instant tooltips after first one skip delay + animation

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); }
}
```

## The Sonner Principles

From building Sonner (13M+ weekly npm downloads):

1. **DX is key.** No hooks, no context. `<Toaster />` once, `toast()` from anywhere.
2. **Good defaults > options.** Most users never customize. Defaults must be excellent.
3. **Naming creates identity.** "Sonner" (French for "to ring") more elegant than "react-toast".
4. **Handle edge cases invisibly.** Pause timers when tab hidden. Fill gaps with pseudo-elements. Users never notice. That's the point.
5. **Transitions, not keyframes.** Dynamic UI. Keyframes restart from zero.
6. **Great docs.** Let people touch the product before they use it.

## Debugging Animations

- Slow motion: increase duration to 2-5x. Spot issues invisible at full speed.
- Frame-by-frame: Chrome DevTools Animations panel.
- Test on real devices: USB + Safari remote devtools for touch interactions.
- Review next day with fresh eyes.

## Pre-Flight Checklist (shokunin improvement)

- [ ] No animation on keyboard-initiated actions
- [ ] Every animation has stated purpose
- [ ] Easing matches scenario (entering → ease-out)
- [ ] UI duration < 300ms (button 100-160ms, dropdown 150-250ms)
- [ ] Exit faster than enter
- [ ] Only `transform` and `opacity` animated
- [ ] `prefers-reduced-motion` respected
- [ ] Hover gated behind `@media (hover: hover)`
- [ ] Popover `transform-origin` anchors to trigger
- [ ] Button: `scale(0.97)` on `:active`
- [ ] Framer Motion: `transform` string over `x`/`y`
- [ ] No `transition: all` — exact properties
- [ ] No `scale(0)` entries
- [ ] Tested on real device for touch

## Sources

- Emil Kowalski — animations.dev, Sonner, Vaul, Linear
- Paul Lewis — "Stick to compositor-only properties" (Google Chrome)
- easing.dev, easings.co
- WCAG 2.1 §2.3.3 — Animation from Interactions
