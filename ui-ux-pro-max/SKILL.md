---
name: ui-ux-pro-max
description: Query a searchable database of UI patterns, color palettes, font pairings, UX guidelines, and chart types. Use for specific design decisions — color palette recommendations, font pairings, UI style names, and implementation-specific UX patterns by stack. Do NOT use for general visual design critique, responsive layout (use responsive-engine), or animation design (use motion-craft).
license: MIT
compatibility: opencode
metadata:
  workflow: design
  audience: developers
  version: "2.0"
---

# UI/UX Pro Max

Comprehensive design reference database for web and mobile. Searchable via Python CLI.

## Prerequisites

```bash
python3 --version || python --version
```

## Workflow

### Step 1: Analyze requirements

Extract from user request:
- **Product type**: SaaS, e-commerce, portfolio, dashboard, landing, service
- **Style keywords**: minimal, playful, professional, elegant, dark mode, brutalism
- **Industry**: healthcare, fintech, gaming, education, beauty
- **Stack**: React, Vue, Next.js, or default to `html-tailwind`

### Step 2: Design system (new project)

```bash
python3 skills/ui-ux-pro-max/scripts/search.py \
  "<product_type> <industry> <keywords>" \
  --design-system \
  [-p "Project Name"]
```

Returns: pattern, style, colors, typography, effects, anti-patterns.

### Step 3: Targeted searches

```bash
python3 skills/ui-ux-pro-max/scripts/search.py \
  "<keyword>" \
  --domain <domain> \
  [-n <max_results>]
```

| Domain | Use for |
|--------|---------|
| `style` | UI styles, effects (glassmorphism, minimalism, brutalism) |
| `typography` | Font pairings, Google Fonts |
| `color` | Palettes by product type |
| `landing` | Page structure, CTA strategies |
| `chart` | Chart types, library recommendations |
| `ux` | Best practices, anti-patterns |
| `react` | React/Next.js performance patterns |

### Step 4: Stack implementation

```bash
python3 skills/ui-ux-pro-max/scripts/search.py \
  "<keyword>" \
  --stack <stack>
```

Stacks: `html-tailwind`, `react`, `nextjs`, `vue`, `svelte`, `swiftui`, `react-native`, `flutter`, `shadcn`, `jetpack-compose`

## Examples

```bash
# Full design system
python3 skills/search.py "fintech dashboard analytics" --design-system -p "FinDash"

# Search style options
python3 skills/search.py "glassmorphism" --domain style

# Stack-specific
python3 skills/search.py "form validation" --stack html-tailwind
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `python3` not found | Install Python 3.12+ |
| `ModuleNotFoundError` | Run `pip install -r requirements.txt` from skill dir |
| Script not found | Verify path: `ls scripts/search.py` |
| No results | Try broader keywords, check --domain flag |

## Pre-Delivery Checklist

- [ ] No emojis as icons (SVG only: Heroicons, Lucide)
- [ ] Hover states don't cause layout shift
- [ ] `cursor-pointer` on all clickable elements
- [ ] Transitions 150-300ms
- [ ] Light mode text contrast 4.5:1
- [ ] Responsive at 375px, 768px, 1024px, 1440px
- [ ] No horizontal scroll on mobile
- [ ] Alt text on all images
- [ ] `prefers-reduced-motion` respected

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| Relying solely on UI data without user context | Patterns without context mislead | Combine DB results with user's specific audience |
| Over-engineering the first iteration | Blocks shipping | Start with one pattern, iterate |
| Ignoring accessibility recommendations | Excludes users | Always check contrast, touch targets, reduced motion |
| Using trends over proven patterns | Trend may not have conversion data | Prefer patterns with A/B test results |
| Not considering platform conventions | Feels foreign on the target platform | Check platform-specific guidelines (HIG, Material) |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Search returns no relevant results | Query too specific or database empty | Broaden search terms, try synonyms |
| Color palette not found | Filter combination too restrictive | Relax filters, check hex format |
| Font pairing algorithm slow | Large font database | Use local font cache, limit to system fonts |
| Pattern description unclear | Terminology mismatch | Use common UX terms, not academic jargon |
| WCAG contrast calculation wrong | Updated WCAG 2.2 thresholds | Reference latest WCAG contrast guidelines |

## Sources

- Laws of UX (lawsofux.com)
