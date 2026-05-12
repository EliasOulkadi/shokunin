---
name: feedback-craft
description: Write constructive feedback using SBI model
---

Write feedback that is specific, actionable, and kind. Based on the Situation-Behavior-Impact (SBI) model from the Center for Creative Leadership, Kim Scott's Radical Candor, and Crucial Conversations by Patterson et al.

## The SBI Model

- **Situation**: when and where it happened (specific time, place, context)
- **Behavior**: what exactly was said or done (observable, video-camera test — not interpreted)
- **Impact**: what effect it had on you, the team, or the outcome (tangible result)

```
Instead of:
"You were rude in the meeting"

Use:
"(S) In yesterday's sprint retro, (B) you interrupted Sarah three times while she was presenting her update. (I) This made it hard for her to finish her points and discouraged others from sharing."
```

## Feedback Framework: SBI + BID

For growth-oriented feedback, extend SBI with the BID model:

- **SBI**: Situation, Behavior, Impact
- **BID**: Behavior — Impact — Desired behavior / Do differently

```
(S) In the last sprint review,
(B) you presented the technical architecture without checking if stakeholders understood the context.
(I) The client asked to schedule a follow-up meeting, adding 2 hours to the timeline.
(D) Next time, start with a one-sentence context summary and ask "Does that make sense?" before diving deep.
```

## Feedback Types

| Type | Purpose | When to use |
|------|---------|-------------|
| Reinforcement | Encourage repetition of good behavior | Immediately after positive behavior |
| Redirect | Change behavior that isn't working | Soon after negative behavior, not in public |
| Growth | Stretch someone's skills or responsibility | During 1:1s, performance reviews |
| Appreciation | Recognize effort, impact, or attitude | Publicly, in team channels, in 1:1s |

### Reinforcement (keep doing)
Format: SBI

```
(S) In the last two weeks of code reviews,
(B) you've been proactively reviewing open PRs without being asked, leaving detailed comments on architecture and edge cases.
(I) This reduced our review queue from 5 days to 1 day and helped the team ship the quarter-end release on time.
```

### Redirect (do differently)
Format: SBI + BID

```
(S) During the API design discussion yesterday afternoon,
(B) you suggested switching to GraphQL without first asking the team about our current pain points with REST.
(I) This derailed the conversation — we spent 30 minutes debating a solution before aligning on the problem.
(D) Next time, try: start with "What problems are we trying to solve?" and let the solution emerge from the discussion.
```

### Growth (stretch)
Format: SBI + BID

```
(S) For the upcoming migration project,
(B) you have the strongest understanding of the legacy system on the team.
(I) I think you'd be the right person to lead the technical design doc.
(D) I'd suggest you write the first draft and I'll review — it's a growth opportunity ahead of the senior promotion cycle.
```

## Feedback by Channel

| Channel | Best for | Rules |
|---------|----------|-------|
| In person (1:1) | Redirect, growth, sensitive topics | Private, uninterrupted, conversational |
| In person (team) | Reinforcement, group appreciation | Public, specific, brief |
| Written (Slack, email) | Simple reinforcement, async feedback | Avoid redirect in writing — tone is too easily misinterpreted |
| Written (performance review) | Growth, comprehensive feedback | SBI format for every point, no surprises |
| Code review | Technical feedback only | Constructive, specific, tied to standards |

## Code Review Feedback

| Situation | Constructive | Dismissive |
|-----------|-------------|------------|
| Bug or edge case | "This edge case throws on empty input. Add a guard clause to handle it?" | "This is broken." |
| Design concern | "Have you considered extracting this to a custom hook? It would make testing and reuse easier." | "This should be a hook." |
| Style/structure | "We use camelCase for functions per our style guide. Could you update this?" | "Fix formatting." |
| Missing test | "Could you add a test for the error path? That's where most of our bugs come from." | "No tests." |
| Performance | "This filter runs O(n²) on the full list. A Map lookup would be O(1). Want me to show you?" | "Slow code." |

### Code Review Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| "Why did you..." | Sounds accusatory | "Consider using X here because Y" |
| Nitpicking style | Demotivating, wastes time | Only flag style that violates documented standards |
| No explanation | The change gets reverted next week | Explain the reasoning |
| Blocking on non-blocking issues | Slows everyone down | Separate blockers from suggestions explicitly |
| Too many comments | Overwhelming, demoralizing | Group related comments, prioritize top 3 |

## Delivery Rules

| Rule | Why |
|------|-----|
| Give feedback as close to the event as possible | Delayed feedback loses relevance and impact |
| Focus on actions, not personality | "You didn't update the docs" vs "You're disorganized" — behavior is fixable |
| End with a question | "Does that resonate?" / "What are your thoughts?" — invites dialogue |
| For negative feedback, always in private | Public feedback humiliates, creates defensiveness |
| For positive feedback, public when appropriate | Reinforces behavior AND sets team standards |
| Ask permission first | "Can I share some feedback?" → recipient is ready to listen |
| One topic per feedback session | Stacking feedback overwhelms and dilutes all messages |
| Describe, don't judge | "When X happened, Y was the effect" not "You made a mistake" |

## Receiving Feedback

| Situation | Effective response | Ineffective response |
|-----------|-------------------|---------------------|
| When receiving critical feedback | "Thank you. Can you give me a specific example?" | Getting defensive, making excuses |
| When you disagree | "I see it differently. Can I share my perspective?" | Dismissing, arguing |
| When feedback is vague | "Can you be more specific about what you'd like to see different?" | Assuming bad intent |
| When you need time | "I want to think about this. Can we revisit tomorrow?" | Agreeing just to end the conversation |

## Constraints

| Rule | Why |
|------|-----|
| No "you always" or "you never" (absolutes) | Absolutes are almost never true and trigger defensiveness |
| No accusatory statements without SBI structure | Feels like an attack, not feedback |
| No feedback by ambush | Unexpected feedback in 1:1 creates distrust. Set expectation: "I have some feedback to share later" |
| No comparison to others | "Unlike X, you..." — demoralizing and inaccurate |
| No unsolicited advice without context | Ask first: "Can I share some feedback?" |

## Sources

- Center for Creative Leadership — SBI model development
- Radical Candor by Kim Scott — care personally, challenge directly framework
- Crucial Conversations by Patterson, Grenny, McMillan, Switzler — high-stakes communication
- Thanks for the Feedback by Douglas Stone and Sheila Heen — receiving feedback effectively
- Harvard Business Review "The Feedback Fallacy" — rethinking feedback culture
- Google Project Aristotle — psychological safety in teams
- Manager Tools "Feedback Model" — practical delivery framework
- MindTools "The Situation-Behavior-Impact Model" — SBI applied
