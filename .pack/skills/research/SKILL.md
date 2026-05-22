---
name: research
description: Deep research with web search, source verification, and fact-checking. Runs before humanize + kami in the document pipeline. Use when user asks to research a topic, verify facts, gather sources, or do deep web investigation. Covers source validation, citation, and evidence hierarchy.
triggers:
  - "research"
  - "research this"
  - "find information about"
  - "search the web"
  - "verify facts"
  - "fact check"
  - "gather sources"
  - "deep investigation"
  - "web research"
  - "look up"
  - "investigate"
negatives:
  - "memory search"
  - "ChromaDB"
  - "vector search"
  - "code search"
  - "git history"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: ai-agents
  audience: general
---

# research · 調査

**調査 · ちょうさ** — "investigation". Source verification and fact-checking for document generation.

Pre-loads facts before writing. Runs BEFORE humanize + kami + kagen in the document pipeline. Prevents hallucinated data, fake citations, unverified claims.

Based on: CIA Structured Analytic Techniques (Heuer & Pherson), US Government Tradecraft Primer, NPR Training verification guide, Princeton triangulation methodology, OSINT verification tiers (War Intel Hub), journalistic cross-verification research (Godler & Reich), AI hallucination benchmarks (Vectara HHEM 2026), and evidence hierarchy frameworks (NHMRC).

---

## Core principle

**Sources before phrasing.** Do not write a claim without verifying it first. Every number, date, name, version, and citation must be traced to a primary or reputable secondary source.

---

## Evidence hierarchy (adapted from NHMRC + intelligence community)

Use this hierarchy to determine the weight of each source:

| Level | Type | Example |
|-------|------|---------|
| **1 — Direct primary** | Official document, direct capture, observed data | Real HTTP response, source code, DB dump, screenshot |
| **2 — Official primary** | Official statement, public documentation, filing | SEC filing, CVE entry, official changelog, press release |
| **3 — Reputable secondary** | Established outlet, peer-reviewed paper, curated database | NVD, Wordfence, OWASP, Reuters, arXiv |
| **4 — Multiple independent sources** | 3+ unrelated sources report the same | Cross-reference across tech blogs + forums + docs |
| **5 — Single source with evidence** | One verifiable source but no corroboration | Researcher blog with reproducible evidence |
| **6 — Unverified** | Unsupported claim, rumor, speculation | Do NOT use as fact in a document |

**Rule:** a professional document only uses levels 1–4 for factual claims. Level 5 for context or direct quotes, marked as such. Level 6 is not published.

---

## Source verification protocol (NPR + Princeton triangulation)

### Step 1: The direct knowledge test (before citing)

Ask about each source:

- **First-hand:** Did the source witness the event, participate directly, or have documentation? → Strong, but requires corroboration
- **Second-hand:** Did the source hear it from someone else? → Useful for leads, insufficient to publish
- **Third-hand+:** Rumor, hearsay, speculation? → Not publishable as fact

### Step 2: Triangulation (Princeton method)

Cross-check each claim against multiple independent sources:

```
Claim: "WordPress 6.7 has vulnerability X"
  → Source A: official WordPress advisory
  → Source B: entry in NVD/CVE
  → Source C: Wordfence or similar analysis
  → Do they agree? → VERIFIED
  → Only one source? → NOT VERIFIED
```

### Step 3: Bias and agenda assessment (NPR)

For each source, identify:

- **Financial interest:** Does the source benefit financially from a particular narrative?
- **Professional interest:** Does their reputation/career depend on a certain outcome?
- **Personal relationships:** Friends, family, enemies of the subject?
- **Funding:** Who funds the source? What interests does that funder have?

### Step 4: The five-minute background check (NPR)

When time is short:

1. Read the source's bio and "About" page
2. Identify who funds or backs them
3. Look for behavior patterns or prior claims
4. Verify if there are visible conflicts of interest

---

## Verification tiers (adapted from OSINT + War Intel Hub)

Every claim in the document must have an assigned tier:

