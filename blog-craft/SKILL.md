---
name: blog-craft
description: Write technical blog posts with code examples
---

Write technical blog posts that developers actually read and share. Based on patterns from CSS-Tricks, Smashing Magazine, Refactoring UI, and developer audience research from Gartner and Stack Overflow.

## Structure

```
Headline (100% of readers see this)
  → Subtitle / dek (80%)
  → Table of contents (for posts >1000 words)
  → Lead paragraph (60%)
  → Sections with H2 + H3 (40%)
  → Code examples (30%)
  → Conclusion with key takeaways (20%)
  → Author bio + CTA (10%)
```

## Headline Formula

| Pattern | Example | Best for |
|---------|---------|----------|
| How to [verb] [noun] | "How to Design REST APIs in 2026" | Tutorials, how-to guides |
| [Number] [noun] for [audience] | "10 React Patterns for Senior Engineers" | List posts, curated resources |
| Why [common belief] is [wrong] | "Why Microservices Are Not the Answer" | Opinion pieces, hot takes |
| From [X] to [Y] | "From Zero to 1M Requests with FastAPI" | Case studies, journey posts |
| [Topic]: A Complete Guide | "API Authentication: A Complete Guide" | Reference, comprehensive overview |
| What I Learned From [X] | "What I Learned From Migrating 50 Services to Kubernetes" | Experience reports, retrospectives |
| The [Adjective] Guide to [Topic] | "The Practical Guide to TypeScript Generics" | Opinionated tutorials |
| [Year] Guide to [Topic] | "The 2026 Guide to Frontend Testing" | Annual updates, evergreen content |

### Headline Rules
- Under 15 words. Shorter = higher CTR.
- Include the primary keyword near the start.
- Promise a specific outcome the reader wants.
- No clickbait — deliver what the headline promises.
- A/B test headlines for 48 hours before finalizing.

## Lead Paragraph

- Restate the problem the reader has (make them feel seen)
- Hint at the solution (create curiosity)
- Set expectations (what they will learn, in what time)
- Maximum 3 sentences. No more.
- No dictionary definitions. No "In today's world." No "As a developer..."

### Lead Types

| Type | Structure | Example |
|------|-----------|---------|
| Problem-first | "[Pain point]. Here's how to fix it." | "Your API tests take 15 minutes to run. They don't need to." |
| Story-first | "I [did thing] and learned [lesson]." | "I inherited a codebase with 60% test coverage. Here's what I did." |
| Curiosity gap | "[Claim you'll prove]. Here's why." | "You don't need TypeScript for type safety. Here's what I use instead." |
| Data-first | "[Stat]. [Why it matters]." | "90% of developers skip integration tests. That's a mistake." |

## Section Organization

### Headings
- H2: major concepts or steps
- H3: sub-topics, examples, edge cases
- H4: code annotations, notes, exceptions
- One level of depth below the main heading — don't go to H5
- Headings must be descriptive: "Error Handling in Async Functions" not "Error Handling"

### Paragraphs
- 2-4 sentences each. Scannable.
- One idea per paragraph. If a paragraph has two ideas, split it.
- Bold the key takeaway in each section — let skimmers get the point.
- Code examples break up text walls: alternate paragraph → code → paragraph → code

## Code Examples

| Rule | Why | Example |
|------|-----|---------|
| Only show relevant lines | Full files overwhelm readers | Show the function, not the imports |
| Syntax highlighting always | Without it, code is unreadable | Use fenced code blocks with language tag |
| Runnable code | Readers copy-paste to try it | Include imports, don't use pseudo-code |
| Error examples too | Readers also want to know what to avoid | "Wrong: ..." then "Right: ..." |
| Line annotations on complex blocks | Not everyone reads every line | Use numbered line comments for key steps |

### Code Block Format

```typescript
// ✅ Good: focused, annotated, runnable
function validateEmail(email: string): boolean {
  // Simple check — valid format exists in most cases
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

// ❌ Bad: no context, no annotation, incomplete
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}
```

## SEO Fundamentals

| Element | Requirement | Example |
|---------|-------------|---------|
| Primary keyword | In H1, first paragraph, and one H2 | "API authentication" |
| Meta description | Under 155 characters, includes value prop | "Learn 3 proven API authentication methods: JWT, OAuth 2.0, and API keys. Includes code examples and security best practices." |
| URL | kebab-case, matches H1, no stop words | `/api-authentication-methods` |
| Alt text | Descriptive (not keyword-stuffed) | "JWT token structure diagram showing header, payload, and signature" |
| Internal links | 2-3 related posts | Link to previous tutorials in the series |
| External links | Authoritative sources | MDN, documentation, research papers |

## Content Quality Checklist

- [ ] Headline passes the "so what?" test — specific, valuable, clear
- [ ] Lead paragraph makes a developer want to keep reading
- [ ] Every code block is runnable (or clearly marked as pseudo-code)
- [ ] Each section teaches one thing clearly
- [ ] Bold key takeaways for skimmers
- [ ] Version numbers included for all tools and libraries
- [ ] No assumptions about reader's prior knowledge without context
- [ ] External sources linked for claims and data
- [ ] Opinionated and useful, not neutral and forgettable
- [ ] Read aloud: sounds like a human wrote it
- [ ] Mobile test: code blocks don't overflow viewport

## Post-Publishing Checklist

- [ ] Check for broken links (internal and external)
- [ ] Verify code examples work by running them
- [ ] Add featured image with proper alt text
- [ ] Share on social media with a hook, not the headline
- [ ] Monitor comments and reply within 24 hours
- [ ] Update metadata for search engines after 1 week
- [ ] Review performance (traffic, time on page, bounce rate) after 30 days
- [ ] Update version numbers when libraries release new major versions

## Anti-Patterns

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| Writing for "everyone" | Resonates with no one | Pick one reader persona and write to them |
| No code until halfway | Developers scan for code first | Show code in the first 3 paragraphs |
| Over-explaining fundamentals | Bores experienced readers | State assumptions upfront: "This assumes you know React" |
| Dictionary opening | Wastes first paragraph | "What is X?" → readers already know. Start with why. |
| No opinion | Readable but forgettable | Take a position. "I prefer X because Y." |
| Walls of text | Readers leave | Break into sections, lists, code, images |
| Outdated code | Destroys credibility | Keep examples tested and versioned |
| No conclusion | Reader leaves without action | End with key takeaways and what to try next |

## Sources

- Smashing Magazine editorial standards — technical writing and code presentation
- CSS-Tricks writing guide — developer-first content structure
- Moz SEO writing guide — search optimization for technical content
- HubSpot blog research — headline performance data
- Gartner "Technical Content Engagement Study" — developer reading patterns
- Stack Overflow "How Developers Consume Content" — audience research
- Nielsen Norman Group "How Users Read on the Web" — scanning patterns
- Write Useful Books (Rob Fitzpatrick) — non-fiction writing frameworks
