---
name: seo-geo
description: SEO + Generative Engine Optimization (GEO) for 2026 — technical SEO, on-page optimization, structured data (JSON-LD, schema.org), Core Web Vitals, citability scoring (llms.txt, entity clarity), AI search engine optimization (ChatGPT, Gemini, Perplexity, Claude, Google AI Overviews), and brand authority building. Use when user asks to optimize a site for search engines, improve SEO, write SEO content, implement structured data, optimize for AI search/GEO, audit a page, or improve Google rankings. Do NOT use for content writing strategy (use content-marketing), performance optimization beyond Core Web Vitals (use performance-profiler), or paid ad strategy.
license: MIT
compatibility: opencode
metadata:
  workflow: marketing
  audience: developers
  version: "4.0"
  author: shokunin
allowed-tools: Read Bash Write Grep WebFetch
---

# SEO & GEO Architect

Optimize for traditional search AND AI-powered engines. Based on Google Search Central, Moz, and GEO research (2025-2026).

## Sub-Commands

| Command | Description |
|---------|-------------|
| `audit-seo` | Run full SEO audit (titles, meta, schema, speed, mobile) |
| `audit-geo` | Run GEO audit (llms.txt, entity clarity, AI answer format) |
| `schema` | Generate JSON-LD structured data for any page type |
| `optimize` | Implement priority fixes ranked by impact |
| `llms` | Generate/update llms.txt for AI crawler discovery |

## Workflow

### Step 1: Run SEO audit

Check: title tags (< 60 chars, keyword first), meta descriptions (< 155 chars, value prop), H1 (one per page, keyword), img alt text, OG tags, canonical, robots.txt, sitemap.xml, Core Web Vitals.

Score: 90-100% good. 70-89% fix flagged. < 70% structural issues first.

### Step 2: Run GEO audit

Check: llms.txt presence, ai-plugin.json, FAQ/HowTo schema, entity clarity, brand mention structure, answer format (direct answer in first 2 paragraphs).

### Step 3: Prioritized fixes

| Fix | Impact | Effort |
|-----|:------:|:------:|
| Fix crawl errors (GSC) | High | Low |
| Improve LCP < 2.5s | High | Medium |
| Add structured data (JSON-LD) | High | Medium |
| Create llms.txt | High | Low |
| Fix meta titles/descriptions | Medium | Low |
| Add hreflang (if multilingual) | Medium | Low |
| Improve internal linking | Medium | Medium |

### Step 4: Structured data (must implement)

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Brand Name",
  "description": "One sentence. What you do.",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": ["https://twitter.com/handle", "https://github.com/handle"]
}
```

Also: Article, FAQPage, HowTo, Product, BreadcrumbList, LocalBusiness (if applicable).

### Step 5: llms.txt

```
# Brand Name
> One-line description.

## Core pages
- https://example.com/: Home
- https://example.com/about: About

## Docs
- https://docs.example.com/api: API reference

## Blog
- https://example.com/blog/post: Title
```

Place at `/.well-known/llms.txt`. This is how AI crawlers (GPTBot, Claude, Gemini) discover your site.

### Step 6: GEO optimization

| Factor | Implementation |
|--------|---------------|
| Citability | Publish original research, unique data. AI cites sources. |
| Entity clarity | Clear about pages. Define who/what/for whom. |
| Answer format | Direct answer in first 2 paragraphs before expanding. |
| Conversational tone | Write naturally. AI penalizes keyword stuffing. |
| Source authority | Link to .edu, .gov, peer-reviewed. Build topical authority. |
| Brand mentions | Get mentioned on authoritative sites. |

## Production Checklist

- [ ] Technical SEO > 90%
- [ ] GEO audit passes (llms.txt, schema, entity clarity)
- [ ] Core Web Vitals pass (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] Structured data: Organization + page-specific types
- [ ] Sitemap.xml submitted to GSC
- [ ] robots.txt correct (not blocking anything important)
- [ ] hreflang configured (if multilingual)
- [ ] Canonical URLs on every page
- [ ] Open Graph + Twitter Cards on every page
- [ ] llms.txt published
- [ ] GSC monitoring active

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Keyword stuffing | Natural language. For humans first, search second. |
| No structured data | Schema critical for Google AND AI search. |
| No original research | AI cites original data. Publish unique findings. |
| Thin content (< 500 words) | Comprehensive, authoritative. |
| Ignoring Core Web Vitals | Performance is a ranking factor. |
| No E-E-A-T signals | Author bios, citations, credentials, about page. |

## Sources

- Google Search Central
- Google E-E-A-T guidelines
- schema.org documentation
- Moz Beginner's Guide to SEO
- GEO research papers (2025-2026)
- Perplexity Publisher Guidelines
- OpenAI GPT crawler docs

## Error Handling

| Cause | Fix |
|-------|-----|
| Google Search Console reports crawl errors on critical pages | Check robots.txt for accidental `Disallow: /` rules. Verify server returns 200 (not 5xx or 3xx loops). Submit individual URL inspection in GSC to trigger re-crawl. |
| Structured data (JSON-LD) fails Google Rich Results Test | JSON-LD must be a valid `@type` from schema.org (not a made-up type). Check required properties for the type. Use `application/ld+json` MIME type, not `text/javascript`. Escape HTML entities inside JSON strings. |
| llms.txt returns 404 when accessed at `/.well-known/llms.txt` | The `.well-known` directory requires explicit server routing. For static sites, place at root: `/llms.txt` and add a redirect from `/.well-known/llms.txt`. For Next.js, add to `public/` directory. |
| Core Web Vitals LCP > 4s despite image optimization | LCP element may not be an image — it could be a text block, video poster, or background image loaded via CSS. Identify the actual LCP element in PageSpeed Insights report. Preload critical resources with `<link rel="preload">`. |
| AI search engines (ChatGPT, Perplexity) ignore llms.txt | llms.txt is an emerging standard (2025-2026), not universally adopted. Complement with `ai-plugin.json`, comprehensive sitemap.xml, and clear entity pages. Submit to Perplexity Publisher Program separately. |
| Canonical URL points to wrong domain after migration | Stale canonicals cause duplicate content penalties. Audit all pages with a crawler (Screaming Frog, Sitebulb). Update in bulk with server-side redirects. Verify each canonical returns 200, not a redirect chain. |
| Hreflang tags return 404 or self-referencing loops | Each language variant must return a valid page. Use `x-default` for the language selector page. Validate with the hreflang tag tester in GSC International Targeting report. Remove broken variant links rather than leaving dead hreflang. |
| Site dropped in rankings after major redesign | URLs may have changed without 301 redirects. Audit before/after URL maps. Implement redirects for all high-traffic pages first (prioritize by organic traffic in GSC). Submit old sitemap + new sitemap to GSC simultaneously for faster re-indexing. |
