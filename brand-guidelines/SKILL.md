---
name: brand-guidelines
description: Generate brand guidelines and visual identity systems. Logo usage, color palette, typography, tone of voice, and application rules.
---

Generate brand guidelines that keep identity consistent across every touchpoint. Based on professional standards from Pentagram, Wolff Olins, IDEO, and brand guideline examples from NASA, Zendesk, and Stripe.

## Core Components

A complete brand system has 9 sections:
1. Brand story: mission, vision, values, personality
2. Logo: primary, secondary, icon, clear space, minimum size, incorrect usage
3. Color: primary, secondary, neutral, semantic palettes with hex/rgb/cmyk
4. Typography: headline, body, mono fonts with sizes, weights, line heights
5. Spacing and layout: grid system, padding, margins, baseline grid
6. Imagery: photography style, illustration style, iconography standards
7. Voice and tone: personality, vocabulary, what to say and what not to say
8. Application: stationery, digital, social media, print, signage, environmental
9. Anti-patterns: what never to do with the brand

## Color Palette Structure

### Primary Palette
The primary palette is 2-4 colors that carry the brand. These appear most frequently.

| Role | Hex | RGB | CMYK | Pantone |
|------|-----|-----|------|---------|
| Primary | #1B365D | 27,54,93 | 71/42/0/64 | PMS 295 |
| Secondary | #00BCD3 | 0,188,211 | 74/0/17/0 | PMS 7707 |
| Accent | #F5BD47 | 245,189,71 | 3/27/83/0 | PMS 142 |

Rules:
- Primary color covers 60%+ of brand touchpoints
- Accent used sparingly (CTAs, highlights, 10% max)
- Never use accent for body text or large backgrounds
- Always define light/dark variants (80%, 60%, 40% tints)

### Secondary Palette
Supporting colors for charts, illustrations, and UI elements. 3-5 colors.

| Role | Hex | Usage |
|------|-----|-------|
| Success | #2ECC71 | Confirmations, positive metrics |
| Warning | #F39C12 | Alerts, pending states |
| Error | #E74C3C | Errors, destructive actions |
| Info | #3498DB | Information, help text |

### Neutral Palette
The grays that do most of the work in UI and layout.

| Name | Hex | Usage |
|------|-----|-------|
| Dark | #080808 | Headings, primary text |
| Mid | #666666 | Body text |
| Light | #E0E0E0 | Borders, dividers |
| Surface | #F5F5F5 | Backgrounds, cards |
| White | #FFFFFF | Page backgrounds |

## Typography Rules

### Typeface Selection
- Headline: 1 display typeface (serif for premium, sans for modern, slab for bold)
- Body: 1 reading typeface (highly legible at small sizes)
- Mono: 1 monospace for code (if needed)

### Hierarchy System

| Element | Typeface | Weight | Size | Line Height | Tracking |
|---------|----------|--------|------|-------------|----------|
| Display H1 | Headline | Bold | clamp(2.5rem, 5vw, 4.5rem) | 1.1 | -0.02em |
| Heading H2 | Headline | Bold | clamp(1.75rem, 3vw, 2.5rem) | 1.2 | -0.01em |
| Heading H3 | Headline | Semibold | clamp(1.25rem, 2vw, 1.75rem) | 1.25 | 0 |
| Body | Body | Regular | 1rem (16px) | 1.6 | 0 |
| Body small | Body | Regular | 0.875rem (14px) | 1.5 | 0 |
| Caption | Body | Regular | 0.75rem (12px) | 1.4 | 0.01em |
| Label | Body | Semibold | 0.75rem (12px) | 1 | 0.05em |
| Code/Mono | Mono | Regular | 0.875rem | 1.5 | 0 |

### Font Pairing Examples

| Style | Headline | Body |
|-------|----------|------|
| Premium editorial | Playfair Display | Source Sans Pro |
| Modern SaaS | Inter | Inter (same family, different weights) |
| Creative agency | Syne | Plus Jakarta Sans |
| Technical product | Plus Jakarta Sans | IBM Plex Sans |
| Luxury | Cormorant Garamond | Proxima Nova |
| Minimal | Sora | DM Sans |

### Readability Rules
- Body text minimum 16px (never smaller on web)
- Line length: 45-75 characters per line
- Line height: 1.5-1.8 for body, 1.1-1.3 for headings
- Color contrast: minimum 4.5:1 for body, 3:1 for large text (WCAG AA)

## Logo Guidelines

### Logo Variations
- Primary logo: full lockup (symbol + wordmark), horizontal orientation
- Secondary logo: stacked or compact version for narrow spaces
- Icon/avatar: symbol only, minimum detail, works at 32x32px
- Wordmark: text only, for contexts where symbol is unnecessary

### Clear Space
- Minimum clear space = height of the letter "H" in the wordmark on all sides
- Nothing — text, graphics, or UI elements — enters this zone
- Use a visual guide showing the exclusion zone with X marks

### Minimum Size
| Format | Primary logo | Icon only |
|--------|-------------|-----------|
| Print | 1.5 inches wide | 0.5 inches |
| Digital | 80px wide | 32px |

### Incorrect Usage (always show examples)
- Do not stretch or squash the logo
- Do not recolor the logo (use approved color versions only)
- Do not rotate the logo
- Do not add effects (drop shadows, gradients, glows)
- Do not place logo on low-contrast backgrounds
- Do not rearrange elements of the lockup
- Do not use older versions of the logo

### Logo Color Variations
| Background | Logo version |
|------------|-------------|
| White/light | Full color primary |
| Dark (over 60% black) | White/reversed |
| Photographic | White with slight drop shadow, or full color with background panel |
| Brand color | White or reversed |
| Grayscale printing | Black or grayscale version |

## Tone of Voice Matrix

| Dimension | Description | Example |
|-----------|-------------|---------|
| Personality | 3-5 adjectives that describe the brand as a person | Confident, warm, precise, curious |
| Vocabulary | Words to use and avoid | Use "we", "you", "let's". Avoid "one", "our users", "individuals" |
| Sentence structure | Short vs long sentences | Short for web/mobile, varied for narrative |
| Formality level | Formal vs casual | Casual for social media, formal for investor communications |
| Humor | When and how to use it | In social and email. Never in legal, support, or crisis comms |
| Emotional tone | How the brand makes people feel | Empowered, understood, capable |

## Imagery & Photography

- Photo style: describe lighting, composition, subjects, color treatment
- Illustration: consistent style (line art, flat, 3D, hand-drawn), consistent stroke width
- Iconography: outline vs filled, rounded vs sharp corners, stroke weight
- Never mix photography styles (stock + authentic = inconsistent)
- Never mix illustration styles

## Sources

- Brand New (UnderConsideration) — brand identity reviews and case studies
- Pentagram — brand identity project standards
- Wolff Olins — brand strategy and identity frameworks
- NASA Graphics Standards Manual (1976, repr. 2015) — gold standard for usage guidelines
- Zendesk Brandland — modern, accessible brand guideline example
- Stripe Brand Guidelines — developer-first brand system
- Bynder "What is a Brand Style Guide?" — definition and components
- Digital Polo "Brand Guidelines: What They Are, What to Include" (2026)
- Rallio "Complete Guide to Brand Guidelines 2026"
- Brandy "Logo Usage Guidelines: Complete Guide to Consistent Branding"
- GTMA "Understanding & Using Brand Guidelines"
