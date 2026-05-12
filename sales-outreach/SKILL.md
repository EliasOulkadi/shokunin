---
name: sales-outreach
description: Generate cold and warm outreach emails that get replies. Use when user asks to write a sales email, outreach sequence, cold email, follow-up, LinkedIn message, or prospecting message. Triggers on "write an outreach email", "cold email template", "sales sequence", "follow-up message", "reach out to [prospect]", "draft a prospecting email". Do NOT use for internal team communication, support replies, or transactional emails like invoices and receipts. Based on Close.com research, SalesHacker data, and outbound sales analysis.
license: MIT
compatibility: opencode
metadata:
  workflow: sales
  audience: sales
---

Generate outreach sequences that get replies. Follow the template below, then personalize based on user's context.

## Required Discovery

Before writing, determine:
1. **Prospect**: Company + person + their role
2. **Trigger**: Why now? (funding, post, product launch, job change)
3. **Value prop**: One sentence: "We help [X] do [Y] so they can [Z]"
4. **Proof**: Case study, testimonial, data point, or mutual connection
5. **Goal**: Reply? Call? Demo? Trial?

## Cold Email Structure

1. **Subject line**: Personalized + curiosity gap. 10 words max.
2. **Opening**: Specific reference to them. (company news, their post, achievement, mutual)
3. **Value proposition**: One sentence. Their benefit, not your features.
4. **Proof**: Social proof or relevant data point.
5. **Ask**: Single, low-friction next step.
6. **Close**: Simple. No pressure. "Best, [Name]"

## Subject Line Patterns

| Pattern | Example | Best For |
|---------|---------|----------|
| Reference | "[Company] + [specific observation]" | Always, minimum viable |
| Question | "Quick question about [their specific situation]" | Curiosity, high open rate |
| Compliment | "Impressed by [specific achievement]" | Warm outreach, use genuinely |
| Resource | "[Common problem] — a fix we found" | Value-led, low pressure |
| Mutual connection | "[Name] suggested I reach out" | Warm intro, highest conversion |

## Personalization Rules

3 levels of personalization. ALL required before sending:

| Level | What | Examples |
|-------|------|----------|
| 1 — Company | Recent news, funding, product launch, hiring spree | "Congrats on the Series A" |
| 2 — Person | Recent post, talk, job change, GitHub activity | "Loved your post on API design" |
| 3 — Fit | Why this matters to THEM specifically | "Given you're scaling to 3 markets..." |

If you cannot do level 2, do not send the email. Generic outreach gets ignored.

## Sequence Logic

```
Email 1 (Day 1):   Value prop + low-friction ask
                   Goal: start a conversation

Email 2 (Day 4):   Follow-up with additional value
                   Goal: provide new info, don't repeat

Email 3 (Day 8):   Different angle or case study
                   Goal: show proof it works

Email 4 (Day 12):  Breakup email
                   Goal: leave door open gracefully
```

**Between emails**: Engage on LinkedIn (like, comment on posts — no DM).

**Hard stop**: 4 emails max. No response in 12 days → move to nurture.

## Templates

### Cold Outreach (Day 1)
```
Subject: [Observation about their company/work]

Hi [Name],

I noticed [specific observation]. [One sentence on why this matters.]

We helped [similar company] achieve [measurable result] by [your solution].

Would you be open to a 10-min chat next week? I have ideas specific to [their situation].

Best,
[Your name]
```

### Follow-up with Value (Day 4)
```
Subject: Re: [original subject]

Hi [Name],

Following up. I also wanted to share [specific resource relevant to them]:

[One-liner about the resource and why it applies to their situation]

Happy to walk through how this applies to your setup if useful.

Best,
[Your name]
```

### Case Study (Day 8)
```
Subject: Re: [original subject]

Hi [Name],

[Company X] was facing [same problem]. They used [approach] and got [result with numbers].

Key insight: [one thing that made it work].

Worth a quick call to see if this applies to you?

Best,
[Your name]
```

### Breakup (Day 12)
```
Subject: Re: [original subject]

Hi [Name],

I'll leave it here. If your priorities change, feel free to reach out — happy to help anytime.

Best,
[Your name]
```

## LinkedIn Outreach Rules

- Do NOT connect + DM on the same day
- Engage with their content for 3-5 days before connecting
- Connection request note: reference-based, no sales pitch
- After accepted: wait 2-3 days before sending a message

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| "I hope this email finds you well" | Delete. Start with substance. |
| "I wanted to reach out" | Reduce filler by 50%. Just say what you want. |
| Multiple questions (What's your process? Who decides? Budget?) | One ask per email. |
| Attachments | No attachments unless explicitly requested. |
| Fake urgency ("limited time") | Only if genuinely time-sensitive. |
| LinkedIn + email same day | Pick one channel per 3-day window. |
| No personalization | If you can't personalize beyond [Name], don't send. |

## Sources
- Close.com outbound sales research
- SalesHacker cold email data analysis
- Outreach.io sequencing studies
- Lavender AI email analysis
