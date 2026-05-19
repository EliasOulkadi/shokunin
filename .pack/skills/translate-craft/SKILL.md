---
name: translate-craft
description: Professional translation and localization for 8 languages (ES, JA, FR, DE, PT, ZH, KO, AR). Covers tone matrix, formality levels, i18n patterns (react-intl, i18next, ICU), RTL layout, cultural adaptation, and locale formatting. Use when user asks to translate text, localize an app, adapt tone, review translations, add i18n, or set up RTL.
license: MIT
compatibility: opencode
triggers:
  - translate text from one language to another
  - localize an app or website for a new market
  - adapt tone/register for a target audience
  - review an existing translation for quality
  - add i18n support to a codebase
  - set up RTL layout for Arabic or Hebrew
  - internationalize a React/i18next project
  - format dates, currencies, numbers per locale
negatives:
  - word-for-word dictionary lookups
  - raw machine translation without human review
  - translating code comments or variable names
metadata:
  version: "4.0.0"
  workflow: communication
  audience: developers, translators
---


# Translate Craft

Translation that reads as if originally written in the target language. Based on ATA standards, Mozilla l10n best practices, Airbnb style guide, and Microsoft Language Portal.

## Core Principle

Translate **meaning**, not words. If the reader can tell it's a translation, it failed.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `translate` | Translate text with tone, formality, and cultural adaptation |
| `localize` | Localize dates, currencies, units, addresses per locale |
| `i18n` | Set up i18n framework (react-intl / i18next / ICU) |
| `rtl` | Implement RTL layout with CSS logical properties |
| `audit` | Review existing translation for quality issues |
| `teach` | Create a localization guide for a language pair |

## Language-Specific Rules (8 languages)

### EN → ES (Spanish)
- **Formality**: `tú` (internal), `usted` (client/external)
- **Gender**: inclusive language. "El usuario" → "La persona usuaria"
- **Length**: ~25% longer. Account for UI expansion.
- **Passive**: Active preferred. "Se decidió" not "Fue decidido"

### EN → JA (Japanese)
- **Politeness**: 3 levels: casual (だ), polite (です), honorific (敬語). Default: polite.
- **Subject omission**: Drop subjects when clear from context
- **Pronouns**: Minimize 私/あなた. Overuse sounds foreign.

### EN → FR (French)
- **Formality**: `vous` (professional), `tu` (casual)
- **Gender**: Everything has gender. Ensure agreement across sentences.
- **Punctuation**: Non-breaking space before `?`, `!`, `:`, `;`

### EN → DE (German)
- **Compound nouns**: "cloud storage" → "Cloud-Speicher"
- **Capitalization**: All nouns capitalized
- **Formality**: `Sie` (prof), `du` (casual)

### EN → PT (Portuguese)
- **Formality**: `você` (general), `o senhor/a senhora` (formal)
- **Length**: ~20-25% longer

### EN → ZH (Mandarin)
- **Measure words**: 个, 张, 条, 块 — correct classifier per noun
- **Tone**: 您 (formal) vs 你 (casual)
- **Shortened**: ~15-20% shorter. More room in UI.
- **Script**: Simplified for CN. Traditional for TW/HK.

### EN → KO (Korean)
- **Honorifics**: 합쇼체 (formal), 해요체 (polite casual), 해체 (casual). Default: 해요체
- **SOV word order**: Subject-Object-Verb, opposite of English

### EN → AR (Arabic)
- **RTL**: Everything mirrors. Use CSS logical properties.
- **Root system**: Words derive from 3-letter roots
- **Length**: ~25% shorter. Text shrinks in UI.

## Workflow

1. **Identify scope**: source, target, audience, medium, tone tier
2. **Analyze source**: flag idioms, cultural references, ambiguity
3. **Translate**: first pass applying language-specific rules
4. **Adapt tone**: adjust register per audience
5. **Localize**: dates, times, currencies, units, phone, addresses
6. **Restructure**: natural target-language word order
7. **Reverse review**: read only target. If you can reconstruct source, too literal.
8. **UI verify**: paste into layout. Check truncation, overflow, RTL, line breaks.
9. **Final pass**: production checklist.

## i18n Framework Patterns

### ICU Message Syntax
```
{count, plural, one {# item} other {# items}}
{gender, select, male {He} female {She} other {They}}
```

### RTL Layout (CSS logical properties)
```css
.element {
  margin-inline-start: 1rem;   /* auto-flips LTR/RTL */
  padding-inline: 1rem;
  border-inline-end: 1px solid;
}
```

## Locale Formatting Quick Reference

| Format | EN | DE | JA | AR |
|--------|----|----|----|-----|
| Date short | 05/12/2026 | 12.05.2026 | 2026/05/12 | 12/05/2026 |
| Time | 3:30 PM | 15:30 | 15:30 | 03:30 م |
| Currency | $1,234.56 | 1.234,56 € | ¥1,235 | ١٬٢٣٤٫٥٦ ر.س |
| Number | 1,234.56 | 1.234,56 | 1,234.56 | ١٬٢٣٤٫٥٦ |

