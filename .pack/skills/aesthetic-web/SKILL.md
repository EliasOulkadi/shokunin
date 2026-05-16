---
name: Aesthetic Web Design
description: >
  Apply professional, premium UI/UX design standards when building or styling
  web interfaces. Use this skill when the user asks to create a website, landing
  page, web app, dashboard, UI component, or any visual interface — or when they
  ask to make something look better, more professional, or more beautiful. Covers
  visual hierarchy, typography, color systems, layout, spacing, motion, dark mode,
  responsive design, and conversion patterns. Activate even when the user doesn't
  say "design" — if they're building a web frontend, these standards apply.
---

# Aesthetic Web Design

A specific, opinionated design language based on real references. This skill encodes a visual DNA — not generic "make it look good" — but exact fonts, exact palettes, exact CSS values.

## Creative North Star

The default direction is **editorial + atmospheric**.

Core DNA:
- Typography as primary visual element — massive, oversized, bleeding off-screen
- Backgrounds with depth: gradient meshes, grain texture, illustrated scenes
- 3D scroll effects and parallax on hero
- Dark (#080808) OR cream (#f5f2ec) palettes — never generic white
- Serif display for editorial, bold condensed display for tech
- Product screenshots floating at angles, not centered boxes

Anti-identity (absolute bans):
- Flat #fff background with Inter font — wireframe, not finished design
- Purple/indigo gradient on white — the #1 AI cliché
- Generic 3-column centered layout with icon + heading + text cards
- Emoji as icons
- Animations on everything with no purpose

---

## Register Distinction

Every design task is either **Brand** or **Product**.

| Register | Scope | Bar | Approach |
|----------|-------|-----|----------|
| Brand | Marketing, landing pages, campaign surfaces, portfolios, long-form content. Design IS the product. | Distinctiveness. Must stand out from competitors. | Full creative range. Editorial, luxury, brutalist, cinematic — any visual lane. |
| Product | App UI, admin, dashboards, developer tools. Design SERVES the product. | Earned familiarity. Users of Linear, Stripe, Vercel should trust it. | Restrained. Clean. Fast. One palette. Predictable patterns. |

Identify before designing. Priority: (1) task cue ("landing page" vs "dashboard"), (2) surface in focus, (3) project context. First match wins.

---

## 1. Typography — The Main Visual Element

### Display fonts by direction

**Editorial serif** (Structured.money, Cori Corinne, Steep.app):
- Canela (preferred, premium license) — high contrast, editorial
- DM Serif Display (free) — elegant, sharp serifs
- Cormorant Garamond (free) — ultra-high contrast, ultra-luxury
- Playfair Display (free) — classic editorial
- Fraunces (free) — optical-size variable, editorial/vintage

**Bold display sans** (Leonardo.AI, Monopo):
- Neue Haas Grotesk Display — definitive display grotesque
- Cabinet Grotesk (free) — wide, excellent for oversized headlines
- Bebas Neue (free) — all-caps condensed
- Anton (free) — punchy, condensed
- Space Grotesk (free) — tech/futuristic

**Body/UI text** (never as display, never Inter as headline):
- DM Sans (free, pairs with DM Serif Display)
- Geist (free, clean, modern)
- Inter (free, body text only)

### Oversized typography

```css
.display-hero {
  font-size: clamp(80px, 12vw, 180px);
  line-height: 0.9;
  letter-spacing: -0.03em;
  font-weight: 700;
}

.bleed-text {
  font-size: clamp(120px, 18vw, 280px);
  line-height: 0.85;
  white-space: nowrap;
  overflow: hidden;
  letter-spacing: -0.04em;
}

.mixed-headline {
  font-size: clamp(40px, 6vw, 96px);
  font-weight: 600;
  line-height: 1.05;
}
.mixed-headline em {
  font-style: italic;
  font-weight: 400;
}
```

### Fluid type scale

```css
:root {
  --text-body:    clamp(15px, 1.1vw, 18px);
  --text-lead:    clamp(18px, 1.5vw, 24px);
  --text-h3:      clamp(22px, 2vw, 32px);
  --text-h2:      clamp(30px, 3.5vw, 56px);
  --text-h1:      clamp(48px, 7vw, 96px);
  --text-display: clamp(80px, 12vw, 180px);
  --text-bleed:   clamp(120px, 18vw, 280px);
}
```

---

## 2. Color System (OKLCH)

All new colors in OKLCH. High chroma at extremes looks garish — reduce chroma as lightness approaches 0 or 100.

### Direction 1: Dark + accent (Leonardo.AI, tech)

```css
--bg:         #080808;
--bg-surface: oklch(15% 0 0);
--text:       #f0ede8;
--text-muted: oklch(60% 0 0);
--accent:     oklch(55% 0.2 270);
--border:     oklch(25% 0 0);
```

### Direction 2: Deep navy + spotlight (Notion)

```css
--bg:         oklch(12% 0.05 260);
--text:       #ffffff;
--text-muted: oklch(65% 0 0);
--accent:     oklch(55% 0.2 260);
--spotlight:  oklch(50% 0.2 260 / 0.3);
```

### Direction 3: Cream editorial (Structured.money, Cori Corinne)

```css
--bg:         #f5f2ec;
--bg-surface: #ede9e0;
--text:       #0a0a0a;
--text-muted: #5a5550;
--accent:     #1a1a1a;
--border:     oklch(85% 0 0);
```

### Direction 4: Warm mesh (Steep.app)

```css
--bg:         #fdf6ef;
--text:       #1a1412;
--accent:     #c8502a;
--mesh-1:     oklch(70% 0.15 30 / 0.3);
--mesh-2:     oklch(70% 0.15 280 / 0.25);
```

**Color rules (all directions):**
- Never pure `#000` or `#fff`. Tint every neutral (chroma 0.005-0.01 is enough).
- One accent ≤ 10% of any screen. Scarcity is the design choice.
- OKLCH for all new colors. Hex only for legacy values.

---

## 3. Backgrounds — Atmospheric, Never Flat

### Gradient mesh

```css
.mesh-light {
  background: #fdf6ef;
  background-image:
    radial-gradient(ellipse 80% 60% at 20% 30%, rgba(255, 180, 150, 0.5) 0%, transparent 60%),
    radial-gradient(ellipse 60% 80% at 80% 70%, rgba(180, 160, 255, 0.4) 0%, transparent 60%),
    radial-gradient(ellipse 70% 50% at 50% 10%, rgba(255, 220, 180, 0.3) 0%, transparent 60%);
}

.mesh-dark {
  background: #080c1a;
  background-image:
    radial-gradient(ellipse 60% 80% at 10% 20%, oklch(30% 0.15 260 / 0.6) 0%, transparent 55%),
    radial-gradient(ellipse 70% 60% at 90% 80%, oklch(50% 0.2 20 / 0.5) 0%, transparent 55%),
    radial-gradient(ellipse 50% 40% at 50% 50%, oklch(5% 0.02 260 / 0.7) 0%, transparent 60%);
}
```

### Grain/noise overlay

```css
.grain::after {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.04;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
  background-repeat: repeat;
  background-size: 200px 200px;
}
```

---

## 4. Scroll Effects — 3D and Parallax

### 3D perspective typography (Leonardo.AI)

```css
.perspective-container {
  perspective: 800px;
  perspective-origin: 50% 50%;
  overflow: hidden;
}

.text-3d-top {
  transform: rotateX(35deg) translateY(-20px);
  transform-origin: center bottom;
}
.text-3d-bottom {
  transform: rotateX(-35deg) translateY(20px);
  transform-origin: center top;
}
```

### Scroll-driven parallax

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

### Smooth scroll entrance

```css
.reveal {
  opacity: 0;
  transform: translateY(40px);
  transition: opacity 0.7s ease, transform 0.7s cubic-bezier(0.16, 1, 0.3, 1);
}
.reveal.visible {
  opacity: 1;
  transform: translateY(0);
}
```

---

## 5. Floating Product Screenshots

```css
.screenshot-float {
  border-radius: 12px;
  box-shadow:
    0 24px 80px rgba(0, 0, 0, 0.25),
    0 4px 16px rgba(0, 0, 0, 0.15);
  position: absolute;
}

.screenshot-left {
  left: -40px;
  top: 15%;
  transform: rotate(-4deg);
  width: 280px;
}

.screenshot-right {
  right: -40px;
  top: 25%;
  transform: rotate(3deg);
  width: 300px;
}

@keyframes float {
  0%, 100% { transform: translateY(0px) rotate(-4deg); }
  50% { transform: translateY(-12px) rotate(-4deg); }
}
```

---

## 6. Spacing and Layout

- Section padding: `clamp(80px, 12vh, 160px)` top and bottom
- Max content width: 1400px for app, 900px for editorial
- Hero padding: 0 — let content breathe

**Breaking the grid:**
- Text bleeds off left: `margin-left: -5vw`
- Full-bleed section: `width: 100vw; margin-left: calc(-50vw + 50%)`
- Overlapping sections: negative `margin-top` on next section

---

## 7. Motion Standards

| Element | Duration | Easing |
|---------|----------|--------|
| Hover state | 120-160ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Button press | 160ms | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Scroll reveal | 600-800ms | `cubic-bezier(0.16, 1, 0.3, 1)` |
| 3D scroll transform | No duration — driven by scroll position | — |

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1);
```

---

## 8. Do's and Don'ts

### Do:
- **Do** treat Warm Cream (#f5f2ec) or Dark (#080808) as default background. Never flat white.
- **Do** use OKLCH for all new color declarations.
- **Do** apply grain overlay (opacity 0.03-0.06) on atmospheric backgrounds.
- **Do** use oversized display typography (`clamp(48px, 7vw, 96px)` or larger).
- **Do** caps body line length at 65-75ch via `max-width`.
- **Do** use Lucide or Phosphor for icons. SVG only.
- **Do** respect `prefers-reduced-motion` on every animation.
- **Do** test at 320px, 768px, 1024px, 1440px.

### Don't:
- **Don't** use pure black (#000) or pure white (#fff). Tint every neutral.
- **Don't** use `border-left` > 1px as a colored accent. Immediate AI-dashboard tell.
- **Don't** use `background-clip: text` with gradient. Decorative, never meaningful.
- **Don't** use glassmorphism as default. Rare and purposeful, or nothing.
- **Don't** use the hero-metric template (big number + small label + gradient). SaaS cliché.
- **Don't** use identical card grids (same-sized cards with icon + heading + text).
- **Don't** use Inter as a display/headline font.
- **Don't** use emoji as icons.
- **Don't** use bounce or elastic easing on functional UI.
- **Don't** nest cards inside cards. Flatten the hierarchy.
- **Don't** center hero text. Left-aligned text + right visual.
- **Don't** animate `width`, `height`, `top`, `left`. Use `transform` and `opacity`.

---

## Pre-Delivery Checklist

- [ ] Background has texture/atmosphere — not a flat solid color
- [ ] Display font is editorial serif or bold condensed display — not Inter
- [ ] Headline oversized (`clamp(48px, 7vw, 96px)` or larger)
- [ ] Scroll has at least one effect: parallax, reveal, 3D, or horizontal text
- [ ] Color palette matches one of the 4 directions — no generic blue/grey
- [ ] OKLCH used for all new colors
- [ ] No emoji icons — Lucide/Phosphor only
- [ ] Product screenshots floating/tilted — not centered in flat box
- [ ] Grain overlay present on atmospheric backgrounds (opacity 0.03-0.06)
- [ ] All interactive elements have hover/active/focus states
- [ ] Button press: `scale(0.97)` on `:active`, 160ms ease-out
- [ ] Mobile: touch targets 44px+, body 16px+ min, single-column
- [ ] `min-h-[100dvh]` used for full-screen sections
- [ ] Line length capped at 65-75ch
- [ ] One accent ≤ 10% of any screen
- [ ] No `border-left` > 1px as colored accent
- [ ] No gradient text
- [ ] No bounce/elastic easing on UI
- [ ] `prefers-reduced-motion` respected
- [ ] Empty, loading, error, and success states all rendered

---

## Sources

- Structured.money — Editorial luxury design
- Leonardo.AI — 3D perspective typography
- Monopo — Dark atmospheric design
- Steep.app — Gradient mesh backgrounds
- Cori Corinne — Editorial serif design
- OKLCH color space (oklch.com)
- Emil Kowalski — Design engineering philosophy
- WCAG 2.2 — Accessibility guidelines