| Tier | Label | Requirement | Color in document |
|------|-------|-----------|-------------------|
| ✓ | **VERIFIED** | 2+ primary sources or 1 primary + direct evidence | Normal (no mark) |
| o | **CORROBORATED** | Multiple independent sources report the same, without direct primary source | Normal (no mark) |
| X | **UNVERIFIED** | Single source or unconfirmable | Explicitly mark "unverified" or don't include |

**Rule:** in professional documents, everything published without a mark must be VERIFIED or CORROBORATED. UNVERIFIED is omitted or declared as such.

---

## Anti-hallucination checklist (based on Vectara HHEM benchmarks 2026)

LLMs hallucinate 15-20% of the time on factual queries (source: Prompt Guardrails, Vectara benchmark March 2026). Reasoning models hallucinate more than standard ones in summarization (DeepSeek-R1: 14.3% vs V3: 6.1%).

Before writing any claim, run it through this filter:

| Question | Check |
|----------|-------|
| Does this number have a verifiable source? | |
| Is this date confirmed by a primary source? | |
| Does this name/version actually exist? | |
| Is this quote verbatim and verifiable? | |
| Is this CVE/ID real and does it match what I'm saying? | |
| Does this statistic come from a real study? | |
| Am I making up a "study shows" to add weight? | |
| Is this claim about the model/framework true today? | |

---

## Common categories of AI-invented data (research flags)

| Category | Red flag | What to do |
|-----------|----------------|-----------|
| **Versions** | "WordPress 6.8 has..." with no advisory | Check wordpress.org/news/releases |
| **CVEs** | CVE-2026-XXXX with no NVD entry | Search nvd.nist.gov |
| **Statistics** | "80% of sites..." with no study | Don't use without a source |
| **Dates** | Patch dates, release dates | Verify in official changelog |
| **Quotes** | "As X said: '...'" | Confirm X actually said that |
| **Security metrics** | Exploit times, rates | Search real reports (Veracode, Splunk, etc.) |
| **Tool names** | Non-existent tools or wrong versions | Verify official homepage or repository |

---

## Context adaptation by document type

Not all documents need the same verification level. Adjust by type:

| Document type | Verification priority | Critical fields | Tolerance |
|-------------------|---------------------------|-----------------|------------|
| **Pentest / Security** | Maximum | CVEs, versions, dates, screenshots, exploits | Zero. A fake CVE invalidates the report |
| **White paper / Technical** | High | Statistics, quotes, dates, versions, tool names | Low. Made-up quotes destroy credibility |
| **One-pager / Executive** | Medium | Core metrics, client names, key dates | Medium. Minor errors tolerable if the central message is correct |
| **Resume / CV** | Maximum in personal data | Employment dates, titles, companies, quantifiable achievements | Zero in personal data. Achievement claims can be contextual |
| **Letter** | Low | Names, titles, dates | High. Tone matters more than factual precision |
| **Slides / Deck** | Medium | Key statistics, verbatim quotes, names | Medium. Visual context takes priority over detail |

Rule: if the document goes to an external client or has legal/security implications, always use maximum verification.

## Document pipeline integration
- A specific software version → check official changelog
- A CVE or vulnerability → search NVD + official advisory
- A statistic or metric → find primary source or don't include
- A verbatim quote → confirm it exists
- An event date → verify in official source
- A person/tool/company name → verify it exists and is spelled correctly

---

## Sources

- Heuer & Pherson, *Structured Analytic Techniques for Intelligence Analysis* (CIA Sherman Kent School)
- US Government, *A Tradecraft Primer: Structured Analytic Techniques for Improving Intelligence Analysis* (2009)
- NPR Training, "Don't just check the facts, check the source: a guide to verification" (March 2026)
- Princeton University Library, guide "Triangulation and Media Literacy" (2025)
- War Intel Hub, "OSINT Verification Methodology"
- Vectara HHEM hallucination benchmark leaderboard (March 2026)
- Prompt Guardrails, "AI Hallucination Detection and Prevention Guide" (2026)
- News Factory, "News Fact-Checking in 2026: Hallucination Benchmarks, RAG, and Verification Tools"
- Reuters / AP sourcing standards
- GlobalX Publications, "Fact-Checking, Triangulation, and Evidence Reliability in Research"
- NHMRC evidence hierarchy framework

