---
name: communication
description: >
  Draft professional emails, feedback (SBI/BID), difficult conversations, meeting
  notes, and escalation templates. Covers tone matrix, cross-cultural
  communication, Slack/Teams async patterns, and structured notes from raw
  transcripts.
triggers:
  - "write an email"
  - "draft feedback"
  - "difficult conversation"
  - "meeting notes"
  - "escalate"
  - "compose a message"
  - "corporate email"
  - "tone check"
  - "reply to this email"
  - "status update"
  - "project delay"
  - "async message"
  - "Slack message"
  - "Teams message"
  - "follow-up email"
  - "meeting agenda"
  - "meeting summary"
  - "say no to a client"
negatives:
  - "sales outreach"  -> use business-proposals
  - "cold email sequence" -> use business-proposals
  - "proposal" -> use business-proposals
  - "SOW" -> use business-proposals
  - "pitch deck" -> use business-proposals
  - "investor deck" -> use business-proposals
  - "translate" -> use translate-craft
  - "translation" -> use translate-craft
  - "localize" -> use translate-craft
  - "blog post" -> use content-marketing
  - "newsletter" -> use content-marketing
  - "marketing copy" -> use content-marketing
license: MIT
compatibility: opencode 1.0+
metadata:
  version: "4.0.0"
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

Professional writing that gets results. Based on Harvard Business Review, Radical Candor (Kim Scott), Crucial Conversations (Patterson et al.), Amazon Working Backwards, and Google Project Aristotle.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `draft` | Draft an email, message, or document from context |
| `polish` | Polish tone, cut filler, strengthen ask |
| `feedback` | Draft feedback using SBI/BID model |
| `notes` | Structure meeting notes from raw transcript or notes |
| `escalate` | Draft escalation with clear facts, impact, and request |
| `reply` | Reply to a message with appropriate tone |

## Workflow

**Step 1 — Identify audience & context**
- Who is the recipient? What is your relationship?
- What is their communication style (direct/indirect, formal/casual)?
- What is the power dynamic (peer, manager, report, client, exec)?
- What has happened before this communication?

**Step 2 — Choose tone from matrix**

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

Email structure:
1. **Subject**: `[Verb] + [Topic]`. Max 50 chars. Prefix: `[Request/Update/Follow-up/Escalation]`
2. **Context**: reference previous communication in one sentence
3. **Purpose**: the ask or update in the FIRST paragraph
4. **Detail**: supporting info, bulleted if > 3 items
5. **Next step**: who does what by when
6. **Closing**: matched to relationship

**Step 5 — Review checklist**
- [ ] Subject ≤ 50 chars, prefixed with `[Request/Update/Follow-up/Escalation]`
- [ ] One explicit ask per message, with deadline
- [ ] Length ≤ 150 words internal, ≤ 200 client
- [ ] Tone matches recipient in matrix
- [ ] Zero filler: no "hope this finds you well", "just checking in", "I wanted to reach out"
- [ ] No passive-aggression: no "as per my last email", "per our conversation"
- [ ] Blame externalized: "The deployment failed" not "You failed"

**Step 6 — Send at appropriate time**
- During recipient's working hours (respect timezone)
- Avoid Friday afternoon (unless urgent)
- Avoid right before lunch or end of day

**Step 7 — Follow up**
- If no response in 48h, send ONE follow-up
- Format: same subject, first line = "Gentle ping on this — do you need anything from me to move forward?"

---

## Filler Phrases to Delete (exact replacements)

| Delete | Replace with |
|--------|-------------|
| "I hope this email finds you well" | Nothing. Start with the purpose. |
| "I just wanted to reach out" | State the purpose directly. |
| "Per my last email" | Restate the ask directly. |
| "Just checking in" | "Following up on [specific thing] — do you have an ETA?" |
| "Quick question" | Ask the question directly in the subject. |
| "Sorry to bother you" | "When you have a moment, [ask]" |
| "To be honest" | Everything you write should be honest. Drop the phrase. |
| "I think" / "I feel" | "I recommend" / "The data shows" — be direct. |

---

## Feedback (SBI Model)

- **S**ituation: when and where
- **B**ehavior: what exactly was said/done (observable, not interpreted)
- **I**mpact: what effect it had

Rules:
- Always in private for redirecting feedback
- As close to the event as possible
- Focus on actions, not personality
- End with a question: "Does that resonate?"
- Ask permission first: "Can I share some feedback?"
- One topic per session
- Never: "you always", "you never", comparison to others

---

