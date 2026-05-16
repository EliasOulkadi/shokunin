---
name: taste
description: "Senior UI/UX Engineer. Architect digital interfaces overriding default LLM biases. Enforces metric-based rules, strict component architecture, hardware-accelerated CSS, and balanced design engineering. By Leon Lin & blueemi. Multi-runtime improved by shokunin."
license: MIT (based on Leonxlnx/taste-skill)
compatibility: opencode
metadata:
  version: "2.0-improved"
  author: Leon Lin, blueemi, improved by shokunin
  source: https://github.com/Leonxlnx/taste-skill
---

# High-Agency Frontend Skill

## Authority References (shokunin improvement)

The rules in this skill are based on patterns observed across:
- Linear, Vercel, Stripe, Notion — product UI
- Apple Human Interface Guidelines
- Material Design 3
- Emil Kowalski's design engineering (Sonner, Vaul, animations.dev)
- Paul Lewis (Google Chrome) — compositor-only properties
- Ahmad Shadeed — Container Queries and CSS architecture
- WCAG 2.2 — Accessibility guidelines
- CSS Working Group — modern CSS features

## 1. ACTIVE BASELINE CONFIGURATION

- **DESIGN_VARIANCE**: 8 (1=Perfect Symmetry, 10=Artsy Chaos)
- **MOTION_INTENSITY**: 6 (1=Static, 10=Cinematic/Magic Physics)
- **VISUAL_DENSITY**: 4 (1=Art Gallery/Airy, 10=Pilot Cockpit/Packed Data)

These are the standard baselines. ALWAYS listen to the user: adapt these values dynamically based on what they explicitly request. Use these values as global variables driving Sections 3 through 7.

## 2. DEFAULT ARCHITECTURE & CONVENTIONS

### Framework & Interactivity
- React or Next.js. Default to Server Components (RSC).
- **INTERACTIVITY ISOLATION:** Interactive UI components with motion MUST be extracted as isolated leaf components with `'use client'` at top.
- **DEPENDENCY VERIFICATION [MANDATORY]:** Before importing ANY 3rd party library (framer-motion, lucide-react, zustand), check `package.json`. If missing, output `npm install <package>` before code. Never assume.

### Styling
- Use Tailwind CSS (v3/v4) for 90% of styling.
- **CSS vanilla alternative (shokunin improvement):** For projects without Tailwind, use CSS custom properties + modern CSS (Container Queries, clamp(), :has(), OKLCH).
- **TAILWIND VERSION LOCK:** Check `package.json`. No v4 syntax in v3 projects.
- **ANTI-EMOJI POLICY:** NEVER use emojis in code, markup, text, or alt text. Replace with Phosphor, Lucide, or clean SVG primitives.

### Responsiveness
- **Viewport Stability [CRITICAL]:** NEVER `h-screen`. Always `min-h-[100dvh]` for iOS Safari.
- **Grid over Flex-Math:** NEVER `w-[calc(33%-1rem)]`. Always CSS Grid `grid-cols-3 gap-6`.
- Standardize breakpoints: sm(640), md(768), lg(1024), xl(1280).

### Icons
- `@phosphor-icons/react` or `@radix-ui/react-icons`. Standardize `strokeWidth` (1.5 or 2.0).

## 3. DESIGN ENGINEERING DIRECTIVES (Bias Correction)

### Rule 1: Deterministic Typography
- **Display/Headlines:** `text-4xl md:text-6xl tracking-tighter leading-none`. Use `Geist`, `Outfit`, `Cabinet Grotesk`, or `Satoshi`. NEVER Inter for premium.
- **TECHNICAL UI:** Serif fonts strictly BANNED for Dashboards. Use high-end Sans-Serif: `Geist` + `Geist Mono`.
- **Body:** `text-base text-gray-600 leading-relaxed max-w-[65ch]`.

