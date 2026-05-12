---
name: landing-craft
description: Build conversion-optimized landing pages with scroll effects
---

Build landing pages designed for conversion. Combines aesthetic web design with performance optimization and conversion rate research. Based on data from Unbounce, GoodUI, Refactoring UI, and NN Group conversion studies.

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
| Background | Dark (#080808) or cream (#f5f2ec). Never generic grey (#f5f5f5). |
| Headline font | Editorial serif. `clamp(2.5rem, 5vw, 4.5rem)` for hero. |
| Body font | Clean sans. Minimum 16px. Line height 1.6. |
| Spacing grid | 8px base. Section padding: `clamp(4rem, 8vw, 8rem)`. |
| Texture | Grain overlay: `opacity: 0.03-0.06` on hero/background sections. |
| Icons | Lucide or Heroicons. Never emojis as icons. |
| Motion | Subtle scroll-triggered animations. Parallax or 3D on hero. |

## Hero Rules

1. **Value in 3 seconds**: the headline must communicate the core benefit immediately
2. **CTA visible without scroll**: primary CTA button above the fold
3. **One CTA, not three**: one primary action. Secondary links are text only.
4. **Headline under 10 words**: longer headlines lose 50%+ of readers
5. **Supporting visual**: image, illustration, or demo video that reinforces the message

## Social Proof

Place near the top (within the first 2 sections). Types ranked by effectiveness:

1. **Logos of recognizable companies**: "Used by teams at [logo cloud]"
2. **Specific user metrics**: "Join 10,000+ paying customers"
3. **Relevant testimonial**: quote with name, title, photo, measurable result
4. **Award or certification badge**: only if recognizable to the target audience

Rules:
- Logo cloud: 3-12 logos, grayscale with hover color
- Never use logos without permission
- Testimonials must have real attribution (name, title, company)
- Metrics need context: "10,000+ customers" not "Over 10k users"

## Problem Section

The problem section should make the reader think "this is about me." Use the PAS structure:

- **Problem**: name the exact pain. Specific beats general. "Your landing page converts at 0.8%" not "Your marketing isn't working."
- **Agitate**: explore the consequences of NOT solving it. What are they losing? Time, money, reputation, sleep?
- **Solution**: present your approach as the natural answer to the now-urgent problem

## Features Grid

3-6 features. Each one gets:
- Icon (meaningful, not decorative)
- Benefit-led headline: "Ship 3x faster" not "Automated CI/CD pipeline"
- 1-2 sentence explanation

Layout: 3 columns on desktop, 2 on tablet, 1 on mobile. Each card has consistent padding, a subtle border, and hover state.

## Testimonials

| Element | Rule |
|---------|------|
| Photo | Required. Real person. No stock photos that look fake. |
| Name + title | Full real name. "Sarah Chen, VP Eng at Acme Corp" |
| Quote | Specific, results-oriented. "Our conversion rate went from 1.2% to 4.8% in 90 days" |
| Length | 1-3 sentences. Long testimonials don't get read. |
| Placement | Near relevant claim — testimonial about performance next to the feature about speed |

## Pricing

3 tiers. The middle one is your real offer.

| Position | Role | Strategy |
|----------|------|----------|
| Left (Starter) | Anchor low | "Free" or low price. Less features. Makes middle look reasonable. |
| Center (Pro) | The offer | Best value. Highlighted/highlighted border. "Most popular" badge. |
| Right (Enterprise) | Anchor high | Highest price. Full features. Makes middle look affordable. |

Rules:
- Annual/monthly toggle (annual = 20% discount, shown as savings)
- Every tier lists features explicitly
- Highlight the differences between tiers, not the similarities
- Include a money-back guarantee or risk reversal near the pricing

## FAQ

Address the top 5 objections that prevent someone from buying. Each FAQ item:
- Names the objection directly: "Is it hard to set up?" not "Setup questions"
- Answers honestly, including limitations
- Ends with a link to more detail or the CTA

Never write FAQ that could be answered by reading the page. FAQ is for objections, not explanations.

## CTA Strategy

| Position | CTA type | Text |
|----------|----------|------|
| Hero | Primary | "Start free trial" / "Get started" |
| Mid-page (after features) | Secondary | "See how it works" / "Book a demo" |
| End of page | Primary | "Start your free trial" / "Get started for free" |
| Sticky (long pages) | Primary (text only) | "Start free trial →" |

Rules:
- One primary action per CTA. "Start free trial" NOT "Start free trial or book a demo"
- CTA button text: verb + outcome. "Start my free trial" beats "Submit" by 40%+
- CTA color: high contrast against page background. Complementary to brand palette.
- CTA size: minimum 48px tall, comfortable padding.

## Performance

| Metric | Target | Why |
|--------|--------|-----|
| Lighthouse performance | > 90 | Google ranking + user experience |
| FCP | < 1.5s | Visitors leave if it takes longer |
| LCP | < 2.5s | Core Web Vitals requirement |
| TBT | < 200ms | Google ranking factor |
| CLS | < 0.1 | Prevents layout shift, improves UX |

Achievement checklist:
- No render-blocking resources above the fold
- Images lazy-loaded with explicit width/height
- Minimal JS: no heavy frameworks for a simple landing page
- CSS critical path inlined, async for rest
- Fonts self-hosted or preloaded with `font-display: swap`
- Third-party scripts loaded with `defer` or `async`

## Scroll Effects

| Effect | Implementation | When to use |
|--------|---------------|-------------|
| Fade in on scroll | IntersectionObserver + CSS opacity transition | Section reveals, feature cards |
| Parallax | `transform: translateY()` scaled slower than scroll | Hero backgrounds, decorative elements |
| Stagger reveal | Children with incremental `animation-delay` | Grid items, feature cards |
| Fixed CTA | `position: sticky` on mobile | Long pages, purchases |
| Scroll progress | Progress bar at top of page | Article/sales pages over 3000px |

Always respect `prefers-reduced-motion: reduce` — disable all scroll-triggered animations.

## Mobile Optimization

| Element | Mobile rule |
|---------|-------------|
| CTA | Full-width button, minimum 48px tall, thumb-friendly |
| Forms | Single column, large inputs (44px min), autofill enabled |
| Font size | Body never below 16px. Headlines scale with clamp(). |
| Touch targets | 44x44px minimum. 8px minimum gap between touch targets. |
| Horizontal scroll | Never. Test on 320px width. |
| Testimonials | Single column, full width, photo above quote. |

## A/B Testing Framework

Always recommend testing these elements first (highest impact):
1. **Headline**: the single highest-impact element
2. **CTA button text and color**: easy to change, measurable impact
3. **Hero image/video**: different visuals can change perception
4. **Social proof placement**: top vs mid page
5. **Pricing structure**: tiers, placement, annual/monthly toggle

Test one element at a time. Statistical significance at 95% confidence. Minimum 1,000 visitors per variant.

## Sources

- Refactoring UI by Adam Wathan and Steve Schoger
- Unbounce Conversion Benchmark Report — industry data
- GoodUI.org — UI patterns validated by A/B testing
- Nielsen Norman Group conversion studies
- CXL Institute — conversion optimization research
- Google Web Vitals documentation — performance standards
- Lighthouse performance scoring guide
- Web.dev "Landing Page Best Practices"
