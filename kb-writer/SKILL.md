---
name: kb-writer
description: Create knowledge base articles for support
---

Create knowledge base articles that solve user problems without escalation. Based on Zendesk, Notion, Intercom, and Help Scout documentation standards and support efficiency research.

## Article Format

```
Title: as a question or problem the user would search for
Context: 1-2 sentences — who is this for, what product/feature
Steps: numbered, one action per step
Expected result: what happens after the last step
Escalation: what to do if it still doesn't work
```

## Title Patterns

| Pattern | Example | Use case |
|---------|---------|----------|
| How to [verb] [noun] | "How to reset your password" | Procedural task |
| Troubleshooting [problem] | "Login fails after password reset" | Error resolution |
| What is [feature] | "What is two-factor authentication" | Explanation |
| Complete guide to [topic] | "Complete guide to workspace permissions" | Complex feature |
| [Feature] overview | "Dashboard overview" | Product tour |
| [Error message] | "Error: 'Payment declined'" | Known error |
| Setting up [feature] | "Setting up Slack integration" | Onboarding |
| Best practices for [topic] | "Best practices for data exports" | Advanced use |

## Writing Rules

| Rule | Why | Example |
|------|-----|---------|
| One action per step | Reduces cognitive load, fewer errors | "Click 'Save' in the top-right corner" not "Click 'Save' and then confirm" |
| Start each step with an action verb | Clear, imperative, scannable | "Navigate to Settings → Workspace" |
| Bold UI labels exactly as they appear | Matches what user sees on screen | "Click **Publish**" (not "publish button") |
| No jargon when plain language works | Reduces confusion for non-technical users | "Turn off notifications" not "Disable push notification service" |
| Maximum 15 words per step | Forces conciseness | "Enter your email address in the field labeled 'Email'" |
| Numbered lists for sequential steps | Users can follow in order, know where they are | 1. ... 2. ... 3. ... |
| Bullet lists for non-sequential items | No implied order, no wrong sequence | Supported formats: |
| Include expected result after each step | User confirms they're on the right track | "The page reloads and shows 'Settings saved'" |

## Troubleshooting Flow

```
Problem: symptom the user reports (exactly as they'd describe it)

Step 1: Quick fix (under 10 seconds)
- Refresh, retry, restart

Step 2: Common fix (solves ~80% of cases)
- Check settings, permissions, clear cache

Step 3: Advanced fix (remaining cases)
- Logs, API checks, manual configuration

Still stuck:
- "Contact support with:"
- Error message (exact text, not "it said error")
- When it started
- Steps to reproduce
- Browser/OS version
```

### Troubleshooting Title Patterns

| Good title | Bad title |
|-----------|-----------|
| "Can't log in after changing password" | "Login issues" |
| "Payment declined with 'Insufficient funds'" | "Error in payment" |
| "Exports fail on Safari browser" | "Export not working" |
| "Email notifications not sending to Gmail" | "Email problem" |

## Article Metadata

| Field | Requirement | Example |
|-------|-------------|---------|
| Title | 50-80 characters | "How to reset your workspace password in 3 steps" |
| Description | 120-155 characters, includes target keywords | "Learn how to reset your password in the workspace settings. Takes 2 minutes and works on any device." |
| Category | Fits existing hierarchy | Settings & Account → Authentication |
| Tags | 3-5 synonyms users might search | "password reset, forgot password, login help, account recovery" |
| Last updated | ISO date | "2026-05-12" |

## Article Types

### Procedural (How-to)
```
How to [do specific thing]

1. Go to [location]
2. Click [button/link]
3. Enter [value]
4. Click [save/confirm]
→ [expected result]
```

### Troubleshooting
```
[Problem] — [specific symptom]

1. Quick fix: [10-second solution]
2. Common cause: [80% fix with explanation]
3. Advanced: [if steps 1-2 don't work]
Still having issues? [escalation path]
```

### Reference
```
What is [feature]?

[One-paragraph definition. What it does. Who needs it. Why it exists.]

## Key concepts
- [Term 1]: [1-sentence definition]
- [Term 2]: [1-sentence definition]

## How it works
[Short explanation with simple diagram or example]

## Related articles
- [Link to related article 1]
- [Link to related article 2]
```

### Announcement
```
[Feature/Change] is now available

## What changed
[1-2 sentence summary]

## How it affects you
[Impact on existing workflows]

## What you need to do
[Actions required, if any]

## Timeline
[Release dates, deprecation dates]
```

## KB Maintenance Schedule

| Task | Frequency | Owner |
|------|-----------|-------|
| Review articles | Every 6 months | Product team |
| Update screenshots | When UI changes | Design team |
| Check search queries returning nothing | Monthly | Support team |
| Rewrite articles with low CSAT | Monthly | Content team |
| Archive articles for deprecated features | When feature is removed | Product team |
| Audit broken internal links | Quarterly | Content team |

## Knowledge Base Quality Metrics

| Metric | Target | How to measure |
|--------|--------|----------------|
| Article CSAT | > 85% satisfied | "Was this helpful?" thumbs up/down after each article |
| Search success rate | > 70% find what they need | Internal search analytics |
| Deflection rate | > 15% ticket reduction | Tickets mentioning "saw article / still need help" |
| Article age | < 12 months since last update | KB audit report |
| Click-through rate | > 30% from search results | Search analytics |
| Average read time | 2-5 minutes per article | Analytics |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Steps that assume user knowledge | Spell out every action — "Click the blue button labeled Save" |
| Multiple actions in one step | Break into individual steps. One action = one step. |
| Vague error messages | Include exact error text. Screenshots help. |
| No expected result after steps | User doesn't know if they succeeded. Add "→ You'll see..." |
| Article too long (over 10 steps) | Split into multiple articles or add a table of contents |
| Outdated screenshots | Users lose trust when UI doesn't match |
| Passive voice in instructions | "Click Save" not "The Save button should be clicked" |
| "See above" or "as mentioned earlier" | Don't make users scroll. Repeat or link. |
| No escalation path | Users who aren't helped by the article end up frustrated |

## Sources

- Zendesk Guide best practices — knowledge base structure and SEO
- Help Scout documentation standards — clarity and conciseness
- Intercom article writing guide — conversational support tone
- Notion documentation style guide — internal knowledge base patterns
- Moz SEO fundamentals for knowledge base articles
- Nielsen Norman Group "Writing for the Web" research
- Jared Spool "The Micro-Journeys of Support" — user support flow research