### Rule 2: Color Calibration
- Max 1 Accent Color. Saturation < 80%.
- **THE AI PURPLE BAN:** No purple button glows, no neon gradients. Use neutral bases (Zinc/Slate) with singular accents (Emerald, Electric Blue, Deep Rose).
- **OKLCH preferred (shokunin improvement):** `oklch(50% 0.2 170)` over hex `#10b981`.
- One palette for entire project. No warm/cool gray mix.

### Rule 3: Layout Diversification
- **ANTI-CENTER BIAS:** When `DESIGN_VARIANCE > 4`, centered Hero sections are BANNED. Use Split Screen (50/50), Left Aligned content + Right Aligned asset, or Asymmetric White-space.

### Rule 4: Materiality and Shadows
- **DASHBOARD HARDENING:** For `VISUAL_DENSITY > 7`, cards are BANNED. Use `border-t`, `divide-y`, or negative space. Data breathes without boxes.
- Cards only when elevation communicates hierarchy. Tint shadow to background hue.

### Rule 5: Interactive UI States
- **Mandatory:** Loading (skeletal, not spinners) → Empty (beautiful, with guidance) → Error (inline, specific) → Success.
- **Tactile Feedback:** `:active` → `scale-[0.98]`. `transition: transform 160ms ease-out`.

### Rule 6: Data & Form Patterns
- Labels ABOVE inputs. Error text BELOW input. Standard `gap-2` for input blocks.

## 4. CREATIVE PROACTIVITY (Anti-Slop Implementation)

- **"Liquid Glass":** When glassmorphism is needed, add 1px inner border + inner shadow. Never default decoration.
- **Magnetic Micro-physics** (MOTION_INTENSITY > 5): Use Framer Motion `useMotionValue` + `useTransform` outside React render cycle. NEVER `useState` for continuous animations.
- **Perpetual Micro-Interactions:** Pulse, Typewriter, Float, Shimmer. Spring physics (`type: "spring", stiffness: 100, damping: 20`). No linear easing.
- **Staggered Orchestration:** `animation-delay: calc(var(--index) * 100ms)`. 30-80ms between items. Parent + Children in same Client Component tree.
- **WAAPI fallback for heavy load (shokunin improvement):** When Framer Motion drops frames under load, use WAAPI: `element.animate(...)`. Runs off main thread.

## 5. PERFORMANCE GUARDRAILS

- **GPU-Safe:** Only animate `transform` and `opacity`. Never `top`, `left`, `width`, `height`.
- **Grain/Noise:** Apply exclusively to `position: fixed; pointer-events: none` pseudo-elements. Never on scrolling containers.
- **Blur:** Only on fixed/sticky elements. Never on scrolling content.
- **Z-Index Discipline:** Only for systemic layers (sticky nav, modals, overlays).
- **`prefers-reduced-motion` (shokunin improvement):** Mandatory on every animation:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## 6. TECHNICAL REFERENCE (Dial Definitions)

### DESIGN_VARIANCE (1-10)
- **1-3 (Predictable):** `justify-center`, 12-column grids, equal paddings.
- **4-7 (Offset):** Overlapping, varied aspect ratios, left-aligned over center.
- **8-10 (Asymmetric):** Masonry, fractional grids, massive empty zones.
- **MOBILE OVERRIDE:** Levels 4-10: collapse to single-column (`w-full`, `px-4`, `py-8`) below `768px`.

### MOTION_INTENSITY (1-10)
- **1-3 (Static):** `:hover` and `:active` only.
- **4-7 (Fluid):** `transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1)`. Stagger reveals.
- **8-10 (Choreography):** Complex scroll-triggers. Framer Motion. NEVER `window.addEventListener('scroll')`.

### VISUAL_DENSITY (1-10)
- **1-3 (Gallery):** Lots of white space. Expensive, clean.
- **4-7 (Daily App):** Normal spacing.
- **8-10 (Cockpit):** Tiny paddings. No cards. 1px lines. Monospace for all numbers.

