# Web Vitals Reference (2026)

> Core Web Vitals are Google's quality signals for user experience. As of 2026, INP has fully replaced FID. The three pillars: **LCP**, **INP**, **CLS**.

---

## LCP — Largest Contentful Paint (≤2.5 s)

Measures perceived load speed — when the largest content element (image, video, text block) becomes visible.

### Optimization checklist

| Technique | Impact | Effort |
|-----------|--------|--------|
| **Critical CSS** inline in `<head>` | High | Medium |
| **Image optimization** (AVIF/WebP, responsive `srcset`, lazy loading) | High | Low |
| **CDN** with edge caching + early hints (103 Early Hints) | High | Medium |
| **Preload key resources** (`<link rel=preload>`) | Medium | Low |
| **Server Timing header** in response | Low | Low |
| **Optimize TTFB** (server-side caching, DB queries, edge compute) | High | High |
| **Eliminate render-blocking resources** (defer JS, inline critical CSS) | High | Medium |
| **Compression** (Brotli > Gzip) | Medium | Low |
| **HTTP/2 or HTTP/3** multiplexing | Medium | Low |
| **Minimize DOM size** — keep under 1500 nodes | Low | Low |

### Good thresholds
- **Good**: ≤2.5 s
- **Needs improvement**: 2.5–4.0 s
- **Poor**: >4.0 s

---

## INP — Interaction to Next Paint (≤200 ms)

Measures responsiveness — the time from a user interaction (click, tap, keypress) to the next paint. Replaced FID in March 2024.

### Optimization checklist

| Technique | Impact | Effort |
|-----------|--------|--------|
| **Break up long tasks** (>50 ms) via `setTimeout`, `requestIdleCallback`, or yielding | High | Medium |
| **Debounce / throttle event handlers** (scroll, resize, input) | Medium | Low |
| **Avoid `layout thrashing`** — batch DOM reads before writes | Medium | Low |
| **Use `content-visibility: auto`** for off-screen content | Medium | Low |
| **Web Workers** for heavy computation | High | High |
| **Minimize main-thread work** — reduce JS bundle size, code-split | High | High |
| **Avoid `document.write`** | Low | Low |
| **Use `pointer-events` instead of JS hover detection** | Low | Low |

### Good thresholds
- **Good**: ≤200 ms
- **Needs improvement**: 200–500 ms
- **Poor**: >500 ms

---

## CLS — Cumulative Layout Shift (≤0.1)

Measures visual stability — unexpected movement of visible elements during load.

### Optimization checklist

| Technique | Impact | Effort |
|-----------|--------|--------|
| **Explicit width + height attributes** on images and videos | High | Low |
| **`aspect-ratio` CSS property** for responsive containers | High | Low |
| **`font-display: swap` + `size-adjust`** for @font-face | Medium | Low |
| **Reserve space for embeds** (ads, iframes, widgets) | High | Medium |
| **Avoid inserting dynamic content above existing content** | High | Medium |
| **Prefer `transform: translate()`** over `top`/`left` for animations | Low | Low |
| **Set min-height on dynamically loaded sections** | Medium | Low |
| **Web Fonts** — use `font-display: optional` for non-critical text | Medium | Low |

### Good thresholds
- **Good**: ≤0.1
- **Needs improvement**: 0.1–0.25
- **Poor**: >0.25

---

## Measuring

### Web Vitals library (JS)

```js
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

Returns `{ name, value, rating, delta, id }` for each metric.

### Lighthouse

```bash
# via CLI
lighthouse https://example.com --preset=desktop --output=json --output=html

# via Node
const { lighthouse } = require('lighthouse');
const report = await lighthouse(url, { preset: 'desktop' });
```

### CrUX (Chrome User Experience Report)

- BigQuery: `chrome-ux-report.all.2026*`
- API: `https://chromeuxreport.googleapis.com/v1/records:queryRecord`
- PSI (PageSpeed Insights): wraps CrUX + Lighthouse in one endpoint.

### RUM (Real User Monitoring)

Collect from real users:

```js
// Send to your analytics
onLCP((m) => navigator.sendBeacon('/analytics', JSON.stringify(m)));
```

---

## Server Timing Header

Helps differentiate server vs client contribution:

```
Server-Timing: db;dur=120, cache;dur=30, render;dur=65
```

Exposed in DevTools Network tab → Timing.

---

## Budgets

Set performance budgets in `lighthouserc.js`:

```js
module.exports = {
  ci: {
    assert: {
      assertions: {
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'interaction-to-next-paint': ['error', { maxNumericValue: 200 }],
        'cumulative-layout-shift':  ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time':      ['error', { maxNumericValue: 200 }],
      },
    },
  },
};
```

---

## Key Tools

- **Lighthouse CI** — automates budget enforcement in CI/CD
- **WebPageTest** — multistep, location-aware waterfall
- **Chrome DevTools Performance tab** — frame-by-frame analysis
- **Speedcurve / Calibre / Treo** — RUM dashboards
- **BundlePhobia** — JS cost per package
