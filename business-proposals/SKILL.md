---
name: business-proposals
description: Generate sales outreach sequences, proposals, SOWs, investor pitch decks, and RFP responses. Covers cold email sequences, proposal structure, pricing tiers (Good-Better-Best), scope of work with exclusions, and 10-slide pitch deck. Use when user asks to write a proposal, cold email, pitch deck, investor deck, SOW, sales outreach, or respond to RFP. Do NOT use for general corporate communication (use communication), content marketing (use content-marketing), or brand design (use design).
license: MIT
compatibility: opencode
metadata:
  workflow: sales
  audience: consultants
  version: "2.0"
---

# Business Proposals

Win deals and raise funding. Covers the full pipeline: outreach, proposals, and pitch decks.

## Sales Outreach

### Required Discovery
1. **Prospect**: Company + person + role
2. **Trigger**: Why now? (funding, product launch, job change)
3. **Value prop**: "We help [X] do [Y] so they can [Z]"
4. **Proof**: Case study, testimonial, data point, mutual connection
5. **Goal**: Reply? Call? Demo? Trial?

### Cold Email Structure
1. **Subject**: Personalized + curiosity gap. 10 words max.
2. **Opening**: Specific reference to them (news, post, achievement)
3. **Value prop**: One sentence. Their benefit, not your features.
4. **Proof**: Social proof or relevant data point.
5. **Ask**: Single, low-friction next step.
6. **Close**: Simple. "Best, [Name]"

### Subject Line Patterns
| Pattern | Example |
|---------|---------|
| Reference | "[Company] + [observation]" |
| Question | "Quick question about [situation]" |
| Compliment | "Impressed by [achievement]" |
| Mutual connection | "[Name] suggested I reach out" |

### Personalization Levels (ALL required)
1. **Company**: Recent news, funding, launch
2. **Person**: Recent post, talk, job change, GitHub activity
3. **Fit**: Why this matters to THEM specifically

If you cannot do level 2, do not send the email.

### Sequence Logic
```
Email 1 (Day 1):  Value prop + low-friction ask
Email 2 (Day 4):  Follow-up with additional value
Email 3 (Day 8):  Different angle or case study
Email 4 (Day 12): Breakup — leave door open
```

4 emails max. No response in 12 days → move to nurture.

## Proposals

### Required Discovery
| Question | Why |
|----------|-----|
| What problem needs solving? | Problem statement anchors the proposal |
| What is the solution? | Scope definition |
| What are the deliverables? | Tangible output client expects |
| What is excluded? | Prevents scope creep |
| What is the budget range? | Pricing tier selection |

### Executive Summary
```
[Client] needs to [solve specific problem].
We propose to [solution overview] over [timeline] for [price].
This achieves [outcome 1], [outcome 2], [outcome 3].
```
One paragraph. This is the only section most decision-makers read.

### Scope of Work
**Included**: features, revision rounds, deliverables (docs, source, deployment)
**Excluded** (critical): hosting, maintenance, content creation, third-party licenses, training
**Assumptions**: client access, decision-maker availability, feedback turnaround, frozen requirements after sign-off

### Timeline
| Phase | Duration | Activities | Deliverable |
|-------|----------|------------|-------------|
| Discovery | Week 1 | Interviews, audit, requirements | Requirements doc |
| Build | Weeks 2-4 | Implementation in sprints | Working build |
| Review | Week 5 | QA, revisions, acceptance | Reviewed build |
| Deploy | Week 6 | Production deployment, docs | Live system |

Add 20% buffer for unknowns.

### Pricing (Good-Better-Best)
- **Core**: essential features, basic revisions, standard timeline
- **Recommended** (best value): everything in Core + extras + priority support
- **Enterprise**: everything + premium features + dedicated team + ongoing support

Payment terms: 50% deposit, 25% midpoint, 25% delivery. Net 30.

### Risk Reduction
| Risk | Mitigation |
|------|-----------|
| Will they deliver? | Portfolio item similar to this project |
| Does it work? | Case study with measurable results |
| What if it fails? | Guarantee (satisfaction, timeline) |

## Pitch Decks

### The 10 Slides (Sequoia/Y Combinator)

| # | Slide | Emotion | Investor question |
|---|-------|---------|-------------------|
| 1 | Title | — | Company, tagline, founder |
| 2 | Problem | Pain | Is this real? How bad? |
| 3 | Solution | Hope | Is it compelling? |
| 4 | Market | Ambition | Is it big enough? |
| 5 | Product | Excitement | Does it work? |
| 6 | Traction | Proof | Is anyone using it? |
| 7 | Business model | Confidence | Does the business make sense? |
| 8 | Competition | Trust | Can they win? |
| 9 | Team | Conviction | Is this the right team? |
| 10 | Ask | Urgency | How much? What for? |

### Content Rules
- One slide, one idea. Max 20 words per slide (except traction).
- No bullet points. Font min 24pt content, 36pt headlines.
- Images > text for product slides. 3 seconds per slide max.
- PDF format, 5MB max.

### Traction Benchmarks
| Stage | Key metric | Benchmark |
|-------|-----------|-----------|
| Pre-seed | Problem validation | 50+ interviews, 500+ waitlist |
| Seed | Engagement | 10k+ MAU, 30%+ weekly retention |
| Series A | Revenue | $1M+ ARR, <20% monthly churn |
| Series B | Growth + unit economics | 3x YoY, LTV/CAC > 3 |

### Ask Slide Format
```
Raising [$X] at [$Y valuation]

Use of funds:
→ [%] Engineering
→ [%] Go-to-market
→ [%] Operations
→ [%] Reserve (6-month runway)

Milestones 18 months: [metrics from → to]
```

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| No personalization beyond [Name] | Don't send |
| No exclusions in proposal | Client assumes everything included → scope creep |
| Single pricing option | No frame of reference, client demands discount |
| No traction in deck | "We just launched" is not traction |
| No clear ask | "We're raising a round" without specifics |
| Too many words on slides | Investor stops reading |
| 5-year projections pre-revenue | 12-18 months is credible |

## Sources

- Sequoia Capital pitch deck template
- Y Combinator Startup School
- DocSend "Pitch Deck Study"
- Close.com outbound sales research
- AIGA agency proposal best practices
- B2B pricing psychology research
