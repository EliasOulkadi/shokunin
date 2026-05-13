---
name: strategy
description: Run structured brainstorming sessions (divergent/convergent), improve prompts with 7-dimension framework, and apply decision frameworks (RICE, weighted scoring, first principles, pre-mortem). Use when user asks to brainstorm ideas, run an ideation session, improve a prompt, write a better prompt, make decisions, or do strategic thinking. Do NOT use for creative direction (use design), content strategy (use content-marketing), or personal coaching.
license: MIT
compatibility: opencode
metadata:
  workflow: strategy
  audience: developers
  version: "2.0"
---

# Strategy

Structured thinking for brainstorming, prompt engineering, and decision making.

## Brainstorming

### The Process
1. **Divergent** (generate, no judgment) — 15-30 min
2. **Clustering** (organize, group, eliminate) — 10-15 min
3. **Convergent** (select, vote, prioritize) — 15-20 min

Never mix divergent and convergent — judgment kills ideas before they form.

### Divergent Techniques

| Technique | How | Best for |
|-----------|-----|----------|
| Free association | Write everything, no filter | Warm-up, quantity |
| Brainwriting 6-3-5 | 6 people write 3 ideas in 5 min, pass | Avoiding dominant voices |
| Reverse brainstorming | How to make it worse? Then reverse. | Breaking assumptions |
| Random word | Random noun → force connections | Lateral thinking |
| SCAMPER | Substitute, Combine, Adapt, Modify, Put to use, Eliminate, Reverse | Systematic exploration |
| HMW | Reframe as "How Might We" questions | Design thinking |
| Worst idea | Generate terrible ideas, then invert | Reducing fear |

### Convergent Techniques

| Technique | How |
|-----------|-----|
| Dot voting | 3-5 votes per person |
| Impact/effort matrix | X: impact, Y: effort |
| ICE scoring | Impact, Confidence, Ease (1-10, average) |
| NUF test | New, Useful, Feasible (1-10 each) |

### Session Template
| Phase | Duration | Activity |
|-------|----------|----------|
| Problem framing | 10 min | Define "How might we..." question |
| Warm-up | 5 min | Low-stakes exercise |
| Divergent round 1 | 15 min | Brainwriting. Target: 30+ ideas |
| Cluster | 10 min | Affinity mapping |
| Divergent round 2 | 10 min | SCAMPER on strongest clusters |
| Convergent | 15 min | Impact/effort matrix. Top 3-5 |
| Action planning | 10 min | Owner, next step, deadline |

### Session Ground Rules
- Defer judgment. Go for quantity (set targets: "50 ideas in 20 min")
- One conversation at a time. Build on "Yes, and..."
- Encourage wild ideas. Round-robin or brainwriting.
- Hard stop at 90 min.

## Decision Frameworks

### ICE Scoring
```
Score = Impact (1-10) × Confidence (1-10) × Ease (1-10)
Higher = prioritize first
```

### Impact/Effort Matrix

```
           High Impact          Low Impact
Low Effort  → Do First         → Quick Wins
High Effort → Strategic        → Don't Do
```

### First Principles Thinking

1. Identify the current belief/assumption
2. Break it down into fundamental truths
3. Rebuild from those truths

```
Current: "Our testing takes too long to run"
Deconstruction: What IS testing? Verifying code behavior.
Fundamental: We need confidence code works. Speed matters but accuracy matters more.
Rebuild: What's the fastest way to get accuracy confidence? Change test scope to integration-focused.
```

### Pre-Mortem Analysis

Before starting a project, imagine it failed 6 months from now:
1. What went wrong? (list 5-10 failure modes)
2. For each, what's the probability? (low/medium/high)
3. For each, what's the impact? (minor/major/critical)
4. Mitigation: What can we do NOW to prevent it?

### Opportunity Cost

```
Choosing Option A means NOT choosing Options B-Z.
Before committing, list: What else could these resources do?
```

## Prompt Engineering

### The 7 Dimensions

#### 1. Clarity
Remove ambiguity. Every noun and verb should have one interpretation.

#### 2. Specificity
| Vague | Specific |
|-------|----------|
| "help with this code" | "refactor auth middleware in src/middleware/auth.ts" |
| "some options" | "exactly 3 options ranked by cost" |

#### 3. Constraints
Technology, resource, time, compliance hard boundaries.

#### 4. Format
Bullet list, table, code block, JSON, Mermaid.

#### 5. Examples
One example is worth 100 words of description.

#### 6. Tone
Internal message (direct), client email (professional-cordial), docs (neutral-precise), bug report (factual-minimal).

#### 7. Iteration Signal
"Start here, refine later" vs "Production-ready" vs "Give me options" vs "Just the code"

### Enhancement Workflow
1. **Diagnose**: run through 7 dimensions
2. **Rewrite**: complete rewrite, don't annotate original
3. **Changelog**: 1-2 bullet points per dimension improved

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Mixed divergent and convergent | Separate phases with a break |
| No warm-up | Always do 5-min warm-up |
| Dominant voices take over | Use brainwriting, round-robin |
| Too many people (8+) | 4-8 max per session |
| No follow-through | Assign ownership before closing |
| Prompt too short (<10 words) | Model fills with wrong assumptions |
| Compound request | Models optimize for first instruction |
| No output format | Model chooses, rarely useful |

## Sources

- Alex Osborn "Applied Imagination"
- IDEO design thinking
- d.school Stanford facilitation guides
- Jake Knapp "Sprint"
- Annie Duke "Thinking in Bets"
- First Principles (Elon Musk / Richard Feynman approach)
- Fermi Estimation techniques
