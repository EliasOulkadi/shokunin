---
name: impeccable
description: "Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers design systems, anti-pattern detection, brand vs product registers, typography, color (OKLCH), spacing, motion, copy, and accessibility. By Paul Bakaus (ex-Google, ex-Disney, ex-Unity). Full version includes 23 sub-commands, CLI detection, Chrome extension, and E2E test suite: npx skills add pbakaus/impeccable"
license: Apache 2.0 (based on pbakaus/impeccable)
compatibility: opencode
metadata:
  version: "1.0-lite"
  author: Paul Bakaus, lite integration by shokunin
  source: https://github.com/pbakaus/impeccable
  full_install: npx skills add pbakaus/impeccable
---

# Impeccable (Lite)

Design and iterate production-grade frontend interfaces. This is a lite integration of Paul Bakaus's Impeccable design language for AI. For the full 23 sub-commands, CLI detection, Chrome extension, and E2E test suite, install: `npx skills add pbakaus/impeccable`

## Quick Start (Lite mode)

Skip context gathering for rapid iteration. For full brand/product context, install the full version.

## Shared Design Laws

### Color

- Use **OKLCH**. Reduce chroma as lightness approaches 0 or 100. High chroma at extremes looks garish.
- Never `#000` or `#fff`. Tint every neutral toward brand hue (chroma 0.005-0.01 is enough).
- Pick a **color strategy**:
  - **Restrained**: tinted neutrals + one accent ≤ 10%. Product default.
  - **Committed**: one saturated color carries 30-60%. Brand default.
  - **Full palette**: 3-4 deliberate roles. Brand campaigns.
  - **Drenched**: the surface IS the color. Brand heroes.

### Dark vs Light

Never a default. Write one sentence of physical scene: who, where, under what light, in what mood. "SRE glancing at incident severity on a 27-inch monitor at 2am in a dim room" forces dark. "Editor reading a long-form article on an iPad in morning sunlight" forces light. Run the scene, not the category.

### Typography

- Cap body line length at **65-75ch** via `max-width`.
- Hierarchy through scale + weight contrast (≥1.25 ratio between steps).
- No Inter as display font.

### Motion

- Don't animate layout properties (`width`, `height`, `top`, `left`).
- Ease out with exponential curves. No bounce, no elastic.
- UI durations < 300ms. Exit faster than enter.

### Copy

- Every word earns its place. No restated headings.
- **No em dashes.** Use commas, colons, periods, or parentheses. Also no `--`.
- No AI filler: "elevate", "seamless", "unleash", "delve".

## Absolute Bans

Match-and-refuse. If you're about to write any of these, rewrite with different structure.

| Ban | Why |
|-----|-----|
| **Side-stripe borders** (`border-left` > 1px as accent) | The #1 AI-dashboard tell |
| **Gradient text** (`background-clip: text` + gradient) | Decorative, never meaningful |
| **Glassmorphism as default** | Rare and purposeful, or nothing |
| **Hero-metric template** | Big number + small label + gradient. SaaS cliché. |
| **Identical card grids** | Icon + heading + text, repeated. Lazy. |
| **Modal as first thought** | Exhaust inline/progressive alternatives first. |

## The AI Slop Test

If someone could look at this interface and say "AI made that" without doubt, it's failed.

**First-order check:** Can someone guess the theme from the category alone? "Observability → dark blue", "Healthcare → white + teal", "Crypto → neon on black" — these are training-data reflexes. Rework.

**Second-order check:** Can someone guess the aesthetic from category-plus-anti-references? "AI workflow that's not SaaS-cream → editorial-typographic". Still a reflex. Rework again.

## Design Tokens (OKLCH)

```css
--color-ink: oklch(10% 0 0);          /* Body copy, even for small text */
--color-charcoal: oklch(25% 0 0);      /* Headings, larger body */
--color-ash: oklch(55% 0 0);           /* Labels, captions, metadata */
--color-mist: oklch(92% 0 0);          /* Hairline borders, dividers */
--color-cream: oklch(96% 0.005 350);   /* Page background (tinted, never pure white) */
```

## Anti-Pattern Detection (Lite)

The full Impeccable CLI detects 27 anti-patterns. Install for `npx impeccable detect`.

Quick manual checks:
- [ ] No `border-left` > 1px as colored accent on any element
- [ ] No gradient text anywhere
- [ ] No glass cards as default decoration
- [ ] No hero-metric template
- [ ] No identical card grids
- [ ] Cards not nested inside cards
- [ ] Body line length 65-75ch
- [ ] Body line-height 1.6
- [ ] No em dashes in copy

## Pre-Flight Checklist

- [ ] Color strategy selected (Restrained / Committed / Full palette / Drenched)
- [ ] Dark vs light decided by physical scene, not category
- [ ] All colors in OKLCH
- [ ] No `#000` or `#fff` — tint every neutral
- [ ] Body line length 65-75ch
- [ ] No absolute bans violated
- [ ] AI slop test passed (both first-order and second-order)
- [ ] No em dashes in copy
- [ ] `prefers-reduced-motion` respected

## Sources

- Paul Bakaus — Impeccable (impeccable.style)
- OKLCH color space
- Stripe Design System
- Linear Design
