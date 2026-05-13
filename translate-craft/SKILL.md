---
name: translate-craft
description: Professional translation and localization for 8 languages (ES, JA, FR, DE, PT, ZH, KO, AR) with cultural adaptation, tone matrix, formality levels, i18n framework patterns (react-intl, i18next, ICU), and RTL layout.
version: "3.0"
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
  - word-for-word dictionary lookups or glossaries
  - raw machine translation without human review
  - translating code comments or variable names
  - generating locale files from scratch
metadata:
  workflow: communication
  audience: developers, translators
  revision: 3
  changelog:
    "3.0": Added YAML frontmatter with triggers/negatives, numbered workflow, error handling table, production checklist, anti-patterns table
    "2.0": Added Korean, Arabic, RTL layout, ICU patterns
    "1.0": Initial release with 6 languages
---

# Translate Craft

Professional translation that reads as if originally written in the target language. Based on ATA standards and Mozilla l10n best practices.

## Core Principle

Translate meaning, not words. If the reader can tell it's a translation, it failed.

## Translation Layers

| Layer | What it handles |
|-------|----------------|
| Lexical | Word choice, terminology |
| Syntactic | Sentence structure, word order |
| Idiomatic | Expressions, figures of speech |
| Pragmatic | Implied meaning, intent |
| Cultural | References, norms, taboos |
| Register | Formality level, politeness |

## Tone Adaptation Matrix

| English (casual) | Spanish (formal) | Japanese |
|-----------------|------------------|----------|
| "Hey team" | "Estimado equipo" | チームの皆様 |
| "Thanks!" | "Muchas gracias" | ありがとうございます |
| "Quick question" | "Una consulta" | 簡単な質問があります |

## Language-Specific Rules

### English → Spanish
- **Formality**: `tú` for internal, `usted` for client/external
- **Gender**: "The user" → "el usuario" / "la persona usuaria" (inclusive)
- **Length**: ~25% longer. Account for UI constraints.
- **Passive**: Active/reflexive preferred. "It was decided" → "Se decidió"

### English → Japanese
- **Politeness**: 3 levels — casual (だ), polite (です), honorific (敬語). Default: polite
- **Subject omission**: Drop subjects when clear
- **Pronouns**: Minimize 私/あなた. Overuse sounds unnatural
- **Loan words**: Prefer native terms over katakana English
- **Counters**: Use correct counters (本 for long, 枚 for flat, etc.)

### English → French
- **Formality**: `vous` for professional, `tu` for casual
- **Gender**: Everything has gender. Ensure agreement across sentences
- **Punctuation**: Non-breaking space before `?`, `!`, `:`, `;`
- **Length**: ~20% longer

### English → German
- **Compound nouns**: "cloud storage" → "Cloud-Speicher"
- **Capitalization**: All nouns capitalized
- **Verb position**: Main verb second, modal at end in subordinate
- **Formality**: `Sie` for professional, `du` for casual

### English → Portuguese
- **Formality**: `você` for general, `o senhor/a senhora` for formal
- **Contractions**: `de + o = do`, `em + o = no`, `a + aquele = àquele`
- **Personal infinitive**: Inflected when subject differs from main clause
- **Length**: ~20-25% longer

### English → Chinese (Mandarin)
- **Measure words**: Every noun needs correct classifier (个, 张, 条, 块, etc.)
- **Tone**: Formal vs casual via word choice, not grammar (您 vs 你)
- **No conjugation**: Same verb form regardless of tense (context/time word tells tense)
- **Shortened**: ~15-20% shorter than English. More room in UI.
- **Simplified vs Traditional**: Know your target market (CN uses Simplified, TW/HK use Traditional)

### English → Korean
- **Honorifics**: 합쇼체 (formal), 해요체 (polite casual), 해체 (casual). Default: 해요체
- **Subject/object particles**: 이/가, 을/를, 은/는 — must be correct for grammatical meaning
- **Counters**: 명 (people), 개 (objects), 번 (times), etc.
- **No pronouns**: Use title/name instead of "you" when possible
- **Word order**: SOV (Subject-Object-Verb), opposite of English

