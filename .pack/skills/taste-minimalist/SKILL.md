---
name: taste-minimalist
description: "Clean editorial-style interfaces. Warm monochrome palette, typographic contrast, flat bento grids, muted pastels. No gradients, no heavy shadows. Based on taste-skill by Leon Lin & blueemi, improved by shokunin."
license: MIT
compatibility: opencode
metadata:
  version: "2.0-improved"
  author: Leon Lin, blueemi, improved by shokunin
---

# Premium Utilitarian Minimalism & Editorial UI

Protocol for generating highly refined, ultra-minimalist, "document-style" web interfaces analogous to top-tier workspace platforms. Enforces high-contrast warm monochrome palette, bespoke typographic hierarchies, meticulous macro-whitespace, bento-grid layouts, and ultra-flat component architecture with deliberate muted pastel accents.

Based on: Apple Notes, Linear, Notion, Basecamp, iA Writer, and premium editorial systems.

## 1. Absolute Negative Constraints (Banned)

- NO Inter, Roboto, or Open Sans typefaces
- NO Lucide, Feather, or standard Heroicons (use Phosphor Bold/Fill)
- NO Tailwind default drop shadows (`shadow-md`, `shadow-lg`, `shadow-xl`)
- NO primary colored backgrounds for sections
- NO gradients, neon colors, or 3D glassmorphism (beyond subtle navbar blur)
- NO `rounded-full` for large containers, cards, or primary buttons
- NO emojis anywhere
- NO "John Doe", "Acme Corp", "Lorem Ipsum" — realistic, contextual content
- NO AI copywriting clichés: "Elevate", "Seamless", "Unleash", "Next-Gen"
- NO centered Hero sections — left-aligned text

## 2. Typographic Architecture

- **Primary Sans-Serif:** `'SF Pro Display', 'Geist Sans', 'Helvetica Neue', 'Switzer', sans-serif`
- **Editorial Serif (Hero Headings):** `'Lyon Text', 'Newsreader', 'Playfair Display', 'Instrument Serif'`. Tight tracking (`-0.02em` to `-0.04em`). Tight line-height (`1.1`).
- **Monospace (Code, Keystrokes):** `'Geist Mono', 'SF Mono', 'JetBrains Mono'`
- **Text Colors:** Never `#000000`. Use off-black (`#111111`, `#2F3437`). Secondary: `#787774`. Line-height `1.6`.

## 3. Color Palette (Warm Monochrome + Muted Pastels)

- **Canvas:** `#FFFFFF` or `#F7F6F3` / `#FBFBFA`
- **Surface (Cards):** `#FFFFFF` or `#F9F9F8`
- **Borders:** `#EAEAEA` or `rgba(0,0,0,0.06)` — exactly 1px solid
- **Accents** (muted pastels only):
  - Pale Red: bg `#FDEBEC`, text `#9F2F2D`
  - Pale Blue: bg `#E1F3FE`, text `#1F6C9F`
  - Pale Green: bg `#EDF3EC`, text `#346538`
  - Pale Yellow: bg `#FBF3DB`, text `#956400`

**CSS vanilla alternative (shokunin improvement):** Prefer CSS custom properties over Tailwind for pure editorial projects:
```css
:root {
  --canvas: #F7F6F3;
  --surface: #FFFFFF;
  --border: #EAEAEA;
  --text: #111111;
  --text-secondary: #787774;
}
```

## 4. Component Specifications

### Bento Box Feature Grids
- Asymmetrical CSS Grid. `border: 1px solid #EAEAEA`. Radius: `8px` to `12px` max.
- Internal padding: `24px` to `40px`.
- Labels placed OUTSIDE and BELOW cards.

### Primary CTAs
- Background `#111111`, text `#FFFFFF`. Radius `4px` to `6px`. No box-shadow.
- Hover: `background: #333333` or `transform: scale(0.98)`. Transition: `200ms ease-out`.
- Active: `transform: scale(0.97)`. `160ms`.

### Tags & Status Badges
- Pill-shaped (`border-radius: 9999px`), `text-xs` uppercase, `tracking: 0.05em`.
- Background: muted pastels from palette above.

### Accordions (FAQ)
- NO container boxes. Separated by `border-bottom: 1px solid #EAEAEA`.
- Clean `+` / `−` toggle icon.

### Keystroke Micro-UIs
- `<kbd>` with `border: 1px solid #EAEAEA`, `border-radius: 4px`, `background: #F7F6F3`. Monospace.

### Faux-OS Window Chrome
- Minimalist container with white top bar + three small light gray macOS circles.

## 5. Iconography & Imagery

- **Icons:** Phosphor Icons (Bold or Fill). Consistent stroke width.
- **Illustrations:** Monochromatic, rough continuous-line ink sketches on white background. Single offset geometric shape in muted pastel.
- **Photography:** Desaturated, warm tone. Subtle grain overlay (`opacity: 0.04`). Never oversaturated stock. Placeholder: `https://picsum.photos/seed/{context}/1200/800`.
- **Hero Backgrounds:** Subtle full-width imagery at very low opacity, soft radial light spots (`opacity: 0.03`), or minimal geometric line patterns.

## 6. Subtle Motion (Quiet Sophistication)

- **Scroll Entry:** `translateY(12px)` + `opacity: 0` → resolve over `600ms` with `cubic-bezier(0.16, 1, 0.3, 1)`. Use `IntersectionObserver`.
- **Hover:** Cards lift with ultra-subtle shadow (`box-shadow: 0 2px 8px rgba(0,0,0,0.04)` over `200ms`). Buttons: `scale(0.98)` on `:active`.
- **Staggered Reveals:** `animation-delay: calc(var(--index) * 80ms)`. Never mount everything at once.
- **Background Ambient:** Single slow-moving radial blob (`20s+`, `opacity: 0.02-0.04`). `position: fixed; pointer-events: none`.
- **Performance:** Only `transform` + `opacity`. No layout-triggering properties.
- **`prefers-reduced-motion` (shokunin improvement):** Mandatory on every animation.

## 7. Execution Protocol

1. Establish macro-whitespace: `py-24` to `py-32` between sections.
2. Constrain content to `max-w-4xl` or `max-w-5xl`.
3. Apply typographic hierarchy + monochromatic color immediately.
4. Every card, divider, border: `1px solid #EAEAEA`.
5. Add scroll-entry animations to all major content blocks.
6. Visual depth through imagery, ambient gradients, or subtle textures — no empty flat backgrounds.
7. Mobile collapse: single-column `w-full px-4` below `768px`. `min-h-[100dvh]` for full-screen.

## 8. Error Handling (shokunin improvement)

| Error | Fix |
|-------|-----|
| Scroll jank from grain overlay | Move to `position: fixed; pointer-events: none` |
| iOS Safari layout jump | `min-h-[100dvh]` instead of `h-screen` |
| Bento cards break on mobile | Single column + remove asymmetric spans below `768px` |
| Accent color too vibrant | Check palette: muted pastels only. Saturation < 40%. |

## 9. Pre-Output Checklist

- [ ] No banned items from Section 1
- [ ] Warm monochrome palette applied
- [ ] Muted pastels for accents only
- [ ] Typography: serif headline + sans body
- [ ] All borders: `1px solid #EAEAEA`
- [ ] No gradients, no heavy shadows
- [ ] No `rounded-full` on large elements
- [ ] Scroll entries on all content blocks
- [ ] Mobile collapse: single-column, `min-h-[100dvh]`
- [ ] `prefers-reduced-motion` on all animations
- [ ] No emojis, no AI clichés, no generic names
- [ ] Overall reads as "editorial, calm, premium" — not "template"
