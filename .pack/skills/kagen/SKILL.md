---
name: kagen
description: Convert Kami HTML templates to production-grade PDF via Chromium/Playwright. Complements Kami (design) with PDF rendering. Use when user asks to generate PDF files, render HTML to PDF, or export documents.
triggers:
  - "render PDF"
  - "convert HTML to PDF"
  - "PDF from template"
  - "Kami render"
  - "Kagen"
  - "HTML to PDF"
  - "Playwright PDF"
  - "PDF generation"
  - "Chromium PDF"
negatives:
  - "design PDF"
  - "create template"
  - "HTML design"
  - "CSS styling"
  - "branding"
  - "document design"
  - "PDF design template" -> use kami
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: documents
  audience: developers
---

# kagen · 紙源

**紙源 · かげん** - paper source. PDF generation companion to Kami.

Kami designs, **Kagen ships**. Converts Kami HTML templates to production-grade PDF using Chromium (Playwright), bypassing WeasyPrint's Windows limitations.

## Why Kagen

| Problem | Solution |
|---------|----------|
| WeasyPrint doesn't work on Windows (no GTK) | Kagen uses Playwright/Chromium — works everywhere |
| WeasyPrint cold-start ~630ms per render | Playwright warm ~13ms per render |
| WeasyPrint can't execute JS | Chromium renders fully (charts, dynamic content) |
| wkhtmltopdf is deprecated and unmaintained | Playwright is actively maintained by Microsoft |

Based on benchmarks (pdf4.dev 2026), engineering discussions (HN, Stack Overflow, BrowserStack), and production experience from DocRaptor, customjs.space, and print-css.rocks.

## Prerequisites

- Node.js 20+
- Playwright (`npx playwright` auto-installs on first use)
- Chromium browser installed (`npx playwright install chromium`)
- Kami HTML templates (any valid HTML with print CSS)

## Quick start

```powershell
npx playwright pdf "file:///path/to/doc.html" "output.pdf"
```

Or from Node.js:

```js
const { chromium } = require('playwright');
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('file:///path/to/doc.html', { waitUntil: 'networkidle' });
await page.pdf({
  path: 'output.pdf',
  format: 'A4',
  printBackground: true,
  margin: { top: '0', bottom: '0', left: '0', right: '0' }
});
await browser.close();
```

## Production settings (from professional research)

### Page options

```js
await page.pdf({
  path: 'output.pdf',
  format: 'A4',              // or 'Letter', 'A3'
  printBackground: true,     // always true — renders parchment bg
  margin: { top: '0', bottom: '0', left: '0', right: '0' },
  // For screen media (not print):
  // await page.emulateMedia({ media: 'screen' });
});
```

### Critical CSS rules for reliable PDF output

```css
/* Always include in your HTML template header */

@page {
  size: A4;
  margin: 24mm 26mm 26mm 26mm;
  background: #f5f4ed;
  widows: 4;
  orphans: 4;
}

/* Force background colors in Chromium */
* {
  -webkit-print-color-adjust: exact;
  print-color-adjust: exact;
}

/* Avoid orphan text lines — high widows/orphans prevents single-line splits */
body { widows: 4; orphans: 4; }
p    { widows: 3; orphans: 3; }
li   { widows: 2; orphans: 2; }

/* Page break control — only on chapters with heavy content */
.chapter { }
.chapter.break { break-before: page; }

/* Never let a heading sit alone at page bottom */
h1, h2, h3, h4 { break-after: avoid; }

/* Keep these blocks intact — never split across pages */
table, pre, figure, .callout, .card,
blockquote, .finding-header, .takeaway {
  break-inside: avoid;
}

/* Avoid code blocks getting orphaned from their preceding paragraph */
pre {
  margin-top: 6pt;
  page-break-before: avoid;
}

/* Tables should not break rows across pages */
table tr {
  break-inside: avoid;
}
```

### Visual patterns by document type

Each document type needs its own set of visual patterns. Apply accordingly:

