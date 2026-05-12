---
name: feedback-craft
description: Write constructive feedback using SBI model
---


# Feedback Craft

Generates feedback that is specific, actionable, and kind. Based on the Situation-Behavior-Impact (SBI) model from the Center for Creative Leadership and Kim Scott's Radical Candor.

## The SBI Model

- **Situation**: when and where it happened
- **Behavior**: what exactly was said or done (observable, not interpreted)
- **Impact**: what effect it had on you, the team, or the outcome

```
Instead of:
"You were rude in the meeting"

Use:
"(S) In yesterday's sprint retro, (B) you interrupted Sarah three times while she was presenting her update. (I) This made it hard for her to finish her points and discouraged others from sharing."
```

## Feedback Types

### Reinforcement (keep doing)
```
(S) In the last two weeks, (B) you've been proactively reviewing open PRs without being asked. (I) This reduced our queue time by 40% and helped the team ship faster.
```

### Redirect (do differently)
```
(S) During the API design discussion, (B) you suggested switching to GraphQL without first understanding our current pain points with REST. (I) This derailed the conversation and we spent 30 minutes on a solution to a problem we hadn't defined yet.
```

### Growth (stretch)
```
(S) For the upcoming migration project, (B) you have the strongest understanding of the legacy system. (I) I think you'd be the right person to lead the technical design doc and mentor two junior devs through it.
```

## Code Review Guidelines

| Situation | Constructive | Dismissive |
|-----------|-------------|------------|
| Bug | "This edge case throws on empty input. Add a guard clause?" | "This is broken." |
| Design | "Have you considered extracting this to a custom hook? It would make testing easier." | "This should be a hook." |
| Style | "We use camelCase for functions per our style guide." | "Fix formatting." |
| Missing test | "Can you add a test for the error path here?" | "No tests." |

## Delivery Rules

- Give feedback as close to the event as possible
- Focus on actions, not personality ("you didn't update the docs" vs "you're disorganized")
- End with a question ("Does that resonate?", "What are your thoughts?")
- For negative feedback, always in private
- For positive feedback, public when appropriate

## Constraints

- No "you always" or "you never" (absolutes)
- No accusatory "you" statements without SBI structure
- No feedback by ambush (unexpected in 1:1 â€” set expectation first)
- No comparison to others ("unlike X, you...")
- No unsolicited advice â€” ask permission first: "Can I share some feedback?"

## Sources
- Center for Creative Leadership SBI model
- Radical Candor by Kim Scott
- Thanks for the Feedback by Stone and Heen