---

## Workflow

1. **Define research scope** — identify exactly what claims need verification: numbers, dates, versions, names, quotes, CVE IDs, statistics.
2. **Search primary sources first** — official changelogs, CVE entries (nvd.nist.gov), SEC filings, source code repositories, direct HTTP responses.
3. **Triangulate across independent sources** — cross-check each claim against 3+ unrelated sources. Do they independently agree? If only one source, mark as UNVERIFIED.
4. **Assess source credibility** — financial interest, professional stake, funding bias, personal relationships. Apply the five-minute background check from NPR methodology.
5. **Assign verification tiers** — VERIFIED (2+ primary sources), CORROBORATED (multiple sources, no primary), UNVERIFIED (single source). Tag every claim.
6. **Run anti-hallucination filter** — verify every number, date, version, and quote against the Vectara HHEM checklist before writing.
7. **Adapt verification level to document type** — maximum for pentest/security reports and CVs. Medium for white papers and exec summaries. Lower for personal letters.

## Error Handling

| Cause | Fix |
|-------|-----|
| CVE ID returned no results from NVD | Search official vendor advisory directly. Check if it's a reserved but unpublished CVE. Mark as CORROBORATED if vendor confirms. |
| Official changelog disagrees with secondary sources | Trust the primary source. Note the discrepancy. Re-check secondary sources for outdated or misinterpreted data. |
| Statistics claim with no identifiable study | Reject the claim. Do not publish. Replace with qualified language ("commonly observed", "widely reported") or omit entirely. |
| Source behind paywall or login gate | Search for preprint, open-access version, or web archive. If unavailable, mark as "source not independently verified." |
| Direct quote cannot be confirmed to exist | Do not publish as verbatim. If essential, paraphrase with attribution like "as characterized by..." or "according to reporting by..." |
| Multiple sources conflict on a key date or number | Go with the primary source. Note the conflict if it matters (e.g., "Sources differ on exact date; official changelog lists [date]"). |
| AI hallucination detected in generated text during verification | Strip the hallucinated claim immediately. Replace with verified data or omit. Re-check surrounding context for contamination. |
| Research timed out before all claims verified | Prioritize critical claims (CVEs, versions, names). Mark unverified claims explicitly. Ship with "preliminary" designation if necessary. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| "Studies show..." with no citation | Hallucinated authority. Undermines entire document credibility. | Never state a study exists without a verifiable citation. Use real sources or don't claim one. |
| Accepting the first Google result as fact | Single-source bias. SEO ranking ≠ accuracy. | Always triangulate. Minimum 3 independent sources for factual claims. |
| Citing Wikipedia as a primary source | Wikipedia is a tertiary source. Editing wars and vandalism skew content. | Trace Wikipedia citations to their original primary sources. Use Wikipedia as a launch point, not an endpoint. |
| Publishing numbers without checking if they're from a real study | LLMs invent plausible-sounding statistics 15-20% of the time. | Verify every number against its original study. If the study doesn't exist, the number doesn't either. |
| Using LLM training data as "verification" without web search | Training data is frozen, outdated, and hallucination-prone. | Always run live web searches. Cross-check against current official sources. |
| Including level 5 (single source) claims without marking them | Reader assumes verified when it's actually unconfirmed. | Explicitly mark any level 5 claim: "[Source: single report, not independently confirmed]". |
| Treating all sources as equally credible | A Reddit comment ≠ a peer-reviewed paper ≠ an NVD entry. | Apply evidence hierarchy. Weight sources by type, not by what supports the desired narrative. |
| Skipping verification because the claim "sounds right" | Confirmation bias. LLMs are confident and wrong simultaneously. | Verify every factual claim. "Sounds right" is how hallucinations reach production documents. |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
