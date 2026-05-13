---
name: communication
description: >
  Draft professional emails, feedback (SBI/BID), difficult conversations, meeting
  notes, and escalation templates. Covers tone matrix, cross-cultural
  communication, Slack/Teams async patterns, and structured notes from raw
  transcripts.

  Trigger phrases: "write an email", "draft feedback", "difficult conversation",
  "meeting notes", "escalate", "compose a message", "corporate email", "feedback
  for [person]", "créame un correo", "tone check", "reply to this email", "say
  no to a client", "status update to exec", "project delay email", "cold email
  to [person]", "async message", "Slack message", "teams message", "follow-up
  email", "meeting agenda", "meeting summary".

  Negative triggers:
    "sales outreach", "cold email sequence", "proposal", "SOW", "pitch deck",
    "investor deck" → delegate to business-proposals skill.
    "translate", "translation", "localize", "traducir" → delegate to
    translate-craft skill.
    "blog post", "newsletter", "Twitter thread", "case study", "marketing copy"
    → delegate to content-marketing skill.
license: MIT
compatibility: opencode 1.0+
metadata:
  version: "3.0"
  workflow: communication
  audience: developers
  allowed-tools:
    - read
    - write
    - edit
    - grep
    - glob
    - bash
    - webfetch
    - websearch
    - skills
---

# Communication

Professional writing for every workplace scenario. Based on Harvard Business Review, Radical Candor, Crucial Conversations, and Amazon Working Backwards.

## Procedural Workflow

Follow these steps in order. Skip steps only when context doesn't apply.

**Step 1 — Identify audience & context**
- Who is the recipient? What is your relationship?
- What is their communication style (direct/indirect, formal/casual)?
- What is the power dynamic (peer, manager, report, client, exec)?
- What has happened before this communication?

**Step 2 — Choose tone from matrix**
- Look up the recipient type in the Tone Matrix below.
- Read a past exchange from them to calibrate.
- When in doubt, go one notch more formal than they use.

**Step 3 — Select channel**
| Scenario | Channel |
|----------|---------|
| Simple question, needs quick answer | DM (Slack/Teams) |
| Team-wide decision or update | Public channel |
| Sensitive feedback | In-person or video call |
| Complex explanation | Loom or shared doc |
| Formal request or escalation | Email |
| Needs paper trail | Email |
| External client | Email |

**Step 4 — Draft using structure**
- Follow the Email Structure section for email.
- Follow Meeting Notes structure for meetings.
- Follow SBI model for feedback.

**Step 5 — Review for clarity, brevity, tone**
- Delete filler phrases (see table below).
- Check: is the ask explicit? Is there a deadline?
- Read aloud. If it sounds wrong, rewrite.
- For emotional topics: draft → wait 1 hour → revise → send.

**Step 6 — Send at appropriate time**
- Send during recipient's working hours (use timezone data).
- Avoid Friday afternoon unless urgent.
- Avoid right before lunch or end of day.

**Step 7 — Track and follow up**
- If no response in 48h, send one follow-up.
- Follow-up format: [original subject], first line = "Gentle ping on this — do you need anything from me to move forward?"
- Archive completed threads. No "checking in every day."

---

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

1. **Subject**: `[Verb] + [Topic]`. "Request: Q3 budget approval". Max 50 chars.
2. **Context**: reference previous communication in one sentence.
3. **Purpose**: the ask or update in the first paragraph.
4. **Detail**: supporting info, bulleted if > 3 items.
5. **Next step**: who does what by when.
6. **Closing**: matched to relationship.

### Subject Line Rules

- Keep under 50 characters (mobile truncates at 40).
- No ALL CAPS, no exclamation marks, no "URGENT" unless system is down.
- Prefix pattern: `[Request/Update/Follow-up/Escalation]: [topic]`.
- Specific enough to distinguish from other threads.

### Filler Phrases to Delete

