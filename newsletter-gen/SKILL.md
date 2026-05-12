---
name: newsletter-gen
description: Generate newsletters that get opened
---


# Newsletter Gen

Generates email newsletters that perform. Based on data from Mailchimp, Campaign Monitor, Twilio SendGrid, and Gartner email marketing research (2025-2026).

## The Four Decisions

Every newsletter needs four decisions before writing a word:

1. **Goal** — what does this email need to accomplish? (one thing)
2. **Audience** — who is reading this? (one person, not a segment)
3. **Channel** — is email the right medium for this message?
4. **Measure** — what metric determines success? (open, click, reply, conversion)

## Subject Line Architecture

| Type | Formula | Open rate impact |
|------|---------|-----------------|
| Curiosity | "The [X] that nobody tells you about" | High |
| Utility | "[Number] [topic] patterns I use" | Medium |
| Personal | "What I learned about [topic] this month" | Medium |
| Urgent | "[Deadline] for [opportunity]" | High (use <1/month) |

Rules:
- 30-50 characters. Mobile cuts off after 40 in Gmail.
- Start with a verb or a number. Not a filler word.
- No ALL CAPS, no exclamation marks, no clickbait.
- A/B test subject lines with 20% of list before full send.

## Structure

```
Preheader: 85-100 characters, extends the subject line
  ? Greeting (personalized if you have the data)
  ? Primary item (the reason they should open)
  ? Supporting items (2-3, scannable)
  ? One CTA (button, not text link)
  ? Footer (unsubscribe, address, privacy)
```

## Content Rules

- 200-400 words for a digest. Up to 1000 for a deep dive.
- One CTA per email. Not two. Not three.
- Write to one person. Not "our readers" — "you".
- Bold the key takeaway. Let skimmers get the point.
- Images are optional. If you use one, include alt text.

## Deliverability Checklist

Google and Yahoo require as of 2025:
- [ ] SPF, DKIM, DMARC configured
- [ ] Spam complaint rate below 0.1%
- [ ] Unsubscribe processed within 48 hours
- [ ] List cleaned of inactive subscribers (6+ months)
- [ ] No spam trigger words (free, guarantee, act now)
- [ ] Text version alongside HTML
- [ ] Mobile-responsive template
- [ ] From name is a person, not a company

Source: Twilio SendGrid, mySMTP 2025, Google/Yahoo sender guidelines.

## Engagement Benchmarks

| Metric | Good | Needs work |
|--------|------|------------|
| Open rate | 25-40% | Below 20% |
| Click rate | 2-5% | Below 1% |
| Bounce rate | Under 3% | Over 5% |
| Unsubscribe | Under 0.5% | Over 1% |
| Spam complaint | Under 0.1% | Over 0.1% |

## Anti-Patterns

- Sending without SPF/DKIM/DMARC (emails go to spam)
- Buying email lists (ruins sender reputation permanently)
- Image-only emails (most clients block images by default)
- No plain text version (spam filters flag HTML-only)
- "Just checking in" follow-ups (add value or don't send)

## Sources

- Twilio SendGrid deliverability best practices (2025)
- Campaign Monitor newsletter benchmarks
- Mailjet "Email Marketing Trends 2026"
- Gartner "Future of Marketing: 5 Trends for 2026"
- Google/Yahoo sender requirements (2025)
- Statista email user data 2026








