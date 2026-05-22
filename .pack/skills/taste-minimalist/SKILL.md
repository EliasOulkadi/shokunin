---
name: taste-minimalist
description: "Clean editorial-style interfaces. Warm monochrome palette, typographic contrast, flat bento grids, muted pastels. No gradients, no heavy shadows. Based on taste-skill by Leon Lin & blueemi, improved by shokunin."
triggers:
  - "minimalist design"
  - "clean interface"
  - "editorial design"
  - "warm monochrome"
  - "bento grid"
  - "muted palette"
  - "flat design"
  - "document-style"
  - "typographic layout"
  - "ultra-minimalist"
negatives:
  - "luxury design"
  - "glassmorphism"
  - "agency design"
  - "heavy shadows"
  - "gradients"
  - "3D design"
  - "base design framework" -> use taste
license: MIT
compatibility: opencode
metadata:
  version: "2.0.0"
  author: Leon Lin, blueemi, improved by shokunin

  workflow: frontend
  audience: designers
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

## Error Handling

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

---

## Workflow

1. **Establish canvas** — set `--canvas: #F7F6F3`, constrain content to `max-w-4xl`/`max-w-5xl`, macro-whitespace `py-24` to `py-32` between sections.
2. **Apply typographic hierarchy** — serif headline with tight tracking/line-height, sans body at `text-base text-[#787774] leading-relaxed`, monospace for code.
3. **Layer the monochrome system** — every card, divider, and UI surface gets `1px solid #EAEAEA`. Off-black text `#111111`. White or near-white surfaces.
4. **Place muted pastel accents sparingly** — only for badges, tags, status indicators. Pale red, blue, green, or yellow backgrounds with matching desaturated text.
5. **Add subtle motion** — scroll-entry reveal on content blocks (600ms cubic-bezier(0.16, 1, 0.3, 1)), hover scale(0.98) on buttons, staggered child reveals at 80ms intervals.
6. **Collapse for mobile** — single-column `w-full px-4` below `768px`. Force `min-h-[100dvh]` for full-screen sections.
7. **Verify editorial feel** — no gradients, no heavy shadows, no `rounded-full` on large elements, no centering, no emojis, no AI clichés.

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Using Inter, Roboto, or Open Sans | Default AI font choices, no character | Use SF Pro Display, Geist Sans, or Switzer |
| Centered hero sections with stacked text | Looks like every template | Left-align hero text. Use asymmetric layout. |
| `rounded-full` on cards or large containers | Soft, generic pill aesthetic | Max `12px` radius. Many elements at `4px`–`8px`. |
| Tailwind `shadow-md`/`shadow-lg` | Heavy, muddy, cheap-looking | No box-shadow on cards. Ultra-subtle `0 2px 8px rgba(0,0,0,0.04)` on hover only. |
| Full-saturation accent colors | Disrupts the monochrome harmony | Pastels only: saturation below 40%. Use the 4 preset pale palettes. |
| Gradient backgrounds on sections | Breaks the flat, editorial aesthetic | Solid `#F7F6F3` or `#FBFBFA` canvas. Subtle grain overlay at opacity 0.03–0.04. |
| "John Doe", "Acme Corp", placeholder names | Instantly signals template/AI-generated | Use realistic, contextual names and data. |
| Stock photography with high saturation | Clashes with monochrome system | Desaturated, warm-toned images. Subtle grain overlay. Or use picsum.photos. |

## Sources

- Apple Human Interface Guidelines — Typography and Color (developer.apple.com/design)
- Linear — "Linear Method: Designing in the Open" (linear.app/method)
- iA Writer — "The Philosophy of iA Writer" (ia.net/writer)
- Basecamp — "Shape Up: Stop Running in Circles" (basecamp.com/shapeup)
- Notion — Design System (notion.so/design)
- Erik Spiekermann — "Stop Stealing Sheep & Find Out How Type Works" (Adobe Press)
- Robert Bringhurst — "The Elements of Typographic Style" (Hartley & Marks)
- Josef Müller-Brockmann — "Grid Systems in Graphic Design" (Niggli Verlag)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