| Delete | Replace with |
|--------|-------------|
| "I hope this email finds you well" | Nothing |
| "I just wanted to reach out" | State the purpose |
| "Per my last email" | Restate the ask directly |
| "Just checking in" | "Following up on [specific]" |
| "Not sure if you saw my last email" | Reference date: "In my email from Monday..." |
| "Quick question" | Ask the question directly in the subject |

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
- Include context in first message (don't make them ask "which part?").
- Use threads for answers, not new messages.
- Set status / expectations: "No rush" or "By EOD".
- Max 2 paragraphs. Longer → Loom or document.

## Difficult Conversations

### Framing Principles

- Separate person from problem: attack the issue, not the individual.
- State your intent first: "I want to talk about [topic] so we can [outcome]".
- Describe the gap: what was expected vs what happened.
- Propose a path forward: not just the problem, but the solution.

### Tone by Emotion

| Emotion | Do | Don't |
|---------|----|-------|
| Frustrated | State facts, propose solution | Blame, generalize |
| Disappointed | Express specifically, offer path | Guilt trip, passive-aggression |
| Urgent | Name deadline, state consequence | ALL CAPS, threats |
| Apologetic | Apologize once, focus on fix | Over-apologize, deflect |

### Constraints

- No threats (unless legal/compliance).
- No ultimatums without offering an alternative.
- No apologizing for things outside your control.
- Never respond to angry emails within 1 hour (draft, wait, revise).
- One ask per email.

## Feedback (SBI Model)

- **Situation**: when and where.
- **Behavior**: what exactly was said/done (observable, not interpreted).
- **Impact**: what effect it had.

### Feedback by Type

| Type | Format | When |
|------|--------|------|
| Reinforcement | SBI | Immediately after positive behavior |
| Redirect | SBI + BID (Behavior-Impact-Desired) | Soon after, in private |
| Growth | SBI + opportunity | During 1:1s |
| Appreciation | SBI | Publicly or in 1:1 |

### Delivery Rules

- Give feedback as close to the event as possible.
- Focus on actions, not personality.
- End with a question: "Does that resonate?"
- Negative feedback always in private.
- Ask permission: "Can I share some feedback?"
- One topic per session.
- No "you always" or "you never".
- No comparison to others.

## Meeting Notes

Every meeting produces four things:
1. **Decisions** — what was agreed.
2. **Action items** — who does what by when.
3. **Open questions** — unresolved, with owner.
4. **Risks** — anything that could block progress.

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

- Each action item must have a named owner and deadline.
- Prefix with `[DECIDED]`, `[ACTION]`, `[QUESTION]`.
- Dates in ISO format (2026-05-12). No "next week" or "tomorrow".
- Notes sent within 2 hours of meeting end.

## Cross-Cultural Communication

| Culture | Communication style | Email approach |
|---------|-------------------|----------------|
| US/UK | Direct, task-focused | Clear ask, bullet points |
| Japan | Indirect, relationship-first | Polite preamble, implicit ask |
| Germany | Direct, formal | Structured, complete information |
| France | Debate-oriented, formal | Context first, then ask |
| Brazil | Warm, relationship-first | Personal greeting, then business |

## Error Handling

| Scenario | Root Cause | Fix |
|----------|------------|-----|
| Recipient didn't understand the ask | Implicit or buried CTA | Restate with explicit request in first paragraph. Add bold or bullet. |
| Recipient offended by tone | Tone mismatch with relationship | Apologize, clarify intent, rephrase. Cross-check against Tone Matrix before next send. |
| No response after 48h | Wrong channel or message too long | Follow up with 2-sentence version on a different channel. |
| Escalation backfires | Emotion leaked into writing | Use escalation template. Never send first draft. Have a peer review. |
| Action items from meeting ignored | No owner or deadline assigned | Apply formatting rules retroactively. Send a follow-up with clear owners + dates. |
| Meeting notes too long to be useful | Included verbatim discussion | Strip to 4 sections (Decisions, Actions, Questions, Risks). Delete everything else. |
| Feedback received as personal attack | SBI not used | Rewrite using Situation + Behavior (observable) + Impact. Remove all evaluative language. |
| Cross-cultural misunderstanding | Assumed same communication style | Check Cross-Cultural table. Adapt formality and directness to recipient's culture. |
| Async thread exploded | Too many topics in one message | Split into separate messages per topic. Move off-topic replies to new threads. |
| Overly long email | No length constraint applied | Cut to max 150 words internal, 200 client. Move details to bullet list or attachment. |

## Production Checklist

Before sending any communication, verify:

- [ ] **Subject**: ≤ 50 chars, prefixed `[Request/Update/Follow-up/Escalation]`
- [ ] **Ask**: one explicit request per message, with deadline
- [ ] **Length**: ≤ 150 words internal, ≤ 200 client
- [ ] **Tone**: matches recipient type in Tone Matrix
- [ ] **Filler**: no "hope this finds you well", "just checking in", etc
- [ ] **Passive-aggression**: none. No "as per my last email", "per our conversation"
- [ ] **Blame**: externalized. "The deployment failed" not "you failed"
- [ ] **Emotion**: drafted, waited 1h (if emotional), revised
- [ ] **Channel**: right for the content (DM vs public vs email vs in-person)
- [ ] **Attachments**: included (or called out if missing)
- [ ] **Meeting notes**: sent within 2 hours, 4 sections only
- [ ] **Feedback**: follows SBI model, asked permission first (if negative)
- [ ] **Deadlines**: every action item has a named owner + ISO date

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| No clear ask | Reader doesn't know what to do | State CTA explicitly in the first paragraph |
| Passive voice in feedback | Sounds weak, avoids accountability | Use SBI — specific behaviors, observable actions |
| Reply-all for 1:1 matters | Exposes private context, noise for others | DM or email to relevant person only |
| Long meeting notes | Nobody reads them | 4 sections only. Extract signals, discard water-cooler |
| Sending when emotional | Regret within the hour | Draft, wait 1 hour, revise, send |
| No subject line | Looks like spam, hard to find | `[Action/Update/Request]: [Topic]` |
| Over-apologizing | Undermines confidence, wastes words | Apologize once sincerely, pivot to solution |
| Wall of text | Reader skips it entirely | Max 2 paragraphs. Bullet points for > 3 items. Loom for complex topics |
| CC'ing manager unnecessarily | Escalates tension, appears political | Only CC when they need to know or have been discussed previously |
| False urgency ("URGENT" / "ASAP") | Desensitizes recipient, boy who cried wolf | Reserve for actual production outages. Use specific deadline otherwise |
| Opening with "Sorry to bother" | Undermines importance of message | Start with context or ask directly |
| Vague follow-ups ("Checking in") | No context, no specific ask | "Following up on X — do you have an ETA for Y?" |

## Constraints

- Max 150 words internal, 200 for client emails.
- No passive-aggressive language.
- No assigning blame to a person ("the deployment failed" not "you failed").
- Signature: Name, Title, Company, Phone. No quotes, no ASCII art.

## Sources

- Harvard Business Review communication guides
- Radical Candor by Kim Scott
- Crucial Conversations by Patterson et al.
- Center for Creative Leadership — SBI model
- Amazon Working Backwards methodology
- Basecamp Shape Up — Meeting practices
- Thanks for the Feedback by Stone & Heen
- Google Project Aristotle — psychological safety
