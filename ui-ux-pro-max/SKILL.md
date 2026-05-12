---
name: ui-ux-pro-max
description: Query a searchable database of 67 UI patterns, 96 color palettes, 57 font pairings, 99 UX guidelines, and 25 chart types across 13 tech stacks. Use for specific design decisions when aesthetic-web's general guidance is not enough, or when user asks for color palette recommendations, font pairings, UI style names (glassmorphism, brutalism, neumorphism), or implementation-specific UX patterns for a given stack. Triggers on "find a color palette for", "what font goes with", "UI style for [product type]", "chart type for [data]", "UX best practices for [stack]", "design system for [product]". Do NOT use for general visual design critique, responsive layout advice, or accessibility basics — aesthetic-web covers those better. Requires Python.
license: MIT
compatibility: opencode
metadata:
  workflow: design
  audience: developers
---

Comprehensive design reference database for web and mobile. Searchable via Python CLI.

## Prerequisites

Check Python:
```bash
python3 --version || python --version
```

Install if missing:
```bash
# macOS
brew install python3
# Ubuntu/Debian
sudo apt update && sudo apt install python3
# Windows
winget install Python.Python.3.12
```

## Workflow

### Step 1: Analyze Requirements

Extract from user request:
- **Product type**: SaaS, e-commerce, portfolio, dashboard, landing page, service
- **Style keywords**: minimal, playful, professional, elegant, dark mode, brutalism
- **Industry**: healthcare, fintech, gaming, education, beauty
- **Stack**: React, Vue, Next.js, or default to `html-tailwind`

### Step 2: Design System (if project is new)

```bash
python3 skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system [-p "Project Name"]
```

Returns: pattern, style, colors, typography, effects, anti-patterns.

Persist for multi-page projects:
```bash
python3 skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Project Name"
```

### Step 3: Targeted Searches (for specific questions)

```bash
python3 skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

| Domain | Use For | Examples |
|--------|---------|----------|
| `style` | UI styles, effects, colors | glassmorphism, minimalism, brutalism |
| `typography` | Font pairings, Google Fonts | elegant, playful, professional |
| `color` | Palettes by product type | SaaS, ecommerce, healthcare, fintech |
| `landing` | Page structure, CTA strategies | hero, testimonial, pricing, social-proof |
| `chart` | Chart types, library recommendations | trend, comparison, funnel, timeline |
| `ux` | Best practices, anti-patterns | animation, z-index, loading, accessibility |
| `react` | React/Next.js performance | waterfall, suspense, memo, rerender, cache |

### Step 4: Stack Implementation

```bash
python3 skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack <stack>
```

Available: `html-tailwind`, `react`, `nextjs`, `vue`, `svelte`, `swiftui`, `react-native`, `flutter`, `shadcn`, `jetpack-compose`

## Examples

```
# Find a design system for a fintech dashboard
python3 skills/ui-ux-pro-max/scripts/search.py "fintech dashboard analytics" --design-system -p "FinDash"

# Search for glassmorphism style options
python3 skills/ui-ux-pro-max/scripts/search.py "glassmorphism" --domain style

# Get Tailwind-specific form patterns
python3 skills/ui-ux-pro-max/scripts/search.py "form validation" --stack html-tailwind
```

## Output Formats

```bash
# ASCII box (default - best for terminal)
python3 skills/ui-ux-pro-max/scripts/search.py "fintech" --design-system

# Markdown (best for documentation)
python3 skills/ui-ux-pro-max/scripts/search.py "fintech" --design-system -f markdown
```

## Tips

1. Be specific with keywords: "healthcare SaaS dashboard" > "app"
2. Search multiple times with different keywords
3. Combine domains: style + typography + color = complete system
4. Always check UX for interaction-related issues
5. Use `--stack` for implementation-specific guidance

## Pre-Delivery Checklist

- [ ] No emojis used as icons (SVG only: Heroicons, Lucide)
- [ ] Hover states don't cause layout shift
- [ ] `cursor-pointer` on all clickable elements
- [ ] Transitions 150-300ms
- [ ] Light mode text contrast 4.5:1 minimum
- [ ] Responsive at 375px, 768px, 1024px, 1440px
- [ ] No horizontal scroll on mobile
- [ ] Alt text on all images
- [ ] `prefers-reduced-motion` respected
