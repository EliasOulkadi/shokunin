# SEO Fundamentals (2026)

## Technical SEO

### Crawl Budget
- **Definition**: The number of pages a search engine crawls on your site within a given timeframe. Managed via robots.txt, sitemaps, internal linking, and server response times.
- **Optimization**:
  - XML sitemaps: max 50K URLs per sitemap, 50K entries per index. Priority signals but not directives.
  - `robots.txt` directives: `Disallow` low-value paths (`/search/`, `/cart/`, pagination filters, parameterized URLs).
  - `noindex` thin/duplicate content rather than blocking crawl — blocked pages waste crawl budget without signaling value.
  - Crawl rate setting in GSC: reduce for large sites (>100K pages) with slow servers.
  - `Last-Modified` and `304 Not Modified` responses: return 304 for unchanged pages to conserve crawl budget.
  - Internal link depth: pages deeper than 4 clicks from homepage get fraction of crawl budget.
- **Monitoring**: Google Search Console > Crawl Stats > Crawl requests per day, by response, by file type.

### Render Budget
- **Definition**: The computational cost (time + resources) for a search engine to fully render a page. Critical for JavaScript-rendered content (React, Angular, Vue, SPA).
- **Optimization**:
  - Server-side rendering (SSR) or static generation (SSG) for critical content. Next.js/Nuxt/SvelteKit preferred.
  - Dynamic rendering: serve pre-rendered HTML to crawlers, full JS to users.
  - Lazy-load below-the-fold content, non-critical JS, images.
  - Resource hints: `<link rel="preload">` for critical CSS/fonts, `<link rel="preconnect">` for 3rd-party origins.
  - Avoid layout shifts caused by deferred JS or dynamically injected content.
- **Testing**: Google URL Inspection Tool > Screenshot + rendered HTML. Compare raw HTML to rendered DOM.

### Core Web Vitals (2026 Update)
- **LCP (Largest Contentful Paint)**: < 2.5s. Optimize: preload hero image, use next-gen formats (WebP/AVIF), CDN, eliminate render-blocking resources.
- **INP (Interaction to Next Paint)**: < 200ms (replaced FID in 2024). Optimize: break long tasks (< 50ms), debounce handlers, use web workers, avoid main-thread layout thrashing.
- **CLS (Cumulative Layout Shift)**: < 0.1. Optimize: explicit width/height on images and embeds, reserve space for ads/dynamic content, use `aspect-ratio` CSS property.
- **TTFB (Time to First Byte)** (unofficial but monitored): < 800ms. Optimize: CDN, server location, caching headers, database query optimization, OPcache.
- **Tools**: Chrome UX Report (CrUX), PageSpeed Insights, Web Vitals library, Lighthouse CI.
- **2026 Trends**: Interaction readiness metrics gaining importance. Google may introduce new "responsiveness" composite score.

### JavaScript SEO
- Googlebot uses Chromium (version 126+ as of 2026). Crawls JS but with caveats:
  - Shallow crawl vs. deep render: budget-limited. Critical content must be in initial HTML.
  - Avoid client-side-only routing for content pages. Use `<link rel="canonical">` and proper history API.
  - Lazy Hydration: defer JS execution for non-critical interactivity.
  - `noscript` fallbacks are ignored by Googlebot — don't rely on them.
- **SPA considerations**: prerender.io or Rendertron for dynamic rendering; Next.js SSG/SSR for production.

### HTTPS & Security
- TLS 1.3 preferred. Valid certificate, no mixed content warnings.
- HSTS header (`Strict-Transport-Security: max-age=31536000; includeSubDomains`).
- CSP headers: mitigate XSS but ensure they don't block analytics/inline scripts needed for rendering.
- `Referrer-Policy: strict-origin-when-cross-origin`.

### Site Architecture & URL Structure
- Flat hierarchy: top-level pages within 3 clicks of homepage.
- URL conventions: lowercase, hyphens, descriptive (`/blog/seo-tips-2026` not `/blog/424?cat=seo`).
- Pagination: `rel="next"` / `rel="prev"` (deprecated by Google but still used by Bing). Better: infinite scroll with pushState.
- Faceted navigation: parameter handling via robots.txt or `noindex` on filter-heavy URLs.

### Log File Analysis
- Parse server logs to see actual crawler behavior (vs. GSC approximation).
- Key metrics: crawl frequency per URL, average response time by user-agent, crawl budget waste on redirects/4xx/5xx.
- Tools: Splunk, Elastic Stack, custom Python parsing with `pandas`.

---

## On-Page SEO

### Keyword Research
- **Process**:
  1. Seed keywords from product/services/core topics.
  2. Expand via: Google Keyword Planner, Ahrefs, Semrush, AlsoAsked, People Also Ask.
  3. Cluster by search intent: informational, navigational, commercial, transactional.
  4. Map keywords to funnel stages: TOFU (topical authority), MOFU (comparison), BOFU (purchase).
