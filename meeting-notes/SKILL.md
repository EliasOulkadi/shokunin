---
name: meeting-notes
description: Transform raw transcripts into structured notes
---


# Meeting Notes

Transforms raw meeting content into structured notes that drive action. Based on Amazon's Working Backwards documentation culture, Basecamp Shape Up meeting practices, and Linear's async communication methodology.

## The Output

Every meeting produces four things. If you don't have all four, the notes are incomplete:

1. **Decisions** — what changed, what was agreed
2. **Action items** — who does what by when
3. **Open questions** — unresolved, with an owner to close
4. **Risks** — anything that could block progress

## Extraction Method

### Step 1: Identify signals
From the raw transcript, extract only:
- "We decided..." or "Let's go with..."
- "[Name] will..." or "I'll take care of..."
- "I'm blocked on..." or "We need input from..."
- "This changes the timeline because..."

### Step 2: Discard noise
Delete everything else:
- Water-cooler chat at the start
- Technical deep dives (note the decision, not the details)
- Repeating known context
- Off-topic tangents
- Complaints without proposed solutions

### Step 3: Structure
```
## [Topic] — [Date]

## Summary
One paragraph. A person who didn't attend should understand what happened.

## Decisions
- [DECIDED] We will use X instead of Y because Z
- [DECIDED] Sprint extended by 3 days

## Action Items
| Owner | Task | Due |
|-------|------|-----|
| @alice | Draft the migration plan | 2026-05-15 |
| @bob | Review the API contract | 2026-05-17 |

## Open Questions
- [QUESTION] Who owns the QA sign-off? ? @carol to decide by Friday

## Risks
- Third-party API rate limiting may block launch ? mitigation: request early access
```

## Formatting Rules

- Each action item must have a named owner and a deadline. If either is missing, flag it.
- Prefix with [DECIDED], [ACTION], [QUESTION] for scanability.
- Use @mentions for owners. Not names — @mentions.
- Dates in ISO format (2026-05-12). No "next week" or "tomorrow".
- One line per action. No paragraphs in the action items section.

## Meeting Type Templates

### Standup (15 min)
Keep to: What I did, What I'll do, Blockers. Flag anything needing offline discussion.

### Sprint planning (60 min)
Per item: Estimate, owner, acceptance criteria. Note capacity. Flag risks to scope.

### One-on-one (30 min)
Topics: Wins, challenges, feedback, growth, career. Note personal context. Never share notes publicly.

### Client meeting
Stick to: Requirements, timeline, budget changes, questions. Note sentiment. Send within 2 hours.

## Anti-Patterns

- Notes that are a wall of text (no one reads them)
- Action items without owners (they won't get done)
- Action items without deadlines (they'll be forgotten)
- Notes sent 3 days later (useless by then)
- No decisions section (the most important part, always included)

## Sources

- Amazon Working Backwards methodology (internal documentation culture)
- Basecamp Shape Up — Meeting practices chapter
- Linear documentation on async communication
- Scrum Guide for sprint ceremonies
- Harvard Business Review "How to Run a Meeting" by Antony Jay (1976, still the best)







