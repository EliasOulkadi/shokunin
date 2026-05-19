---
name: performance-profiler
description: Performance profiling and optimization for web apps — Core Web Vitals (LCP, INP, CLS), Lighthouse audits, bundle analysis, backend profiling (CPU, memory, DB queries), N+1 detection, caching strategies (Redis, CDN, HTTP), and performance budgets. Use when user asks to improve performance, run Lighthouse audit, profile a Node.js app, optimize Core Web Vitals, reduce bundle size, or investigate slow response times. Do NOT use for database schema optimization (use db-sculptor), Docker image optimization (use docker), or CDN configuration.
triggers:
  - "performance"
  - "optimize"
  - "slow"
  - "Lighthouse"
  - "Core Web Vitals"
  - "LCP"
  - "INP"
  - "CLS"
  - "bundle size"
  - "profiling"
  - "N+1 query"
  - "caching"
  - "response time"
negatives:
  - "schema optimization"
  - "Docker image optimization"
  - "CDN configuration"
  - "database indexes"
license: MIT
compatibility: opencode
metadata:
  workflow: quality
  audience: developers
  version: "4.0.0"
  author: shokunin
allowed-tools: Read Bash Write WebFetch
---


# Performance Profiler

Find and fix performance issues from frontend to backend. Based on Google Core Web Vitals, Lighthouse, Chrome DevTools, and production patterns from WebPageTest and clinic.js.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `audit` | Run comprehensive performance audit (frontend + backend) |
| `vitals` | Audit Core Web Vitals specifically (LCP, INP, CLS, TBT) |
| `lcp` | Optimize Largest Contentful Paint |
| `inp` | Fix Interaction to Next Paint (long tasks) |
| `bundle` | Analyze bundle size and split strategy |
| `backend` | Profile Node.js/Python backend performance |
| `budget` | Set and verify performance budgets |

## Workflow

### Step 1: Run Lighthouse audit (exact command)

```bash
npx lighthouse https://example.com --preset=desktop --output=html --output-path=./lighthouse-report.html
npx lighthouse https://example.com --preset=desktop --output=json --output-path=./lighthouse.json
```

Target scores:
| Metric | Target | Severity if missed |
|--------|--------|-------------------|
| Performance | > 90 | Critical |
| LCP (Largest Contentful Paint) | < 2.5s | Critical |
| INP (Interaction to Next Paint) | < 200ms | Critical |
| CLS (Cumulative Layout Shift) | < 0.1 | Critical |
| TBT (Total Blocking Time) | < 200ms | High |
| FCP (First Contentful Paint) | < 1.8s | Medium |
| Speed Index | < 3.4s | Medium |

### Step 2: Fix Core Web Vitals

#### LCP optimization (exact fixes)

```html
<!-- 1. Preload LCP image -->
<link rel="preload" as="image" href="hero.webp" fetchpriority="high">

<!-- 2. LCP image: no lazy loading -->
<img src="hero.webp" width="1200" height="600" fetchpriority="high" alt="">

<!-- 3. Inline critical CSS in <head> -->
<style>
  .hero { display: grid; min-height: 100dvh; }
  .hero img { width: 100%; height: auto; aspect-ratio: 2/1; }
</style>

<!-- 4. Defer non-critical CSS -->
<link rel="preload" href="styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">

<!-- 5. Self-host fonts with font-display: swap -->
@font-face {
  font-family: 'Geist';
  src: url('/fonts/geist.woff2') format('woff2');
  font-display: swap;
}
```

**LCP sub-parts breakdown:**
1. TTFB (Time to First Byte): < 800ms. Optimize server response. CDN. Caching.
2. Resource load delay: Preload + fetchpriority + no render-blocking.
3. Resource load time: Compress, CDN, modern format (WebP/AVIF).
4. Element render delay: Inline critical CSS. No layout-shifting JS above fold.

#### INP optimization (long task breakup)

```typescript
// Break up long tasks with scheduler.yield()
async function processLargeDataset(items: Item[]) {
  const CHUNK_SIZE = 50

  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE)
    processChunk(chunk)

    if (i + CHUNK_SIZE < items.length) {
      // Yield to main thread every 50ms
      await new Promise(resolve => setTimeout(resolve, 0))
    }
  }
}

// Or use scheduler.yield() (Chrome 115+)
for (let i = 0; i < items.length; i += CHUNK_SIZE) {
  processChunk(items.slice(i, i + CHUNK_SIZE))
  await scheduler.yield()
}
```

**Common INP causes:**
- Expensive event handlers (click, keydown, input)
- Synchronous layout reads/writes (layout thrashing)
- Large DOM manipulations in single frame
- JSON.parse() on large payloads (> 50KB)

#### CLS optimization

```css
/* Reserve space for images */
img, video, iframe {
  width: 100%;
  height: auto;
  aspect-ratio: attr(width) / attr(height);
}

/* Reserve space for dynamic content */
.ad-container {
  min-height: 250px;
}

/* Prevent layout shift from web fonts */
body {
  font-display: swap;
}

/* Fixed size for injected elements */
.cookie-banner {
  min-height: 80px;
}
```

### Step 3: Profile backend