- **2026 Trends**:
  - Entity-first keyword mapping: cluster around topics/entities, not exact-match strings.
  - AI-generated search overviews (SGE) reduce click-through rates for informational queries. Target "appeared in AI overview" as KPI.
  - Question-based keywords gaining volume (voice search, AI chat queries).
  - Zero-volume keyword opportunities: emerging topics without search data but high AI citation potential.

### Title Tags
- Length: 50-60 chars. Front-load the primary keyword.
- Format: `Primary Keyword - Secondary Keyword | Brand` (pipe separator preferred).
- Unique per page. Avoid keyword stuffing.
- For AI overview targeting: write titles that directly answer the query.

### Meta Descriptions
- Length: max 160 chars (Google truncates beyond).
- Include primary keyword naturally. Add CTA for transactional pages.
- SGE impact: meta descriptions still used as fallback when AI overview doesn't trigger. Still critical for traditional SERP CTR.

### Headings (H1-H6)
- One H1 per page, matching the primary topic.
- H2s for major sections, H3s for subsections. Logical hierarchy.
- Include keywords naturally. Don't skip heading levels (H1 > H2 > H3).

### Content Optimization
- **Content length**: comprehensive coverage (1,500-2,500 words for competitive topics). Depth > word count.
- **Keyword usage**: in first 100 words, H2s, naturally throughout. Avoid exact-match density targets.
- **LSI/semantic terms**: include related entities, co-occurring terms, question variations.
- **Freshness**: update "best of" and statistics-based content quarterly. Google has recency bias for YMYL topics.
- **Media**: original images (not stock), video embeds, infographics. Alt text on all images.
- **Readability**: Flesch-Kincaid 60-70 for general audience. Short paragraphs, subheadings, bullet points.
- **AI content**: Google's helpful content system (now integrated into core ranking) evaluates helpfulness, not provenance. Human-review AI content for accuracy, originality, and E-E-A-T signals.

### Internal Linking
- Link relevant pages with descriptive anchor text.
- Silo architecture: topic clusters linked from pillar page.
- Orphan page detection: every page should have at least 1 internal link.
- Use breadcrumb schema for clear path signals.
- Link equity distribution: prioritize high-value pages (money pages, cornerstone content).

### Image SEO
- Descriptive filenames: `seo-checklist-2026.png` not `IMG_4242.png`.
- Alt text: describe the image, include keyword if natural. Decorative images: `alt=""`.
- Responsive images: `<picture>` element with `srcset` and `sizes` attributes.
- Next-gen formats: AVIF (best compression), WebP (wide support).
- Lazy loading: `loading="lazy"` for below-fold images. Use native lazy loading, not JS libraries.
- Captions: `<figure>` + `<figcaption>` for supplementary context.

### UX Signals
- Bounce rate, dwell time, pogo-sticking are correlated with rankings.
- Improve: fast load times, clear CTAs, readable typography, mobile-friendly layout, no intrusive interstitials.
- Mobile-first indexing: Google primarily uses mobile content for ranking. Ensure parity.

---

## Off-Page SEO

### Backlinks
- **Quality over quantity**: one link from a high-authority topical page > 100 low-quality directory links.
- **Link velocity**: natural growth pattern. Sudden spikes trigger spam filters.
- **Dofollow vs nofollow**: natural ratio (60-80% dofollow for healthy profiles). Nofollow still carries value for brand exposure.
- **Link relevance**: topical alignment matters more than domain authority. A link from a relevant niche site is worth more than a generic .edu.
- **Types**:
  - Editorial: earned naturally through content quality.
  - Guest posts: niche-relevant, no keyword-stuffed anchors.
  - Digital PR: data-driven stories, surveys, expert roundups.
  - Unlinked mentions: tools like Brand24 to find and convert.
- **Toxic link** disavowal: only for manual actions or algorithmic hits. Google largely ignores spammy links otherwise.

### E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)
- Not a direct ranking factor but a framework Google's Quality Raters use. Influences algorithm indirectly.
- **Experience**: first-hand participation. Reviews, testimonials, case studies, original research.
- **Expertise**: credentials, author bios with links to professional profiles, cited sources.
- **Authoritativeness**: mentions from credible sources, industry awards, citations from .gov/.edu, expert roundups.
- **Trustworthiness**: clear about page, contact info, privacy policy, secure checkout, factual accuracy, transparent sourcing.
- **YMYL (Your Money or Your Life)**: finance, health, legal, news sites require highest E-E-A-T. Author bylines with credentials, medical review boards, editorial oversight.
- **Implementation**:
  - Author schema (`@type=Person` with `knowsAbout`, `affiliation`, `sameAs`).
  - Organization schema with logo, social profiles, contact info.
  - About Us page with detailed team bios.
  - Fact-checking process documentation for news/media sites.

### Brand Signals
- Branded search volume growth.
- Direct traffic trends (GA4: user acquisition > direct).
- Social media mentions (LinkedIn, Twitter, Reddit, industry forums).
- Google Business Profile: complete, verified, with reviews and posts.
- NAP consistency (Name, Address, Phone) across all citations.
- Brand mentions (even unlinked) correlate strongly with rankings.

