---
name: case-study
description: Build case studies from problem and results
---

Build case studies that close deals. Based on B2B case study frameworks from HubSpot, Salesforce, Gartner, and conversion copywriting research from Copyhackers and the MECLab.

## The Structure

```
Headline: [Company] achieved [result] with [approach]
  → Executive summary (3 sentences max)
  → The problem (before state, quantified)
  → The approach (why this solution, not others)
  → The solution (what was built, key decisions)
  → The results (after state with numbers)
  → Testimonial (client quote, placed near the relevant metric)
  → Key takeaways (for someone in a similar situation)
  → CTA (what to do if they want similar results)
```

## Headline Patterns

| Pattern | Example | Best for |
|---------|---------|----------|
| [Company] [result] with [approach] | "Acme Corp cut cloud costs 40% with serverless migration" | General |
| How [company] achieved [result] | "How FinTechX achieved 99.99% uptime with chaos engineering" | Technical audience |
| From [before] to [after]: [company] | "From 4.2s page load to 1.1s: how ShopFlow rebuilt their frontend" | Transformation story |
| [Number]x [metric] for [company] | "3x faster deployments for DataStream with Kubernetes" | Metric-forward |

## Problem Section

Must answer three questions:
- **What was broken?** Specific, not generic. "The checkout page crashed on 15% of mobile sessions" not "The site had issues."
- **How did it impact the business?** In concrete terms: lost revenue ($X/mo), wasted time (X hours/week), missed opportunities (X% of users affected).
- **Why now?** What changed to make this urgent? A new competitor, growth milestone, regulatory deadline, customer complaint volume?

### Problem Section Template

```
Before working with us, [company] faced [specific problem].
This caused [business impact quantified].
[Stakes]: [what happened when they tried to solve it internally / why it couldn't wait].
```

No vague "they were struggling with inefficiency." Give numbers.

## Approach Section

Explain the decision process, not just the solution. Include:
- **Alternatives considered**: what else did they evaluate, and why was each rejected?
- **Key decision criteria**: what mattered most (cost, speed, scalability, maintainability)?
- **The tipping point**: what made them choose this path?
- **Timeline**: how long from first conversation to decision?

## Solution Section

- Architecture at a high level: diagram helps (Mermaid or simple description)
- Key decisions with rationale: "We chose X over Y because Z"
- Timeline and team size: who built it, how long
- What was specifically built or changed: be specific about components, not "we rebuilt everything"

### Solution Section Template

```
We built [specific thing] using [tech/methodology].
This involved:
- [Key component or decision 1]: [what and why]
- [Key component or decision 2]: [what and why]
- [Key component or decision 3]: [what and why]

The team of [number] delivered this in [timeframe].
```

## Results Section

Every result gets a row in the comparison table:

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Page load time | 4.2s | 1.1s | -74% |
| Conversion rate | 2.1% | 4.8% | +129% |
| Support tickets | 340/mo | 120/mo | -65% |
| Deployment frequency | 1/week | 5/day | +350% |

Rules:
- Use real numbers or don't publish it
- Include both lagging indicators (revenue, cost) and leading indicators (speed, uptime)
- Ranges and percentages are acceptable
- Single data points without context are not
- Show the trend, not just the endpoint (month-over-month if available)
- Cost savings should include the investment (ROI, not just savings)

## Testimonial Placement

Bad: all quotes at the end in a block.

Good: quote about performance next to the performance metric.

```
[Table showing performance improvement]

"Our site went from unusable on mobile to faster than any competitor.
The rebuild paid for itself in three months."

— Sarah Chen, VP Engineering, ShopFlow
```

### Testimonial Requirements

- Real person: full name, title, company. No "Satisfied Client."
- Specific result: "reduced our onboarding time by 60%" not "great experience."
- 1-3 sentences. Long testimonials don't get read.
- Permission in writing to use name, quote, and results.
- Offer anonymity option if needed ([CXO at Fortune 500 company]).

## Case Study Formats

| Format | Best for | Length |
|--------|----------|--------|
| Written (long) | Website, docs, sales collateral | 800-1500 words |
| Written (short) | Email nurture, social proof snippet | 200-300 words |
| Video (2-3 min) | Enterprise sales, landing page | Interview format |
| Infographic | Social media, LinkedIn | Data visualization |
| Slide deck | Sales presentation, conference talk | 5-8 slides |
| Audio clip | Podcast, testimonial page | 60-90 seconds |

## When to Skip

Do not write a case study when:
- Results are not measurable (no data = no credibility)
- Client doesn't want to be named (anonymity limits effectiveness)
- You can't describe the problem honestly (readers will sense it)
- The solution was over-engineered and you can't admit it
- Results are not repeatable (one-off success with lucky timing)
- Client relationship ended poorly (risk of public dispute)

## Distribution Checklist

- [ ] Published on website in a dedicated case studies section
- [ ] One-page PDF version for sales team
- [ ] Social media posts (LinkedIn, Twitter) with key stat in first line
- [ ] Email to relevant segment with link to full study
- [ ] Added to sales deck as proof slide
- [ ] Client approved and signed off
- [ ] Reviewed quarterly for accuracy (numbers may change)

## Anti-Patterns

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| No results section | It's a story, not a case study | Add comparison table |
| Results without context | "We saved 50%" — from what baseline? | Always show before AND after |
| Hiding the client name | Credibility drops to zero | Use real names or skip |
| No screenshots or evidence | Looks made up | Include dashboard screenshots, charts, or data exports |
| No problem definition | Reader doesn't know if it applies to them | Describe the problem specifically |
| Generic happy talk | "They were thrilled with the results" | Use specific metrics |
| Ignoring challenges | Too perfect = not believable | Include obstacles you overcame |
| No testimonial near the CTA | No social proof at the decision point | Place a testimonial near the final CTA |

## Sources

- HubSpot case study templates and methodology
- Salesforce case study best practices
- Nielsen Norman Group case study research — credibility factors
- Conversion copywriting frameworks (Copyhackers, Joanna Wiebe)
- Gartner "B2B Buyer Enablement Study" — how buyers use case studies
- MECLab "Case Study Format Testing" — what drives conversion
- Content Marketing Institute — B2B case study benchmarks
- Harvard Business Review "How to Write a Compelling Case Study"
