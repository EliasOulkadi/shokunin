---
name: design
description: Generate brand guidelines, design systems with design tokens (W3C format), creative direction (SCAMPER, Design Thinking, TRIZ), design briefs with scope and success criteria, and design system audit checklist. Use when user asks to create brand guidelines, style guide, design brief, creative brief, campaign concept, brand identity, visual identity, or design system. Do NOT use for UI component design patterns (use ui-ux-pro-max), landing page layout (use landing-craft), or responsive design (use responsive-engine).
license: MIT
compatibility: opencode
metadata:
  workflow: design
  audience: designers
  version: "2.0"
---

# Design

Brand identity, design systems, creative direction, and project briefs.

## Brand Guidelines

A complete brand system has 9 sections: brand story, logo, color, typography, spacing, imagery, voice, application, anti-patterns.

### Color Palette

**Primary** (2-4 colors, 60%+ of touchpoints):
| Role | Hex | Usage |
|------|-----|-------|
| Primary | #1B365D | Headlines, primary buttons |
| Accent | #F5BD47 | CTAs, highlights |

**Neutral** (grays for UI):
| Name | Hex | Usage |
|------|-----|-------|
| Dark | #080808 | Headings |
| Mid | #666666 | Body text |
| Light | #E0E0E0 | Borders |
| Surface | #F5F5F5 | Backgrounds |

**Semantic**: Success #2ECC71, Warning #F39C12, Error #E74C3C, Info #3498DB

### Design Tokens (W3C Format)

```json
{
  "color": {
    "primary": { "$value": "#1B365D", "$type": "color" },
    "accent": { "$value": "#F5BD47", "$type": "color" },
    "surface": { "$value": "#F5F5F5", "$type": "color" }
  },
  "spacing": {
    "xs": { "$value": "4px", "$type": "dimension" },
    "sm": { "$value": "8px", "$type": "dimension" },
    "md": { "$value": "16px", "$type": "dimension" },
    "lg": { "$value": "32px", "$type": "dimension" }
  },
  "borderRadius": {
    "sm": { "$value": "4px", "$type": "dimension" },
    "md": { "$value": "8px", "$type": "dimension" },
    "full": { "$value": "9999px", "$type": "dimension" }
  }
}
```

### Typography

| Element | Weight | Size | Line Height |
|---------|--------|------|-------------|
| Display H1 | Bold | clamp(2.5rem,5vw,4.5rem) | 1.1 |
| H2 | Bold | clamp(1.75rem,3vw,2.5rem) | 1.2 |
| H3 | Semibold | clamp(1.25rem,2vw,1.75rem) | 1.25 |
| Body | Regular | 1rem (16px) | 1.6 |
| Caption | Regular | 0.75rem | 1.4 |

Body text minimum 16px. Line length 45-75 chars. Contrast min 4.5:1 (WCAG AA).

**Font Pairing Examples:**
| Style | Headline | Body |
|-------|----------|------|
| Premium editorial | Playfair Display | Source Sans Pro |
| Modern SaaS | Inter | Inter |
| Creative agency | Syne | Plus Jakarta Sans |
| Luxury | Cormorant Garamond | Proxima Nova |

### Logo Guidelines
- Variations: primary, secondary, icon (32x32), wordmark
- Clear space = height of "H" on all sides
- Min size: 80px digital, 1.5in print
- Never stretch, recolor, rotate, add effects, or use on low-contrast backgrounds

### Tone of Voice
| Dimension | Rule |
|-----------|------|
| Personality | 3-5 adjectives (e.g. confident, warm, precise) |
| Vocabulary | Use "we/you". Avoid "one/our users" |
| Formality | Casual for social, formal for investor comms |
| Humor | In social/email. Never in legal, support, or crisis |

## Design System Audit Checklist

- [ ] All colors have hex/RGB/HSL values and usage guidelines
- [ ] Typography scale covers 6+ sizes with line-height
- [ ] Spacing scale (4/8/16/24/32/48/64px)
- [ ] Component library matches design tokens
- [ ] Dark mode variants defined
- [ ] Accessibility: all color combos pass WCAG AA 4.5:1
- [ ] Icons: consistent stroke width, corner radius, size grid
- [ ] Shadow/elevation system defined
- [ ] Motion: duration, easing, reduced-motion alternative
- [ ] Form elements: all states (default, hover, focus, error, disabled)
- [ ] Breakpoints match design tool
- [ ] Figma component properties mapped to code props

## Creative Direction

### Ideation Methodologies

| Methodology | Best for |
|-------------|----------|
| SCAMPER | Product innovation, rebranding |
| Design Thinking | Human-centered problem solving |
| TRIZ (40 principles) | Technical problem solving |
| Bisociation | Connecting two unrelated frameworks |
| Synectics (analogies) | Creative campaigns |
| SIT | Innovation with constraints |
| Blue Ocean Strategy | Market differentiation |

### Campaign Architecture
| Level | Timeframe | What |
|-------|-----------|------|
| Brand platform | 3-5 years | Positioning |
| Campaign theme | Annual | What we say this year |
| Creative executions | Per asset | How we bring it to life |
| Tactical adaptations | Per channel | How it works in this medium |

### Campaign Idea Evaluation (5-axis)
| Axis | Passing | Fail |
|------|---------|------|
| Originality (1-10) | 7+ | Below 5 |
| Relevance (1-10) | 8+ | Below 6 |
| Impact (1-10) | 7+ | Below 5 |
| Feasibility (1-10) | 6+ | Below 4 |
| Durability (1-10) | 6+ | Below 4 |

Score min 3 axes at 7+ to proceed.

## Design Brief

### Structure
1. **Project overview**: what and why (2-3 sentences)
2. **Problem statement**: "[User] cannot [goal] because [barrier]"
3. **Objectives**: SMART
4. **Target audience**: demographics, behaviors, goals, pain points, anti-audience
5. **Scope**: what's in and explicitly out
6. **Deliverables**: format, quantity, specs, revision rounds
7. **Timeline**: phases, milestones, review points, buffer
8. **Success criteria**: testable, with metrics and targets
9. **Constraints**: budget, technology, brand, legal, timeline

### Stakeholder Alignment Questions
1. Who has final approval?
2. What's the single most important metric?
3. What can we deprioritize if scope shrinks?
4. Who are we NOT designing for?
5. What are the non-negotiables (legal, brand, technical)?

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| No single-minded proposition | Force one idea. Kill the rest. |
| Problem stated as solution | Describe the problem, not the fix |
| Vague success criteria | Define specific, testable criteria |
| No constraints given | Design that can't be built |
| Too many stakeholders | Design by committee |
| Skipping audience insight | Research first, find non-obvious truth |
| Chasing trends | Reference culture, not competitors |
| Falling in love with first idea | Force 5+ directions before selecting |

## Sources

- Pentagram — brand identity project standards
- NASA Graphics Standards Manual
- Stripe Brand Guidelines
- W3C Design Tokens Format
- IDEO design thinking methodology
- Ogilvy "On Advertising"
- Design Council UK "Double Diamond"
- NN Group "How to Write a Design Brief"
- Figma Design Tokens plugin
