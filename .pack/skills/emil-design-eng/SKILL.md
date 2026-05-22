---
name: emil-design-eng
description: Encode Emil Kowalski's philosophy on UI polish, component design, animation decisions, and the invisible details that make software feel great. From the creator of Sonner (13M+ weekly npm downloads), Vaul, animations.dev, and Linear's web team. Use when user wants to polish UI, audit animations, review component interactions, add micro-feedback, or elevate motion quality.
triggers:
  - "Emil Kowalski"
  - "UI polish"
  - "micro-interactions"
  - "button animation"
  - "popover design"
  - "modal animation"
  - "tooltip behavior"
  - "design engineering"
  - "UI feel"
  - "invisible details"
  - "animation philosophy"
  - "Sonner"
  - "Vaul"
negatives:
  - "SEO"
  - "content strategy"
  - "backend"
  - "API design"
  - "database"
  - "full animations" -> use motion-craft
  - "design framework" -> use taste
license: Apache 2.0 (based on emilkowalski/skill)
compatibility: opencode
metadata:
  version: "2.0.0"
  author: Emil Kowalski, improved by shokunin
  source: https://github.com/emilkowalski/skill

  workflow: frontend
  audience: designers
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

## Workflow

### Step 1: Audit existing interactions

Before writing any animation code, inspect current state:
1. List every animated element on the page
2. Check easing, duration, and animated-properties for each
3. Flag violations: `transition: all`, `ease-in` on entering elements, animations on keyboard shortcuts, durations > 300ms for UI

### Step 2: Apply the Animation Decision Framework

For each interaction, answer in strict order:
1. **Should this animate?** Check frequency. 100+/day = no animation. Tens/day = reduce. Occasional = standard. Rare = delight allowed.
2. **What is the purpose?** Must be: spatial consistency, state indication, user feedback, or preventing jarring changes. Not "it looks cool."
3. **What easing?** Entering → `cubic-bezier(0.23, 1, 0.32, 1)`. Exiting → `cubic-bezier(0.4, 0, 1, 1)`. On-screen movement → `cubic-bezier(0.77, 0, 0.175, 1)`.
4. **How fast?** Button: 100-160ms. Tooltip: 125-200ms. Dropdown: 150-250ms. Modal: 200-400ms. Exit faster than enter.

### Step 3: Implement with compositor-only properties

1. Animate only `transform` and `opacity` — GPU-composited
2. Use CSS transitions for interruptible UI elements (hover, toggle, expand)
3. Use CSS animations only for looping or self-triggered animations
4. For Framer Motion: write `transform: "translateX(100px)"` as a string, never `x: 100` (which uses `requestAnimationFrame`)
5. Set `transform-origin` to trigger anchor for popovers, `center` for modals

### Step 4: Add tactile micro-feedback

1. Every pressable element: `scale(0.97)` on `:active`, 160ms `cubic-bezier(0.23, 1, 0.32, 1)`
2. Popovers/dropdowns scale from trigger point using `--radix-popover-content-transform-origin`
3. Tooltips: 125ms entry, skip delay on subsequent hovers (`data-instant`)
4. Stagger list items 30-80ms apart, total stagger < 400ms

### Step 5: Add accessibility and performance gates

1. Wrap all animations in `@media (prefers-reduced-motion: reduce)` — set duration to 0.01ms
2. Gate hover effects behind `@media (hover: hover) and (pointer: fine)`
3. Test on real device with touch input (USB + Safari remote devtools)
4. Slow-motion pass: increase all durations 2-5x to spot issues invisible at full speed

### Step 6: Review and ship

1. Review next day with fresh eyes
2. Frame-by-frame in Chrome DevTools Animations panel
3. Verify: no `transition: all`, no `ease-in` on enter, no animation on keyboard actions, no `scale(0)` entries
4. Run the Pre-Flight Checklist

## Error Handling

