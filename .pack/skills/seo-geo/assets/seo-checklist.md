# SEO/GEO Pre-Publish Checklist

## Keyword Research
- [ ] Primary keyword identified with clear search intent (informational/navigational/commercial/transactional)
- [ ] Secondary keywords (3-5) mapped to subtopics
- [ ] Question-based keywords analyzed (People Also Ask, AlsoAsked)
- [ ] Keyword difficulty assessed (target: < 50 for new sites, < 70 for established)
- [ ] AI overview trigger checked: does this keyword trigger SGE/Perplexity answers?
- [ ] Entity/topic cluster defined: which pillar does this page belong to?
- [ ] SERP analysis done: what formats rank? (listicles, guides, videos, products)
- [ ] Zero-volume keyword opportunities noted for GEO targeting

## Technical SEO
- [ ] HTTPS enforced (no mixed content warnings)
- [ ] Canonical URL set (self-referencing if no duplicate)
- [ ] Robots meta: index, follow (unless intentionally noindex)
- [ ] robots.txt allows crawling for this URL path
- [ ] XML sitemap includes this URL (with lastmod)
- [ ] Page is not blocked by robots.txt or noindex
- [ ] URL structure: lowercase, hyphens, no special chars, descriptive slug
- [ ] URL length: under 60 characters, no stop words if possible
- [ ] Hreflang tags if multi-language/multi-region
- [ ] Pagination handled (rel next/prev or infinite scroll with pushState)
- [ ] 301 redirects mapped if URL changed from draft to live
- [ ] Trailing slash consistency checked (enforce or strip, not mixed)
- [ ] Language attribute on `<html>` tag
- [ ] Viewport meta tag present and responsive

## Core Web Vitals & Performance
- [ ] LCP: hero image preloaded, size < 100KB, modern format (WebP/AVIF)
- [ ] INP: long tasks (< 50ms), debounced handlers, no main-thread layout thrashing
- [ ] CLS: explicit width/height on all images, videos, iframes, embeds
- [ ] TTFB: server response < 800ms (target < 200ms)
- [ ] Render-blocking resources minimized (defer/async non-critical JS/CSS)
- [ ] Critical CSS inlined above the fold
- [ ] Fonts: self-hosted or preconnect, font-display: swap
- [ ] Images: lazy loading (`loading="lazy"`) for below-fold
- [ ] Mobile responsiveness tested (real device, not just dev tools)
- [ ] Page weight: under 500KB initial load (excluding media)
- [ ] Lighthouse score: 90+ on all categories (desktop + mobile)
- [ ] Web Vitals library or RUM monitoring configured

## On-Page SEO
- [ ] Title tag: 50-60 chars, primary keyword front-loaded
- [ ] Meta description: under 160 chars, includes keyword, CTA for transactional
- [ ] H1: exactly one, matches primary topic, includes primary keyword
- [ ] H2-H3 hierarchy: logical structure, keywords in subheadings naturally
- [ ] Primary keyword in first 100 words of body content
- [ ] Secondary keywords distributed naturally throughout
- [ ] Content length: 1,500+ words (adjust by competitiveness and topic depth)
- [ ] Readability: Flesch-Kincaid 60-70, short paragraphs (< 4 sentences)
- [ ] Internal links: 3-5+ relevant links to other pages
- [ ] External links: 1-3+ to authoritative sources (opens in new tab)
- [ ] Anchor text: descriptive, varied, not over-optimized
- [ ] Bullet points / numbered lists used for scannable content
- [ ] Bold/strong on key terms (not excessive)
- [ ] No keyword stuffing (keyword density under 3%)
- [ ] Thin content check: does this page provide unique value vs competitors?
- [ ] E-E-A-T signals: author bio, credentials, publication date, references
- [ ] AI-generated content reviewed: accuracy, originality, E-E-A-T compliance
- [ ] Freshness: publication date shown, update date for revised content
- [ ] Table of contents for long-form content (internal anchor links)

## Image & Media SEO
- [ ] All images have descriptive alt text (keyword where natural, decorative = alt="")
- [ ] Image filenames: descriptive, hyphenated (e.g., `seo-checklist-2026.png`)
- [ ] Images optimized: WebP/AVIF, compressed, under 100KB (200KB max for hero)
- [ ] Video: hosted properly (self or YouTube/Vimeo), title, description, transcript
- [ ] Video schema included if video is primary content
- [ ] Responsive images: srcset + sizes attributes
- [ ] Captions for images where context helps (figure + figcaption)
- [ ] PDFs: if linked, include text HTML version too

## Structured Data
- [ ] Article/BlogPosting schema present with headline, author, publisher, date
- [ ] Organization schema (global for all pages)
- [ ] Person schema for each author (knowsAbout, affiliation, sameAs)
- [ ] BreadcrumbList schema on all pages
- [ ] FAQPage schema if page contains Q&A content
- [ ] HowTo schema if page contains step-by-step instructions
- [ ] Product schema if e-commerce (price, availability, reviews, MPN/SKU)
- [ ] LocalBusiness schema if local business (opening hours, address, phone)
- [ ] VideoObject schema if page has video
- [ ] ImageObject schema for main image
- [ ] WebPage schema with about + mentions for entity definition
- [ ] JSON-LD syntax (preferred over microdata/RDFa)
- [ ] Schema validated with Google Rich Results Test
- [ ] Manual testing: no schema warnings or errors
- [ ] Schema data matches visible page content (no deception)

