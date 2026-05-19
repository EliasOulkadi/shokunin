---
name: content-marketing
description: >
  Write blogs, newsletters, Twitter threads, case studies, and marketing copy
  that convert. Covers copywriting frameworks (AIDA, PAS, BAB, FAB), headline
  formulas, SEO/GEO for 2026 (AI Overviews, SGE), newsletter deliverability,
  Twitter thread hooks, Cialdini psychology, and cognitive biases.
triggers:
  - "write a blog post"
  - "write a newsletter"
  - "write a Twitter thread"
  - "case study"
  - "marketing copy"
  - "copywriting"
  - "landing page copy"
  - "ad copy"
  - "sales copy"
  - "content strategy"
negatives:
  - "sales outreach"
  - "proposal"
  - "SOW"
  - "pitch deck"
  - "translation"
  - "localization"
license: MIT
compatibility: opencode
metadata:
  version: "4.0.0"
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

## Workflow

1. **Define the audience persona** — who reads this? What do they know? What problem do they have? Language, examples, and tone reflect this one persona.
2. **Select the copywriting framework** — AIDA for landing pages, PAS for pain-point content, BAB for transformational offers, FAB for product descriptions.
3. **Write the headline first** — under 15 words, keyword near start, specific outcome promise. Score against headline formulas. No clickbait.
4. **Open with a strong lead** — problem-first, story-first, curiosity gap, or data-first. Hook the reader in the first 2 sentences.
5. **Layer Cialdini principles** — minimum 3 per piece. Reciprocity (free value), social proof (testimonials/logos), authority (data/sources), scarcity (genuine limits only).
6. **Optimize for SEO + GEO** — primary keyword in H1, first 100 words, one H2. Direct answer in first 2 paragraphs for AI overviews. Structured data where applicable.
7. **Close with one clear CTA** — single action verb + specific outcome. "Get the checklist" not "Learn more."

## Error Handling

| Cause | Fix |
|-------|-----|
| Headline scores poorly against formulas (generic, no outcome) | Rewrite with: specific number + target audience + promised result. Test 3-5 variants. |
| Open rate below 20% on newsletter | Subject line too long or too vague. Target 30-50 chars. Start with verb or number. A/B test 20% of list. |
| Click rate below 1% on newsletter | CTA not prominent or actionable. Move CTA higher. Make it a single, specific action with a clear benefit. |
| Blog post reads like AI-generated, high bounce rate | Check for AI tells: uniform paragraph length, mechanical connectors, absolute neutrality, no opinion. Humanize voice. |
| Twitter thread hook gets scrolled past | Hook must stop the scroll in 240 chars. Use: surprising stat, contrarian take, direct promise, story opening, or bold claim. |
| Content flagged as thin or unhelpful by Google | Add original data, unique perspective, or expert insight. Cite primary sources. Include contrarian viewpoint for GEO. |
| "Fake scarcity" damages brand trust | Only use genuine limits: limited cohort, real deadline, actual inventory constraint. Never invent urgency. |
| Cialdini principle overuse feels manipulative | Max 3-4 principles per piece. Layer naturally. Social proof and authority should feel earned, not forced. |

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

## Headline Formulas by Platform

### Blog Headings
- "How to [Achieve Outcome] [Timeframe]" (How to Ship Faster in 30 Days)
- "[Number] [Adjective] Ways to [Solve Problem]" (7 Proven Ways to Reduce Churn)
- "Why [Common Belief] Is Wrong (And What to Do Instead)" 
- "[Year] Guide to [Topic]: [Specific Angle]" (2026 Guide to SEO: GEO Edition)

### Newsletter Subject Lines
- Questions: "Is your [metric] where it should be?"
- Urgency: "[Name], [deadline] is tomorrow"
- Social proof: "How [company] grew [metric] by [number]%"
- Curiosity gap: "The [industry] secret nobody talks about"

### Twitter/X Threads
- Hook line 1: Contrarian take or surprising statistic
- Line 2-3: Expand with evidence
- Line 4-6: Steps/methods (numbered)
- Line 7-8: Results/social proof
- Last line: Call to action + link

### LinkedIn
- Line 1: Statement that challenges assumption
- Line 2-3: Story with specific numbers
- Line 4-5: Lesson learned
- Last line: Question to drive comments

## Newsletter Deliverability

### Authentication
```
DNS Records:
TXT  @   "v=spf1 include:mail.provider.com ~all"
TXT  _dmarc  "v=DMARC1; p=quarantine; rua=mailto:dmarc@domain.com"
CNAME  selector1._domainkey  selector1.provider.com
CNAME  selector2._domainkey  selector2.provider.com
```

### Deliverability Checklist
- SPF record covers all sending IPs
- DKIM signed with 2048-bit key
- DMARC policy at minimum `p=none` (monitor), eventually `p=reject`
- Custom tracking domain (not shared with other senders)
- Sender reputation > 95% (Google Postmaster Tools)
- Spam rate < 0.1% (Google threshold is 0.3%)
- Unsubscribe link visible in every email (CAN-SPAM/GDPR requirement)
- List cleaned monthly: remove addresses that haven't opened in 90 days

## Sources

- Ogilvy on Advertising
- Breakthrough Advertising — Eugene Schwartz
- Copyhackers — Joanna Wiebe
- Cialdini "Influence"
- Google Search Central — SEO documentation
- Mailchimp / Campaign Monitor — Email benchmarks

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
