---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, update or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.
triggers:
  - "create a skill"
  - "new skill"
  - "edit skill"
  - "improve skill"
  - "write a skill"
  - "skill evaluation"
  - "skill benchmark"
  - "description optimization"
  - "evals"
  - "test a skill"
negatives:
  - "general coding"
  - "code review"
  - "find a skill"
  - "install a skill"
  - "ecosystem update"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"
  workflow: tooling
  audience: developers
  author: shokunin
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run the skill on them
- Help the user evaluate the results both qualitatively and quantitatively
- Rewrite the skill based on feedback from the user's evaluation of the results
- Repeat until you're satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. So for instance, maybe they're like "I want to make a skill for X". You can help narrow down what they mean, write a draft, write the test cases, figure out how they want to evaluate, run all the prompts, and repeat.

On the other hand, maybe they already have a draft of the skill. In this case you can go straight to the eval/iterate part of the loop.

Of course, you should always be flexible and if the user is like "I don't need to run a bunch of evaluations, just vibe with me", you can do that instead.

Then after the skill is done (but again, the order is flexible), you can also optimize the description to improve the triggering of the skill.

Cool? Cool.

## Communicating with the user

The skill creator is liable to be used by people across a wide range of familiarity with coding jargon. If you haven't heard (and how could you, it's only very recently that it started), there's a trend now where the power of LLMs is inspiring plumbers to open up their terminals, parents and grandparents to google "how to install npm". On the other hand, the bulk of users are probably fairly computer-literate.

So please pay attention to context cues to understand how to phrase your communication! In the default case, just to give you some idea:

- "evaluation" and "benchmark" are borderline, but OK
- for "JSON" and "assertion" you want to see serious cues from the user that they know what those things are before using them without explaining them

It's OK to briefly explain terms if you're in doubt, and feel free to clarify terms with a short definition if you're unsure if the user will get it.

---

## Workflow

### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture (e.g., they say "turn this into a skill"). If so, extract answers from the conversation history first — the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill the gaps, and should confirm before proceeding to the next step.

1. What should this skill enable the model to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

### Interview and Research

Proactively ask questions about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

Check available tools — if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents if available, otherwise inline. Come prepared with context to reduce burden on the user.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. This is the primary triggering mechanism - include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Note: currently models have a tendency to "undertrigger" skills — to not use them when they'd be useful. To combat this, make the skill descriptions a little bit "pushy". So for instance, instead of "How to build a simple fast dashboard to display internal data", you might write "How to build a simple fast dashboard to display internal data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"
- **compatibility**: Required tools, dependencies (optional, rarely needed)
- **the rest of the skill :)

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)

These word counts are approximate and you can feel free to go longer if needed.

**Key patterns:**
- Keep SKILL.md under 500 lines; if you're approaching this limit, add an additional layer of hierarchy along with clear pointers about where the model using the skill should go next to follow up.
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
The model reads only the relevant reference file.

#### Principle of Lack of Surprise

This goes without saying, but skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user in their intent if described. Don't go along with requests to create misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activities. Things like a "roleplay as an XYZ" are OK though.

#### Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats** - You can do it like this:
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern** - It's useful to include examples. You can format them like this (but if "Input" and "Output" are in the examples you might want to deviate a little):
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs. Use theory of mind and try to make the skill general and not super-narrow to specific examples. Start by writing a draft and then look at it with fresh eyes and improve it.

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to a JSON file in your workspace. Don't write assertions yet — just the prompts. You'll draft assertions in the next step.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

The full eval schema also supports an `assertions` array (added later):
```json
{
  "assertions": [
    {
      "id": 1,
      "description": "Output file exists and is valid JSON",
      "type": "file_exists",
      "expected": "output.json"
    }
  ]
}
```

---

## Running and evaluating test cases

This section is one continuous sequence — don't stop partway through.

### Step 1: Run all test cases

For each test case, run the skill against the prompt. If your platform supports subagents/parallel execution, run all test cases simultaneously. Otherwise, run them sequentially.

**With-skill run**: Execute each test prompt using the skill you're testing. Save all outputs (generated files, logs, console output) to a workspace directory.

