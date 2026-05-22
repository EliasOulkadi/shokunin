---
name: humanize
description: Rewrite AI-generated text to sound natural, remove AI tells, and adjust tone. Use when user asks to make text less robotic, more natural, or humanize AI output. Covers tone matrix, filler words, sentence rhythm, and anti-AI-slop patterns.
triggers:
  - "humanize"
  - "make it natural"
  - "less robotic"
  - "more human"
  - "remove AI tells"
  - "adjust tone"
  - "rewrite naturally"
  - "natural text"
  - "anti AI slop"
  - "make it conversational"
negatives:
  - "translation"
  - "formal writing"
  - "academic writing"
  - "technical documentation"
  - "code comments"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: ai-agents
  audience: general
---

# humanize · 人間

**人間 · にんげん** — "human being". Makes AI-generated text sound like a real person wrote it.

Based on research from: Grammarly, MIT Technology Review, GPTZero, QuillBot, Reddit (r/auscorp, r/cybersecurity), Hacker News, Stack Overflow, JustDone, print-css.rocks, BrowserStack, pdf4.dev benchmarks, and professional writing guides (2024–2026).

---

## Core metrics AI detectors measure

| Metric | What it means | Human text | AI text |
|--------|---------------|------------|---------|
| **Perplexity** | How predictable each word is | High — uses unexpected words | Low — always picks the most probable word |
| **Burstiness** | Variance in sentence length | High — mixes short/long sentences | Low — uniform sentence length |
| **Word frequency** | Rate of common vs rare words | Balanced — uses uncommon terms | Skewed — overuses "the", "it", "is" |
| **Repetition** | Recurring patterns | Low — natural variation | High — same structures repeat |

Sources: GPTZero, QuillBot, MIT Technology Review, Google Brain research (Ippolito et al. 2020)

---

## The 16 AI tells (how to spot them)

### 1. Overused buzzwords (Grammarly 2026, Reddit)

| AI word | Human alternative |
|------------|-------------------|
| delve into | analyze, explore, dig into |
| pivotal | key, decisive, critical |
| underscore | highlight, point out, stress |
| multifaceted | complex, with several aspects |
| landscape | ecosystem, context, situation |
| paradigm | model, approach, framework |
| robust | solid, reliable, resilient |
| leverage | use, harness, take advantage of |
| seamless | smooth, frictionless, natural |
| transformative | disruptive, profound, radical |

### 2. Mechanical connectors (GPTZero research)

- "Moreover", "Furthermore", "Nevertheless", "Consequently" → use "Also", "But", "So" or nothing
- "However" every 3 paragraphs → cut half, let it flow
- "Nevertheless", "Therefore", "Consequently" → replace with "So", "Then", "That means"

### 3. Perfect symmetrical structure (MIT Tech Review)

LLMs generate paragraphs of the same length, same structure: intro → point → example → conclusion.

**Fix:** Break the pattern. One-line paragraph. Then a long one. List. Then another short one.

### 4. Low burstiness (QuillBot, pdf4.dev)

AI produces sentences of similar length. Humans alternate:
- Short sentence. Impact.
- Then a longer one that develops the idea with more detail and nuance, adding context.
- Another short one.

### 5. Absolute neutrality (r/auscorp, Reddit)

AI never takes a position. Sounds like a wiki.
**Fix:** Add opinion, judgment, acknowledged bias. "We don't like this", "This is well done", "This is debatable".

### 6. Forced transitions (HN, cybersecurity forums)

"It is important to note that...", "It is worth mentioning that...", "It should be noted that..." → delete all. If the sentence doesn't work without the crutch, rewrite it.

### 7. Numbers and statistics without source

AI invents data that "sounds good". E.g.: "Studies show that 80% of users..."
**Fix:** If there's no real source, don't put a number. Use "many", "most", "it's common".

### 8. Excessive passive voice

"It was carried out", "It has been determined", "It can be observed"
**Fix:** Active. "We carried out", "We determined", "We observe"

### 9. Empty hyperbole (r/cybersecurity)

"Critical", "Massive", "Transformative", "Revolutionary" without backup.
**Fix:** Concrete data or measured language.

### 10. Closing with rhetorical question

"Are you ready for the future?", "Can you imagine a world where...?"
**Fix:** Close with a statement or direct call to action.

### 11. Uniform paragraph length

AI: all paragraphs 3-5 lines.
Human: natural mix of 1 line with 8 lines.

### 12. Lack of colloquialisms

AI doesn't use "well", "look", "you see", "the thing is", "let's see". Real speech has filler words.
**Fix:** Add controlled natural language. Don't overdo it, but loosen up.

### 13. Too formal for the context

An internal report written like an academic paper. An email like a formal letter.
**Fix:** Match the register to the channel and audience.

### 14. No errors or imperfections