## Meeting Notes Format

Every meeting produces exactly four things:

```
## [Topic] — [Date]

## Summary
One paragraph. A non-attendee should understand what happened.

## Decisions
- [DECIDED] We will use X instead of Y because Z

## Action Items
| Owner | Task | Due |
|-------|------|-----|
| @name | Specific task description | 2026-05-15 |

## Open Questions
- [QUESTION] ... → @owner to decide by Friday

## Risks
- Risk description → mitigation
```

Rules:
- Notes sent within 2 hours of meeting end
- Every action has a named owner + ISO date deadline
- No verbatim discussion. Strip to 4 sections.

---

## Cross-Cultural Communication

| Culture | Directness | Formality | Time | Feedback |
|---------|-----------|-----------|------|----------|
| US | Direct | Informal | Strict deadlines | Direct + positive |
| Japan | Indirect | Formal | Punctual | Indirect, private |
| Germany | Direct | Formal | Strict | Direct, factual |
| Brazil | Indirect | Relationship-first | Flexible | Indirect, relationship |
| India | Context-dependent | Formal with seniors | Flexible | Indirect, hierarchical |

## Async Communication Protocols

1. Default to async: assume response within 24h (not instant)
2. No "hi" messages: include context + question in first message
3. Status updates: visible in project tool, not via DM
4. Meeting notes: posted within 1h. Action items with owners + deadlines.
5. Decision log: key decisions documented with rationale + date + decider.

## Meeting Facilitation

- Agenda sent 24h before. Start with purpose + desired outcome.
- Timebox: 15min (standup), 30min (decision), 60min max (workshop)
- Parking lot: off-topic items written down for later
- Round-robin: every voice heard before discussion

---

## Error Handling

| Cause | Fix |
|-------|-----|
| Recipient didn't respond in 48 hours | Send one follow-up with same subject. First line: "Gentle ping on this — do you need anything from me to move forward?" |
| Email draft is too long (>200 words client, >150 internal) | Cut to essentials. Move details to bullet points. Complex topics → Loom video or shared doc. |
| Tone feels passive-aggressive on re-read | Replace "per my last email" with direct restatement. Remove "as I mentioned." Check for blame language. |
| Cross-cultural miscommunication risk | Check culture table. Japanese: add polite preamble, drop subject pronouns. German: complete information, use Sie. French: context before ask. |
| Emotional reaction while drafting | Save draft. Wait 1 hour minimum. Revise before sending. Remove all loaded language. |
| Vague action items after meeting | Every action item must have: named owner + ISO date deadline + specific verb. No "we should think about." |
| Feedback received negatively | Check SBI structure: Situation (when/where) + Behavior (observable) + Impact (effect). End with "Does that resonate?" Never "you always/never." |
| Escalation email ignored by leadership | Structure: clear facts first, business impact second, specific request third. Keep under 150 words. No blame. Include deadline. |

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| No clear ask | Reader doesn't know what to do | State CTA explicitly in first paragraph |
| Reply-all for 1:1 matters | Noise for others, exposes private context | DM or email only relevant person |
| Wall of text | Nobody reads it | Max 2 paragraphs. Bullets for > 3 items. Loom for complex. |
| Sending when emotional | Regret within the hour | Draft, wait 1h, revise, send |
| CC'ing manager unnecessarily | Political escalation | Only CC when they need to know |
| False urgency ("URGENT" / "ASAP") | Boy who cried wolf | Reserve for actual outages. Use specific deadline otherwise. |
| Over-apologizing | Undermines confidence | Apologize once sincerely, pivot to solution |
| Vague follow-ups ("Checking in") | No context, no action | "Following up on X — ETA for Y?" |

## Constraints

- Max 150 words internal, 200 for client emails
- No passive-aggressive language
- No assigning blame to a person
- Signature: Name, Title, Company, Phone. No quotes. No ASCII art.

## Checklist

- [ ] Audience identified (executive, peer, client, direct report)
- [ ] Purpose clear: inform, persuade, align, or escalate
- [ ] Tone matched to relationship and context
- [ ] Key action item or ask stated explicitly near the top
- [ ] Proofread for ambiguity and unnecessary jargon

## Sources

- Radical Candor — Kim Scott
- Crucial Conversations — Patterson, Grenny, McMillan, Switzler
- Harvard Business Review — Communication guides
- Center for Creative Leadership — SBI model
- Amazon Working Backwards methodology
- Google Project Aristotle — Psychological safety
- Thanks for the Feedback — Stone & Heen
