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
  version: "4.0"
  workflow: content-marketing
  audience: developers
allowed-tools: [websearch, webfetch, read, write, edit, glob, grep, bash, skill]
---

# Content Marketing

Content that ranks, converts, and gets shared. Based on Ogilvy, Cialdini, Copyhackers, and modern distribution strategies.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `blog` | Write a blog post (outline → draft → optimize → publish) |
| `newsletter` | Write a newsletter issue with subject line + body |
| `thread` | Write a Twitter/X thread (hook + value + CTA) |
| `case-study` | Write a case study from results data |
| `headline` | Generate and score headlines against formulas |
| `optimize` | Optimize existing content for SEO + GEO |

## Copywriting Frameworks

| Framework | Structure | Best for |
|-----------|-----------|----------|
| AIDA | Attention → Interest → Desire → Action | Landing pages, emails |
| PAS | Problem → Agitate → Solve | Pain-point focused content |
| BAB | Before → After → Bridge | Transformational offers |
| FAB | Feature → Advantage → Benefit | Product descriptions |
| 4Ps | Picture → Promise → Prove → Push | Long-form direct response |

## Headline Formulas

| Type | Formula | Example |
|------|---------|---------|
| Direct benefit | "[Number] [noun] for [audience]" | "10 Email Templates for Busy Founders" |
| How-to | "How to [outcome] in [time]" | "How to Double Conversion Rate in 30 Days" |
| Pain avoidance | "[Outcome] Without [pain]" | "Get More Leads Without Spending on Ads" |
| Contrarian | "Why [common belief] is [wrong]" | "Why 'Write for Skimmers' Is Terrible Advice" |
| Personal story | "I [did thing] and [result]" | "I Rewrote One Page and Made $40K" |

**Rules:** Under 15 words. Keyword near start. Specific outcome promise. No clickbait.

## Blog Structure

```
Headline → Lead (problem/story/curiosity/data) → H2 sections → Code examples → Conclusion → CTA
```

Lead types:
| Type | Formula |
|------|---------|
| Problem-first | "[Pain]. Here's how to fix it." |
| Story-first | "I [did thing] and learned [lesson]." |
| Curiosity gap | "[Claim]. Here's why." |
| Data-first | "[Stat]. [Why it matters]." |

## SEO + GEO (2026)

### Traditional SEO
- Primary keyword in H1, first 100 words, one H2
- Meta description under 155 chars with value prop
- URL: kebab-case, no stop words
- Internal links: 2-3 related posts

### GEO (Generative Engine Optimization)
- Direct answer in first 2 paragraphs (AI scrapes opening)
- Structured data: FAQ, HowTo, Article schema
- Entity clarity: define who you are, what you do, for whom
- Cite primary sources (studies, data, .edu/.gov)
- Contrarian takes (AI models reference multiple viewpoints)
- Conversational tone (AI penalizes keyword-stuffed text)

## Twitter Threads (5-7 tweets)

```
Tweet 1: Hook — stop the scroll (240 chars max)
Tweet 2: Context — why this matters
Tweets 3-5: Value — core teaching, step by step
Tweet 6: Proof — evidence, results, data
Tweet 7: CTA — one clear action
```

Hook patterns: surprising stat, contrarian take, direct promise, story opening, bold claim.

## Newsletter Benchmarks

| Metric | Good | Needs work |
|--------|:----:|:----------:|
| Open rate | 25-40% | Below 20% |
| Click rate | 2-5% | Below 1% |
| Unsubscribe | Under 0.5% | Over 1% |

Subject line: 30-50 chars. Start with verb or number. No ALL CAPS. A/B test 20%.

## Cialdini Principles (minimum 3 per piece)

| Principle | Application |
|-----------|-------------|
| Reciprocity | Free content, valuable upfront |
| Scarcity | Limited time, real limits only |
| Authority | Data, certifications, named sources |
| Social proof | Testimonials, user count, logos |
| Consistency | Micro-yes → macro-yes |
| Liking | Relatable voice, shared identity |

## Production Checklist

- [ ] Audience persona defined and reflected in language
- [ ] Copywriting framework chosen
- [ ] Headline under 15 words, keyword near start
- [ ] At least 3 Cialdini principles applied
- [ ] Every claim backed by data, quote, or source link
- [ ] Primary keyword in H1, first paragraph, one H2
- [ ] Direct answer in first 2 paragraphs (GEO)
- [ ] CTA: single action verb with specific outcome
- [ ] No anti-pattern violations
- [ ] Links tested and valid
- [ ] Read aloud: flow natural, no jargon

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Generic headline | Specific: name outcome + audience |
| No social proof | Add testimonials near every claim |
| Weak CTA | Action verb + specific outcome |
| Writing for "everyone" | Pick one persona |
| Fake scarcity | Only use genuine limits |
| No proof | Back every claim with data |
| Selling too early | Build trust before the ask |

## Sources

- Ogilvy on Advertising
- Breakthrough Advertising — Eugene Schwartz
- Copyhackers — Joanna Wiebe
- Cialdini "Influence"
- Google Search Central — SEO documentation
- Mailchimp / Campaign Monitor — Email benchmarks