### Social Signals (Indirect)
- Content distribution via LinkedIn, Twitter/X, YouTube drives visibility → links → ranking.
- Social profiles rank for brand queries (SERP real estate control).
- Engagement metrics (shares, saves) influence content amplification.

### Local SEO
- GBP optimization: categories, products/services, Q&A, posts, reviews.
- Local citations: Moz Local, BrightLocal, Yext. Consistency is key.
- Local link building: sponsorships, chambers of commerce, local events.
- Reviews: volume, recency, diversity across platforms. Respond to all reviews.
- Schema: LocalBusiness, opening hours, geo coordinates.

---

## International SEO

### hreflang Implementation
- **Syntax**: `<link rel="alternate" hreflang="es-mx" href="https://example.mx/" />`
- **x-default**: specify for language-agnostic/auto-redirect page.
- **Placement**: in `<head>`, sitemap, or HTTP headers. Sitemap is easiest for large sites.
- **Common mistakes**:
  - Missing self-referencing hreflang (page must list itself).
  - Mismatched return tags (if page A links to page B, page B must link back).
  - Wrong language codes (`en-uk` should be `en-gb`).
- **Validation**: hreflang validator tools, GSC international targeting report.
- **2026 Note**: Google now uses hreflang as a strong signal but may override based on user location and content relevance.

### ccTLDs vs Subdomains vs Subdirectories
| Strategy | Pros | Cons |
|----------|------|------|
| **ccTLD** (.de, .fr) | Strongest geotargeting signal. | High maintenance, separate link equity, cost. |
| **Subdomain** (de.example.com) | Medium geotargeting, separate crawl queues. | Diluted domain authority. |
| **Subdirectory** (example.com/de/) | Shared domain authority, easiest maintenance. | Weakest geotargeting signal. |
- Recommendation: subdirectories with hreflang for most businesses. ccTLDs only for dedicated local teams/markets.

### Geotargeting in GSC
- Set target country in GSC per property (subdirectory or ccTLD).
- For ccTLDs: GSC automatically assigns country target. Subdomains/subdirectories need manual setting.
- Use `geo-platform` in sitemaps for market-level targeting signals.

### Multi-Regional Content Strategy
- **Translation vs. Localization**:
  - Translation: word-for-word (cheap, weak engagement).
  - Localization: cultural adaptation, local examples, local currency/measurements, local testimonials.
- Content duplication: don't run identical content across regions. Add localized sections, examples, data.
- Pricing: display local currency. Avoid USD-only for non-US markets.
- Legal compliance: GDPR (EU), CCPA (California), PIPEDA (Canada), LGPD (Brazil).

### CDN & Server Location
- Use CDN with edge nodes in target countries (Cloudflare, Fastly, AWS CloudFront).
- Server location is a weak geotargeting signal but still matters for TTFB and user experience.
- For ccTLDs: host in the target country if possible (improves speed + geotargeting signal).

---

## Monitoring & Tools

### Google Search Console
- Performance report: clicks, impressions, CTR, avg position. Filter by page, query, country, device.
- URL Inspection: test live URLs, view indexed vs. canonical, request indexing.
- Index Coverage: track indexed URLs, errors, warnings, excluded.
- Sitemaps: submit and monitor discovery.
- Core Web Vitals: LCP, INP, CLS breakdown by URL group.
- Manual Actions & Security Issues.

### Google Analytics 4
- Organic search traffic: session source = google / medium = organic.
- Landing page performance: bounce rate, engagement rate, conversions by page.
- Search Console integration: query-level data inside GA4.
- Attribution models: understand SEO's role in multi-channel conversion paths.

### Third-Party Tools
- **Crawling**: Screaming Frog, Sitebulb, DeepCrawl.
- **Backlinks**: Ahrefs, Semrush, Majestic, Moz.
- **Rank Tracking**: STAT, AccuRanker, Wincher.
- **Content**: Clearscope, SurferSEO, MarketMuse.
- **Technical**: GTmetrix, WebPageTest, DebugBear.
- **Log Analysis**: ELK Stack, Logz.io, custom Python.

### SEO KPIs (2026)
| KPI | Target | Notes |
|-----|--------|-------|
| Organic traffic growth | 10-20% MoM (early), 5-10% MoM (mature) | GA4 |
| Keyword rankings | Top 10 for 80% of target terms | Track by intent cluster |
| CTR from AI overviews | > 5% cite rate | Manual SGE monitoring |
| Core Web Vitals pass rate | > 90% of URLs | CrUX data |
| Crawl budget utilization | > 80% of allocated budget | GSC Crawl Stats |
| Index coverage ratio | > 95% of submitted URLs | GSC Index Coverage |
| Backlink growth | 5-15% MoM (organic) | Ahrefs/Semrush |
| Brand search volume | > 20% of total branded traffic | GSC Performance |
| E-E-A-T signals | Author pages, about page, reviews | Manual audit |
