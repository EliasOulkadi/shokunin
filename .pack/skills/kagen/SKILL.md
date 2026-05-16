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

Cada tipo de documento necesita su propio conjunto de patrones visuales. Aplicar segun corresponda:

| Tipo | Patrones obligatorios | Patrones opcionales |
|------|----------------------|---------------------|
| **Pentest / Security report** | Severity badges (rojo/naranja/verde), risk bar, bloques de codigo con borde izquierdo, cajas impacto/remediacion | Finding-header con metadatos, tabla de hallazgos con badges |
| **One-pager / Executive summary** | Glance grid (4 metricas), lead paragraph, takeaway box, cover con titulo grande + linea decorativa | Callout para dato clave, footer con contacto |
| **White paper / Long doc** | Chapter breaks en secciones densas, tabla de contenidos, callouts, keep-together en bloques criticos | Quotes, diagramas, appendix |
| **Letter** | Margenes amplios (25mm), saludo y cierre formales, sin columnas, sin tablas | Membrete, firma |
| **Resume** | Dense body (9.2pt), metric row, project bullets con accion + resultado | Timeline, skills grid |
| **Slides** | Assertion-evidence titles, una idea por slide, bullets de una linea, pinned callout | Code cards, 2x2 table |

**Regla:** si el tipo de documento no esta en la tabla, elegir el mas cercano y adaptar.

### Near-empty pages prevention

Nada queda mas amateur que una pagina con 2 lineas. Causas y soluciones:

| Causa | Solucion | Deteccion automatica |
|-------|----------|---------------------|
| Heading con 1 parrafo corto al final | Fusionar con seccion anterior | Si un capitulo tiene solo 1 h2 + 1 p, no merece pagina propia |
| `break-before: page` en cada seccion | Solo usar en capitulos con >1/3 pagina de contenido | Contar parrafos + tablas + listas. Si suman menos de 5 elementos, no forzar salto |
| `break-inside: avoid` en bloque grande que no entra | Relajar `break-inside` o dividir el bloque | Si un keep-together mide mas de 1 pagina, no forzarlo |
| Lista de fuentes al final que sobra en pagina aparte | Mover al capitulo de fuentes consolidado | Las fuentes van en un solo lugar, no repetidas en cada capitulo |

### Anti-patterns de IA en documentos

Validar que el contenido heredado de Kami no tenga estas marcas:

| Anti-pattern | Problema | Fix |
|-------------|----------|-----|
| Em dash `—` repetido como separador label/valor | `Black Box — sin credenciales`, varias lineas seguidas | Parentesis, coma, dos puntos. El dash es para incisos genuinos, no para separar labels |
| Tablas uniformes sin color | Todas las filas iguales, sin indicacion visual de severidad o prioridad | Badges de color, zebra rows suaves, primera columna destacada |
| Bloques de code sin contraste | Se mezclan con el body, no se ven como codigo | Borde izquierdo azul, fondo ivory, monospace, padding generoso |
| Misma estructura en cada pagina | Todas las paginas son titulo + tabla o titulo + lista | Variar: caja de hallazgo, risk bar, flowchart, callout. Alternar ritmo |
| Afirmaciones sin fuente | "Los LLM alucinan 15-20%" sin atribucion | "Segun Vectara HHEM 2026, los LLM..." |

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
| Near-empty page (2 lines sola) | Fusionar sección corta con anterior; evitar `break-before: page` en capítulos ligeros |
| Content overflow | Use `page-break-inside: avoid` on large blocks |
| Chinese chars as boxes | Include CJK font in `@font-face` or use system CJK fallback |
| PDF too large | Remove unnecessary images, compress embedded fonts |
| Slow first render | Keep browser instance alive (warm mode) |

### CSS visual pattern snippets

Patrones concretos para incluir en el HTML segun el tipo de documento:

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

No generar el PDF sin pasar esta checklist. Cada item es un fallo real documentado en iteraciones anteriores.

### Estructurales (bloqueantes)
- [ ] Cada capitulo tiene contenido suficiente para ocupar >1/3 de pagina
- [ ] No hay secciones con solo heading + 1 parrafo corto (fusionar)
- [ ] No hay paginas casi vacias (2 lineas solas)
- [ ] `break-before: page` solo en capitulos con contenido denso

### Visuales (alta prioridad)
- [ ] Los elementos visuales corresponden al tipo de documento (badges, risk bars, code blocks, etc.)
- [ ] Las tablas tienen el estilo adecuado (zebra opcional, padding, headers claros)
- [ ] Los bloques de codigo se distinguen del cuerpo (borde, fondo, monospace)
- [ ] No hay em dashes `—` usados como separadores label/valor repetidos
- [ ] Hay variedad de ritmo visual (no todas las paginas iguales)

### Contenido (alta prioridad)
- [ ] Cada afirmacion categorica tiene su fuente visible ("segun X...")
- [ ] Se distingue metodologia interna de hecho verificado (disclaimer si aplica)
- [ ] No hay contenido redundante entre capitulos (fuentes, listas repetidas)
- [ ] Cada parrafo es necesario (si se puede eliminar sin perdida, eliminar)

### Tecnicos (bloqueantes)
- [ ] `printBackground: true` en la configuracion de Playwright
- [ ] `-webkit-print-color-adjust: exact` en CSS
- [ ] `widows: 4; orphans: 4` en @page y body
- [ ] `break-inside: avoid` en pre, table, blockquote, callout
- [ ] `table tr { break-inside: avoid }` para que las tablas no partan filas

## Complete HTML example

Template minimo funcional que incluye todos los patrones esenciales. Copiar y adaptar:

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Titulo del Documento</title>
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
  /* Anadir patrones visuales segun tipo de documento (badges, risk bar, etc.) */
</style>
</head>
<body>
<!-- Cover -->
<section style="min-height:240mm;display:flex;flex-direction:column;justify-content:space-between;padding:40mm 0 0 0;break-after:page;">
  <div>
    <div style="font-size:10pt;color:var(--brand);letter-spacing:2pt;text-transform:uppercase;margin-bottom:18pt;">Tipo de Documento</div>
    <div style="font-size:40pt;font-weight:500;line-height:1.12;margin-bottom:16pt;">Titulo Principal</div>
    <div style="width:60pt;height:2pt;background:var(--brand);margin:20pt 0;border-radius:1pt;"></div>
    <div style="font-size:14pt;color:var(--olive);max-width:85%;">Subtitulo o descripcion</div>
  </div>
  <div style="font-size:10pt;color:var(--stone);">Autor · Fecha</div>
</section>
<!-- Chapter -->
<section class="break">
  <h1>Titulo del Capitulo</h1>
  <p>Contenido del documento. Verificar fuentes (research), humanizar texto (humanize), disenar con Kami.</p>
  <!-- Tablas, listas, callouts segun necesidad -->
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