### English → Arabic
- **RTL**: Right-to-left layout. Everything mirrors.
- **Root system**: Words derive from 3-letter roots (كَتَبَ = he wrote, كِتاب = book, مَكتَب = office)
- **Formal vs colloquial**: MSA (Modern Standard Arabic) for writing, dialect for speech
- **Gender**: Verbs conjugated by gender of subject
- **Length**: ~25% shorter than English. Text shrinks in UI.
- **Numbers**: Written left-to-right within RTL text

## Procedural Workflow

1. **Identify scope** — source language, target language, audience profile, medium (web/app/print), tone tier (casual/polite/honorific/formal)
2. **Analyze source** — flag idioms, cultural references, ambiguity, gender-dependent terms, text with expansion/shrinkage risk
3. **Translate** — produce first pass applying language-specific rules from the section above. Keep placeholders intact
4. **Adapt tone** — adjust register per audience. Use the Tone Adaptation Matrix as reference for formality level
5. **Localize** — convert dates, times, currencies, units, phone numbers, addresses per Locale-Specific Formatting table
6. **Restructure** — reflow sentences for natural target-language word order. Check for false friends, gender agreement, politeness consistency
7. **Reverse review** — read only the target text. If you can mentally reconstruct the source English, the translation is too literal. Rewrite
8. **UI verify** — for digital products, paste translated text into the layout. Check for truncation, overflow, RTL mirroring, line breaks
9. **Final pass** — run the Production Checklist below. Confirm no placeholders broken, no segments left untranslated

## Error Handling

| Error type | Symptom | Root cause | Fix |
|------------|---------|------------|-----|
| Literalism | Translation sounds foreign, odd word choices | Translated words instead of meaning | Rewrite freely preserving intent, not form |
| Register mismatch | Too formal/casual for context | Wrong politeness tier selected | Identify correct audience relationship, reapply formality rules |
| False friend | Nonsensical or misleading word | Word looks similar in source/target but means different | Verify against known false friends list for the language pair |
| Gender disagreement | Article/adjective doesn't match noun | Missed gender rule in target language | Ensure all modifiers agree with noun gender across sentence boundaries |
| Broken placeholder | `{name}` or `%s` appears in output | Placeholder treated as translatable text | Wrap placeholders in skip markers, verify post-translation |
| RTL breakage | Text overlaps, layout inverted, numbers reversed | RTL not handled at layout level | Apply CSS logical properties, test with long Arabic string |
| UI overflow | Text truncated or overlapping | Length expansion/shrinkage not accounted for | Check source vs target character count ratios, request layout adjustment |
| Honorific inconsistency | Mixed speech levels in same sentence | Switched between polite and casual mid-text | Normalize entire document to single honorific tier |

## i18n Framework Patterns

### ICU Message Syntax

```
{count, plural,
  one {# item}
  other {# items}
}

{gender, select,
  male {He has {count, plural, one {# book} other {# books}}}
  female {She has {count, plural, one {# book} other {# books}}}
  other {They have {count, plural, one {# book} other {# books}}}
}
```

### react-intl / FormatJS

```typescript
import { useIntl, FormattedMessage } from 'react-intl'

function Welcome({ name, unreadCount }) {
  const intl = useIntl()
  return (
    <p>
      <FormattedMessage
        defaultMessage="{name} has {unreadCount, plural, one {# message} other {# messages}}"
        values={{ name, unreadCount }}
      />
    </p>
  )
}
```

### i18next

```typescript
import { useTranslation } from 'react-i18next'

function Welcome({ name, unreadCount }) {
  const { t } = useTranslation()
  return <p>{t('welcome', { name, count: unreadCount })}</p>
}
```

