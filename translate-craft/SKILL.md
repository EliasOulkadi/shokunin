---
name: translate-craft
description: Professional translation and localization for 8 languages (ES, JA, FR, DE, PT, ZH, KO, AR) with cultural adaptation, tone matrix, formality levels, i18n framework patterns (react-intl, i18next, ICU), and RTL layout. Use when user asks to translate, localize, adapt tone for target language, or internationalize an app. Do NOT use for word-for-word dictionary lookups, machine translation without review, or code comments translation.
license: MIT
compatibility: opencode
metadata:
  workflow: communication
  audience: developers
  version: "2.0"
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

## Localization Checklist

- [ ] Placeholders preserved and repositioned
- [ ] Date formats converted
- [ ] Time formats converted (AM/PM → 24h)
- [ ] Currency adapted
- [ ] Units converted (miles → km, °F → °C)
- [ ] Phone number formats adapted
- [ ] Address formats restructured
- [ ] Cultural references explained or replaced
- [ ] Idioms replaced with equivalent
- [ ] Formality level consistent
- [ ] Gender agreement checked
- [ ] UTF-8 encoding verified
- [ ] Text expansion/shrinkage accounted for in UI

## Workflow

1. **Identify**: source, target, audience, medium
2. **Translate**: apply language-specific rules
3. **Adapt**: adjust tone, register, culture
4. **Localize**: run localization checklist
5. **Review**: read in target language only

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Literal idioms | "break a leg" ≠ "romper una pierna" |
| False friends | "embarrassed" ≠ "embarazada" (pregnant) |
| Inconsistent formality | Don't mix tú/usted in same document |
| Word-for-word structure | "20 years old" → "Tengo 20 años" (not "Soy 20 años") |
| No space adaptation | English is shorter than Spanish/French. UI breaks. |
| Ignoring RTL | RTL needs layout mirroring, not just text direction |

## Sources

- ATA (American Translators Association) standards
- Mozilla localization (l10n) best practices
- Airbnb translation style guide
- Microsoft Language Portal
- UN Translation guidelines
- W3C Internationalization (i18n) articles
- FormatJS / ICU Message Syntax
- Google Material Design — RTL layout guidelines
