---
name: impeccable
description: "Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers design systems, anti-pattern detection, brand vs product registers, typography, color (OKLCH), spacing, motion, copy, and accessibility. By Paul Bakaus (ex-Google, ex-Disney, ex-Unity). Full version includes 23 sub-commands, CLI detection, Chrome extension, and E2E test suite: npx skills add pbakaus/impeccable"
triggers:
  - "impeccable"
  - "design audit"
  - "UI critique"
  - "redesign"
  - "polish UI"
  - "design review"
  - "anti-patterns"
  - "design quality"
  - "improve design"
negatives:
  - "animations"
  - "components"
  - "landing page"
  - "conversion"
  - "design philosophy" -> use taste
  - "premium design standards" -> use aesthetic-web
license: Apache 2.0 (based on pbakaus/impeccable)
compatibility: opencode
metadata:
  version: "1.0.0"
  author: Paul Bakaus, lite integration by shokunin
  source: https://github.com/pbakaus/impeccable
  full_install: npx skills add pbakaus/impeccable

  workflow: frontend
  audience: designers
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

## Workflow

### Step 1: Set the physical scene

Write one sentence describing who, where, under what light, in what mood. "SRE glancing at incident severity on a 27-inch monitor at 2am in a dim room" forces dark. "Editor reading long-form on an iPad in morning sunlight" forces light. This single sentence determines dark vs light, color intensity, and typographic density. Never skip this step or default to a mode without scene reasoning.

### Step 2: Choose color strategy

Select one of four based on the scene and register:
- **Restrained**: tinted neutrals + one accent <= 10% of any surface. Default for Product (dashboards, admin, tools)
- **Committed**: one saturated color carrying 30-60% of visual weight. Default for Brand (landing pages, marketing)
- **Full palette**: 3-4 deliberate color roles with clear semantic mapping. Brand campaigns, data-heavy interfaces
- **Drenched**: the surface IS the dominant color. Brand hero sections, immersive experiences

### Step 3: Audit against the absolute bans

Check every element against the 6 absolute bans: side-stripe borders, gradient text, default glassmorphism, hero-metric template, identical card grids, modal-as-first-thought. If any ban is violated, restructure the element — do not tweak. Bans require different structure, not subdued execution.

### Step 4: Run the AI Slop Test

**First-order**: Can someone guess the visual theme from the category alone? "Observability → dark blue dashboard", "Healthcare → white + teal cards", "Crypto → neon-on-black" — these are training-data reflexes. If yes, rework from a different visual lane.

**Second-order**: Can someone guess the aesthetic from category plus anti-references? "AI workflow that is NOT SaaS-cream → editorial-typographic". Still a reflex. Rework again. A genuine design is harder to predict from metadata alone.

### Step 5: Apply design tokens and refine copy

1. Replace all hex/rgb colors with OKLCH design tokens. Tint every neutral. Reduce chroma as lightness approaches 0 or 100
2. Copy audit: remove every em dash (`—`). Replace with commas, colons, periods, or parentheses
3. Remove AI filler: "elevate", "seamless", "unleash", "delve", "transformative"
4. Cap body line length at 65-75ch. Set line-height to 1.6

### Step 6: Polish and verify

1. Motion check: compositor-only properties, durations < 300ms, no bounce, exit faster than enter
2. Body line length 65-75ch, line-height 1.6 on all text blocks
3. Every word earns its place — no restated headings, no filler
4. Run the Pre-Flight Checklist before delivery

## Error Handling

