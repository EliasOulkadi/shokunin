---
name: seo-geo
description: SEO + Generative Engine Optimization (GEO) for 2026 — technical SEO, on-page optimization, structured data (JSON-LD, schema.org), Core Web Vitals, citability scoring (llms.txt, entity clarity), AI search engine optimization (ChatGPT, Gemini, Perplexity, Claude, Google AI Overviews), and brand authority building. Use when user asks to optimize a site for search engines, improve SEO, write SEO content, implement structured data, optimize for AI search/GEO, audit a page, or improve Google rankings. Do NOT use for content writing strategy (use content-marketing), performance optimization beyond Core Web Vitals (use performance-profiler), or paid ad strategy.
license: MIT
compatibility: opencode
metadata:
  workflow: marketing
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep WebFetch
---

# SEO & GEO Architect

Optimize websites for both traditional search engines AND AI-powered search engines (GPT, Gemini, Perplexity, Claude Search, Google AI Overviews). Based on Google Search Central, Moz, and GEO research from 2025-2026.

## Workflow

### Step 1: Run SEO audit

```powershell
scripts/audit-seo.ps1 -Url "https://example.com"
```

This checks: title tags, meta descriptions, H1 headings, img alt text, OG tags, hreflang, canonical, robots.txt, structured data.

**Score interpretation:**
- 90-100%: Good. Move to GEO audit.
- 70-89%: Fix flagged items before publishing.
- <70%: Major issues. Fix structural SEO first.

### Step 2: Run GEO audit

```powershell
scripts/audit-geo.ps1 -Url "https://example.com" -BrandName "YourBrand"
```

This checks: llms.txt, ai-plugin.json, FAQ/HowTo schema, entity clarity, brand mention structure, answer format optimization.

**If llms.txt is missing**, create one at `/.well-known/llms.txt`:
```
# Your Brand
> One-line description of what you do.

## Core pages
- https://example.com/: Home — what we do
- https://example.com/about: About us

## Docs
- https://docs.example.com/getting-started: Getting started guide
```

### Step 3: Implement technical SEO

See [references/seo-fundamentals.md](references/seo-fundamentals.md) for complete reference.

**Priority fixes by impact:**
| Fix | Impact | Effort |
|-----|--------|--------|
| Fix crawl errors (Google Search Console) | High | Low |
| Improve LCP (< 2.5s) | High | Medium |
| Add structured data (JSON-LD) | High | Medium |
| Fix meta titles/descriptions | Medium | Low |
| Add hreflang (if multilingual) | Medium | Low |
| Improve internal linking | Medium | Medium |
| Fix broken links | Low | Low |
| Set up sitemap.xml | High | Low |

**Critical schema types to implement:**
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Your Brand",
  "description": "What you do in one sentence",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://twitter.com/yourhandle",
    "https://github.com/yourhandle"
  ]
}
```

Also implement: Article (for blog), FAQPage (for FAQs), HowTo (for tutorials), Product (for products), BreadcrumbList, and LocalBusiness (if applicable).

### Step 4: Optimize for AI search engines

See [references/geo-strategy.md](references/geo-strategy.md) for complete strategy.

**Key GEO optimizations:**
| Factor | Implementation |
|--------|---------------|
| Citability (how often cited by AI) | Publish original research, data, unique insights. Cite primary sources. |
| Entity clarity | Define who you are, what you do, for whom. Clear `about` pages. |
| Answer format | First 2 paragraphs must directly answer the query before expanding. |
| Conversational tone | Write naturally. AI models penalize keyword-stuffed text. |
| Structured data | FAQ, HowTo, Article schema are most consumed by AI. |
| Source authority | Link to .edu, .gov, peer-reviewed sources. Build topical authority. |
| Brand mentions | Get mentioned on authoritative sites in your niche. |

### Step 5: Pre-publish checklist

See [assets/seo-checklist.md](assets/seo-checklist.md) for the complete 50+ item checklist.

**Quick essentials:**
- [ ] Primary keyword in H1, first paragraph, one H2, and title tag
- [ ] Meta description under 155 chars with value prop
- [ ] URL: kebab-case, no stop words, includes primary keyword
- [ ] Internal links: 2-3 related posts/pages
- [ ] External links: 1-2 authoritative sources
- [ ] Structured data: Article or FAQ schema
- [ ] Image alt text with keyword
- [ ] Open Graph + Twitter Card meta tags
- [ ] Canonical URL set
- [ ] Mobile-friendly (test with Chrome DevTools)
- [ ] Core Web Vitals pass (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] llms.txt updated for AI discovery

## Error Handling

| Issue | Cause | Fix |
|-------|-------|-----|
| Page not indexed | No sitemap or blocked by robots.txt | Check robots.txt, submit URL in GSC |
| No Google AI Overview mention | Missing structured data | Add FAQ/HowTo/Article schema |
| Low citability score | No original research/data | Publish unique data, analysis, or insights |
| Schema not detected | Syntax error or wrong @type | Test with Google Rich Results Test |
| Slow LCP | Large images or render-blocking resources | Optimize images, inline critical CSS |

## Production Checklist

- [ ] Technical SEO audit passes (90%+)
- [ ] GEO audit passes (llms.txt, schema, entity clarity)
- [ ] Core Web Vitals pass (LCP, INP, CLS)
- [ ] Structured data: Organization + relevant types per page
- [ ] Sitemap.xml submitted to Google Search Console
- [ ] robots.txt correct
- [ ] hreflang configured (if multilingual)
- [ ] Canonical URLs on every page
- [ ] Open Graph + Twitter Cards on every page
- [ ] llms.txt published
- [ ] Brand entity defined in schema.org/Organization
- [ ] Google Search Console monitoring set up

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Keyword stuffing | Natural language. Write for humans, optimize for search. |
| Ignoring structured data | Schema is critical for both Google and AI search. |
| No original research | AI cites original data. Publish unique findings. |
| Thin content (< 300 words) | Comprehensive, authoritative content per topic. |
| Ignoring Core Web Vitals | Performance is a ranking factor. Optimize LCP/INP/CLS. |
| No E-E-A-T signals | Author bios, citations, credentials, about page. |
| Writing for "everyone" | Target specific search intent (informational, navigational, transactional). |

## Sources

- Google Search Central (developers.google.com/search)
- Google's E-E-A-T guidelines
- Google Rich Results Test
- Moz Beginner's Guide to SEO
- schema.org documentation
- GEO research: "Generative Engine Optimization" (2025-2026 papers)
- Perplexity Publisher Guidelines
- OpenAI GPT crawler documentation
