---
name: taste
description: "Senior UI/UX Engineer. Architect digital interfaces overriding default LLM biases. Enforces metric-based rules, strict component architecture, hardware-accelerated CSS, and balanced design engineering. By Leon Lin & blueemi. Multi-runtime improved by shokunin."
triggers:
  - "taste"
  - "design taste"
  - "UI taste"
  - "design variance"
  - "anti-slop"
  - "creative arsenal"
  - "Leon Lin"
  - "design engineering"
negatives:
  - "animations"
  - "motion"
  - "components library"
  - "brand identity"
  - "premium agency design" -> use taste-soft
  - "minimalist editorial" -> use taste-minimalist
  - "design audit" -> use impeccable
  - "micro-interactions" -> use emil-design-eng
license: MIT (based on Leonxlnx/taste-skill)
compatibility: opencode
metadata:
  version: "2.0.0"
  author: Leon Lin, blueemi, improved by shokunin
  source: https://github.com/Leonxlnx/taste-skill

  workflow: frontend
  audience: designers
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

## Error Handling

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

---

## Workflow

1. **Read user intent** — extract product type, style keywords, motion preference, visual density preference. Map to the three dial values (DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY).
2. **Lock dependencies** — check package.json before importing. Tailwind version (v3 vs v4 syntax). Icon library availability. Framer Motion presence.
3. **Establish the global config** — set typography (display sans, body sans, mono). Set 1 accent color (saturation < 80%). Set neutral palette (Zinc or Slate, never mixed).
4. **Apply bias corrections** — anti-center for DESIGN_VARIANCE > 4. No cards for VISUAL_DENSITY > 7. No serif for dashboards. No purple glows. No Inter as display.
5. **Build component tree** — extract interactive/motion components into isolated Client Components with `'use client'`. Static content stays server-rendered.
6. **Layer creative effects** — apply grain/noise to fixed pseudo-elements only. Add scroll-entry reveals (staggered at 100ms intervals). Spring physics for magnetic micro-interactions.
7. **Guard performance** — only animate `transform` + `opacity`. Gate hover behind `@media (hover: hover)`. Mandatory `prefers-reduced-motion` on every animation.
8. **Run pre-flight checklist** — verify mobile `min-h-[100dvh]`, no emojis, no banned patterns, all states rendered (loading, empty, error, success).

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Importing Framer Motion without checking package.json | Build fails, missing dependency | Verify dependency exists first. Output `npm install framer-motion` if missing. |
| Using Tailwind v4 syntax in v3 projects | Breaking changes in class names | Check package.json Tailwind version. Match syntax to installed version. |
| `h-screen` everywhere | iOS Safari viewport bugs, layout shift | Always `min-h-[100dvh]` for full-screen sections. |
| Animated `width`/`height`/`top`/`left` properties | Layout thrashing, GPU cannot accelerate | Only animate `transform` and `opacity`. Use compositor-only properties. |
| Inter as display font for premium products | Looks generic, no character | Use Geist, Outfit, Cabinet Grotesk, or Satoshi for display headings. |
| Neon glows, purple button shadows, oversaturated accents | AI tell — looks templated | Neutral bases (Zinc/Slate) with a single controlled accent. OKLCH over hex. |
| Grain texture on scrolling containers | Scroll jank, paint storms | Apply grain exclusively to `position: fixed; pointer-events: none` pseudo-elements. |
| `useState` for continuous animation values | Triggers React re-renders 60fps | Use Framer Motion `useMotionValue` + `useTransform` outside React render cycle. |
| Centered hero section when DESIGN_VARIANCE > 4 | Cliché, no personality | Split screen (50/50), left-aligned content with right-aligned asset, or asymmetric whitespace. |
| Missing loading/empty/error states on interactive components | Broken UX when data isn't perfect | Implement all four states: loading (skeleton), empty (guidance), error (inline+actionable), success. |

## Sources

- Emil Kowalski — Design engineering (Sonner, Vaul, Linear, animations.dev)
- Paul Lewis — Compositor-only properties (Google Chrome)
- Ahmad Shadeed — Container Queries and modern CSS
- WCAG 2.2 — Accessibility
- Apple Human Interface Guidelines
- Material Design 3
- OKLCH color space (W3C)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
