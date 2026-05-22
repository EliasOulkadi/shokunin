---
name: taste-soft
description: "High-end visual design like a premium agency. Defines exact fonts, spacing, shadows, card structures, and animations that make a website feel expensive. Blocks common defaults that make AI designs look cheap or generic. Based on taste-skill by Leon Lin & blueemi, improved by shokunin."
triggers:
  - "luxury design"
  - "premium UI"
  - "agency design"
  - "expensive look"
  - "high-end design"
  - "Apple-esque"
  - "Linear-tier"
  - "double-bezel"
  - "magnetic button"
  - "fluid nav"
negatives:
  - "minimalist design"
  - "editorial design"
  - "brutalist"
  - "flat design"
  - "components"
  - "base design framework" -> use taste
license: MIT
compatibility: opencode
metadata:
  version: "2.0.0"
  author: Leon Lin, blueemi, improved by shokunin

  workflow: frontend
  audience: designers
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

## Workflow

### Step 1: Select Archetypes

Pick exactly one Vibe Archetype and one Layout Archetype from Section 2 before writing any code. Document the selection so the entire build stays coherent:

```
Vibe: Ethereal Glass | Editorial Luxury | Soft Structuralism
Layout: Asymmetrical Bento | Z-Axis Cascade | Editorial Split
```

Never mix vibes. A page that blends Ethereal Glass gradients with Editorial Luxury serifs reads as confused, not premium.

### Step 2: Block banned defaults

Before writing any Tailwind class, review Section 1 "Absolute Zero" and remove all banned fonts, icons, borders, shadows, and motion defaults from the project scaffold. This is a blocking step — do not proceed until every banned item is replaced.

### Step 3: Build outer shell → inner core

Follow the Double-Bezel architecture (Section 3). For every major section:
1. Create the outer wrapper (`bg-black/5 ring-1 ring-black/5 rounded-[2rem] p-1.5`)
2. Place the inner content container (`shadow-[inset_0_1px_1px_rgba(255,255,255,0.15)]`)
3. Add content. Never skip the bezel — it is the signature of this aesthetic.

### Step 4: Wire motion

Apply motion choreography (Section 4) to:
- Navigation: Fluid Island pattern with hamburger morph + staggered mask reveal
- CTAs: Magnetic button physics with nested icon animation
- Scroll entries: IntersectionObserver-driven fade + slide + blur

### Step 5: Mobile collapse

Overwrite every asymmetric layout rule at the `md` breakpoint (768px). All `col-span` values reset, all rotations removed, all negative margins zeroed. Use `min-h-[100dvh]` everywhere; never `h-screen`.

### Step 6: Pre-output checklist

Run through the 12-item checklist (Section 6) before delivering. Every unchecked box is a regression from "$150k agency" to "template with nice fonts."

### Step 7: Accessibility verification

- All animations respect `prefers-reduced-motion: reduce`
- Color contrast meets WCAG 2.2 AA minimum (4.5:1 for text, 3:1 for large text)
- Focus indicators visible and non-removed (never `outline: none` without replacement)
- Grain overlay has `pointer-events: none` and `aria-hidden="true"`

## Error Handling

| Cause | Fix |
|-------|-----|
| CSS grain texture causes layout shift or scroll jank | Grain must be `position: fixed; pointer-events: none; z-index: [system layer]`. Never apply grain to a scrolling container. |
| backdrop-blur causes GPU compositing failure on low-end devices | Limit blur to fixed/sticky elements only. Feature-detect with `@supports (backdrop-filter: blur(1px))`. Provide solid fallback background. |
| Double-Bezel nested radii don't align mathematically | Outer radius `R`, inner radius must be `R - padding`. If `rounded-[2rem]` and `p-1.5` (24px), inner is `rounded-[calc(2rem-1.5rem)]`. Always use `calc()` to prevent drift. |
| Magnetic button jitters on rapid hover/unhover | Apply `transition-transform duration-200` on the inner element only. Use `will-change: transform` on the button and remove it on `animationend`. |
| Z-Axis Cascade cards overlap incorrectly on Safari | Safari handles `z-index` in stacking contexts differently with transforms. Apply explicit `z-index` values (not `auto`) and `transform-style: flat` on the parent. |
| Scroll entry animations fire multiple times on fast scroll | Use `IntersectionObserver` with `threshold: 0.1` and a `once: true` flag. Track animated elements in a `WeakSet` to prevent re-triggering. |
| Custom cubic-bezier feels sluggish on quick interactions | For interactive elements (buttons, toggles), use shorter duration: `duration-200 ease-[cubic-bezier(0.32,0.72,0,1)]`. Reserve `duration-700` for scroll entries and page transitions only. |

## Sources

- Apple Human Interface Guidelines (developer.apple.com/design/human-interface-guidelines) — spatial layout, motion, and material principles
- Linear Design System (linear.app/docs/design-system) — opinionated component architecture and animation philosophy
- Stripe Design documentation (stripe.com/design) — premium SaaS visual language and interaction patterns
- Emil Kowalski "Animation Engineering" (animations.dev) — WAAPI, spring physics, and compositor-only animation
- Ahmad Shadeed "CSS Container Queries" (ishadeed.com) — modern responsive layout patterns
- WCAG 2.2 Specification (w3.org/TR/WCAG22) — accessibility compliance for motion, contrast, and focus
- Paul Lewis "The Compositor's Properties" (web.dev/animations-guide) — GPU-safe animation properties and layout thrashing prevention

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Dropping the Double-Bezel on inner sections "for simplicity" | The page loses its signature depth. Cards become flat and generic. | Every major card/section gets the bezel. Only minor inline elements (tags, badges, tooltips) skip it. |
| Using `h-screen` instead of `min-h-[100dvh]` | `100vh` ignores mobile browser chrome (address bar), causing overflow and clipped content. | Always use `min-h-[100dvh]`. Dynamic viewport height compensates for browser UI. |
| Applying the same archetype combination to every project | The Creative Variance Engine exists to prevent repetition. Reusing the same vibe+layout produces indistinguishable output. | Track previously used combinations. Force new selection if the last 3 projects used the same archetype. |
| Omitting mobile overrides | Asymmetric bento and Z-axis cascade layouts break catastrophically below 768px. | Every `col-span-*` and rotation resets at `md:` breakpoint. Test at 375px width before delivery. |
| Linear or ease-in-out on any transition | These are explicitly banned in Section 1. Default easing reads as unpolished AI output. | Custom cubic-bezier with asymmetric curve on every transition. Interactive: `duration-200`. Scroll: `duration-700`. |
| Adding a fourth or fifth font to "make it unique" | Premium design uses 2 fonts max (heading + body). More fonts create visual noise and degrade performance. | Stick to 1-2 typefaces. Use weight, size, and letter-spacing for hierarchy instead of additional families. |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
