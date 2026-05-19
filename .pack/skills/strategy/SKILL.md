---
name: strategy
description: Run structured brainstorming sessions (divergent/convergent), improve prompts with 7-dimension framework, and apply decision frameworks (RICE, weighted scoring, first principles, pre-mortem).
triggers:
  - brainstorm ideas
  - run an ideation session
  - improve a prompt
  - write a better prompt
  - make decisions
  - strategic thinking
  - how to decide between options
  - prompt engineering
  - structured thinking
negatives:
  - creative direction (use brand-design skill)
  - content strategy (use content-marketing)
  - personal coaching
  - simple yes/no decisions without tradeoffs
  - design feedback or visual critique
license: MIT
compatibility: opencode
metadata:
  workflow: strategy
  audience: developers
  version: "3.0.0"
---


# Strategy

Structured thinking for brainstorming, prompt engineering, and decision making.

## Workflow

### Step 1: Intake & Framing

Extract the user's core need and classify it into one of three tracks:

| Track | Trigger | Output |
|-------|---------|--------|
| **Decision** | "Should I...", "Which option...", "Help me choose..." | Scored recommendation with rationale and runner-up tradeoff |
| **Ideation** | "Brainstorm...", "Generate ideas for...", "What are ways to..." | Prioritized list of ideas with convergent selection |
| **Clarity** | "How do I think about...", "Improve this prompt", "Reframe..." | Restructured framing, 7-dimension prompt, or first-principles breakdown |

If the user's need spans multiple tracks, run them sequentially: Clarity → Ideation → Decision.

### Step 2: Select Framework

For **Decision** track: Choose ICE if speed matters, Impact/Effort matrix if resources are constrained, First Principles if the problem feels stuck or assumed, Pre-Mortem if the decision is high-stakes and irreversible.

For **Ideation** track: Start with brainwriting (quantity). If ideas stall, inject SCAMPER or reverse brainstorming. Never open with free association for groups of 3+ — dominant voices take over.

For **Clarity** track: Run the 7-dimension prompt diagnosis. Identify which dimensions are weak (0-3 on a 1-10 scale). Rewrite the prompt addressing the weakest dimensions first.

### Step 3: Execute Framework

Follow the framework protocol from its dedicated section below. Timebox strictly:
- Decision: 20 min (5 min framing, 10 min scoring, 5 min decision)
- Ideation: 60 min (divergent 30 min, cluster 10 min, convergent 20 min)
- Clarity: 10 min (diagnose 3 min, rewrite 5 min, changelog 2 min)

### Step 4: Document & Deliver

Every strategy output must include:
- The chosen framework and why it was selected
- The raw output (scores, ideas, rewritten prompt)
- One recommended action with owner + next step + deadline
- One explicitly rejected alternative and the reason

### Step 5: Verify Against Production Checklist

Run the Production Checklist before delivering. If any item is unchecked, return to the relevant step. Never deliver a strategy artifact that skips convergent selection or lacks a specified output format.

## Brainstorming

### 1. Process

1. **Divergent** (generate, no judgment) — 15-30 min
2. **Clustering** (organize, group, eliminate) — 10-15 min
3. **Convergent** (select, vote, prioritize) — 15-20 min

Never mix divergent and convergent — judgment kills ideas before they form.

### 2. Divergent Techniques

| Technique | How | Best for |
|-----------|-----|----------|
| Free association | Write everything, no filter | Warm-up, quantity |
| Brainwriting 6-3-5 | 6 people write 3 ideas in 5 min, pass | Avoiding dominant voices |
| Reverse brainstorming | How to make it worse? Then reverse. | Breaking assumptions |
| Random word | Random noun → force connections | Lateral thinking |
| SCAMPER | Substitute, Combine, Adapt, Modify, Put to use, Eliminate, Reverse | Systematic exploration |
| HMW | Reframe as "How Might We" questions | Design thinking |
| Worst idea | Generate terrible ideas, then invert | Reducing fear |

### 3. Convergent Techniques

| Technique | How |
|-----------|-----|
| Dot voting | 3-5 votes per person |
| Impact/effort matrix | X: impact, Y: effort |
| ICE scoring | Impact, Confidence, Ease (1-10, average) |
| NUF test | New, Useful, Feasible (1-10 each) |

### 4. Session Template

| Phase | Duration | Activity |
|-------|----------|----------|
| Problem framing | 10 min | Define "How might we..." question |
| Warm-up | 5 min | Low-stakes exercise |
| Divergent round 1 | 15 min | Brainwriting. Target: 30+ ideas |
| Cluster | 10 min | Affinity mapping |
| Divergent round 2 | 10 min | SCAMPER on strongest clusters |
| Convergent | 15 min | Impact/effort matrix. Top 3-5 |
| Action planning | 10 min | Owner, next step, deadline |

### 5. Session Ground Rules

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