| Type | Required patterns | Optional patterns |
|------|----------------------|---------------------|
| **Pentest / Security report** | Severity badges (red/orange/green), risk bar, code blocks with left border, impact/remediation boxes | Finding-header with metadata, findings table with badges |
| **One-pager / Executive summary** | Glance grid (4 metrics), lead paragraph, takeaway box, cover with large title + decorative line | Callout for key data point, footer with contact |
| **White paper / Long doc** | Chapter breaks in dense sections, table of contents, callouts, keep-together on critical blocks | Quotes, diagrams, appendix |
| **Letter** | Wide margins (25mm), formal greeting and closing, no columns, no tables | Letterhead, signature |
| **Resume** | Dense body (9.2pt), metric row, project bullets with action + result | Timeline, skills grid |
| **Slides** | Assertion-evidence titles, one idea per slide, one-line bullets, pinned callout | Code cards, 2x2 table |

**Rule:** if the document type isn't in the table, choose the closest one and adapt.

### Near-empty pages prevention

Nothing looks more amateur than a page with 2 lines. Causes and solutions:

| Cause | Solution | Auto-detection |
|-------|----------|---------------------|
| Heading with 1 short paragraph at the end | Merge with previous section | If a chapter has only 1 h2 + 1 p, it doesn't deserve its own page |
| `break-before: page` on every section | Only use on chapters with >1/3 page of content | Count paragraphs + tables + lists. If they add up to less than 5 elements, don't force a break |
| `break-inside: avoid` on large block that doesn't fit | Relax `break-inside` or split the block | If a keep-together measures more than 1 page, don't force it |
| Source list at the end spilling onto a separate page | Move to consolidated sources chapter | Sources go in one place, not repeated in each chapter |

### AI anti-patterns in documents

Validate that content inherited from Kami doesn't have these marks:

| Anti-pattern | Problem | Fix |
|-------------|----------|-----|
| Repeated em dash `—` as label/value separator | `Black Box — no credentials`, multiple lines in a row | Parentheses, comma, colon. The dash is for genuine asides, not for separating labels |
| Uniform tables without color | All rows identical, no visual indication of severity or priority | Color badges, subtle zebra rows, highlighted first column |
| Code blocks without contrast | They blend with the body, don't look like code | Left blue border, ivory background, monospace, generous padding |
| Same structure on every page | Every page is title + table or title + list | Vary: finding box, risk bar, flowchart, callout. Alternate rhythm |
| Claims without source | "LLMs hallucinate 15-20%" without attribution | "According to Vectara HHEM 2026, LLMs..." |

### Best practices from professionals

| Practice | Source | Why |
|----------|--------|-----|
| Always set `printBackground: true` | BrowserStack, Playwright docs | Kami uses parchment bg #f5f4ed — Chromium strips it by default |
| Use `file://` protocol | Stack Overflow, DocuPotion | Avoids auth/CORS issues with local files |
| Set `waitUntil: 'networkidle'` | BrowserStack | Ensures fonts, CSS fully loaded |
| Lock browser version in CI | BrowserStack, blog.rasc.ch | Chromium updates can change rendering |
| Use `@page` margins, not Playwright margins | print-css.rocks, CSS Paged Media spec | CSS margins are more predictable for paged media |
| `-webkit-print-color-adjust: exact` | MDN, Chromium docs | Critical for parchment backgrounds and brand colors |
| Reuse browser instance (warm) | pdf4.dev benchmark | 42ms → 3ms speedup (14x) |
| Validate PDF visually in CI | BrowserStack | Page count, whitespace, font check |

## Warm mode (production pipeline)

```js
const { chromium } = require('playwright');

class PDFRenderer {
  constructor() {
    this.browser = null;
  }

  async start() {
    this.browser = await chromium.launch();
  }

  async render(htmlPath, outputPath) {
    const page = await this.browser.newPage();
    await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), {
      waitUntil: 'networkidle'
    });
    await page.pdf({
      path: outputPath,
      format: 'A4',
      printBackground: true,
      margin: { top: '0', bottom: '0', left: '0', right: '0' }
    });
    await page.close();
  }

  async stop() {
    await this.browser.close();
  }
}
```

## Font embedding

Chromium embeds system fonts by default. For custom fonts (like TsangerJinKai02 in Kami):

```css
@font-face {
  font-family: "CustomFont";
  src: url("fonts/CustomFont.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
}
```

