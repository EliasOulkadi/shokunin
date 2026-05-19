---
name: brand-design
description: Generate brand guidelines, design systems with design tokens (W3C format), creative direction (SCAMPER, Design Thinking, TRIZ), and design briefs with scope and success criteria.
triggers:
  - "brand guidelines"
  - "style guide"
  - "design brief"
  - "creative brief"
  - "campaign concept"
  - "brand identity"
  - "visual identity"
  - "design system"
  - "creative direction"
  - "brand strategy"
negatives:
  - "UI component design patterns"  # use ui-ux-pro-max
  - "landing page layout"  # use landing-craft
  - "responsive design"  # use responsive-engine
  - "icon set creation"  # use component-forge
  - "color palette generation"  # use ui-ux-pro-max
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "3.0.0"

---
# Brand Design Skill v3.0

Brand identity, design systems, creative direction, and project briefs.

---

## Workflow: Brand / Design System Creation

Follow this numbered process. Do not skip steps.

| Step | Action | Output |
|------|--------|--------|
| 1 | Gather inputs: brand story, competitors, audience research, technical constraints | Brief document |
| 2 | Define brand strategy: positioning, personality (3-5 adjectives), tone of voice | Brand strategy doc |
| 3 | Build color system: primary, neutral, semantic palettes + WCAG AA checks | Color tokens + palette |
| 4 | Select typography: headline/body pairing, scale, line-height, responsive sizing | Typography tokens |
| 5 | Define spacing, radius, shadow, motion tokens (W3C format) | Design tokens JSON |
| 6 | Create logo variations + usage guidelines | Logo guidelines |
| 7 | Apply to 3+ touchpoints: web, print, social, or environmental | Application mockups |
| 8 | Run design system audit (see checklist below) | Audit report |
| 9 | Document anti-patterns and error states | Error + anti-pattern docs |
| 10 | Stakeholder review + alignment sign-off | Approved design system v1.0 |

---

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Color contrast fails WCAG AA | Luminance ratio < 4.5:1 for text | Darken or lighten until ratio passes. Use `contrastRatio` in tokens. |
| Token mismatch across platforms | Figma tokens != code tokens | Single source of truth: W3C JSON. Export from design tool. |
| Typography scale gaps | Missing intermediate sizes | Build scale with modular scale (1.25 or 1.333 ratio). |
| Logo illegible at min size | Too much detail in icon | Use simplified lockup or separate wordmark + icon variants. |
| Design brief scope creep | Unclear out-of-scope list | Explicit "what's NOT included" section. Reference during reviews. |
| Stakeholder disagreement | No clear decision authority | Identify single approver in brief. Escalate to DRI. |
| Campaign fails originality axis | Cliché or derivative idea | Force 5+ directions. Run through SCAMPER/TRIZ. Reference culture, not competitors. |

---

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

---

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

---

## Production Checklist

Before shipping any design system or brand guidelines:

| Check | Criteria | Owner |
|-------|----------|-------|
| Color parity | Hex values match exactly between Figma + code + docs | Design + Dev |
| Token export | W3C JSON exported and imported into codebase | Design |
| Font licensing | All typefaces have valid web + print licenses | Prod Mgr |
| Logo rasterization | Vector + PNG + favicon exported at all required sizes | Design |
| Accessibility audit | Automated + manual passes (axe, color contrast, keyboard nav) | QA |
| Dark mode | All colors have dark mode variants, no hardcoded values | Design |
| Responsive breakpoints | Layout tested at mobile, tablet, desktop | Dev |
| Motion reduced | `prefers-reduced-motion` respected for all animations | Dev |
| Component states | All interactive elements defined: default, hover, focus, active, error, disabled | Design |
| Figma dev handoff | Components published with props, variants, and descriptions | Design |

---

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

---

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

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| No single-minded proposition | Message dilutes, audience confused | Force one idea. Kill the rest. |
| Problem stated as solution | Brief prescribes fix instead of framing the real issue | Describe the problem, not the fix |
| Vague success criteria | Cannot measure success or failure | Define specific, testable criteria with targets |
| No constraints given | Design that looks great but can't be built or shipped | Add budget, tech, timeline constraints upfront |
| Too many stakeholders | Design by committee produces mediocrity | Identify single DRI per decision type |
| Skipping audience insight | Design solves wrong problem | Research first. Find a non-obvious truth. |
| Chasing trends | Looks dated in 6 months, no differentiation | Reference culture, not competitors |
| Falling in love with first idea | Biased evaluation, better solutions missed | Force 5+ directions before selecting |
| Designing for yourself | End-user needs subordinated to designer preferences | User test with real audience segments |
| No error states defined | UI breaks silently, bad UX | Define error, empty, loading states for every component |

---

## Design Token Architecture

```json
{
  "color": {
    "primary": { "value": "#1B365D", "type": "color" },
    "primary-light": { "value": "#2D5A8A", "type": "color" }
  },
  "spacing": {
    "xs": { "value": "4px", "type": "spacing" },
    "sm": { "value": "8px" }, "md": { "value": "16px" }, "lg": { "value": "24px" }
  },
  "typography": {
    "heading": { "value": { "fontFamily": "Charter", "fontWeight": 500, "fontSize": "clamp(32px,5vw,56px)" } }
  }
}
```

Export as W3C Design Token format for Figma Tokens plugin, Style Dictionary, or token-transformer.

## Figma-to-Code Handoff
1. Dev Mode: inspect spacing (8px grid), colors (variables), typography (named styles)
2. Export assets: SVG for icons, PNG @2x for raster
3. Component mapping: `FigmaComponent → ReactComponent` documented before build
4. Responsive: Figma frames at 375px (mobile), 768px (tablet), 1440px (desktop)

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

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
