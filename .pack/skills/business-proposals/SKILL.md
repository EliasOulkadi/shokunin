---
name: business-proposals
description: Generate sales outreach sequences, proposals, SOWs, investor pitch decks, and RFP responses. Covers cold email sequences, proposal structure, pricing tiers (Good-Better-Best), scope of work with exclusions, and 10-slide pitch deck.
triggers:
  - "write a proposal"
  - "cold email / outreach sequence"
  - "pitch deck / investor deck"
  - "SOW / statement of work"
  - "sales outreach / prospecting"
  - "respond to RFP"
  - "scope of work"
  - "client proposal"
negatives:
  - general corporate communication (use communication skill)
  - content marketing / blog posts (use content-marketing skill)
  - brand design / creative direction (use brand-design skill)
  - financial models / spreadsheets (use finance skill)
  - legal contracts / terms of service (use legal-counsel skill)
license: MIT
compatibility: opencode
metadata:
  version: "3.0.0"
metadata:
  workflow: sales
  audience: consultants, founders, freelancers
  version: "3.0.0"
---


# Business Proposals v3.0

Win deals and raise funding. Covers the full pipeline: outreach, proposals, and pitch decks.

## Workflow

When the user asks for any sales document, follow this process:

1. **Clarify stage**: Outreach (cold) → Proposal (warm) → Pitch deck (investor)? Ask if unclear.
2. **Gather context**: Run discovery questions for the specific stage (sections below).
3. **Select template**: Match the deliverable to the appropriate structure below.
4. **Draft**: Fill template with user-provided info. Use placeholders `[like this]` for unknowns.
5. **Review**: Check against error handling table and production checklist.
6. **Verify anti-patterns**: Scan the anti-patterns table — if any match, fix before delivery.
7. **Output**: Return the completed document in the requested format (text, markdown, email body).

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

## Error Handling

| Situation | Resolution |
|-----------|------------|
| User gives no prospect info | Ask: "Who is the target? Company, person, role?" |
| User gives no budget | Use "investment" language: "Typical engagements $X-$Y" |
| User has no case studies | Use "we've helped similar companies achieve [generic result]" |
| User has no traction data | Focus on problem validation: interviews, surveys, waitlist |
| User wants pricing without scope | Ask: "What deliverables do you need?" then tier pricing |
| User provides 5-year projections pre-revenue | Cap at 12-18 months. "That's our credible horizon." |
| User's RFP is vague or contradictory | Flag contradictions back. "I see X and Y — which takes priority?" |
| Multiple decision-makers with conflicting needs | Ask: "Who has final authority? I'll address their concern first." |
| User wants one price (no tiers) | Explain Good-Better-Best creates reference frame and increases close rate |
| User wants to pitch without problem slide | "No problem = no reason to invest. Always lead with pain." |

## Production Checklist

Before delivering any document, verify:

- [ ] Personalization: company + person + specific reason (outreach)
- [ ] Exclusions listed in scope (proposals)
- [ ] Pricing has at least 3 tiers (proposals)
- [ ] Cover letter or intro paragraph written (proposals, RFP)
- [ ] Slides: one idea per slide, ≤20 words, ≥24pt font (decks)
- [ ] Ask slide: specific amount + use of funds + milestones (decks)
- [ ] Traction or validation data present (decks)
- [ ] Contact info and CTA included (all)
- [ ] PDF export ≤5MB (decks)
- [ ] Proofread for placeholder tokens — no `[unknown]` left in final

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| No personalization beyond `[Name]` | Don't send. Requires company + person + fit level |
| No exclusions in proposal | Client assumes everything included → scope creep |
| Single pricing option | No frame of reference → client demands discount |
| No traction in deck | "We just launched" is not traction. Use validation data. |
| No clear ask | "We're raising a round" without specifics → no urgency |
| Too many words on slides | Investor stops reading. 20 words max per slide. |
| 5-year projections pre-revenue | 12-18 months is credible. Beyond that is fiction. |
| Sending outreach without trigger | "Why now?" missing → immediate delete |
| Pricing before value explained | Always state problem + solution + outcome before price |
| Generic subject lines | "Let's connect" / "Partnership opportunity" → spam folder |

## Pricing Psychology

### Good-Better-Best
| Tier | Role | Price anchor |
|------|------|-------------|
| Good | Makes Best look reasonable | 30-40% below Best |
| Better | The one you want them to buy | Midpoint (highlighted/default) |
| Best | Price anchor | Highest |

### Decoy Effect
Add a third option that makes the target option look better: Option A ($10, basic) + Option B ($25, pro) + Option C ($24, pro-lite) → C makes B look like a deal.

### Bundling
Bundle complementary services at 20-30% discount vs individual. Never discount individual items below bundled price.

### Legalese Templates
"Payment terms: Net 30. Late payments accrue 1.5% monthly. All deliverables remain property of Provider until full payment. Either party may terminate with 30 days written notice. Liability capped at fees paid in prior 12 months."

## Sources
- Sequoia Capital pitch deck template
- Y Combinator Startup School
- DocSend "Pitch Deck Study"
- Close.com outbound sales research
- AIGA agency proposal best practices
- B2B pricing psychology research

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