```bash
# Node.js CPU profile
node --cpu-prof --cpu-prof-interval=1 server.js
# Analyze: clinic doctor -- node server.js

# Node.js heap snapshot
node --heapsnapshot server.js
# Load in Chrome DevTools > Memory tab

# Python profiling
python -m cProfile -o output.prof server.py
# Analyze: snakeviz output.prof
```

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| High CPU | N+1 queries, synchronous crypto | Add eager loading. Use async operations. |
| High memory | No streaming. Array growth. | Stream responses. Paginate results. |
| High latency p99 | DB lock contention | Add indexes. Use read replicas. |
| GC pauses | High allocation rate | Pool objects. Reduce allocations. Use Buffer pools. |
| Connection timeouts | Pool exhaustion | Increase pool size. Add connection queue. |

### Step 4: Bundle analysis

```bash
# Next.js
ANALYZE=true next build

# Vite/Rollup
npx vite-bundle-visualizer

# Generic
npx source-map-explorer dist/**/*.js
```

| Target | Budget |
|--------|--------|
| Total JS | < 300KB (gzipped) |
| Total CSS | < 50KB (gzipped) |
| Total fonts | < 100KB |
| First load JS | < 100KB (gzipped) |
| Total image payload | < 500KB |
| Largest chunk | < 150KB (gzipped) |

### Step 5: Caching strategy decision tree

| What | Cache where | TTL |
|------|-----------|-----|
| Static assets (JS, CSS, images) | CDN + browser | 1 year (versioned filenames) |
| API responses (public, stable) | CDN + HTTP Cache-Control | 5 min to 1h (stale-while-revalidate) |
| Dynamic data (user-specific) | Redis | 30s to 5min |
| Database query results | Application memory (LRU) | 10s |
| Full pages (public) | CDN + Edge caching | 5 min |
| Auth tokens | Never cache | — |

### Step 6: Performance budgets in CI

```json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "interactive": ["error", { "maxNumericValue": 3800 }],
        "total-blocking-time": ["error", { "maxNumericValue": 200 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "resource-summary:script:size": ["warn", { "maxNumericValue": 300000 }]
      }
    }
  }
}
```

```bash
npx lighthouse https://staging.example.com --output=json | \
  npx lighthouse-ci --collect --assert
```

## Production Checklist

- [ ] Lighthouse Performance > 90 (mobile throttled)
- [ ] LCP < 2.5s (p75 field data)
- [ ] INP < 200ms (p75 field data)
- [ ] CLS < 0.1 (p75 field data)
- [ ] Bundle: JS < 300KB, CSS < 50KB (gzipped)
- [ ] Images: WebP/AVIF, srcset, lazy loading below fold
- [ ] Fonts: self-hosted, font-display: swap, subset
- [ ] Critical CSS inlined, rest deferred
- [ ] Hero image preloaded with fetchpriority="high"
- [ ] Server response < 200ms (p95)
- [ ] N+1 queries detected and fixed
- [ ] CDN + HTTP caching configured
- [ ] CI: Lighthouse budget enforcement
- [ ] RUM (Real User Monitoring) configured

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Optimizing without measuring | Always measure first. Field data > lab data. |
| Only testing on dev machine | Test on real devices with throttling (3G, 4x CPU slowdown) |
| Cache everything | Cache only what changes infrequently. Stale cache is worse than no cache. |
| Lazy loading above-fold images | Only lazy load below-fold. LCP image must load immediately. |
| Bundle splitting too aggressively | Split at route boundaries. Not by component. |
| Optimizing non-bottleneck | Use Lighthouse + RUM to find actual bottleneck. |
| Ignoring mobile | Mobile is 2-4x slower than desktop. Optimize for mobile first. |
| No performance budget | CI must fail when budget exceeded. |

## Sources

- web.dev — Core Web Vitals
- Lighthouse documentation
- Addy Osmani — Performance optimization patterns
- Paul Lewis — RequestAnimationFrame, compositor-only properties
- Node.js performance guide
- clinic.js — Node.js profiling
- WebPageTest — Real device testing
- Chrome UX Report — Field data for Core Web Vitals

## Error Handling

| Cause | Fix |
|-------|-----|
| Lighthouse audit crashes on SPA with hash routing | Use `--chrome-flags="--disable-web-security"` or serve localhost via static server, never `file://` |
| Lighthouse scores vary 5+ points between runs | Normal. Run 3-5 times, use median. Always audit Incognito with no extensions. Variance from network jitter and CPU scheduling |
| Bundle analyzer can't parse source maps — blank treemap | Verify `devtool: 'hidden-source-map'` in webpack/Vite. Regenerate build with source maps enabled. Check `sourceMapFilename` matches |
| RUM field data shows much worse LCP than lab (Lighthouse) | Lab is synthetic (fast CPU/network). Field data from real users on slow devices. Trust field data. Optimize for p75, not median |
| Performance budget assertion fails CI on every PR | Investigate which chunk exceeded budget immediately. Treat as build failure. Block merge until resolved or budget explicitly raised with justification |
| Chrome DevTools Performance tab freezes on large trace (>30s) | Record shorter traces (5-10s max). Use `--user-data-dir` with clean profile. Export HAR for sharing instead of full trace |
| `clinic doctor` fails with "Cannot find module" | Works only with Node.js < 22. For Node 22+, use `node --cpu-prof` and analyze with Chrome DevTools. clinic is community-maintained, lagging Node releases |
| WebPageTest results vary significantly by test location | Test from 2+ geographic regions. Use `medianRun` and `repeatView` in WPT API. Document which locations were tested in audit report |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