| Cause | Fix |
|-------|-----|
| OKLCH colors render as black/white in Safari < 15.4 or Firefox < 113 | Always provide hex fallback before each OKLCH value: `--color-ink: #1a1a1a; --color-ink: oklch(10% 0 0)`. Check caniuse for OKLCH support |
| Selected color strategy produces low contrast on key text surfaces | Test every text+background pair against WCAG AA (4.5:1 body, 3:1 large text). Shift lightness values until passing. Don't compromise on contrast for aesthetics |
| AI Slop Test keeps failing — design still reads as generic despite rework | Change the visual lane entirely. "SaaS modern" failing? Try "editorial magazine", "brutalist terminal", or "Swiss typography". The genre shift forces genuinely fresh decisions |
| Physical scene description is too vague to produce concrete design decisions | Add specifics: time of day, screen size, ambient light level, emotional state, session duration. "Day trader watching real-time data at 10am on dual monitors" is actionable |
| Dark mode palette shows an unintended blue cast instead of true dark | Add small chroma to the achromatic dark base: `oklch(8% 0.02 260)` instead of `oklch(8% 0 0)`. Pure achromatic dark reads as lifeless and flat |
| An absolute ban collides with a legitimate design requirement (e.g., client requires a gradient hero) | If a ban must be broken, mitigate with subtle execution: low gradient opacity (0.1-0.2), solid foreground text, no text clipping. Document the exception |
| Copy still reads as AI-generated despite em dash and filler word removal | Check sentence rhythm: AI defaults to uniform sentence length. Vary: short punchy sentences. Followed by longer, more complex ones that breathe. Fragments when needed |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Side-stripe borders (`border-left` > 1px as colored accent on cards/sidebars) | The #1 visual signature of AI-generated dashboards. Present in ~80% of LLM dashboard output. Instant tell | Use background tint shifts, hairline separators, or spacing hierarchy. If accent is essential, use top border or a small badge/glyph |
| Gradient text via `background-clip: text` combined with gradient fill | Decorative, never semantic. Fails WCAG contrast at gradient midpoint. Always reads as "designed by someone who just discovered CSS" | Use solid OKLCH colors with weight contrast and scale for hierarchy. Typography carries meaning — gradient undermines it |
| Glassmorphism (`backdrop-filter: blur()`) as default card/surface treatment | Poor readability. Low contrast. 2022 trend that now reads as dated. Adds visual noise without purpose | Use only when what's behind the glass IS the product (map underlay, data visualization). Otherwise: solid surfaces with slight tint shifts |
| Hero-metric template: big number + small ALL-CAPS label + gradient background | Cookie-cutter SaaS hero. Every AI output defaults to this pattern regardless of product | Lead with a claim, a story, or a distinctive visual. Metrics can go in a dedicated proof section with context, not the hero |
| Identical card grid: icon + heading + paragraph, repeated 3-6 times with equal sizing | Zero visual hierarchy. All content reads as equally important. User scans without engaging any card | Vary card sizes (2fr 1fr asymmetric). Break grid with full-width sections. Use lists or tables where cards aren't needed |
| Center-aligned hero, center-aligned CTA, center-aligned everything | Symmetry = safety. Safety = generic. No visual tension, no directional energy, no memorable composition | Left-align text. Place visuals right. Create deliberate asymmetry. The eye should move, not land in the center and stop |
| Em dashes (`—`) in UI copy and headings | The #1 LLM typographic tic. Used as universal separator when commas, colons, periods, or parentheses would be crisper | Ban em dashes. Use commas for lists, colons for label:value, periods to separate thoughts, parentheses for asides. Em dash only for genuine mid-sentence interruption |
| Defaulting to dark mode because "dark looks better" without physical scene reasoning | Dark mode has lower contrast in bright environments and causes eye strain for long-form reading. It's not universally superior | Write the physical scene. Let the scene dictate the mode. "Late night" = dark. "Morning sunlight" = light. Mode follows context, not preference |
| Modal dialogs as the first interaction pattern for any secondary action | Modal interrupts user flow, loses context, breaks mobile UX. Often used because it's the easiest pattern to implement | Exhaust inline alternatives first: expanding sections, slide-out panels, inline editing, progressive disclosure. Modal only when context loss is intentional |
| Brand colors applied to functional UI elements (buttons, inputs, toggles) at full saturation | Saturated colors on interactive elements vibrate against neutral backgrounds. Reduces usability and reads as "theme applied mechanically" | Desaturate interactive UI colors 15-25% from brand primaries. Reserve full brand saturation for decorative and brand-identity elements only |
| Pure black (#000) or pure white (#fff) anywhere in the palette | #000 doesn't exist in nature or on any physical display surface. #fff creates harsh contrast that fatigues. Both read as "default CSS" | Tint every neutral: add 0.005-0.01 chroma toward brand hue. Darkest color >= oklch(8% 0 0). Lightest <= oklch(97% 0 0) |
| Inter as a display/heading font | Inter is the default AI body font. Using it for headlines signals "didn't choose a font". Zero typographic identity | Pair a display font (serif or bold sans) with Inter as body only. Display font does the heavy lifting; Inter stays in its lane |
| Long-form body text with line-height below 1.5 | Crowded, hard to track across line wraps. Readers lose their place. Especially punishing on mobile where lines wrap more | Minimum body line-height: 1.6. For dense data tables: 1.4. For headings: 1.1-1.2. Longer lines need more line-height |
| Using the same font weight for all heading levels | Flat hierarchy. Reader can't scan. Headings and body text run together visually | Minimum 1.25x weight contrast between heading levels. h1: 700-800, h2: 600-700, h3: 500-600. Scale + weight = hierarchy |

## Typography Pairing Quick Reference

| Direction | Display | Body | Best for |
|-----------|---------|------|----------|
| Editorial luxury | Canela / DM Serif Display | DM Sans | Brand landing, long-form, portfolios |
| Bold tech | Cabinet Grotesk / Space Grotesk | Geist | Product pages, developer tools |
| Swiss modern | Neue Haas Grotesk | Inter | Dashboards, admin, data-heavy |
| Classic warm | Playfair Display / Cormorant Garamond | Charter / Georgia | Editorial, publishing, luxury |
| Punchy condensed | Bebas Neue / Anton | Geist / DM Sans | Hero headlines, campaign pages |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