## GEO-Specific (AI Search Optimization)
- [ ] llms.txt created/referenced for AI crawler guidance
- [ ] FAQ schema present (highly weighted by all AI engines)
- [ ] Entity types: Organization + Person defined in schema
- [ ] Entity relationships mapped: broader, narrower, mentions
- [ ] Author schema with sameAs links (LinkedIn, Twitter, Google Scholar)
- [ ] Standalone answer sentences: "GEO increases citations by 40%"
- [ ] Questions in content matched by FAQ schema
- [ ] Content covers: definitions, comparisons, data, pros/cons, alternatives
- [ ] Original data/statistics with methodology (AI prefers primary sources)
- [ ] Clear entity definition: what is the page about? (about + @id)
- [ ] No ambiguity in claims: specific, verifiable statements
- [ ] Answer format optimized: Q&A pairs, lists, tables, definitions
- [ ] Brand name used consistently throughout
- [ ] Brand entity connected to Wikidata entry
- [ ] Knowledge Panel data matches page schema
- [ ] Competitive gap analysis: does this page cover angles competitors miss?

## Social & Open Graph
- [ ] og:title — should match or closely align with <title>
- [ ] og:description — 2-3 sentences, compelling, includes keyword
- [ ] og:image — 1200x630px, optimized, includes text overlay if helpful
- [ ] og:url — canonical URL
- [ ] og:type — article, website, product, etc.
- [ ] og:locale — language + region (e.g., en_US)
- [ ] og:site_name — brand name
- [ ] Twitter card: summary_large_image for articles, summary for others
- [ ] Twitter card image (may differ from og:image)
- [ ] Social preview tested via validator tools

## User Experience & Accessibility
- [ ] Mobile-first: content same on mobile and desktop (no hidden content)
- [ ] Font size: minimum 16px for body text
- [ ] Contrast ratio: 4.5:1 minimum for body text (WCAG AA)
- [ ] Tap targets: minimum 48x48px on mobile
- [ ] No intrusive interstitials (popups that block content on mobile)
- [ ] Keyboard navigable (tab order, focus indicators)
- [ ] Skip navigation link present
- [ ] ARIA landmarks: banner, main, navigation, contentinfo
- [ ] Forms: labels associated, error messages clear
- [ ] Animations: prefers-reduced-media respected
- [ ] Print stylesheet (for article/content pages)
- [ ] 404 page: useful, branded, with navigation back to content

## Off-Page Pre-Launch
- [ ] Internal links to this page from existing content in place
- [ ] Pillar page updated with link to this new content
- [ ] Sitemap submitted to GSC (request indexing)
- [ ] Sitemap submitted to Bing Webmaster Tools
- [ ] IndexNow API pinged (if supported by hosting)
- [ ] Social media promotion queued (LinkedIn, Twitter/X, relevant communities)
- [ ] Backlink outreach: 3-5 relevant sites to notify of new resource
- [ ] Internal link equity: no deep orphan pages created
- [ ] Google Search Console URL Inspection: "URL is on Google" confirmed
- [ ] Page load time verified after publishing

## Post-Publish Monitoring
- [ ] GSC: performance report checked after 48 hours
- [ ] Indexing confirmed: "indexed, not submitted in sitemap" vs "submitted and indexed"
- [ ] Crawl errors: none (4xx, 5xx, soft 404)
- [ ] Core Web Vitals: real-user data within normal range (CrUX)
- [ ] AI overviews: check if this page is cited in SGE (target keywords)
- [ ] Citation audit: search brand + article title in Perplexity, ChatGPT
- [ ] Traffic baseline: current vs 7-day post-publish
- [ ] Bounce rate: acceptable range (40-60% for informational, lower for transactional)
- [ ] Backlinks appearing: monitor Ahrefs/Semrush for organic links
- [ ] Content freshness: schedule next update (quarterly for timeliness-dependent pages)
- [ ] Competitor reaction: monitor if competitors create similar content
- [ ] Internal link updates: add more internal links from related content (30-day check)
- [ ] Schema performance: check Rich Results report in GSC (impressions, clicks)

## GEO-Specific Post-Publish
- [ ] Perplexity citation: search brand name + topic weekly
- [ ] ChatGPT Search citation: query key topics monthly
- [ ] Google SGE appearance: track target keywords for AI overview
- [ ] Brand search volume change: GSC brand query tracking
- [ ] Wikidata: update entity with new published content
- [ ] Knowledge Panel: verify no incorrect AI-generated summary of page
- [ ] llms.txt: update if new content added to site architecture
- [ ] Structured data: monitor for Google algorithm changes affecting schema interpretation
- [ ] AI hallucination check: does any AI engine attribute incorrect info to your brand?

---

## Quick Reference: Maximum Targets

| Element | Target |
|---------|--------|
| Title length | 50-60 characters |
| Meta description | 120-155 characters |
| Content length | 1,500-2,500 words (competitive) |
| Internal links per page | 3-5 minimum |
| External links per page | 1-3 minimum |
| Paragraph length | Under 4 sentences |
| Flesch-Kincaid | 60-70 |
| Image size (hero) | Under 100KB |
| Image format | WebP (AVIF if supported) |
| TTFB | Under 200ms |
| LCP | Under 2.5s |
| INP | Under 200ms |
| CLS | Under 0.1 |
| Lighthouse score | 90+ |
| FAQ schema items | 3-10 per page |
| Schema types per page | 3-5 minimum |
| llms.txt sections | 3+ |
| Brand mentions per page | 3+ |
