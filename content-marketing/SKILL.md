---
name: content-marketing
description: >
  Write blogs, newsletters, Twitter threads, case studies, and marketing copy
  that convert. Covers copywriting frameworks (AIDA, PAS, BAB, FAB), headline
  formulas, SEO/GEO for 2026 (AI Overviews, SGE), newsletter deliverability,
  Twitter thread hooks, Cialdini psychology, and cognitive biases.
  Triggers: write a blog post, newsletter, Twitter thread, case study,
  marketing copy, landing page copy, ad copy, sales page.
  Negative triggers: sales outreach (use business-proposals), landing page
  design (use landing-craft), translation (use translate-craft).
license: MIT
compatibility: opencode
metadata:
  version: "3.0"
  workflow: content-marketing
  audience: developers
  allowed-tools:
    - websearch
    - webfetch
    - read
    - write
    - edit
    - glob
    - grep
    - bash
    - skill
---

# Content Marketing

Write content that ranks, converts, and gets shared. Based on Ogilvy, Cialdini, and modern distribution strategies.

## Workflow

Follow these steps in order when asked to produce content.

### Step 1: Brief & Research

- Ask for (or infer): audience, goal, format, tone, key message, CTA
- Search competitor content for gaps and angles
- Collect 3-5 data points / quotes / studies to support claims
- Define primary keyword + 2-3 related keywords

### Step 2: Structure Outline

- Choose framework (AIDA / PAS / BAB / FAB / 4Ps / QUEST — see below)
- Draft headline (use Headline Formulas section)
- Define sections with H2/H3 hierarchy
- Place internal links and CTAs

### Step 3: Draft

- Write lead (choose from Lead Types table)
- Expand each section with claims backed by data
- Add code examples if relevant (runnable, annotated, wrong→right)
- Keep paragraphs under 3 sentences

### Step 4: Optimize

- Apply SEO/GEO rules (keywords, schema, answer format)
- Check headline against rules (under 15 words, keyword early, specific outcome)
- Verify Cialdini principles applied (at least 3)
- Validate against Anti-Patterns table

### Step 5: Polish & Deliver

- Read aloud for flow. Cut fluff.
- Check all links work
- Format for target platform (Markdown for blog, plain text for email, etc.)
- Include preview text / subject line if newsletter
- Submit or hand off

## Copywriting Frameworks

| Framework | Structure | Best for |
|-----------|-----------|----------|
| AIDA | Attention → Interest → Desire → Action | Landing pages, emails |
| PAS | Problem → Agitate → Solve | Pain-point focused |
| BAB | Before → After → Bridge | Transformational offers |
| FAB | Feature → Advantage → Benefit | Product descriptions |
| 4Ps | Picture → Promise → Prove → Push | Long-form direct response |
| QUEST | Qualify → Understand → Educate → Stimulate → Transition | B2B complex sales |

## Headline Formulas

### Direct Benefit
- `[Number] [noun] for [audience]` — "10 Email Templates for Busy Founders"
- `How to [outcome] in [time]` — "How to Double Conversion Rate in 30 Days"
- `[Outcome] Without [pain]` — "Get More Leads Without Spending on Ads"

### Curiosity & Engagement
- `Why [common belief] is [wrong]` — "Why 'Write for Skimmers' Is Terrible Advice"
- `I [did surprising thing] and [unexpected result]` — "I Rewrote One Page and Made $40K"

### Rules
Under 15 words. Include keyword near the start. Promise a specific outcome. No clickbait.

## Blogs

### Structure
```
Headline → Lead → Sections (H2+H3) → Code examples → Conclusion → CTA
```

### Lead Types
| Type | Formula |
|------|---------|
| Problem-first | "[Pain]. Here's how to fix it." |
| Story-first | "I [did thing] and learned [lesson]." |
| Curiosity gap | "[Claim]. Here's why." |
| Data-first | "[Stat]. [Why it matters]." |

### Code Examples Rules
- Show only relevant lines (not full files)
- Runnable code with imports
- Include error examples (wrong → right)
- Annotate complex blocks

## SEO & GEO (2026)

### Traditional SEO still applies

| Element | Requirement |
|---------|-------------|
| Primary keyword | In H1, first paragraph, one H2 |
| Meta description | Under 155 chars, includes value prop |
| URL | kebab-case, no stop words |
| Internal links | 2-3 related posts |

### GEO (Generative Engine Optimization) — new for 2026

| Factor | Strategy |
|--------|----------|
| Entity clarity | Clearly define who you are, what you do, for whom |
| Structured data | FAQ, HowTo, Article schema markup |
| Source citation | Link to primary sources, studies, data |
| Contrarian takes | AI models reference multiple viewpoints |
| Conversational tone | MAT answers (Most Accurate Thinking) preferred by AI |
| Answer format | Direct answer in first paragraph, then expand |

### AI Overviews optimization

- Write clear, self-contained answers in first 2 paragraphs
- Use "What is X", "How to Y", "Why does Z" question formats
- Include data, dates, named sources
- Answer the question before expanding context

## Newsletters

### Structure
```
Preheader (85-100 chars, extends subject)
→ Greeting
→ Primary item (reason they opened)
→ Supporting items (2-3, scannable)
→ One CTA (button)
→ Footer (unsubscribe, address, privacy)
```

### Subject Line Types
| Type | Formula | Open rate |
|------|---------|-----------|
| Curiosity | "The [X] nobody tells you about" | High |
| Utility | "[Number] [topic] patterns I use" | Medium |
| Personal | "What I learned about [topic] this month" | Medium |