Place font files relative to the HTML and use relative `src` paths. Chromium resolves them from the HTML file's directory.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| White background instead of parchment | Add `printColorAdjust: exact` in CSS and `printBackground: true` in JS |
| Fonts not rendering | Use relative paths in `@font-face`, check font file exists |
| Page breaks wrong | Check `break-inside: avoid` on tables, pre, callout |
| Near-empty page (2 lines alone) | Merge short section with previous; avoid `break-before: page` on light chapters |
| Content overflow | Use `page-break-inside: avoid` on large blocks |
| Chinese chars as boxes | Include CJK font in `@font-face` or use system CJK fallback |
| PDF too large | Remove unnecessary images, compress embedded fonts |
| Slow first render | Keep browser instance alive (warm mode) |

### CSS visual pattern snippets

Concrete patterns to include in the HTML by document type:

```css
/* Severity badges (pentest, security) */
.badge-high { background: #f5e8e8; color: #a83030; display: inline-block; padding: 2pt 7pt; border-radius: 3pt; font-size: 8pt; font-weight: 500; text-transform: uppercase; }
.badge-medium { background: #f5ede2; color: #b86a25; display: inline-block; padding: 2pt 7pt; border-radius: 3pt; font-size: 8pt; font-weight: 500; text-transform: uppercase; }
.badge-ok { background: #e8f2ec; color: #2a7a4a; display: inline-block; padding: 2pt 7pt; border-radius: 3pt; font-size: 8pt; font-weight: 500; text-transform: uppercase; }

/* Risk bar (pentest exec summary) */
.risk-bar { display: flex; gap: 2pt; margin: 8pt 0 14pt 0; height: 12pt; }
.risk-bar .seg { border-radius: 2pt; display: flex; align-items: center; justify-content: center; font-size: 7pt; color: #fff; font-weight: 500; }

/* Code blocks with left border (pentest, technical) */
pre { border-left: 2.5pt solid #1B365D; border-radius: 3pt; background: #faf9f5; padding: 10pt 14pt; font-family: Consolas, monospace; font-size: 9pt; line-height: 1.5; break-inside: avoid; }

/* Impact/Remediation boxes (pentest) */
.impact-box, .remediation-box { border-left: 2pt solid #e8e6dc; padding-left: 12pt; margin: 10pt 0 14pt 0; break-inside: avoid; }
.impact-box .label, .remediation-box .label { font-size: 8.5pt; letter-spacing: 0.8pt; text-transform: uppercase; font-weight: 500; color: #1B365D; margin-bottom: 4pt; }

/* Cover accent line */
.cover-line { width: 60pt; height: 2pt; background: #1B365D; margin: 20pt 0; border-radius: 1pt; }

/* Pipeline flow (4 step horizontal) */
.pipeline-flow { display: flex; gap: 0; margin: 18pt 0; break-inside: avoid; }
.pipeline-step { flex: 1; text-align: center; padding: 10pt 8pt; }
.pipeline-step .dot { width: 6pt; height: 6pt; border-radius: 50%; background: #1B365D; margin: 0 auto 5pt auto; }
.pipeline-step + .pipeline-step { border-left: 0.5pt dotted #e8e6dc; }
.pipeline-step .name { font-size: 9pt; font-weight: 500; color: #141413; margin-bottom: 3pt; }
.pipeline-step .desc { font-size: 7.5pt; color: #6b6a64; line-height: 1.35; }

/* Keep-together wrapper */
.keep-together { break-inside: avoid; }
```

### Self-review protocol (mandatory)

Don't generate the PDF without passing this checklist. Each item is a real failure documented in previous iterations.

### Structural (blocking)
- [ ] Each chapter has enough content to fill >1/3 of a page
- [ ] No sections with just heading + 1 short paragraph (merge)
- [ ] No near-empty pages (2 lines alone)
- [ ] `break-before: page` only on chapters with dense content

### Visual (high priority)
- [ ] Visual elements match the document type (badges, risk bars, code blocks, etc.)
- [ ] Tables have proper styling (optional zebra, padding, clear headers)
- [ ] Code blocks are distinguishable from body (border, background, monospace)
- [ ] No repeated em dashes `—` used as label/value separators
- [ ] There's variety in visual rhythm (not all pages the same)

