---
name: proposal-gen
description: Generate technical proposals for consulting, agency, and custom software projects. Includes scope, timeline, pricing, terms, and risk reduction. Use when user asks to write a proposal, SOW, statement of work, project quote, engagement letter, or bid response. Triggers on "write a proposal", "create a SOW", "scope this project", "estimate this work", "respond to an RFP", "quote for [project]". Do NOT use for internal project briefs, product specs, or architecture docs. Based on B2B proposal patterns from agency and consulting best practices.
license: MIT
compatibility: opencode
metadata:
  workflow: sales
  audience: consultants
---

Generate proposals that win deals by reducing uncertainty and making the next step obvious.

## Required Discovery

Before writing, determine:

| Question | Why it matters |
|----------|----------------|
| What problem does the client need solved? | Problem statement anchors the proposal |
| What is the proposed solution? | Scope definition |
| What is the timeline? | Feasibility check |
| What are the deliverables? | Tangible output client expects |
| What is excluded? | Prevents scope creep |
| What is the budget range? | Pricing tier selection |
| What risk reduction can you offer? | Removes buyer objections |

## Executive Summary

```
[Client Name] needs to [solve specific problem].
We propose to [solution overview] over [timeline] for [price].
This achieves [outcome 1], [outcome 2], and [outcome 3].
```

One paragraph. No more. This is the only section most decision-makers read.

## Scope of Work

### Included
- [Feature/Service A]: detailed description
- [Feature/Service B]: detailed description
- [Number] revision rounds
- [Deliverables]: documentation, source code, deployment

### Excluded (critical — prevents scope creep)
- Hosting and infrastructure
- Ongoing maintenance beyond warranty period
- Content creation (copy, images, videos)
- Third-party license costs
- Training (unless explicitly included)

### Assumptions
- Client provides access to existing systems within [N] days of kickoff
- Decision maker available for weekly 30-min check-ins
- Requirements frozen after sign-off; changes via change order
- Client provides feedback within [N] business days per revision round

## Timeline

| Phase | Duration | Activities | Deliverable |
|-------|----------|------------|-------------|
| Discovery | Week 1 | Stakeholder interviews, system audit, requirements | Requirements document, wireframes |
| Build | Weeks 2-4 | Implementation in [N] sprints | Working implementation |
| Review | Week 5 | QA, revisions, acceptance testing | Reviewed build |
| Deployment | Week 6 | Production deployment, documentation | Live system, handoff docs |

Buffer: add 20% to timeline for unknowns.

## Pricing

Offer 3 options. The middle one is your real offer.

### Option 1: Core
**$X,XXX**
- [Essential features]
- [Revision rounds]
- [Timeline]

### Option 2: Recommended (best value)
**$X,XXX**
- Everything in Core, plus
- [Additional features]
- [Extra revisions]
- [Priority support]

### Option 3: Enterprise
**$X,XXX**
- Everything in Recommended, plus
- [Premium features]
- [Dedicated team]
- [Ongoing support, N weeks]

**Payment terms**: 50% deposit to start, 25% at midpoint, 25% on delivery.
**Net 30** on final payment.

## Risk Reduction

| Risk | Mitigation |
|------|-----------|
| Will they deliver? | Portfolio item similar to this project |
| Does it work? | Case study with measurable results |
| Are they reliable? | Testimonial from relevant client |
| What if it fails? | Guarantee (satisfaction, timeline, or money-back) |
| Who else trusts them? | References available on request |

## Next Steps

```
1. Sign this proposal (reply with "I accept" or use [e-sign tool])
2. Pay [percentage] deposit via [payment method]
3. We schedule kickoff within 48 hours of deposit
4. First deliverable in [timeframe]

Questions? Reply to this email or book 15 min: [calendar link]
```

## Terms

- **Duration**: Proposal valid for 30 days from date of issue
- **Revisions**: [N] rounds included; additional rounds billed at [$X/hr]
- **Cancellation**: Client may cancel with [N] days written notice; work completed to date billed at hourly rate
- **IP**: Full IP transfer upon final payment. Pre-existing IP remains with each party.
- **Confidentiality**: Both parties agree to NDA terms attached.

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| No exclusions | Client assumes everything is included → scope creep |
| Single option | No frame of reference; client demands discount |
| No risk reduction | Client finds reasons to say no |
| Vague timeline | Client assumes everything is urgent |
| No next steps | Proposal sits in inbox forever |

## Sources
- Agency proposal best practices (AIGA)
- B2B pricing psychology research
- Consulting engagement methodologies
- Harvard Business Review: pricing strategy
