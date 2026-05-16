# CRO Frameworks Deep Reference

## Table of Contents

- [LIFT Model (WiderFunnel)](#lift-model-widerfunnel)
- [Conversion Research Framework (CXL)](#conversion-research-framework-cxl)
- [GoodUI Validated Patterns](#goodui-validated-patterns)
- [Combining Frameworks](#combining-frameworks)

---

## LIFT Model (WiderFunnel)

Created by Chris Goward at WiderFunnel. Evaluates landing pages across 6 factors that influence conversion decisions.

### The Formula

```
Conversion = f(
  Value Proposition × Relevance × Clarity × Urgency
  ────────────────────────────────────────────────
  Distraction × Anxiety
)
```

All factors are multiplicative. A zero in any denominator kills conversion. A 10x numerator improvement means nothing if distraction or anxiety is high.

### Factor Deep Dives

#### 1. Value Proposition

The visitor's answer to "what's in it for me?" — evaluated in under 5 seconds.

| Property | Description | Example |
|----------|-------------|---------|
| Specific outcome | Tangible result they'll achieve | "Get 200 qualified leads/month" |
| Target audience | Who this is for | "For B2B SaaS founders" |
| Differentiation | Why this vs alternatives | "Setup in 2 minutes, not 2 weeks" |
| Timeframe | When they'll see results | "See results in 48 hours" |

**How to diagnose:**
- Cover the headline and ask 5 colleagues: "what does this page offer?"
- If answers diverge, the value prop is unclear
- GoodUI data: specific numbers in headlines outperform generic by 32%

#### 2. Relevance

Match between the visitor's intent (where they clicked from) and the page content.

| Diagnostic | Red flag |
|------------|----------|
| Ad → Page message match | Ad says "free trial" but page talks about features |
| Keyword → Headline match | Search term differs from H1 wording |
| Source → Offer match | Social post promises discount, page shows full price |
| Audience → Tone match | Enterprise landing page uses casual startup tone |

**How to diagnose:**
- Map every traffic source to the first 3 seconds of the page
- If the headline doesn't match the ad/search result, relevance fails
- Create separate landing pages for each campaign rather than one generic page

#### 3. Clarity

How quickly a visitor understands the offer and what to do next.

| Element | Clear | Unclear |
|---------|-------|---------|
| Headline | "Build your second brain" | "Knowledge management reimagined through networked thought" |
| CTA | "Start my free trial" | "Submit" |
| Subheadline | "Organize notes, ideas, and projects in one place" | (none) |
| Hero visual | Product screenshot showing the core workflow | Abstract stock photo of a lightbulb |

**How to diagnose:**
- 5-second test: show the page for 5 seconds, then ask what it does
- Click test: ask where they'd click to buy/sign up
- If >20% click the wrong thing, clarity needs work
- Readability: aim for Flesch-Kincaid Grade 8 or lower

#### 4. Distraction

Every element that doesn't contribute to the conversion goal dilutes it.

| Distraction type | Examples | Fix |
|-----------------|----------|-----|
| Navigation | Full site menu on a landing page | Remove or minimize |
| Multiple CTAs | "Sign up" + "Learn more" + "See pricing" | One primary CTA per viewport |
| Decorative elements | Unrelated illustrations, animations | Remove or make functional |
| Social links | Facebook/Instagram icons | Remove from landing pages |
| Content | Features nobody asked about | Cut to only the 3 most compelling |
| Choice overload | 4+ pricing tiers | Stick to 3 max |
| Form fields | Asking for phone, company size, etc. | Only what's needed |

**How to diagnose:**
- Cover every element one by one and ask: "does this help someone decide to convert?"
- If not, remove it
- Use eye-tracking (or mouse-tracking proxies like Hotjar) to see what's ignored

#### 5. Anxiety

Objections, fears, and hesitations that prevent conversion.

| Anxiety source | Reassurance |
|---------------|-------------|
| Financial risk | Money-back guarantee, free trial, no credit card |
| Privacy concerns | Privacy policy link, SSL badge, "no spam" notice |
| Social risk | Logos of companies that use it, testimonial from peers |
| Performance risk | Case studies with specific results |
| Effort concern | "Setup in 5 minutes", onboarding support |
| Buyer's remorse | Comparison chart showing you're the best option |

**How to diagnose:**
- List every possible objection a skeptical visitor might have
- Check if the page addresses each one
- Common missed: "is this for someone like me?", "will I have time?", "what if it doesn't work?"

#### 6. Urgency

Why the visitor should act now rather than later.

| Type | Example | Effectiveness |
|------|---------|---------------|
| Limited time | "Sale ends in 24 hours" | High, but creates low-quality conversions if fake |
| Limited supply | "Only 3 spots left" | High for services |
| Scarcity of benefit | "You'll miss the early adopter pricing" | Medium |
| FOMO | "Join 10,000+ customers this month" | Medium |
| Natural urgency | "Start Q2 with the right tool" | Lower but authentic |

**Diagnostic check:**
- If there's no reason to act now, most visitors will leave and never return
- Fake urgency destroys trust — only use if genuine

---

## Conversion Research Framework (CXL)

By Peep Laja (CXL Institute). A systematic, 4-step process for identifying what to test.

### Phase 1: Data Collection (Qualitative + Quantitative)

#### Quantitative Data

| Source | What it reveals | Tools |
|--------|----------------|-------|
| Analytics | Drop-off points, traffic sources, device breakdown | GA4, Plausible, PostHog |
| Funnel analysis | Where people leave between landing and converting | Mixpanel, Amplitude |
| Heatmaps | Where people click, scroll, hover | Hotjar, FullStory, Microsoft Clarity |
| Session recordings | Real user behavior, confusion signals | Hotjar, FullStory |
| Form analytics | Which fields cause abandonment | Formisimo, Zuko |

**Key metrics to gather:**

| Metric | Target | Action if below target |
|--------|--------|----------------------|
| Bounce rate (landing page) | < 50% | Improve relevance + clarity |
| Scroll depth (75%+) | > 40% | Make above-fold content more compelling |
| Time on page | > 30s | Weak value prop or confusing layout |
| Form abandonment rate | < 60% | Reduce fields, improve trust signals |
| CTA click rate | > 5% | Better CTA copy, positioning, or visibility |

#### Qualitative Data

| Source | What it reveals | How |
|--------|----------------|------|
| Surveys | Visitor intent, objections, confusion | Exit-intent popup: "What almost stopped you?" |
| User interviews | Deep understanding of decision process | 5-8 interviews with recent converters + non-converters |
| Customer support tickets | Recurring objections | Tag and analyze support queries |
| Sales team feedback | What prospects ask before buying | Record top 10 questions pre-purchase |
| Reviews (competitors) | What users love/hate about alternatives | G2, Capterra, ProductHunt, AppSumo |

**Survey questions that work:**
- Exit intent: "What was almost stopping you from signing up?"
- Post-conversion: "What convinced you to convert?"
- Non-converter: "What would make this a better fit for you?"

### Phase 2: Hypothesis Generation

From the collected data, identify conversion barriers and opportunities.

**Data → Insight → Hypothesis framework:**

```
[Data point] + [Observation] + [Causal reasoning] = [Hypothesis]

Example:
"70% of users leave after seeing pricing"
+ "Support tickets mention unclear tier differences"
+ "Because comparison information is missing"
= "Adding a feature comparison table will reduce pricing page exits by 15%"
```

**Template for hypotheses:**

```
We believe that [change] for [audience] will achieve [metric improvement]
because [insight from data].
```

Format for tracking:

| ID | Hypothesis | Evidence | Impact (1-5) | Confidence (1-5) | Ease (1-5) | ICE Score |
|----|-----------|----------|-------------|-----------------|-----------|-----------|
| H1 | Move testimonial above fold to increase CTA clicks | Heatmap shows users scroll past CTA but stop at testimonial | 4 | 3 | 5 | 60 |
| H2 | Reduce form fields from 5 to 3 to reduce abandonment | Form analytics shows drop-off at fields 4 and 5 | 5 | 4 | 4 | 80 |

**ICE Scoring:**
- **Impact**: How big will the effect be?
- **Confidence**: How sure are we it'll work?
- **Ease**: How easy is it to implement?
- **Score** = (I × C × E) or (I + C + E) — pick one and stay consistent

Test high-ICE hypotheses first. Avoid testing low-confidence ideas early.

### Phase 3: Prioritization

Not all tests are worth running. Use the ICE framework above, plus:

**PIE Framework (for prioritizing which pages to optimize):**
- **P**otential: How much room for improvement?
- **I**mportance: How much traffic/conversion value is at stake?
- **E**ase: How hard is it to run the test?

**Test-priority matrix:**

```
           High Impact          Low Impact
Easy      ★ RUN NOW            Consider
Hard      Test only if high    Skip or automate
```

**Rules of thumb:**
- Fix broken before optimizing working
- Improve analytics/tracking before running tests
- Test high-traffic pages first (faster statistical significance)
- Fix obvious UX issues before running A/B tests (don't test what you know is broken)

### Phase 4: Test Design & Execution

- One hypothesis per test
- Test the most impactful variable first (headline > button color)
- A/A tests to validate tool setup
- Minimum 1 week runtime (capture full business cycle)
- Don't peek at results until sample size is met

---

## GoodUI Validated Patterns

Data-backed UI patterns from goodui.org. Each pattern has been A/B tested with statistically significant results.

### Top 10 Highest-Impact Patterns

#### 1. One primary action per screen (+232% conversions)

Don't give visitors a choice between "Sign up" and "Learn more". Remove all secondary CTAs from landing pages.

**Implementation:** Single CTA button, one link in nav (the same action), no competing buttons.

#### 2. Social proof next to the CTA (+112%)

Place testimonials, trust badges, or user counts directly next to or below the primary CTA button.

**Implementation:**
```html
<div class="cta-group">
  <button class="cta-button">Start free trial</button>
  <p class="trust-text">Join 10,000+ teams · No credit card required</p>
</div>
```

#### 3. Loss aversion framing (+85%)

Frame the CTA around what they'll lose by not acting, not what they'll gain.

| Instead of | Try |
|-----------|-----|
| "Start saving money" | "Stop overpaying" |
| "Get more done" | "Stop missing deadlines" |
| "Improve your health" | "Reverse the damage from sitting all day" |

#### 4. Specific numbers in headlines (+67%)

Generic claims underperform quantified ones.

| Weak | Strong |
|------|--------|
| "Grow your business" | "Grow your revenue 2x in 90 days" |
| "Save time" | "Save 10 hours per week" |
| "Trusted by companies" | "Trusted by 2,400+ companies" |

#### 5. Benefit-driven CTA button text (+55%)

Replace generic "Submit" or "Sign up" with what they actually get.

| Generic | Benefit-driven |
|---------|---------------|
| Sign up | Get my free guide |
| Subscribe | Send me the weekly tips |
| Start trial | Try Premium free for 30 days |
| Buy now | Reserve my spot |

#### 6. Face + eyes on hero image (+38%)

When the hero image shows a person looking at the CTA button, visitors follow the gaze.

**Implementation:**
- Person looking toward the CTA (not away, not looking at camera)
- Real photo, not stock (or high-quality authentic stock)
- Background removed or contextual to your product

#### 7. Single-column form layout (+32%)

Multi-column forms break visual flow and increase cognitive load.

**Rules:**
- One field per row
- Labels above inputs (not side)
- Vertical flow only

#### 8. Progress indicators for multi-step (+28%)

If you must have a multi-step form, show clear progress: "Step 1 of 3"

**Implementation:**
- Show total steps up front
- Completed steps visually distinct
- Current step highlighted
- Never show more than 5 steps

#### 9. Visual cues pointing at the CTA (+22%)

Subtle directional cues (arrow, eye gaze, design element) pointing at the CTA.

**Patterns:**
- Arrow-shaped design elements
- Image of a person looking toward CTA
- Curved lines drawing the eye to the button
- Checkmark path leading to the button

#### 10. Decoy pricing (+18%)

Add a third pricing option that makes your target option look better.

```
Basic      $9    (anchor — makes Pro look reasonable)
Pro        $29   ★ Most popular (the real offer)
Enterprise $99   (anchor — makes Pro look affordable)
```

### Additional Validated Patterns

| Pattern | Lift | Notes |
|---------|------|-------|
| Money-back guarantee near CTA | +18% | Only if you actually offer it |
| Countdown timer (genuine scarcity) | +17% | Only for time-limited offers |
| Customer logo grid (3-12 logos) | +15% | Grayscale, color on hover |
| Video instead of static hero | +14% | Short (<60s), user-initiated |
| Contrasting CTA color | +12% | High contrast against background |
| Fewer form fields | +10% | Per field removed |
| Live chat widget | +9% | But may distract if intrusive |
| Testimonial with photo + name + result | +8% | Specificity matters |
| FAQ section near pricing | +7% | Answers objections at decision moment |
| Annual/monthly price comparison | +6% | "Annual = save 20%" |

---

## Combining Frameworks

### Workflow: LIFT → Research → GoodUI

```
1. Use LIFT Model for heuristic audit (15 min)
   → Score each of the 6 factors 1-10
   → Identify biggest gap

2. Use CXL Research Framework for data-driven validation (1-2 weeks)
   → Collect analytics, heatmaps, surveys
   → Generate hypotheses based on LIFT gaps + data
   → Prioritize with ICE scoring

3. Use GoodUI patterns for implementation ideas (design phase)
   → Map pattern to hypothesis
   → Adapt pattern to your context
   → A/B test the change

4. Rinse and repeat
   → Measure results
   → Document learnings
   → Start next cycle with updated LIFT scores
```

### Quick heuristic audit (LIFT) template

```
Landing page: ___________________  Date: _______________

Value prop     [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]
Relevance      [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]
Clarity        [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]
Distraction    [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]  (low = good)
Anxiety        [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]  (low = good)
Urgency        [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]

Priority fix:
___________________

GoodUI patterns to apply:
1. ___________________
2. ___________________
3. ___________________
```

### References

- WiderFunnel LIFT Model — Chris Goward, "You Should Test That"
- CXL Institute — Conversion Optimization Course, Peep Laja
- GoodUI.org — Jakub Linowski (validated UI patterns)
- "Don't Make Me Think" — Steve Krug (usability for clarity)
- "Influence: The Psychology of Persuasion" — Robert Cialdini
