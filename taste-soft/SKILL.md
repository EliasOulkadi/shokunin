---
name: taste-soft
description: "High-end visual design like a premium agency. Defines exact fonts, spacing, shadows, card structures, and animations that make a website feel expensive. Blocks common defaults that make AI designs look cheap or generic. Based on taste-skill by Leon Lin & blueemi, improved by shokunin."
license: MIT
compatibility: opencode
metadata:
  version: "2.0-improved"
  author: Leon Lin, blueemi, improved by shokunin
---

# Principal UI/UX Architect & Motion Choreographer (Awwwards-Tier)

Engineering $150k+ agency-level digital experiences. Output must exude haptic depth, cinematic spatial rhythm, obsessive micro-interactions, and flawless fluid motion. NEVER generate the same layout twice. Combine different premium archetypes while adhering to elite "Apple-esque / Linear-tier" design language.

## Authority References (shokunin improvement)

Based on: Apple Human Interface Guidelines, Linear Design, Stripe Design, Emil Kowalski (design engineering), Paul Lewis (compositor-only), Ahmad Shadeed (Container Queries), WCAG 2.2.

## 1. THE "ABSOLUTE ZERO" DIRECTIVE (ANTI-PATTERNS)

- **Banned Fonts:** Inter, Roboto, Arial, Open Sans, Helvetica. Use Geist, Clash Display, PP Editorial New, Plus Jakarta Sans.
- **Banned Icons:** Standard thick-stroked Lucide, FontAwesome, Material. Use Phosphor Light, Remix Line.
- **Banned Borders/Shadows:** Generic 1px solid gray. Harsh `rgba(0,0,0,0.3)`. Use tinted, ultra-diffuse shadows.
- **Banned Layouts:** Edge-to-edge sticky nav glued to top. Boring symmetric 3-column grids without massive whitespace.
- **Banned Motion:** Standard `linear` or `ease-in-out`. Instant state changes without interpolation.

## 2. THE CREATIVE VARIANCE ENGINE

Select ONE combination per project to ensure unique output:

### Vibe & Texture Archetypes (Pick 1)
1. **Ethereal Glass (SaaS/Tech):** OLED black (#050505), radial mesh gradients (glowing purple/emerald orbs). Vantablack cards + `backdrop-blur-2xl` + white/10 hairlines. Wide geometric Grotesk.
2. **Editorial Luxury (Lifestyle/Agency):** Warm creams (#FDFBF7), muted sage, deep espresso. High-contrast Variable Serif for headings. CSS noise/film-grain overlay (`opacity-[0.03]`).
3. **Soft Structuralism (Consumer/Health/Portfolio):** Silver-grey or white backgrounds. Massive bold Grotesk. Airy, floating components with soft, highly diffused ambient shadows.

### Layout Archetypes (Pick 1)
1. **Asymmetrical Bento:** Masonry-like grid of varying card sizes (`col-span-8 row-span-2` next to stacked `col-span-4`). **Mobile:** Single column. All `col-span` overrides reset.
2. **Z-Axis Cascade:** Elements stacked like physical cards, overlapping with subtle `-2deg` or `3deg` rotation. **Mobile:** Remove all rotations and negative margins. Stack vertically.
3. **Editorial Split:** Massive typography on left half (`w-1/2`), interactive horizontal scrollable cards on right. **Mobile:** Full-width vertical stack.

**Universal Mobile Override:** Any asymmetric layout ≥ md breakpoint MUST collapse to `w-full px-4 py-8` below `768px`. NEVER `h-screen` — always `min-h-[100dvh]`.

## 3. HAPTIC MICRO-AESTHETICS

### "Double-Bezel" Nested Architecture
- **Outer Shell:** Wrapper with subtle background (`bg-black/5`), hairline border (`ring-1 ring-black/5`), padding `p-1.5`, large radius `rounded-[2rem]`.
- **Inner Core:** Content container with distinct background, its own inner highlight (`shadow-[inset_0_1px_1px_rgba(255,255,255,0.15)]`), mathematically calculated smaller radius `rounded-[calc(2rem-0.375rem)]`.

### CTA "Button-in-Button" Architecture
- Primary buttons: fully rounded pills (`rounded-full`, `px-6 py-3`).
- Trailing icon: NEVER naked. Wrapped in its own circular container (`w-8 h-8 rounded-full bg-black/5`), placed flush with button's right inner padding.

### Spatial Rhythm
- Macro-whitespace: `py-24` to `py-40` for sections. Breathe heavily.
- Eyebrow Tags: Microscopic, pill-shaped badge (`rounded-full px-3 py-1 text-[10px] uppercase tracking-[0.2em] font-medium`) preceding major headings.

## 4. MOTION CHOREOGRAPHY

All motion uses custom cubic-bezier (`transition-all duration-700 ease-[cubic-bezier(0.32,0.72,0,1)]`). Never `linear` or default `ease-in-out`.

### "Fluid Island" Nav
- **Closed:** Floating glass pill detached from top (`mt-6 mx-auto w-max rounded-full`).
- **Hamburger Morph:** Lines fluidly rotate to form 'X' (`rotate-45` / `-rotate-45`), not just disappear.
- **Modal Expansion:** Massive screen-filling overlay with `backdrop-blur-3xl bg-black/80`.
- **Staggered Mask Reveal:** Links fade + slide up (`translate-y-12 opacity-0` → `translate-y-0 opacity-100`) with staggered delay (100ms, 150ms, 200ms).

### Magnetic Button Physics
- `group` utility. `active:scale-[0.98]` for physical press.
- Nested inner icon: `group-hover:translate-x-1 group-hover:-translate-y-[1px] scale-105`.

### Scroll Entry
- Elements fade + slide up + blur: `translate-y-16 blur-md opacity-0` → `translate-y-0 blur-0 opacity-100` over 800ms+.
- Use `IntersectionObserver`. NEVER `window.addEventListener('scroll')`.

## 5. PERFORMANCE GUARDRAILS

- **GPU-Safe:** Only `transform` + `opacity`. `will-change: transform` sparingly.
- **Blur:** Only fixed/sticky elements. Never scrolling content.
- **Grain:** `position: fixed; pointer-events: none` only.
- **Z-Index:** Only systemic layers.
- **`prefers-reduced-motion`:** Mandatory on every animation (shokunin improvement).

## 6. PRE-OUTPUT CHECKLIST

- [ ] No banned fonts, icons, borders, shadows, layouts, motion (Section 1)
- [ ] Vibe + Layout Archetype consciously selected (Section 2)
- [ ] Double-Bezel nested architecture on major cards (Section 3)
- [ ] Button-in-Button on CTAs where applicable (Section 3)
- [ ] Section padding ≥ `py-24`
- [ ] Custom cubic-bezier on all transitions
- [ ] Scroll entry animations present
- [ ] Mobile collapse below `768px`: single-column
- [ ] `min-h-[100dvh]` not `h-screen`
- [ ] `transform` + `opacity` only for animations
- [ ] `prefers-reduced-motion` respected
- [ ] Overall reads as "$150k agency build", not "template with nice fonts"