**Baseline run**: Run the same prompts without the skill (or with the old version if you're improving an existing skill). Save outputs to a separate directory.

Organize results by iteration:
```
workspace/
├── iteration-1/
│   ├── eval-1-with-skill/
│   │   └── outputs/
│   ├── eval-1-baseline/
│   │   └── outputs/
│   └── ...
└── iteration-2/
    └── ...
```

Create an `eval_metadata.json` for each test case:
```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: Draft assertions

While runs are in progress, draft quantitative assertions for each test case and explain them to the user. If assertions already exist from a previous iteration, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names — they should read clearly so someone glancing at the results immediately understands what each one checks. Subjective skills (writing style, design quality) are better evaluated qualitatively — don't force assertions onto things that need human judgment.

Update the `eval_metadata.json` files with the assertions once drafted.

### Step 3: Grade and compare results

Once all runs complete:

1. **Grade each run** — evaluate each assertion against the actual outputs. For assertions that can be checked programmatically, write and run a quick script rather than eyeballing it — scripts are faster, more reliable, and can be reused across iterations.

   Save results to `grading.json` in each run directory:
   ```json
   {
     "expectations": [
       {
         "text": "Output file exists and is valid JSON",
         "passed": true,
         "evidence": "File output.json exists and parses as valid JSON with 3 keys"
       }
     ]
   }
   ```

2. **Aggregate into benchmark** — compile results into a `benchmark.json` with pass_rate, time, and tokens for each configuration, showing mean ± stddev and the delta between with-skill and baseline. Place each with_skill version before its baseline counterpart.

3. **Analyze patterns** — read the benchmark data and surface patterns the aggregate stats might hide. Look for:
   - Assertions that always pass regardless of skill (non-discriminating)
   - High-variance evals (possibly flaky)
   - Time and token tradeoffs (faster but more tokens? worth it?)
   - Cases where the skill made things worse

4. **Present results to the user** — show both qualitative outputs (what files were produced) and quantitative data (benchmark stats). Let the user click through each test case and review outputs. Ask for inline feedback: "How does this look? Anything you'd change?"

### Step 4: Read the feedback

When the user tells you they're done reviewing, collect their feedback. Structure it as:
```json
{
  "reviews": [
    {"run_id": "eval-1-with-skill", "feedback": "the chart is missing axis labels"},
    {"run_id": "eval-2-with-skill", "feedback": ""},
    {"run_id": "eval-3-with-skill", "feedback": "perfect, love this"}
  ]
}
```

Empty feedback means the user thought it was fine. Focus your improvements on the test cases where the user had specific complaints.

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better based on their feedback.

### How to think about improvements

1. **Generalize from the feedback.** The big picture thing that's happening here is that we're trying to create skills that can be used a million times across many different prompts. Here you and the user are iterating on only a few examples over and over again because it helps move faster. The user knows these examples in and out and it's quick for them to assess new outputs. But if the skill you and the user are codeveloping works only for those examples, it's useless. Rather than put in fiddly overfitty changes, or oppressively constrictive MUSTs, if there's some stubborn issue, you might try branching out and using different metaphors, or recommending different patterns of working. It's relatively cheap to try and maybe you'll land on something great.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Make sure to read the transcripts, not just the final outputs — if it looks like the skill is making the model waste a bunch of time doing things that are unproductive, you can try getting rid of the parts of the skill that are making it do that and seeing what happens.

3. **Explain the why.** Try hard to explain the **why** behind everything you're asking the model to do. Today's LLMs are smart. They have good theory of mind and when given a good harness can go beyond rote instructions and really make things happen. Even if the feedback from the user is terse or frustrated, try to actually understand the task and why the user is writing what they wrote, and what they actually wrote, and then transmit this understanding into the instructions. If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag — if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important. That's a more humane, powerful, and effective approach.

4. **Look for repeated work across test cases.** Read the transcripts from the test runs and notice if the model independently wrote similar helper scripts or took the same multi-step approach across all test cases. If all 3 test cases resulted in writing a `create_docx.py` or a `build_chart.py`, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it. This saves every future invocation from reinventing the wheel.

This task is pretty important (we are trying to create billions a year in economic value here!) and your thinking time is not the blocker; take your time and really mull things over. I'd suggest writing a draft revision and then looking at it anew and making improvements. Really do your best to get into the head of the user and understand what they want and need.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs. If you're creating a new skill, the baseline is always `without_skill` (no skill) — that stays the same across iterations. If you're improving an existing skill, use your judgment on what makes sense as the baseline: the original version the user came in with, or the previous iteration.
3. Present results side-by-side with the previous iteration so the user can compare.
4. Wait for the user to review and tell you they're done
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all empty (everything looks good)
- You're not making meaningful progress

---

## Advanced: Blind comparison

For situations where you want a more rigorous comparison between two versions of a skill (e.g., the user asks "is the new version actually better?"), use blind comparison. The basic idea: give two outputs to an independent model without telling it which is which, and let it judge quality. Then analyze why the winner won.

This is optional, requires subagents, and most users won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether a model invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic and something a user would actually type. Not abstract requests, but requests that are concrete and specific and have a good amount of detail. For instance, file paths, personal context about the user's job or situation, column names and values, company names, URLs. A little bit of backstory. Some might be in lowercase or contain abbreviations or typos or casual speech. Use a mix of different lengths, and focus on edge cases rather than making them clear-cut (the user will get a chance to sign off on them).

Bad: `"Format this data"`, `"Extract text from PDF"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

For the **should-trigger** queries (8-10), think about coverage. You want different phrasings of the same intent — some formal, some casual. Include cases where the user doesn't explicitly name the skill or file type but clearly needs it. Throw in some uncommon use cases and cases where this skill competes with another but should win.

For the **should-not-trigger** queries (8-10), the most valuable ones are the near-misses — queries that share keywords or concepts with the skill but actually need something different. Think adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't, and cases where the query touches on something the skill does but in a context where another tool is more appropriate.

The key thing to avoid: don't make should-not-trigger queries obviously irrelevant. "Write a fibonacci function" as a negative test for a PDF skill is too easy — it doesn't test anything. The negative cases should be genuinely tricky.

### Step 2: Review with user

Present the eval set to the user for review. Create a simple HTML page listing all queries with should-trigger toggles, let the user edit queries, add/remove entries, and then save the final set.

This step matters — bad eval queries lead to bad descriptions.

### Step 3: Run the optimization loop

Tell the user: "This will take some time — I'll run the optimization loop and check on it periodically."

The optimization process:
1. Split the eval set into 60% train and 40% held-out test
2. Evaluate the current description by running each query 3 times to get a reliable trigger rate
3. Propose improvements based on what failed
4. Re-evaluate each new description on both train and test
5. Iterate up to 5 times
6. Select the best description by test score (not train) to avoid overfitting

### How skill triggering works

Understanding the triggering mechanism helps design better eval queries. Skills appear in the model's `available_skills` list with their name + description, and the model decides whether to consult a skill based on that description. The important thing to know is that models only consult skills for tasks they can't easily handle on their own — simple, one-step queries like "read this PDF" may not trigger a skill even if the description matches perfectly, because the model can handle them directly with basic tools. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means your eval queries should be substantive enough that the model would actually benefit from consulting a skill. Simple queries like "read file X" are poor test cases — they won't trigger skills regardless of description quality.

### Step 4: Apply the result

Take the best description and update the skill's SKILL.md frontmatter. Show the user before/after and report the scores.

---

## Platform-Specific Instructions

### Without subagents

If your platform doesn't support subagents that means no parallel execution. For each test case, read the skill's SKILL.md, then follow its instructions to accomplish the test prompt yourself. Do them one at a time. This is less rigorous than independent subagents (you wrote the skill and you're also running it, so you have full context), but it's a useful sanity check — and the human review step compensates. Skip the baseline runs — just use the skill to complete the task as requested.

For reviewing results, present results directly in the conversation. For each test case, show the prompt and the output. If the output is a file the user needs to see (like a .docx or .xlsx), save it to the filesystem and tell them where it is so they can download and inspect it. Ask for feedback inline: "How does this look? Anything you'd change?"

Skip quantitative benchmarking — it relies on baseline comparisons which aren't meaningful without subagents. Focus on qualitative feedback from the user.

The iteration loop is the same — improve the skill, rerun the test cases, ask for feedback — just without parallel execution in the middle.

Skip blind comparison — it requires subagents.

### With subagents but no browser

If you have subagents but no browser, the main workflow (spawn test cases in parallel, run baselines, grade) all works. When presenting results, save an HTML file to disk so the user can open it in their browser. Collect feedback via a downloaded JSON file or inline.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| Writing the skill entirely in the description field | Description is for triggering, not instructions. The model reads the body for what to do. | Put workflow, rules, and examples in the SKILL.md body. Keep the description focused on when to trigger. |
| Making the description too narrow | Skill never triggers because the description doesn't match real user phrasing | Add multiple trigger phrases: formal ("create a dashboard"), casual ("make me a viz"), and domain-specific ("show me Q4 metrics") |
| Making the description too broad | Skill triggers for tasks it can't handle, eroding trust and wasting context | Add negative triggers: "Do NOT use for..." with specific adjacent domains |
| Writing opaque instructions ("do it well") | Model doesn't know what "well" means for this domain | Give concrete output templates, examples, and quality bars. Show what good looks like. |
| Over-fitting to test prompts | Skill works perfectly on the 3 eval cases but fails on real-world inputs | Diversify test prompts: add adversarial examples, different phrasings, edge cases. Never optimize for the train set alone. |
| Bundling scripts but never referencing them in the body | Scripts sit unused; every invocation rewrites the same utility from scratch | Add explicit "use the script at `scripts/foo.py`" instructions in the body. Reference scripts by path. |
| Exceeding 500 lines in SKILL.md | Context window budget is consumed by skill body, leaving less room for actual work | Split into reference files. Point to them clearly: "Read `references/database.md` for schema patterns." |
| Writing ALL-CAPS MUSTs without explaining why | Heavy-handed; model follows better when it understands the reasoning | Prefer "This is important because..." over "MUST NOT EVER". Explain the consequence. |
| Skipping the human review step in eval | You optimize for what the assertions measure, not what the user actually wanted | Always present outputs to the user before iterating. Assertions catch bugs; humans catch intent misalignment. |
| Ignoring description optimization | A great skill body with a bad description never gets invoked | After completing the skill body, run the description optimization loop with 20 trigger eval queries. |
| Creating skills without checking if one already exists | Duplicate skills confuse the ecosystem and fragment improvements | Check `npx skills list` and the Shokunin ecosystem before creating. Extend existing skills when possible. |

## Error Handling

Common pitfalls when creating skills:

| Problem | Cause | Fix |
|---------|-------|-----|
| Skill never triggers | Description too narrow or too vague | Add concrete trigger phrases and use cases to description; make it "pushy" |
| Skill triggers too often | Description too broad, overlaps with other skills | Add negative triggers ("Do NOT use for...") and scope boundaries |
| Skill produces inconsistent output | Instructions are ambiguous | Add explicit output format templates and examples |
| Skill is too slow | Too many sequential steps or verbose instructions | Remove redundant guidance; allow parallel execution where safe |
| Test cases pass but real-world fails | Overfitted to test prompts | Diversify test prompts; add edge cases and adversarial examples |
| Skill description and body conflict | Body says one thing, description says another | Audit for consistency; the description is what triggers, the body is what executes |
| Bundled scripts are never used | SKILL.md doesn't reference them clearly | Add explicit "use the script at `scripts/foo.py`" instructions in the body |
| Skill grows too large | Feature creep over iterations | Enforce 500-line limit; split into sub-skills or reference files |

---

## Sources

Skill creation best practices drawn from:
- Anthropic's skill creator documentation and evals framework
- Production skill development patterns observed across 60+ skills in the Shokunin ecosystem
- Iterative prompt engineering principles: draft → test → review → improve loop
- Progressive disclosure architecture for managing context window budgets
- Description optimization techniques for reliable triggering in multi-skill environments

## Checklist

- [ ] Skill solves a specific, recurring problem (not a one-shot instruction)
- [ ] Frontmatter complete: name, description, triggers, negatives, license, compatibility, version
- [ ] Description optimized for triggering — test with 3+ variations of a user request
- [ ] Workflow instructions are actionable and tool-agnostic where possible
- [ ] At least one test prompt included for evaluation

---

Repeating one more time the core loop here for emphasis:

- Figure out what the skill is about
- Draft or edit the skill
- Run the skill on test prompts
- With the user, evaluate the outputs both qualitatively and quantitatively
- Repeat until you and the user are satisfied
- Package the final skill and return it to the user