| Cause | Fix |
|-------|-----|
| Animation jank/stutter on low-end mobile devices | Reduce duration, lower stagger count, or disable entirely via `prefers-reduced-motion`. Animate only `transform` + `opacity` — never layout properties |
| Popover entry animates from wrong origin after scroll or resize | `--radix-popover-content-transform-origin` updates on reposition. Ensure the CSS variable is set dynamically by the popover library, not hardcoded. Verify after scroll |
| Hold-to-delete `clip-path` animation doesn't trigger on iOS Safari touch | Touch events require explicit handling. Use `touchstart`/`touchend` alongside `:active`. Test `clip-path` transition on real iOS Safari — some versions have clipping bugs |
| Framer Motion `x`/`y` drops frames on scroll-heavy pages | Replace `<motion.div animate={{ x: 100 }} />` with `<motion.div animate={{ transform: "translateX(100px)" }} />`. The `x`/`y` shortcuts bypass GPU compositor |
| `@starting-style` dialog/toast entry animation missing in production | Requires Chrome 117+ or Safari 17.2+. For broader support, use two-class approach (`.toast` + `.toast-enter`) toggled via JavaScript |
| Stagger animation blocks user interaction while items are appearing | Keep total stagger < 400ms. Items should be interactive as they appear — do not set `pointer-events: none` on parent during stagger |
| Button `:active` scale not firing on iOS Safari | iOS suppresses `:active` by default on `div`/`span`. Use native `<button>` element or add `touch-action: manipulation` to get immediate touch feedback |
| `transform-origin` on modal causes flicker when combined with backdrop | Modals must use `transform-origin: center`. If backdrop is animated separately, synchronize timing: both use same duration and easing curve |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `transition: all 300ms ease-in` | Triggers expensive layout property transitions. `ease-in` on enter feels sluggish and laggy. `all` causes unintended side-effect transitions | Specify exact properties: `transition: transform 200ms ease-out, opacity 200ms ease-out` |
| Entry animation from `scale(0)` or `opacity: 0` with no intermediate state | Nothing in physics appears from total nothingness. Feels unnatural and jarring | Start from `scale(0.95)` with `opacity: 0`. Minimum visible scale >= 0.9 for UI. The element should feel like it's expanding into existence |
| Animating Cmd+K palette toggle, Escape to close, or any keyboard shortcut | Users trigger these 100+ times/day. Any delay, even 100ms, accumulates to significant daily friction | Zero animation. Instant state change. Raycast, Spotlight, VS Code Command Palette all do this correctly |
| `ease-in` on dropdowns, tooltips, modals entering | Perceived as slower than `ease-out` at the exact same duration. Users interpret as interface lag | Always `cubic-bezier(0.23, 1, 0.32, 1)` (strong ease-out) for entering elements. The eye catches the fastest part first |
| Elastic/bounce easing on functional UI (buttons, toggles, form elements) | Distracting, feels toy-like, undermines professional credibility. Bounce reads as "trying too hard" | Reserve subtle spring (`bounce: 0.2`, `duration: 0.5`) for drag-to-dismiss and celebrations only. Never on standard UI transitions |
| Animating `width`, `height`, `top`, `left` | Triggers layout recalculation on every frame. Runs on CPU, not GPU. Janky at any frame rate | `transform: scale()` instead of `width`/`height`. `transform: translate()` instead of `top`/`left`. Compositor-only properties always |
| Same duration and easing for enter and exit | Exit must feel faster. Users want elements to appear smoothly but disappear instantly so they can continue their task | Exit duration = 50-70% of enter duration. Use `ease-in` (starts fast, slows) on exit. Use `ease-out` (starts fast, slows) on enter |
| Hero text reveal with `animation-delay` > 500ms | User has scrolled past before animation plays. Animation served zero purpose and just annoyed | Hero animations trigger on mount, not on scroll. If scroll-triggered, start when element top is 20% visible from viewport bottom |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