## Production Checklist

- [ ] Placeholders preserved (`{name}`, `%s`, `{{var}}`)
- [ ] Date/time/currency/units converted per locale
- [ ] Cultural references adapted or explained
- [ ] Idioms replaced with natural equivalent
- [ ] Formality consistent across entire document
- [ ] Gender agreement checked
- [ ] UTF-8 encoding verified
- [ ] UI: expansion/shrinkage accounted for
- [ ] RTL: layout mirrored, numbers left-to-right
- [ ] Read-aloud test passed
- [ ] Back-translation sample checked for meaning drift

## Error Handling

| Cause | Fix |
|-------|-----|
| Placeholder syntax (`{name}`, `%s`, `{{var}}`) broken in translation | Preserve exact placeholder format. Verify each appears unchanged in output. Test with real data. |
| Text expansion breaking UI layout (German +25%, Spanish +25%) | Design containers with flex-grow. Test with longest translated string. Account for CJK shortening (-15-20%). |
| False friends between language pairs | Maintain language-pair-specific false friends list. ES: "embarazada" ≠ "embarrassed". FR: "actuellement" ≠ "actually". DE: "Gift" ≠ "gift". |
| Mixed formality in same document (tú/usted, Sie/du) | Pick one register at start. Scan entire document for consistency. Language-specific rules table has defaults. |
| Word-for-word translation producing unnatural phrasing | Restructure to target language word order. KO: SOV. JA: drop subjects. AR: root-based word derivation. |
| RTL layout breaks on dynamically injected content | Use CSS logical properties exclusively (`margin-inline-start`, `padding-inline`, `border-inline-end`). Never `left`/`right`. |
| Back-translation reveals meaning drift | If reconstructed source differs from original, the translation is too literal or too loose. Adjust: preserve meaning, not word order. |
| Cultural reference doesn't exist in target market | Adapt or explain. Replace region-specific idioms with natural equivalent. Add brief context for untranslatable concepts. |

## Anti-Patterns

| Anti-pattern | Correct |
|--------------|---------|
| Literal idiom translation | Find equivalent idiom or drop |
| False friends (embarrassed ≠ embarazada) | Maintain false friends list per language pair |
| Mixed formality (tú/usted in same paragraph) | Pick one register. Enforce throughout. |
| Word-for-word structure | Restructure to target language patterns |
| Ignoring expansion (German +25%) | Design flexible containers. Test with longest string. |
| RTL as afterthought | Use CSS logical properties from day 1 |

## ICU MessageFormat Advanced Patterns

### Plurals (per-language rules)
```
// EN: 1 item, 2 items
{count, plural, one {# item} other {# items}}

// AR: 0 عناصر, 1 عنصر, 2 عنصران, 3-10 عناصر, 11+ عنصر
{count, plural, zero {# عناصر} one {# عنصر} two {# عنصران} few {# عناصر} many {# عنصر}}

// JA: 日本語は複数形がない（単純）
{count}個
```

### Gender
```
// ES
{gender, select, male {Estimado} female {Estimada} other {Estimado/a}}

// FR
{gender, select, male {Cher} female {Chère} other {Cher/Chère}}
```

### Select with nested plural
```
{gender, select,
  male {{count, plural, one {Il a # livre} other {Il a # livres}}}
  female {{count, plural, one {Elle a # livre} other {Elle a # livres}}}
}
```

### Date/Number Locale Formatting

```python
# Python babel
from babel.dates import format_date, format_datetime
format_date(date, locale='de_DE')    # 18.05.2026
format_date(date, locale='en_US')    # May 18, 2026
format_date(date, locale='ja_JP')    # 2026/05/18

from babel.numbers import format_number, format_currency
format_number(1234567, locale='en_US')   # 1,234,567
format_number(1234567, locale='de_DE')   # 1.234.567
format_currency(49.99, 'EUR', locale='de_DE')  # 49,99 €
```

```javascript
// JavaScript Intl
new Intl.DateTimeFormat('ja-JP').format(new Date())        // 2026/5/18
new Intl.DateTimeFormat('ar-SA', { dateStyle: 'full' }).format(new Date())
new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' }).format(49.99)  // 49,99 €
```

### RTL CSS Patterns

```css
/* Logical properties (direction-aware) */
.element {
  margin-inline-start: 16px;   /* margin-left in LTR, margin-right in RTL */
  padding-inline-end: 8px;
  border-inline-start: 2px solid;
  text-align: start;
}
/* Avoid: margin-left, padding-right, text-align: left */
```

## Sources

- ATA (American Translators Association)
- Mozilla l10n best practices
- Airbnb translation style guide
- Microsoft Language Portal
- UN Translation guidelines
- W3C Internationalization articles
- FormatJS / ICU Message Syntax
- Google Material Design — RTL guidelines

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
