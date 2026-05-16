# Motion Design Tokens

## Duration Scale

| Token             | ms    | Use Case                                 |
| ----------------- | ----- | ---------------------------------------- |
| `--duration-instant` | 50  | Micro-feedback, ripple, checkbox toggle  |
| `--duration-fast`    | 100 | Button press, hover state change         |
| `--duration-normal`  | 200 | Panel open/close, fade transitions       |
| `--duration-slow`    | 350 | Page transitions, hero reveals           |
| `--duration-glacial` | 500 | Large element enter, modal backdrop      |

### Usage

```css
/* CSS */
.element {
  transition: opacity var(--duration-fast) var(--ease-standard);
}
```

```ts
// Framer Motion
const transition = { duration: 0.2, ease: [0.4, 0, 0.2, 1] }
```

---

## Easing Curves

### Cubic Bézier Presets

| Token                        | Curve                            | Feel                         |
| ---------------------------- | -------------------------------- | ---------------------------- |
| `--ease-standard`            | `cubic-bezier(0.4, 0, 0.2, 1)`  | Natural, neutral             |
| `--ease-decelerated`         | `cubic-bezier(0.0, 0, 0.2, 1)`  | Element entering             |
| `--ease-accelerated`         | `cubic-bezier(0.4, 0, 1, 1)`    | Element leaving              |
| `--ease-emphasized`          | `cubic-bezier(0.4, 0, 0.2, 1)`  | Standard (identical in MD3)  |
| `--ease-emphasized-decel`    | `cubic-bezier(0.05, 0.7, 0.1, 1)` | Hero entry, large reveal  |
| `--ease-emphasized-accel`    | `cubic-bezier(0.3, 0, 0.8, 0.15)` | Element exiting with force |
| `--ease-linear`              | `linear`                         | Color/opacity only           |

```css
:root {
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-decelerated: cubic-bezier(0.0, 0, 0.2, 1);
  --ease-accelerated: cubic-bezier(0.4, 0, 1, 1);
  --ease-emphasized-decel: cubic-bezier(0.05, 0.7, 0.1, 1);
  --ease-emphasized-accel: cubic-bezier(0.3, 0, 0.8, 0.15);
  --ease-linear: linear;
}
```

### When to pick which

```
INCOMING  (add, mount, enter)  → decelerated / ease-emphasized-decel
OUTGOING  (remove, unmount)    → accelerated / ease-emphasized-accel
SWAP      (replace, reorder)   → standard
NEUTRAL   (opacity, color)     → linear
```

---

## Spring Presets

For JS animation libraries (Framer Motion, react-spring, Motion One) when
you need natural, physics-based motion.

### Light Spring
```ts
{ type: 'spring', stiffness: 300, damping: 30 }
// Gentle, subtle bounce at rest. Good for UI micro-interactions.
```

### Bouncy Spring
```ts
{ type: 'spring', stiffness: 500, damping: 25 }
// Noticeable overshoot, settles quickly. Good for playful UI.
```

### Gentle Spring
```ts
{ type: 'spring', stiffness: 200, damping: 40 }
// Slow, controlled, minimal bounce. Good for hero reveals.
```

### Scale Reference

| Mass | Stiffness | Damping | Behavior           |
| ---- | --------- | ------- | ------------------ |
| 1    | 100       | 10      | Underdamped, wobbly |
| 1    | 300       | 30      | Critically damped   |
| 1    | 500       | 50      | Overdamped, stiff   |
| 2    | 300       | 30      | Heavy, slow         |

```ts
// Framer Motion spring → CSS mapping (approximate)
function springToCss({ stiffness, damping, mass = 1 }): string {
  // Linear easing approximation via `linear()` is ideal,
  // but this gives a reasonable cubic-bezier equivalent
  const zeta = damping / (2 * Math.sqrt(stiffness * mass))
  if (zeta >= 1) return 'cubic-bezier(0.25, 0.1, 0.25, 1)'
  return 'cubic-bezier(0.4, 0, 0.2, 1)'
}
```

---

## Design Token Implementation

### CSS Custom Properties (full system)

```css
:root {
  /* Duration */
  --duration-instant: 50ms;
  --duration-fast: 100ms;
  --duration-normal: 200ms;
  --duration-slow: 350ms;
  --duration-glacial: 500ms;

  /* Easing */
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-decelerated: cubic-bezier(0.0, 0, 0.2, 1);
  --ease-accelerated: cubic-bezier(0.4, 0, 1, 1);
  --ease-emphasized-decel: cubic-bezier(0.05, 0.7, 0.1, 1);
  --ease-emphasized-accel: cubic-bezier(0.3, 0, 0.8, 0.15);
  --ease-linear: linear;

  /* Combined shorthands */
  --motion-enter: opacity 0 var(--duration-normal) var(--ease-decelerated);
  --motion-exit: opacity 0 var(--duration-fast) var(--ease-accelerated);
  --motion-swap: all 0 var(--duration-normal) var(--ease-standard);
}
```

### Style Dictionary Format

```json
{
  "motion": {
    "duration": {
      "instant": { "value": "50ms", "type": "duration" },
      "fast":    { "value": "100ms", "type": "duration" },
      "normal":  { "value": "200ms", "type": "duration" },
      "slow":    { "value": "350ms", "type": "duration" },
      "glacial": { "value": "500ms", "type": "duration" }
    },
    "easing": {
      "standard":     { "value": "cubic-bezier(0.4, 0, 0.2, 1)", "type": "cubicBezier" },
      "decelerated":  { "value": "cubic-bezier(0.0, 0, 0.2, 1)", "type": "cubicBezier" },
      "accelerated":  { "value": "cubic-bezier(0.4, 0, 1, 1)", "type": "cubicBezier" },
      "emphasizedDecel": { "value": "cubic-bezier(0.05, 0.7, 0.1, 1)", "type": "cubicBezier" },
      "emphasizedAccel": { "value": "cubic-bezier(0.3, 0, 0.8, 0.15)", "type": "cubicBezier" },
      "linear": { "value": "linear", "type": "cubicBezier" }
    }
  }
}
```

### Framer Motion Theme

```ts
const motionTheme = {
  duration: {
    instant: 0.05,
    fast: 0.1,
    normal: 0.2,
    slow: 0.35,
    glacial: 0.5,
  },
  easing: {
    standard: [0.4, 0, 0.2, 1],
    decelerated: [0, 0, 0.2, 1],
    accelerated: [0.4, 0, 1, 1],
    emphasizedDecel: [0.05, 0.7, 0.1, 1],
    emphasizedAccel: [0.3, 0, 0.8, 0.15],
  },
  spring: {
    light: { type: 'spring' as const, stiffness: 300, damping: 30 },
    bouncy: { type: 'spring' as const, stiffness: 500, damping: 25 },
    gentle: { type: 'spring' as const, stiffness: 200, damping: 40 },
  },
}

// Usage
<motion.div
  animate={{ opacity: 1, y: 0 }}
  transition={{
    duration: motionTheme.duration.normal,
    ease: motionTheme.easing.emphasizedDecel,
  }}
/>
```