AI has no typos, doesn't repeat a word by accident, doesn't rephrase.
**Fix:** Do NOT introduce artificial errors. But allow natural asymmetry.

### 15. No contractions or contracted forms

AI: "do not", "cannot", "will not", "it is", "I am", "they are"
Human: "don't", "can't", "won't", "it's", "I'm", "they're" (in English)

### 16. Em dash (—) as universal connector

AI abuses the em dash `—` as a universal connector. Typical pattern:

```
❌ AI:   Black Box — no previous credentials
❌ AI:   WordPress — updated to latest version
❌ AI:   Admin panel — accessible without restrictions
```

A human normally uses:

```
✅ Real: Black Box (no previous credentials)
✅ Real: WordPress updated to latest version
✅ Real: Admin panel accessible without restrictions
```

The real em dash is used for asides or tone shifts, not as glue between label and value. If you see multiple lines with `—` in a row, it's AI.

**Fix:** replace `—` with parentheses, comma, colon, or simply nothing. If the `—` separates a label from its value, the label or the dash is probably unnecessary.

---

## Workflow

### Step 1: Detect

Read the full text. Mark every instance of:
- Buzzwords (list above)
- Mechanical connectors
- Identical-length paragraphs
- Chained passive voice
- Unsupported hyperbole
- Absolute neutrality
- Transition crutches

### Step 2: Prune

Delete everything that is filler:
- "It is important to note that" → [delete]
- "It is worth mentioning that" → [delete]
- "It should be pointed out that" → [delete]
- "As previously mentioned" → [delete]
- "In today's world" → [delete]

### Step 3: Vary

Rewrite to break symmetry:
- One short line
- Long paragraph with data
- Another short line
- List or table
- Closing paragraph with opinion

### Step 4: Personalize

Add a layer of judgment/perspective:
- "This is debatable because..."
- "In our experience..."
- "The data that concerns us most is..."
- "Frankly, this solution doesn't convince"

### Step 5: Verify

Run the result through:
- An AI detector (GPTZero, Originality)
- A read-aloud test (if it sounds like a robot, it failed)
- The test: "would a human say this in a conversation?"

---

## Anti-patterns checklist

Use this checklist before delivering any humanized text:

| Signal | Present | Fixed |
|-------|----------|-----------|
| Delve / dive / deep dive | | |
| "In today's world / nowadays" | | |
| All paragraphs same length | | |
| More than 1 "however" per page | | |
| "It is important to note" | | |
| Rhetorical question at the end | | |
| 0 opinions or judgments | | |
| Language more formal than the context | | |
| Connector "moreover / on the other hand" repeated | | |
| Passive voice in more than 30% of verbs | | |
| Numbers without source | | |
| "Nevertheless / nonetheless" | | |
| Em dash `—` separating repeated label/value | | |
| Claims without attributed source | | |

---

## Error Handling

| Cause | Fix |
|-------|-----|
| Text still reads as AI after one pass | Run through AI detector (GPTZero, Originality). Identify remaining tells. Apply second pass focusing on burstiness (vary sentence length). |
| Over-correction: text became too informal | Match register to the channel and audience. Internal email: casual-direct. Client report: professional. Academic: formal. |
| Removing all connectors made text choppy | Keep natural connectors ("but", "so", "and", "then"). Only remove mechanical ones ("Moreover", "Nevertheless", "Consequently"). |
| Added filler words now sound forced | Use colloquialisms sparingly. "Well", "look", "the thing is" — max 1-2 per page. Overuse sounds fake. |
| Passive-to-active conversion reads awkwardly | Not all passives are bad. Keep passive when the actor is unknown or irrelevant. Target < 30% passive voice, not 0%. |
| Text lost important nuance when simplifying | Preserve technical precision. Humanize the wrapper, not the substance. Facts, data, and specific claims stay intact. |
| Em dash removal broke sentence flow | Replace `—` with parentheses, comma, colon, or restructure sentence. Don't just delete — find the right natural alternative. |
| AI detector still flags the text | Check burstiness distribution. Ensure paragraph lengths vary (1-line to 8-line mix). Add one genuine opinion/judgment. Verify no rhetorical question closers. |

## Sources

- Grammarly (2026): "Common Words and Phrases in AI-Generated Text"
- MIT Technology Review (2025): "How to spot AI-generated text"
- GPTZero (2025–2026): "AI Detection Benchmarking", "Perplexity and Burstiness Explained"
- QuillBot: article "Burstiness and Perplexity Explained"
- Reddit r/auscorp: "What's the most obvious tell that someone has used AI"
- Reddit r/cybersecurity, Hacker News discussions
- Ippolito et al., Google Brain (2020): "Automatic Detection of Generated Text"
- JustDone / AHelp: Spanish AI detection guides
- print-css.rocks, BrowserStack, pdf4.dev (document formatting research)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