### Content (high priority)
- [ ] Every categorical claim has its visible source ("according to X...")
- [ ] Internal methodology is distinguished from verified fact (disclaimer if applicable)
- [ ] No redundant content between chapters (sources, repeated lists)
- [ ] Every paragraph is necessary (if it can be removed without loss, remove it)

### Technical (blocking)
- [ ] `printBackground: true` in Playwright configuration
- [ ] `-webkit-print-color-adjust: exact` in CSS
- [ ] `widows: 4; orphans: 4` in @page and body
- [ ] `break-inside: avoid` on pre, table, blockquote, callout
- [ ] `table tr { break-inside: avoid }` so tables don't split rows

## Complete HTML example

Minimum functional template that includes all essential patterns. Copy and adapt:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Document Title</title>
<style>
  @page { size: A4; margin: 24mm 26mm 26mm 26mm; background: #f5f4ed; widows: 4; orphans: 4; }
  * { box-sizing: border-box; margin: 0; padding: 0; -webkit-print-color-adjust: exact; }
  :root {
    --parchment: #f5f4ed; --ivory: #faf9f5; --near-black: #141413;
    --dark-warm: #3d3d3a; --olive: #504e49; --stone: #6b6a64;
    --brand: #1B365D; --border: #e8e6dc; --border-soft: #e5e3d8;
    --serif: Charter, Georgia, Palatino, "Times New Roman", serif;
    --mono: Consolas, "Courier New", monospace;
  }
  body { font-family: var(--serif); font-size: 10.5pt; line-height: 1.65; color: var(--near-black); background: var(--parchment); widows: 4; orphans: 4; }
  h1 { font-size: 24pt; border-left: 2.5pt solid var(--brand); padding-left: 8pt; margin: 0 0 10pt 0; break-after: avoid; }
  h2 { font-size: 16pt; margin: 24pt 0 8pt 0; break-after: avoid; }
  p { margin: 0 0 10pt 0; widows: 3; orphans: 3; }
  table { width: 100%; border-collapse: collapse; font-size: 9.5pt; margin: 12pt 0; break-inside: avoid; }
  table th { text-align: left; padding: 6pt 8pt; border-bottom: 1pt solid var(--border); background: var(--ivory); }
  table td { padding: 5pt 8pt; border-bottom: 0.3pt solid var(--border-soft); }
  table tr { break-inside: avoid; }
  pre { border-left: 2.5pt solid var(--brand); border-radius: 3pt; background: var(--ivory); padding: 10pt 14pt; font-size: 9pt; font-family: var(--mono); break-inside: avoid; margin: 6pt 0 10pt 0; }
  .callout { background: var(--ivory); border-left: 2pt solid var(--brand); padding: 10pt 14pt; border-radius: 3pt; margin: 12pt 0; break-inside: avoid; }
  .keep-together { break-inside: avoid; }
  .break { break-before: page; }
  /* Add visual patterns by document type (badges, risk bar, etc.) */
</style>
</head>
<body>
<!-- Cover -->
<section style="min-height:240mm;display:flex;flex-direction:column;justify-content:space-between;padding:40mm 0 0 0;break-after:page;">
  <div>
    <div style="font-size:10pt;color:var(--brand);letter-spacing:2pt;text-transform:uppercase;margin-bottom:18pt;">Document Type</div>
    <div style="font-size:40pt;font-weight:500;line-height:1.12;margin-bottom:16pt;">Main Title</div>
    <div style="width:60pt;height:2pt;background:var(--brand);margin:20pt 0;border-radius:1pt;"></div>
    <div style="font-size:14pt;color:var(--olive);max-width:85%;">Subtitle or description</div>
  </div>
  <div style="font-size:10pt;color:var(--stone);">Author · Date</div>
</section>
<!-- Chapter -->
<section class="break">
  <h1>Chapter Title</h1>
  <p>Document content. Verify sources (research), humanize text (humanize), design with Kami.</p>
  <!-- Tables, lists, callouts as needed -->
</section>
</body>
</html>
```

## Integration with Kami

```powershell
# One-liner from Kami HTML to PDF
npx playwright pdf "file:///path/to/kami-output.html" "final.pdf"
```

## Sources

- [Playwright PDF API docs](https://playwright.dev/docs/api/class-page#page-pdf)
- [pdf4.dev HTML-to-PDF benchmark 2026](https://pdf4.dev/blog/html-to-pdf-benchmark-2026)
- [BrowserStack: Generate PDFs with Playwright](https://www.browserstack.com/guide/playwright-pdf-html-generation)
- [print-css.rocks: CSS Paged Media tutorial](https://print-css.rocks/)
- [DocuPotion: Generate PDFs with Playwright](https://docupotion.com/blog/generate-pdfs-playwright)
- [CSS Paged Media W3C specification](https://www.w3.org/TR/css-page-3/)
- [Blog.rasc.ch: Generating PDFs with Playwright and Go](https://blog.rasc.ch/2026/03/playwrightpdf.html)
- [HN: What is the open-source way to convert HTML to PDF](https://news.ycombinator.com/item?id=45404760)

## Workflow

### Step 1: Validate HTML template

Before rendering, verify the template is production-ready:
1. Open the HTML in a browser first: confirm fonts load, CSS applies, layout renders correctly at print size
2. Check that `@page` rules specify explicit size (`A4`, `Letter`) and margins
3. Verify `-webkit-print-color-adjust: exact` and `print-color-adjust: exact` are set on `*`
4. Confirm all `@font-face` declarations use relative paths, not absolute filesystem paths

### Step 2: Configure render settings

1. Set `format` (A4, Letter, A3) to match the template's `@page { size: }` declaration
2. Set `printBackground: true` — always. Never skip this. Chromium strips backgrounds by default
3. Set Playwright `margin: { top: '0', bottom: '0', left: '0', right: '0' }` — use CSS `@page` margins instead
4. Use `waitUntil: 'networkidle'` to ensure fonts, CSS, and images are fully loaded before rendering

### Step 3: Render PDF

1. Launch browser once (warm mode) — reuse for all documents in batch
2. Navigate with `file://` protocol to avoid CORS and authentication issues with local files
3. Await `page.pdf()` with configured options
4. Close page after each render but keep browser alive for next document

### Step 4: Validate output PDF

1. Open PDF and check: parchment/tinted background rendered (not white), fonts embedded correctly, page breaks occur at logical points
2. Scan every page for near-empty pages (2 lines or less floating at page top)
3. Verify code blocks, callouts, and tables are not split across page boundaries
4. Check CJK characters render correctly if document contains Chinese, Japanese, or Korean text

### Step 5: Apply visual patterns by document type

1. Pentest/security report: severity badges, risk bars, finding headers, styled code blocks, impact/remediation boxes
2. One-pager/executive summary: glance grid (4 metrics), lead paragraph, takeaway box, cover with decorative accent line
3. White paper/long document: chapter breaks on dense sections, callouts, keep-together wrappers on critical blocks
4. Letter: wide margins (25mm), formal greeting/closing, single-column, no unnecessary breaks
5. Resume: dense body (9.2pt), metric row, project bullets with action + result format

### Step 6: Run self-review protocol

Complete ALL four checklist categories before final output: Structural (blocking), Visual (high priority), Content (high priority), Technical (blocking). Every item in the self-review protocol is a real failure mode documented from previous iterations.

## Error Handling

| Cause | Fix |
|-------|-----|
| PDF renders with stark white background instead of parchment (#f5f4ed) | Chromium strips all backgrounds in print mode. Ensure BOTH `printBackground: true` in Playwright JS config AND `-webkit-print-color-adjust: exact` on `*` in CSS |
| Custom fonts render as fallback system serif in the PDF output | Use relative paths in `@font-face` `src: url("fonts/CustomFont.woff2")`. Place font files in same directory as HTML or a subdirectory. Chromium resolves relative to the HTML file's location |
| CJK characters (Chinese, Japanese, Korean) render as empty boxes or tofu | Include a CJK-capable font via `@font-face` or add system CJK fallback stack: `font-family: "TsangerJinKai02", "SimSun", "MS Mincho", serif`. Test before batch rendering |
| Near-empty page at end of section (2 lines of text floating alone) | Merge the short section with the previous one. Only apply `break-before: page` to chapters with > 1/3 page of content. Count elements: if heading + paragraph count < 5 total, don't force a page break |
| Table rows split awkwardly across consecutive pages | Add `table tr { break-inside: avoid; }` in CSS. For large spanning tables, add `table { break-inside: avoid; }` so the entire table moves as a block |
| Page break leaves an isolated heading at the very bottom of a page | Add `h1, h2, h3, h4 { break-after: avoid; }` to ensure at least the first content element after a heading stays with it on the same page |
| PDF file size is excessive (10MB+ for a text-heavy document) | Remove unnecessary raster images. Subset and compress embedded fonts to only used glyphs. Reduce DPI of any embedded raster content. Check for duplicated embedded resources |
| `page.pdf()` call hangs indefinitely on `networkidle` with dynamic/JS-rendered content | Switch to `waitUntil: 'load'` or add explicit `page.waitForTimeout(3000)`. For charts and JS-rendered content, use `waitForSelector()` on a known rendered element |
| Chromium version mismatch between local dev and CI causes visual output differences | Lock Chromium version explicitly: note the version `npx playwright install chromium` installs. Document it in CI config. Re-baseline visual checks on every Chromium version bump |
| Multiple documents rendered in bulk — browser crashes after N documents due to memory | Implement page pooling: close and reopen pages every 10-20 documents. Or restart browser every 50 documents. Memory leak in Chromium PDF rendering is a known issue |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Setting margins via Playwright `margin` parameter instead of CSS `@page` | Playwright margin rendering is inconsistent across Chromium versions. CSS `@page` margins produce predictable, standards-compliant output | Always use `@page { margin: 24mm 26mm 26mm 26mm; }` in CSS. Set Playwright `margin: { top: '0', bottom: '0', left: '0', right: '0' }` |
| `break-before: page` applied to every section/chapter unconditionally | Creates near-empty pages when a section has little content. Reader sees a page with 2 lines. Looks unprofessional and amateur | Only force page breaks on chapters with > 1/3 page of content. Count paragraph + table + list elements. If < 5 total content elements, skip the forced break |
| All pages share identical visual structure (title → table → title → table) | Monotonous reading experience. Reader disengages after page 3. Document fails to sustain attention through key findings | Vary rhythm: finding box, then risk bar, then callout, then table, then narrative paragraph. Alternate between data-dense and commentary pages |
| Repeated em dashes used as label/value separator in tables and lists | "Black Box — no credentials" repeated 15 times in a pentest report. Jarring, lazy, reads like raw data dump | Use colon separator (`Black Box: no credentials`), parentheses, or proper table columns with distinct header and value styling |
| Code blocks visually indistinguishable from surrounding body text | Reader skims past code assuming it's prose. Reduces document credibility. Technical content loses all impact | Style every code block: 2.5pt left border, ivory/tinted background, monospace font (Consolas/Courier), generous padding (10-14pt), slight border-radius |
| `printBackground: false` anywhere in the production rendering pipeline | Chrome strips all background colors, including parchment. Document renders on stark white default. Destroys the Kami visual design | Always `printBackground: true`. Add CI assertion: if PDF renders with white background, fail the build |
| Launching a new browser instance per PDF document | Cold start ~630ms vs warm ~13ms. 48x slower per document. Wastes CI minutes on multi-document projects | Use warm mode (PDFRenderer class pattern): launch browser once, render all documents, close browser once. Keep-alive between renders |
| Font files referenced with absolute Windows paths (`C:\Users\swagger\fonts\...`) | PDF generated on a different machine or in CI won't find fonts. Paths break across environments. Not portable | Always use relative paths in `@font-face`: `src: url("fonts/CustomFont.woff2")`. Place font files in same directory or subdirectory as the HTML template |
| Skipping the self-review protocol because "it looks fine in the browser" | Browser rendering != PDF output. Chrome applies different print stylesheet rules. Many issues only visible in the final PDF | Always open the actual PDF output and run through all 4 checklist categories. Visual inspection is mandatory, not optional |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