## Locale-Specific Formatting

| Format | US English | German | Japanese | Arabic |
|--------|-----------|--------|----------|--------|
| Date | 05/12/2026 | 12.05.2026 | 2026/05/12 | 12/05/2026 |
| Time | 3:30 PM | 15:30 | 15:30 | 03:30 م |
| Currency | $1,234.56 | 1.234,56 € | ¥1,235 | ١٬٢٣٤٫٥٦ ر.س |
| Number | 1,234.56 | 1.234,56 | 1,234.56 | ١٬٢٣٤٫٥٦ |

### RTL Layout

```css
/* Use logical properties for automatic RTL support */
.element {
  margin-inline-start: 1rem;    /* margin-left in LTR, margin-right in RTL */
  padding-inline: 1rem;         /* padding-left + padding-right, auto-flips */
  border-inline-end: 1px solid;  /* border-right in LTR, border-left in RTL */
}

/* Alternative: dir selector */
[dir="rtl"] .sidebar {
  right: auto;
  left: 0;
}
```

## Production Checklist

- [ ] Placeholders preserved and repositioned
- [ ] Date formats converted per locale
- [ ] Time formats converted (AM/PM ↔ 24h)
- [ ] Currency adapted with correct symbol placement
- [ ] Units converted (miles → km, °F → °C, ft → m)
- [ ] Phone number formats adapted
- [ ] Address formats restructured (street → city → postcode order)
- [ ] Cultural references explained or replaced with local equivalent
- [ ] Idioms replaced with naturally equivalent expression
- [ ] Formality level consistent across entire document
- [ ] Gender agreement checked within and across sentences
- [ ] UTF-8 encoding verified
- [ ] Text expansion/shrinkage accounted for in UI layout
- [ ] RTL layout tested with right-aligned text, mirrored UI, and mixed LTR numbers
- [ ] Honorific/politeness tier applied uniformly
- [ ] False friends checked for the language pair
- [ ] Placeholders `{...}`, `%s`, `{{...}}` untouched by translation
- [ ] Plurals, selectors, and ICU syntax preserved and re-validated
- [ ] Read-aloud test passed: target text sounds natural when spoken
- [ ] Round-trip test: back-translate a sample to catch meaning drift

## Anti-Patterns

| Anti-pattern | Why it fails | Correct approach |
|--------------|-------------|------------------|
| Literal idiom translation | "break a leg" → "romper una pierna" makes no sense | Find equivalent idiom in target language or drop |
| False friend blindness | "embarrassed" ≠ "embarazada" (pregnant) | Maintain a false friends list per language pair |
| Mixed formality | Switching tú/usted in same paragraph feels schizophrenic | Pick one register and enforce it throughout |
| Word-for-word structure | "20 years old" → "Soy 20 años" instead of "Tengo 20 años" | Restructure to target-language sentence patterns |
| Ignoring expansion/shrinkage | German/Spanish text overflows buttons by 25% | Design UI with flexible containers, test with longest realistic string |
| RTL as an afterthought | Arabic text aligned left, UI elements reversed | Use CSS logical properties from the start, test RTL early |
| Leaking placeholders | Translating "{name}" as "{nombre}" | Mark placeholders as untranslatable, verify post-translation |
| Dead string accumulation | Translated strings never deployed, code references removed | Track string usage, remove orphaned translations |
| Homogeneous locale testing | Only tests with short English strings, assumes all locales fit | Test each locale with its longest representative string |
| Honorific skipping | Japanese/Korean without politeness tier sounds rude | Default to polite (です/해요체), only use casual if audience is close |

## Sources

- ATA (American Translators Association) standards
- Mozilla localization (l10n) best practices
- Airbnb translation style guide
- Microsoft Language Portal
- UN Translation guidelines
- W3C Internationalization (i18n) articles
- FormatJS / ICU Message Syntax
- Google Material Design — RTL layout guidelines
