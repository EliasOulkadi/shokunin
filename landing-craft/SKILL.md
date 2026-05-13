---
name: landing-craft
description: Build conversion-optimized landing pages with CRO frameworks (Conversion Research, LIFT Model), scroll effects, A/B testing, personalization, form optimization, and Core Web Vitals (INP, LCP, CLS). Use when user asks to create a landing page, sales page, lead generation page, or improve conversion rates. Do NOT use for full product design (use component-forge), animation-specific (use motion-craft), or brand identity (use design).
license: MIT
compatibility: opencode
metadata:
  workflow: marketing
  audience: developers
  version: "2.0"
---

# Landing Craft

Landing pages designed for conversion. Based on data from Unbounce, GoodUI, Refactoring UI, and CXL Institute.

## The Structure

```
Hero: headline + sub + CTA (above the fold)
Social proof: logos, metrics, testimonials
Problem: framed for empathy, names the pain
Solution: 3 steps max, benefit-focused
Features: 3-6 items, each with one clear benefit
Testimonials: real people, specific results
Pricing: 3 tiers, middle is the offer
FAQ: answers top 5 objections
Final CTA: same ask, different context, near scroll bottom
```

Every section answers: what does the visitor need to hear RIGHT NOW to move to the next section?

## Design Palette

| Element | Specification |
|---------|---------------|
| Background | Dark (#080808) or cream (#f5f2ec). Never #f5f5f5 |
| Headline | Editorial serif. `clamp(2.5rem, 5vw, 4.5rem)` |
| Body | Clean sans. Min 16px. Line height 1.6 |
| Spacing | 8px base. Section: `clamp(4rem, 8vw, 8rem)` |
| Texture | Grain overlay: opacity 0.03-0.06 |
| Icons | Lucide or Heroicons. No emoji icons |
| Motion | Subtle scroll-triggered. Parallax or 3D on hero |

## Hero Rules

1. **Value in 3 seconds**: headline must communicate core benefit
2. **CTA visible without scroll**: primary button above the fold
3. **One CTA**: one primary action. Secondary links are text only.
4. **Headline under 10 words**: longer headlines lose 50%+ of readers
5. **Supporting visual**: image, illustration, or demo video

## CRO Methodology

Use the LIFT Model (by WiderFunnel) to evaluate every element:

| Factor | Question |
|--------|----------|
| Value proposition | Does this clearly communicate the benefit? |
| Relevance | Does this match the visitor's intent? |
| Clarity | Is the message immediately understandable? |
| Distraction | What can we remove to focus attention? |
| Anxiety | What reassures the visitor? (guarantees, trust signals) |
| Urgency | Why should they act now? |

### High-impact test elements (in order)

1. **Headline**: single highest-impact element
2. **CTA button text and color**: easy to change, measurable impact
3. **Hero image/video**: different visuals change perception
4. **Social proof placement**: top vs mid page
5. **Pricing structure**: tiers, placement, annual/monthly toggle

Test one element at a time. Statistical significance at 95% confidence. Min 1,000 visitors per variant.

## Social Proof

Place near the top (within first 2 sections). Types by effectiveness:

1. **Logos of recognizable companies**
2. **Specific user metrics**: "Join 10,000+ paying customers"
3. **Relevant testimonial**: quote with name, title, photo, result
4. **Award/certification badge**: only if recognizable

Rules:
- Logo cloud: 3-12 logos, grayscale with hover color
- Never use logos without permission
- Testimonials must have real attribution
- Metrics need context

## Problem Section (PAS)

- **Problem**: name the exact pain. "Your landing page converts at 0.8%"
- **Agitate**: explore consequences of NOT solving it
- **Solution**: present your approach as the answer

## Features Grid

3-6 features. Each one gets:
- Icon (meaningful, not decorative)
- Benefit-led headline: "Ship 3x faster" not "Automated CI/CD"
- 1-2 sentence explanation

Layout: 3 columns desktop, 2 tablet, 1 mobile.

## Testimonials

| Element | Rule |
|---------|------|
| Photo | Required. Real person. |
| Attribution | Full real name, title, company |
| Quote | Specific, results-oriented |
| Length | 1-3 sentences |
| Placement | Near relevant claim |

## Pricing

3 tiers. Middle is your real offer.

| Position | Role | Strategy |
|----------|------|----------|
| Left (Starter) | Anchor low | Makes middle look reasonable |
| Center (Pro) | The offer | Best value, highlighted, "Most popular" |
| Right (Enterprise) | Anchor high | Makes middle look affordable |

Rules:
- Annual/monthly toggle (annual = 20% discount)
- Every tier lists features explicitly
- Include money-back guarantee near pricing

## Form Optimization

| Element | Best practice |
|---------|---------------|
| Fields | Minimum viable (email only for lead gen) |
| Validation | Inline, real-time, specific error messages |
| Autofill | Enable autocomplete attributes |
| Submit | Button says what happens ("Get my free guide") |
| Error recovery | Preserve entered values, highlight fields |
| Trust | Privacy note: "No spam. Unsubscribe anytime." |

## Performance (Core Web Vitals 2026)

| Metric | Target |
|--------|--------|
| INP | < 200ms (replaces FID) |
| LCP | < 2.5s |
| CLS | < 0.1 |
| TBT | < 200ms |
| Lighthouse | > 90 |

Achievement checklist:
- No render-blocking resources above fold
- Images lazy-loaded with explicit width/height
- Minimal JS
- CSS critical path inlined, async for rest
- Fonts self-hosted or preloaded with `font-display: swap`
- Third-party scripts loaded with `defer` or `async`

## Mobile Optimization

| Element | Mobile rule |
|---------|-------------|
| CTA | Full-width, min 48px tall, thumb-friendly |
| Forms | Single column, large inputs (44px min) |
| Font size | Body never below 16px |
| Touch targets | 44x44px min, 8px gap |
| Horizontal scroll | Never. Test on 320px width. |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Multiple CTAs competing | One primary action per viewport |
| No social proof above fold | Add logos or metrics in hero |
| Weak headline | Specific benefit + audience in 10 words |
| Generic stock photos | Real product screenshots or people |
| No mobile test | Most traffic is mobile |
| Auto-playing video | User-initiated playback only |
| No A/B testing plan | Identify highest-impact element, test one change |

## Sources

- Refactoring UI by Adam Wathan and Steve Schoger
- Unbounce Conversion Benchmark Report
- GoodUI.org — A/B tested UI patterns
- NN Group conversion studies
- CXL Institute — conversion optimization research
- Google Web Vitals (web.dev)
- WiderFunnel LIFT Model