Rules: 30-50 chars. Start with verb or number. No ALL CAPS. A/B test 20% before full send.

### Deliverability Checklist
- [ ] SPF, DKIM, DMARC configured
- [ ] Spam complaint rate below 0.1%
- [ ] List cleaned of inactive subscribers (6+ months)
- [ ] No spam trigger words (free, guarantee, act now)
- [ ] Text version alongside HTML
- [ ] From name is a person, not a company

### Benchmarks
| Metric | Good | Needs work |
|--------|------|------------|
| Open rate | 25-40% | Below 20% |
| Click rate | 2-5% | Below 1% |
| Unsubscribe | Under 0.5% | Over 1% |

## Twitter Threads

### Anatomy (5-7 tweets)

```
Tweet 1: Hook — stop the scroll (240 chars)
Tweet 2: Context — why this matters
Tweets 3-5: Value — core teaching, step by step
Tweet 6: Proof — evidence, results, data
Tweet 7: CTA — one clear action
```

### Hook Patterns
| Type | Formula |
|------|---------|
| Surprising stat | "[Number]% of [group] [do X]" |
| Contrarian | "I stopped doing [common thing]" |
| Direct promise | "[Number] ways to [outcome]" |
| Story opening | "I [did thing] and [unexpected result]" |
| Bold claim | "Most [professionals] are wrong about [topic]" |

### Writing Rules
- One idea per tweet. 240 chars max
- No emojis in first tweet
- End every tweet with reason to keep reading
- Specific numbers: "3.2x" not "more"

## Case Studies

### Structure
```
Headline: [Company] achieved [result] with [approach]
→ Executive summary (3 sentences max)
→ The problem (before state, quantified)
→ The approach (why this solution, not others)
→ The solution (what was built)
→ The results (after state with numbers)
→ Testimonial
→ Key takeaways
→ CTA
```

### Results Table
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Page load | 4.2s | 1.1s | -74% |
| Conversion | 2.1% | 4.8% | +129% |

Rules: real numbers or don't publish. Include lagging and leading indicators.

## Marketing Psychology

### 7 Principles (Cialdini)
| Principle | Application |
|-----------|-------------|
| Reciprocity | Free trials, valuable content upfront |
| Scarcity | Limited time, limited stock |
| Authority | Certifications, awards, data |
| Consistency | Micro-yes → macro-yes |
| Liking | Relatable brand voice |
| Social proof | Testimonials, user count |
| Unity | Shared identity, "we"/"us" framing |

### Cognitive Biases
| Bias | Application |
|------|-------------|
| Anchoring | Show higher price first |
| Decoy effect | 3 pricing tiers, middle is offer |
| Loss aversion | "You're missing out" > "You'll gain" |
| Paradox of choice | Limit to 3-4 options |
| Peak-end rule | Best interaction + strong ending |
| Default bias | Opt-out > opt-in |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Generic headline | Be specific: name outcome + audience |
| No social proof | Add testimonials near every claim |
| Weak CTA | Action verb + specific outcome |
| Writing for "everyone" | Pick one persona |
| Fake scarcity | Only use genuine limits |
| No proof | Back every claim with data |
| 20-tweet threads | Cut to 5-8 |
| Selling in first 5 tweets | Build trust first |
| Ignoring deliverability | Run checklist before send |
| No A/B test on subject | Test 20% before full blast |

## Error Handling

| Scenario | Likely Cause | Fix |
|----------|-------------|-----|
| Content feels generic | No specific audience defined | Re-run Step 1, pick one persona |
| Headline doesn't grab | Missing keyword or benefit | Rewrite with [outcome] + [audience] formula |
| Low open rates | Subject line too long / weak | Trim to 30-50 chars, A/B test |
| High unsubscribe | Wrong audience or too frequent | Audit content relevance, adjust cadence |
| No conversions | CTA too vague or missing | Add single CTA with action verb + outcome |
| SEO not ranking | Keyword not in H1 or first paragraph | Move primary keyword to H1 + first 100 words |
| AI Overviews ignore content | No direct answer format | Restructure opening as direct Q&A |
| Newsletter flagged as spam | Missing DKIM or spam trigger words | Run deliverability checklist |
| Thread gets low engagement | No hook or too much selling | Rewrite first tweet as curiosity gap |
| Case study feels weak | No quantified results | Remove or collect real metrics |

## Production Checklist

Before publishing any piece, verify:

- [ ] Audience persona defined and reflected in language
- [ ] Copywriting framework chosen (AIDA / PAS / BAB / etc.)
- [ ] Headline under 15 words with keyword near start
- [ ] At least 3 Cialdini principles applied
- [ ] Every claim backed by data, quote, or source link
- [ ] Primary keyword in H1, first paragraph, and one H2
- [ ] Meta description under 155 chars (blog)
- [ ] Direct answer format in first 2 paragraphs (GEO)
- [ ] CTA is a single action verb with specific outcome
- [ ] No anti-pattern violations (check table above)
- [ ] Links tested and valid
- [ ] Read aloud — flow is natural, no jargon

## Sources

- Ogilvy on Advertising
- Breakthrough Advertising (Eugene Schwartz)
- Copyhackers (Joanna Wiebe)
- Cialdini "Influence"
- CSS-Tricks, Smashing Magazine
- Mailchimp, Campaign Monitor
- Google Search Central — SEO docs
- Google SGE / AI Overviews documentation
