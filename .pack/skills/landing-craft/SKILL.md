---
name: landing-craft
description: Build conversion-optimized landing pages with CRO frameworks (Conversion Research, LIFT Model), scroll effects, A/B testing, personalization, form optimization, and Core Web Vitals (INP, LCP, CLS). Use when user asks to create a landing page, sales page, lead generation page, or improve conversion rates. Do NOT use for full product design (use component-forge), animation-specific (use motion-craft), or brand identity (use design).
triggers:
  - "landing page"
  - "sales page"
  - "conversion"
  - "CRO"
  - "A/B test"
  - "conversion rate"
  - "lead generation"
  - "signup page"
  - "marketing page"
  - "pricing page"
  - "LIFT model"
negatives:
  - "full product design"
  - "component library"
  - "animations only"
  - "brand identity"
  - "dashboard"
  - "app UI"
license: MIT
compatibility: opencode
metadata:
  workflow: marketing
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# Landing Craft

Landing pages that convert. Based on Unbounce (44,000+ A/B tests), GoodUI, CXL Institute, and WiderFunnel LIFT Model.

## Creative Variance Engine

Before writing code, select ONE combination based on the brief. This prevents every landing page from looking the same.

### Vibe Archetypes (pick 1)

| Archetype | Palette | Typography | Best for |
|-----------|---------|------------|----------|
| Editorial Luxury | Warm cream (#f5f2ec), deep charcoal, ink-blue accent | Serif display (Cormorant Garamond, Playfair Display) + clean body | B2B, consulting, premium SaaS |
| Dark Atmospheric | Deep navy (#080c1a), off-white text, burnt orange accent | Bold condensed display (Cabinet Grotesk, Space Grotesk) | Tech, AI, developer tools |
| Soft Structural | White (#ffffff), zinc neutrals, single accent | Grotesk display (Geist, Plus Jakarta Sans) | SaaS, productivity, health |
| Minimalist Editorial | Warm bone (#f7f6f3), strict 1px borders, muted pastels | Serif + system sans-serif | Portfolios, indie products |

### Layout Archetypes (pick 1)

| Archetype | Structure | Mobile |
|-----------|-----------|--------|
| Split Screen | 50/50: text left, visual right. Clean alignment, no center. | Stack vertical: text on top, visual below |
| Asymmetric Bento | Masonry grid with varying card sizes. `col-span-8` next to `col-span-4`. | Single column. All `col-span` overrides reset to 1 |
| Editorial Z-Cascade | Elements overlap with slight rotation (-2deg to 3deg). Depth through stacking. | Remove all rotations and negative margins. Stack vertically. |
| Full-Bleed Typography | Hero is pure typography. No image. Text spans viewport width. | Text scales down via clamp(). No overflow. |

**Mobile override (universal):** Any asymmetric layout above `md:` (768px) must collapse to single-column (`w-full`, `px-4`, `py-8`) on viewports below `768px`.

---

## Workflow

### Step 1: Select creative archetype
Pick one vibe + layout from the Creative Variance Engine. Every page must feel distinct.

### Step 2: Wireframe the sections
Block out all 10 sections (Hero through Final CTA). Each section answers: what does the visitor need to hear RIGHT NOW to move forward?

### Step 3: Draft copy
Headline under 10 words. One CTA above fold. Social proof near top. Use PAS framework for problem section.

### Step 4: Implement with mobile-first HTML/CSS
8px grid. clamp() for fluid typography. No centered hero text. Grain overlay (opacity 0.03-0.06).

### Step 5: Optimize for Core Web Vitals
Preload hero image. Inline critical CSS. Lazy-load below-fold images. Target LCP < 2.5s, INP < 200ms.

### Step 6: A/B test and iterate
Test highest-impact element first (headline). 95% significance. Min 1,000 visitors per variant.

## The Structure

```
Hero: headline + sub + CTA (above the fold)
Social proof: logos, metrics, testimonials (~100px below hero)
Problem: framed for empathy, names the pain
Solution: 3 steps max, benefit-focused
Features: 3-6 items, each with one clear benefit
Testimonials: real people, specific results
Pricing: 3 tiers, middle is the offer
FAQ: answers top 5 objections
Final CTA: same ask, different context, near scroll bottom
```

Every section answers: what does the visitor need to hear RIGHT NOW to move to the next section?

---

## Hero Rules (from Unbounce data)

1. **Value in 3 seconds**: headline must communicate core benefit. A/B test headline first - highest-impact element.
2. **CTA visible without scroll**: primary button above the fold. Above 600px vh.
3. **One CTA**: one primary action. Secondary links are text only.
4. **Headline under 10 words**: "Ship 3x faster with automated deployments" not "Welcome to DeployPro - the fastest way to ship code"
5. **Never center text**: Left-aligned text + right-aligned visual (Split Screen). Centered hero is the #1 AI clich-.
6. **Supporting visual**: product screenshot, illustration, or demo - never a generic stock photo.

### Hero alt-layouts (not all center)

| Layout | HTML structure | When |
|--------|---------------|------|
| Split 50/50 | `<div class="grid grid-cols-2"><div>text</div><div>visual</div></div>` | Default. Works for everything. |
| Text-bleed | `<div class="pl-[5vw]"><h1 class="text-[clamp(48px,7vw,120px)]">Hero text</h1></div>` | Strong brand, confident product |
| 3D perspective | `<div class="perspective-[800px]"><h1 class="[transform:rotateX(15deg)]">Hero</h1></div>` | Creative, premium, editorial |
| Negative space | `<div class="grid"><div class="col-start-1 col-end-3">text</div><div class="col-start-2">visual</div></div>` | Editorial, luxury |

---

## Design Palette

| Element | Specification |
|---------|---------------|
| Background | Dark (#080808) or cream (#f5f2ec). Never flat #ffffff or #f5f5f5 |
| Headline | Editorial serif or bold display. `clamp(2.5rem, 5vw, 4.5rem)` |
| Body | Clean sans. Min 16px. Line height 1.6 |
| Spacing | 8px base. Section: `clamp(4rem, 8vw, 8rem)` |
| Texture | Grain overlay: opacity 0.03-0.06 |
| Icons | Lucide or Phosphor. No emoji icons. |
| Motion | Subtle scroll-triggered. Parallax or 3D on hero. No gratuitous animation. |

---

## CRO Methodology

### LIFT Model (WiderFunnel)

Evaluate every element against these six factors:

| Factor | Question | Measurement |
|--------|----------|-------------|
| Value proposition | Does this clearly communicate the benefit? | "What do I get?" answerable in 3 seconds |
| Relevance | Does this match the visitor's intent? | Bounce rate < 50% |
| Clarity | Is the message immediately understandable? | "What is this?" answerable in 5 seconds |
| Distraction | What can we remove to focus attention? | Scroll depth > 50% |
| Anxiety | What reassures the visitor? | Trust signals visible above fold |
| Urgency | Why should they act now? | Deadline or scarcity (real, not fake) |

### High-Impact Test Elements (in order of ROI)

| Test | Why | Expected lift |
|------|-----|--------------|
| Headline | First thing read. Shapes entire perception. | 10-40% |
| CTA button text and color | Final friction point. | 5-25% |
| Hero image/video | Visual sets trust and expectation. | 5-15% |
| Social proof placement | Top vs mid page changes trust curve. | 3-10% |
| Pricing structure | Tiers, placement, toggle. | 3-15% |

Test one element at a time. 95% statistical significance. Min 1,000 visitors per variant.

---

## Hero Architecture (Exact CSS)

```css
.hero {
  min-height: 100dvh;
  display: grid;
  grid-template-columns: 1fr 1fr;
  align-items: center;
  padding: 0 clamp(2rem, 5vw, 6rem);
  background: #080c1a;
}

.hero-text {
  max-width: 650px;
}

.hero-text h1 {
  font-family: 'Cabinet Grotesk', 'Geist', sans-serif;
  font-size: clamp(2.5rem, 5vw, 4.5rem);
  font-weight: 700;
  line-height: 1.05;
  letter-spacing: -0.02em;
  color: #f0ede8;
}

.hero-text p {
  font-size: clamp(1rem, 1.2vw, 1.25rem);
  line-height: 1.6;
  color: #a09c96;
  max-width: 480px;
  margin-top: 1.5rem;
}

.hero-cta {
  display: inline-flex;
  align-items: center;
  gap: 0.75rem;
  padding: 16px 48px;
  background: #1B365D;
  color: #f0ede8;
  font-size: 0.9rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border: none;
  border-radius: 0;
  margin-top: 2rem;
  transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1),
              background 200ms ease;
}

.hero-cta:hover {
  background: #e05a20;
  transform: translateY(-2px);
}

.hero-cta:active {
  transform: scale(0.97);
}
```

---

## Social Proof

Place near the top (within first 2 sections). Types by effectiveness:

1. **Logos of recognizable companies** (3-12, grayscale, hover color. Never use without permission.)
2. **Specific user metrics**: "Join 10,000+ paying customers" - number must be real
3. **Relevant testimonial**: quote with name, title, photo, specific result
4. **Award/certification badge**: only if recognizable (SOC 2, YC, Product Hunt)

```html
<div class="social-proof">
  <p class="text-sm uppercase tracking-wider text-slate-400 mb-6">Trusted by teams at</p>
  <div class="flex flex-wrap gap-8 items-center opacity-60">
    <img src="stripe.svg" alt="Stripe" class="h-8 grayscale hover:grayscale-0 transition" />
    <img src="vercel.svg" alt="Vercel" class="h-8 grayscale hover:grayscale-0 transition" />
    <img src="shopify.svg" alt="Shopify" class="h-8 grayscale hover:grayscale-0 transition" />
  </div>
</div>
```

---

## Problem Section (PAS Framework)

**Problem**: name the exact pain with specific numbers. "Your landing page converts at 0.8%. The industry average is 3.2%."
**Agitate**: explore consequences of NOT solving it. Money lost. Growth stalled. Competitors winning.
**Solution**: present your approach. "DeployPro uses conversion science from 44,000+ A/B tests to lift conversion rates."

---

## Features Grid

3-6 features. Each one gets:
- Icon (meaningful, not decorative). Single color, consistent stroke width.
- Benefit-led headline: "Ship 3x faster" not "Automated CI/CD"
- 1-2 sentence explanation. No fluff.

```html
<div class="grid grid-cols-1 md:grid-cols-3 gap-8">
  <div class="feature">
    <Icon icon="zap" class="w-8 h-8 text-amber-500 mb-4" />
    <h3 class="text-lg font-semibold mb-2">Ship 3x faster</h3>
    <p class="text-slate-400">Automated build and deploy pipeline. One command to production.</p>
  </div>
</div>
```

---

## Testimonials

| Element | Rule |
|---------|------|
| Photo | Required. Real person. No stock. |
| Attribution | Full real name, title, company |
| Quote | Specific, results-oriented. "We shipped 40% more features after switching" not "Great product" |
| Length | 1-3 sentences |
| Placement | Near relevant claim. Don't pile all at the bottom. |

---

## Pricing

3 tiers. Middle is your real offer.

| Position | Role | Strategy |
|----------|------|----------|
| Left (Starter) | Anchor low | Makes middle look reasonable. Price at 40-60% of Pro. |
| Center (Pro) | The offer | Best value, highlighted visually. "Most popular" badge. |
| Right (Enterprise) | Anchor high | Makes middle look affordable. 2-3x Pro. |

```css
.pricing-card-featured {
  border: 2px solid var(--accent);
  transform: scale(1.05);
  position: relative;
  z-index: 1;
}

.pricing-card-featured::before {
  content: 'Most popular';
  position: absolute;
  top: 0;
  left: 50%;
  transform: translate(-50%, -50%);
  background: var(--accent);
  color: white;
  padding: 4px 16px;
  border-radius: 9999px;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
```

Rules:
- Annual/monthly toggle (annual = 17-20% discount)
- Every tier lists features explicitly
- Include money-back guarantee near pricing
- No fake scarcity. No "Only 3 spots left" when unlimited.

---

## Form Optimization (exact specs)

| Element | Best practice |
|---------|---------------|
| Fields | Minimum viable. Email only for lead gen. |
| Validation | Inline, real-time, specific error messages |
| Autofill | Enable `autocomplete` attributes |
| Submit | Button says what happens: "Get my free guide", "Start free trial" not "Submit" |
| Error recovery | Preserve entered values, highlight fields |
| Privacy | "No spam. Unsubscribe anytime." |
| Input height | 48px minimum for mobile |
| Input font | 16px minimum (prevents iOS zoom on focus) |

```html
<form class="space-y-4 max-w-md">
  <div>
    <label for="email" class="block text-sm font-medium mb-1">Work email</label>
    <input
      id="email"
      type="email"
      autocomplete="email"
      required
      class="w-full h-12 px-4 border border-slate-200 text-base rounded-md"
      placeholder="you@company.com"
    />
  </div>
  <button
    type="submit"
    class="w-full h-12 bg-slate-900 text-white font-medium rounded-md
           transition-all duration-160 ease-out
           active:scale-[0.97]"
  >
    Get my free guide
  </button>
  <p class="text-xs text-slate-400 text-center">
    No spam. Unsubscribe anytime.
  </p>
</form>
```

---

## Performance (Core Web Vitals 2026)

| Metric | Target | Measurement |
|--------|--------|-------------|
| INP (Interaction to Next Paint) | < 200ms | Field data (Chrome UX Report) |
| LCP (Largest Contentful Paint) | < 2.5s | Lab + field |
| CLS (Cumulative Layout Shift) | < 0.1 | Lab + field |
| TBT (Total Blocking Time) | < 200ms | Lab only |
| Lighthouse Performance | > 90 | Lab |

**Achievement checklist:**
- No render-blocking resources above fold
- Hero image preloaded: `<link rel="preload" as="image" href="hero.webp">`
- Critical CSS inlined in `<style>` tag. Async load for rest.
- Images lazy-loaded (`loading="lazy"`) with explicit `width`/`height`
- Fonts self-hosted or preloaded with `font-display: swap`
- Third-party scripts loaded with `defer` or `async`
- Minimal JS. No frameworks for simple landing pages.

---

## Mobile Optimization

| Element | Mobile rule |
|---------|-------------|
| CTA | Full-width, min 48px tall, thumb-friendly |
| Forms | Single column, large inputs (48px min) |
| Font size | Body never below 16px |
| Touch targets | 44-44px min, 12px gap |
| Horizontal scroll | Never. Test on 320px width. |
| Hero | Full-width text, no image until 768px |

---

## CRO Audit Checklist

Before launching, verify:

- [ ] Value proposition clear in 3 seconds (show to someone new, ask "what is this?")
- [ ] CTA visible without scrolling on mobile and desktop
- [ ] Only one primary CTA above fold
- [ ] Headline under 10 words with specific benefit
- [ ] Hero text NOT centered (left-aligned + right visual)
- [ ] Social proof above fold (logos or metrics)
- [ ] Real testimonials with attribution and specific results
- [ ] LIFT Model: all 6 factors score 4/5 or higher
- [ ] Form: minimum fields, 16px+ font, 48px+ input height
- [ ] Privacy reassurance near form
- [ ] Money-back guarantee near pricing
- [ ] FAQ addresses top 5 real objections
- [ ] Lighthouse Performance > 90
- [ ] Core Web Vitals pass (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] Mobile: all touch targets = 44-44px, no horizontal scroll
- [ ] A/B test plan: identify highest-impact element, document hypothesis
- [ ] No fake urgency or scarcity
- [ ] No generic stock photos - real product, real people, or illustration

---

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Hero image LCP > 4s | No preload or unoptimized format | Preload with `<link rel="preload" as="image">`, use WebP/AVIF, serve via CDN |
| CLS from late-loading fonts | Web font triggers layout shift | Self-host fonts. Use `font-display: swap`. Preload with `<link rel="preload" as="font">` |
| A/B test inconclusive | Not enough traffic or significance | Min 1,000 visitors/variant, 95% significance, run for 2+ business cycles |
| Form abandonment spike | Too many fields or validation confusion | Reduce to minimum viable fields. Inline real-time validation. Preserve values on error. |
| Mobile bounce rate > 70% | Touch targets too small, horizontal scroll | All touch targets >= 44px. Test at 320px width. No horizontal overflow. |
| Scroll effects jank on mobile | `requestAnimationFrame` scroll listeners | Use CSS `animation-timeline: view()` or IntersectionObserver. Debounce JS scroll handlers. |
| CTA click-through below 1% | Weak copy, wrong placement | A/B test CTA text. Ensure CTA visible without scroll. Single primary action above fold. |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Multiple CTAs competing | One primary action per viewport |
| No social proof above fold | Add logos or metrics in hero |
| Weak headline ("Welcome to Our Product") | Specific benefit + audience in 10 words |
| Generic stock photos | Real product screenshots or real people |
| No mobile test | Most traffic is mobile. Test at 320px. |
| Auto-playing video with sound | User-initiated playback only |
| No A/B testing plan | Identify highest-impact element, test one change |
| Centered hero text | Left-aligned text + right-aligned visual |
| "Only 3 spots left" when unlimited | Fake scarcity destroys trust |
| Pricing without annual toggle | Annual = 17-20% discount. Always offer it. |
| CTA says "Submit" | Action verb + value: "Get my free guide" |
| Hero image without preload | `<link rel="preload" as="image">` for LCP |
| `h-screen` for hero | `min-h-[100dvh]` - avoids iOS Safari jump |
| Form inputs under 48px on mobile | iOS zooms on anything under 16px font |

---

## Sources

- Unbounce Conversion Benchmark Report (44,000+ A/B tests analyzed)
- GoodUI.org - A/B tested UI patterns database
- CXL Institute - Conversion optimization research
- WiderFunnel LIFT Model
- NN Group - Conversion studies and usability research
- Refactoring UI - Adam Wathan, Steve Schoger
- Google Web Vitals (web.dev)
- Copyhackers - Conversion copywriting

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