## 7. AI TELLS (Forbidden Patterns)

| Category | Banned | Use Instead |
|----------|--------|-------------|
| Visual | Neon glows, #000000, oversaturated accents, gradient text, custom cursors | Inner borders, tinted shadows, zinc/slate neutrals |
| Typography | Inter font, oversized H1s, serif on dashboards | Geist, Outfit, Satoshi. Hierarchy via weight + color, not just scale |
| Layout | Centered heroes, 3-column equal cards | Split screen, zig-zag, asymmetric |
| Content | "John Doe", "99.99%", "Acme", "Elevate", "Seamless" | Creative names, messy numbers, concrete verbs |
| Resources | Unsplash (broken links), default shadcn/ui | picsum.photos, customized shadcn |

## 8. THE CREATIVE ARSENAL (High-End Inspiration)

Reference library of advanced UI concepts. Never default to generic. Use Framer Motion for Bento/UI interactions. Use GSAP/ThreeJS exclusively for isolated full-page scrolltelling or canvas backgrounds, wrapped in strict useEffect cleanup.

### Hero Paradigms: Split Screen, Slide-Away Text, Curtain Reveal, Zoom Parallax
### Navigation: Mac OS Dock, Magnetic Button, Dynamic Island, Radial Menu
### Layouts: Bento Grid, Masonry, Chroma Grid, Split Scroll
### Cards: Parallax Tilt, Spotlight Border, Holographic Foil, Tinder Swipe
### Scroll: Sticky Stack, Horizontal Hijack, Scroll Progress Path, Liquid Swipe
### Text: Kinetic Marquee, Text Mask Reveal, Scramble Effect, Circular Path
### Micro: Particle Explosion, Ripple Click, Skeleton Shimmer, Animated SVG Line Drawing

## 9. ERROR HANDLING TABLE (shokunin improvement)

| Error | Cause | Fix |
|-------|-------|-----|
| Layout shift on iOS Safari | `h-screen` used | Replace with `min-h-[100dvh]` |
| Framer Motion frames drop under load | Using `x`/`y` shorthand | Use `transform: "translateX()"` string or WAAPI |
| Grain causes scroll jank | Grain on scrolling container | Move to `position: fixed; pointer-events: none` |
| Touch hover state fires incorrectly | No `@media (hover: hover)` guard | Gate hover behind pointer media query |
| Magnetic button causes layout shift | Using `useState` for animation | Use `useMotionValue` + `useTransform` |
| Perpetual animation causes re-renders | Not in isolated Client Component | `React.memo` + isolated leaf component |
| Bento cards break on mobile | No mobile collapse rules | Force single-column below `768px` |

## 10. PRE-FLIGHT CHECKLIST

- [ ] Mobile: `min-h-[100dvh]` (not `h-screen`)
- [ ] Mobile collapse below 768px for asymmetric layouts
- [ ] `prefers-reduced-motion` on every animation
- [ ] Only `transform` + `opacity` animated
- [ ] Hover gated behind `@media (hover: hover)`
- [ ] No emojis in code or content
- [ ] No Inter as display font
- [ ] No neon glows or AI purple
- [ ] No `#000000` or `#ffffff` — tinted neutrals
- [ ] Grid used instead of complex flexbox math
- [ ] Loading, empty, error states all rendered
- [ ] Buttons: `scale-[0.98]` on `:active`
- [ ] Grain/noise: `position: fixed; pointer-events: none` only
- [ ] Perpetual animations in isolated Client Components
- [ ] Dependency verification: all imports exist in package.json

## Sources (shokunin improvement)

- Emil Kowalski — Design engineering (Sonner, Vaul, Linear, animations.dev)
- Paul Lewis — Compositor-only properties (Google Chrome)
- Ahmad Shadeed — Container Queries and modern CSS
- WCAG 2.2 — Accessibility
- Apple Human Interface Guidelines
- Material Design 3
- OKLCH color space (W3C)
