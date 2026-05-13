---
name: communication
description: Draft professional emails, feedback (SBI/BID), difficult conversations, meeting notes, and escalation templates. Covers tone matrix, cross-cultural communication, Slack/Teams async patterns, and structured notes from raw transcripts. Use when user asks to write an email, draft feedback, handle a difficult conversation, create meeting notes, escalate an issue, or compose any corporate communication. Do NOT use for sales outreach (use business-proposals), translation (use translate-craft), or content marketing (use content-marketing).
license: MIT
compatibility: opencode
metadata:
  workflow: communication
  audience: developers
  version: "2.0"
---

# Communication

Professional writing for every workplace scenario. Based on Harvard Business Review, Radical Candor, Crucial Conversations, and Amazon Working Backwards.

## Tone Matrix

| Context | Tone | Salutation | Closing |
|---------|------|------------|---------|
| Internal peer | Casual-direct | "Hi [Name]" | "Thanks" |
| Internal manager | Professional | "Hi [Name]" | "Thanks" |
| Cross-team | Professional | "Hi [Name]" | "Best" |
| Client (established) | Cordial | "Hi [Name]" | "Best regards" |
| Client (new) | Formal-cordial | "Dear [Name]" | "Best regards" |
| Executive / VP+ | Formal | "Dear [Title] [Last]" | "Sincerely" |
| Escalation | Firm, respectful | "Hi [Name]" | "Regards" |
| Complaint | Calm, professional | "Hi [Name]" | "Best regards" |

## Email Structure

1. **Subject**: [Verb] + [Topic]. "Request: Q3 budget approval". Max 50 chars.
2. **Context**: reference previous communication in one sentence
3. **Purpose**: the ask or update in the first paragraph
4. **Detail**: supporting info, bulleted if > 3 items
5. **Next step**: who does what by when
6. **Closing**: matched to relationship

### Subject Line Rules

- Keep under 50 characters (mobile truncates at 40)
- No ALL CAPS, no exclamation marks, no "URGENT" unless system is down
- Prefix pattern: `[Request/Update/Follow-up/Escalation]: [topic]`
- Specific enough to distinguish from other threads

### Filler Phrases to Delete

| Delete | Replace with |
|--------|-------------|
| "I hope this email finds you well" | Nothing |
| "I just wanted to reach out" | State the purpose |
| "Per my last email" | Restate the ask directly |
| "Just checking in" | "Following up on [specific]" |

### Templates

See [assets/templates/](assets/templates/) for full collection:
- Escalation
- Saying no
- Status update to executive
- Project delay
- Client communication

## Asynchronous Communication (Slack/Teams)

| Channel | Best for | Avoid for |
|---------|----------|-----------|
| Public channel | Team updates, decisions, questions | Sensitive feedback, 1:1s |
| Direct message | Quick questions, personal coordination | Decisions that should be visible to team |
| Thread | Follow-ups on specific topics | New topics (start new thread) |
| Loom / video | Complex explanations, walkthroughs | Simple yes/no questions |

### Writing for async

- One topic per message. If you need two things, send two messages.
- Include context in first message (don't make them ask "which part?")
- Use threads for answers, not new messages
- Set status / expectations: "No rush" or "By EOD"
- Max 2 paragraphs. Longer → Loom or document

## Difficult Conversations

### Framing Principles

- Separate person from problem: attack the issue, not the individual
- State your intent first: "I want to talk about [topic] so we can [outcome]"
- Describe the gap: what was expected vs what happened
- Propose a path forward: not just the problem, but the solution

### Tone by Emotion

| Emotion | Do | Don't |
|---------|----|-------|
| Frustrated | State facts, propose solution | Blame, generalize |
| Disappointed | Express specifically, offer path | Guilt trip, passive-aggression |
| Urgent | Name deadline, state consequence | ALL CAPS, threats |
| Apologetic | Apologize once, focus on fix | Over-apologize, deflect |

### Constraints

- No threats (unless legal/compliance)
- No ultimatums without offering an alternative
- No apologizing for things outside your control
- Never respond to angry emails within 1 hour (draft, wait, revise)
- One ask per email

## Feedback (SBI Model)

- **Situation**: when and where
- **Behavior**: what exactly was said/done (observable, not interpreted)
- **Impact**: what effect it had

### Feedback by Type

| Type | Format | When |
|------|--------|------|
| Reinforcement | SBI | Immediately after positive behavior |
| Redirect | SBI + BID (Behavior-Impact-Desired) | Soon after, in private |
| Growth | SBI + opportunity | During 1:1s |
| Appreciation | SBI | Publicly or in 1:1 |

### Delivery Rules

- Give feedback as close to the event as possible
- Focus on actions, not personality
- End with a question: "Does that resonate?"
- Negative feedback always in private
- Ask permission: "Can I share some feedback?"
- One topic per session
- No "you always" or "you never"
- No comparison to others

## Meeting Notes

Every meeting produces four things:
1. **Decisions** — what was agreed
2. **Action items** — who does what by when
3. **Open questions** — unresolved, with owner
4. **Risks** — anything that could block progress

### Format

```
## [Topic] — [Date]

## Summary
One paragraph. A non-attendee should understand what happened.

## Decisions
- [DECIDED] We will use X instead of Y because Z

## Action Items
| Owner | Task | Due |
|-------|------|-----|
| @name | Task description | 2026-05-15 |

## Open Questions
- [QUESTION] ... → @owner to decide by Friday

## Risks
- Risk description → mitigation
```

### Formatting Rules

- Each action item must have a named owner and deadline
- Prefix with [DECIDED], [ACTION], [QUESTION]
- Dates in ISO format (2026-05-12). No "next week" or "tomorrow"
- Notes sent within 2 hours of meeting end

## Cross-Cultural Communication

| Culture | Communication style | Email approach |
|---------|-------------------|----------------|
| US/UK | Direct, task-focused | Clear ask, bullet points |
| Japan | Indirect, relationship-first | Polite preamble, implicit ask |
| Germany | Direct, formal | Structured, complete information |
| France | Debate-oriented, formal | Context first, then ask |
| Brazil | Warm, relationship-first | Personal greeting, then business |

## Constraints

- Max 150 words internal, 200 for client emails
- No passive-aggressive language
- No assigning blame to a person ("the deployment failed" not "you failed")
- Signature: Name, Title, Company, Phone. No quotes, no ASCII art.

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| No clear ask | State what you need explicitly |
| Passive voice in feedback | SBI model — specific and direct |
| Reply-all for 1:1 matters | DM or email to relevant person only |
| Long meeting notes | 4 sections. Extract signals, discard water-cooler |
| Sending when emotional | Draft, wait 1 hour, revise, send |
| No subject line | [Action/Update/Request]: [Topic] |

## Sources

- Harvard Business Review communication guides
- Radical Candor by Kim Scott
- Crucial Conversations by Patterson et al.
- Center for Creative Leadership — SBI model
- Amazon Working Backwards methodology
- Basecamp Shape Up — Meeting practices
- Thanks for the Feedback by Stone & Heen
- Google Project Aristotle — psychological safety
