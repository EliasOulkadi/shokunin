---
name: performance-profiler
description: Performance profiling and optimization for web apps — Core Web Vitals (LCP, INP, CLS), Lighthouse audits, bundle analysis, backend profiling (CPU, memory, DB queries), N+1 detection, caching strategies (Redis, CDN, HTTP), and performance budgets. Use when user asks to improve performance, run Lighthouse audit, profile a Node.js app, optimize Core Web Vitals, reduce bundle size, or investigate slow response times. Do NOT use for database schema optimization (use db-sculptor), Docker image optimization (use docker), or CDN configuration.
license: MIT
compatibility: opencode
metadata:
  workflow: quality
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write WebFetch
---

# Performance Profiler

Find and fix performance issues from frontend to backend. Based on Google Web Vitals, Lighthouse, and profiling tools.

## Workflow

### Step 1: Run Lighthouse audit

```powershell
scripts/audit-lighthouse.ps1 -Url "https://example.com" -Device mobile
```

Outputs scores and metrics:
| Metric | Target | Your score |
|--------|--------|------------|
| Performance | > 90 | — |
| LCP | < 2.5s | — |
| INP | < 200ms | — |
| CLS | < 0.1 | — |
| TBT | < 200ms | — |
| FCP | < 1.8s | — |

**Decision tree:**
- **LCP > 2.5s**: Optimize largest contentful element (usually hero image or heading text)
- **INP > 200ms**: Find long tasks, optimize event handlers
- **CLS > 0.1**: Add size attributes to images/embeds, reserve space for dynamic content
- **TBT > 200ms**: Break up long tasks, defer non-critical JS
- **Overall < 90**: Fix all red metrics first, then yellow

### Step 2: Profile backend (if slow API response)

```powershell
scripts/profile-node.ps1 -ProcessName node
```

Checks:
- Event loop lag
- Heap memory usage (total vs used)
- CPU usage per process
- Garbage collection frequency

**If event loop lag > 50ms**: Blocking operations in the event loop. Look for:
- Synchronous file system operations (`fs.readFileSync`)
- Heavy JSON parsing
- CPU-intensive computations without worker threads
- Long Promise chains

### Step 3: Fix Core Web Vitals

See [references/web-vitals.md](references/web-vitals.md) for complete reference.

**LCP fixes (priority):**
```html
<!-- 1. Preload hero image -->
<link rel="preload" as="image" href="hero.webp">

<!-- 2. Inline critical CSS -->
<style>
  /* Above-the-fold styles only */
  .hero { ... }
</style>

<!-- 3. Optimize image delivery -->
<img src="hero.webp" width="1200" height="600" fetchpriority="high" alt="">
```

**INP fixes:**
- Break up long tasks with `setTimeout()` or `scheduler.yield()`
- Defer non-essential event handlers
- Use `requestAnimationFrame` for visual updates
- Avoid layout thrashing (batch DOM reads/writes)

**CLS fixes:**
```css
/* Reserve space for images */
img, video, iframe {
  aspect-ratio: auto;
  width: 100%;
  height: auto;
}

/* Reserve space for dynamic content (ads, embeds) */
.ad-container {
  min-height: 250px;
}
```

### Step 4: Optimize backend performance

See [references/backend-performance.md](references/backend-performance.md) for complete reference.

**Quick wins by symptom:**
| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| High CPU | N+1 queries, serialization | Add eager loading, paginate |
| High memory | No streaming, buffer buildup | Stream responses, add pagination |
| Slow endpoints | Missing indexes | EXPLAIN ANALYZE, add composite index |
| Variable latency | GC pauses | Reduce allocations, pool objects |
| Connection timeout | Pool exhaustion | Increase pool size, add read replicas |

### Step 5: Set performance budgets

```json
{
  "performance": {
    "budgets": [
      { "resourceType": "total", "budget": 500 },
      { "resourceType": "script", "budget": 200 },
      { "resourceType": "image", "budget": 200 },
      { "resourceType": "font", "budget": 50 }
    ],
    "timings": {
      "firstContentfulPaint": 1800,
      "largestContentfulPaint": 2500,
      "totalBlockingTime": 200,
      "cumulativeLayoutShift": 0.1
    }
  }
}
```

Set budgets in Lighthouse CI or bundle analyzer. Fail CI if budget exceeded.

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Lighthouse fails to launch Chrome | Chrome not found or headless flag issue | Install Chrome or specify path with -ChromePath |
| Profile shows nothing | Process already exited | Run profiling while app is under load |
| LCP is text but shows wrong element | LCP can be text (not just images) | Check LCP element in Lighthouse details |
| Bundle too large but no obvious cause | Duplicate dependencies | Use `npx madge` to find circular deps, `pnpm dedupe` |
| Memory keeps growing (leak) | Event listeners not cleaned up, closures | Check detached DOM nodes, interval cleanup |

## Production Checklist

- [ ] Lighthouse score > 90 on mobile
- [ ] Core Web Vitals pass (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] Bundle size < 500KB (JS), < 200KB (CSS)
- [ ] Image optimization (WebP/AVIF, lazy loading, responsive sizes)
- [ ] Font display: swap
- [ ] Server response time < 200ms (p95)
- [ ] N+1 queries detected and fixed
- [ ] Caching strategy: CDN + HTTP + application cache
- [ ] Performance budget in CI
- [ ] Real User Monitoring (RUM) set up

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Optimizing without measuring | Always measure first with Lighthouse/RUM |
| Only testing on dev machine | Test on real devices with throttling |
| Adding cache everywhere | Cache only what changes infrequently |
| Lazy loading above-fold content | Only lazy load below-fold images |
| Bundle splitting too aggressively | Split at route boundaries, not by component |
| Premature optimization | Focus on metrics that users actually notice |
| Ignoring mobile performance | Mobile is usually 2-4x slower than desktop |

## Sources

- web.dev — Core Web Vitals
- Lighthouse documentation (developers.google.com/web/tools/lighthouse)
- Addy Osmani — Performance optimization patterns
- Paul Lewis — RequestAnimationFrame, compositor-only properties
- Node.js performance guide (nodejs.org)
- Clinic.js documentation (clinicjs.org)
- WebPageTest (webpagetest.org)