1. **Clarity** — Remove ambiguity. Every noun and verb should have one interpretation.
2. **Specificity** — Replace vague language with concrete details. Use names, paths, numbers.
3. **Constraints** — Technology, resource, time, compliance hard boundaries.
4. **Format** — Bullet list, table, code block, JSON, Mermaid. Tell the model *how* to answer.
5. **Examples** — One example is worth 100 words of description.
6. **Tone** — Internal message (direct), client email (professional-cordial), docs (neutral-precise), bug report (factual-minimal).
7. **Iteration Signal** — "Start here, refine later" vs "Production-ready" vs "Give me options" vs "Just the code"

### Enhancement Workflow

1. **Diagnose**: Run through 7 dimensions — identify which are weak or missing
2. **Rewrite**: Complete rewrite, don't annotate original
3. **Changelog**: 1-2 bullet points per dimension improved

### Specificity Table

| Vague | Specific |
|-------|----------|
| "help with this code" | "refactor auth middleware in src/middleware/auth.ts" |
| "some options" | "exactly 3 options ranked by cost" |
| "make it better" | "improve load time from 3s to <1s on mobile Chrome" |
| "explain" | "explain in 3 bullet points to a junior dev" |

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Session runs over 90 min | Poor timeboxing | Assign a timer. Hard stop at 90 min regardless of progress |
| Dominant voice dominates | No facilitation structure | Switch to brainwriting or round-robin. No open floor until last 10 min |
| Ideas too similar / not novel | Groupthink | Insert reverse brainstorming or random-word technique mid-session |
| No clear decision after convergent phase | Tie votes | Use ICE scoring as tiebreaker. Default to impact if still tied |
| Prompt still produces bad output after rewrite | Diagnosed wrong dimension | Re-run 7-dimension check. Most often: missing constraint or missing example |
| "I don't have ideas" block | Blank-page problem | Use worst-idea technique or reverse brainstorming to unstick |

## Production Checklist

Before delivering a strategy artifact (session output, prompt, decision document):

- [ ] Problem statement defined in "How might we..." format
- [ ] Divergent and convergent phases kept separate with a clear transition
- [ ] Convergent selection uses at least one scoring method (ICE, impact/effort, dot voting)
- [ ] Prompt covers all 7 dimensions — no dimension is "N/A" without reason
- [ ] Prompt includes at least one example (dimension 5)
- [ ] Output format specified in prompt (dimension 4)
- [ ] Iteration signal included (dimension 7)
- [ ] Decision documented with rationale and runner-up tradeoff
- [ ] Action items: owner + next step + deadline

## Anti-Patterns

| Anti-Pattern | Why It Fails | Correction |
|--------------|--------------|------------|
| Mixed divergent and convergent | Judgment kills idea generation before it starts | Separate phases with a break. No "yes but" during divergent |
| No warm-up | Cold start produces safe, boring ideas | Always do 5-min warm-up (e.g. "ideas for improving a paperclip") |
| Dominant voices take over | Junior or quiet team members disengage | Use brainwriting, round-robin. No open discussion until convergent |
| Too many people (8+) | Diffusion of responsibility, not enough airtime | 4-8 max per session. Split into parallel groups if larger team |
| No follow-through | Great ideas die after the session | Assign ownership, next step, and deadline before closing |
| Prompt too short (<10 words) | Model fills gaps with wrong assumptions | Expand to cover context, constraint, format, and example |
| Compound request | Model optimizes for first instruction only | Split into separate prompts or use numbered list with weighting |
| No output format | Model chooses — rarely the most useful one | Always specify format (JSON, table, bullet list, code block) |
| Using ICE without confidence check | False precision — confidence is often guessed | Calibrate confidence: "how sure are you on a 1-10?" and average across 3 people |
| Skipping opportunity cost | Overcommit to first good option | Before finalizing, ask: "What else could these resources do?" |

## Advanced Decision Frameworks

### RICE Scoring
Score features: `Score = (Reach * Impact * Confidence) / Effort`
- Reach: how many users affected (1-1000+)
- Impact: 0.25 (minimal), 0.5 (low), 1 (medium), 2 (high), 3 (massive)
- Confidence: 20% (gut), 50% (some data), 80% (quantified), 100% (A/B tested)
- Effort: person-months

### Kano Model
Classify features: Basic (expected, absence = dissatisfaction), Performance (more = better), Delighter (unexpected, absence = neutral). Prioritize: Basic → Performance → Delighter.

### OKR-to-Task Decomposition
- Objective: qualitative, inspiring, time-bound (quarter)
- Key Results: 3-5 quantitative outcomes
- Tasks: decompose each KR into 2-3 actionable tasks per week

## Sources

- Alex Osborn "Applied Imagination"
- IDEO design thinking
- d.school Stanford facilitation guides
- Jake Knapp "Sprint"
- Annie Duke "Thinking in Bets"
- First Principles (Elon Musk / Richard Feynman approach)
- Fermi Estimation techniques

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
