---
name: translate-craft
description: Professional translation with cultural adaptation for Spanish, Japanese, French, German, and Portuguese. Preserves meaning, adapts tone and register, handles idioms, false friends, formality levels, and localization (dates, currency, units). Use when user asks to translate text, localize content, adapt tone for a target audience, review a translation, or ensure cultural appropriateness. Triggers on "translate", "translation", "localize", "localization", "traducir", "翻訳", "l10n", "i18n", "language adaptation", "cultural adaptation". Do NOT use for word-for-word dictionary lookups, machine translation without review, or code comments translation — this skill is for professional human-quality translation.
license: MIT
compatibility: opencode
metadata:
  workflow: communication
  audience: developers
---

Professional translation that goes beyond word-for-word. Preserves meaning, adapts tone, handles cultural nuances, and produces text that reads naturally in the target language — as if originally written in it.

Based on ATA standards, Mozilla localization best practices, and linguistic research on register and pragmatics.

## Core Principle

**Translate meaning, not words.** A good translation sounds like it was originally written in the target language. If the reader can tell it's a translation, it failed.

## Translation Layers

| Layer | What it handles | Example |
|-------|----------------|---------|
| Lexical | Word choice, terminology | "robust" → "sólido" not "robusto" |
| Syntactic | Sentence structure, word order | English SVO vs Japanese SOV |
| Idiomatic | Expressions, figures of speech | "It's raining cats and dogs" → "Llueve a cántaros" |
| Pragmatic | Implied meaning, intent | "Could you..." is a request, not a question |
| Cultural | References, norms, taboos | "404 error" needs explanation in some languages |
| Register | Formality level, politeness | Japanese keigo, Spanish tú vs usted |

## Tone Adaptation Matrix

Adapt tone to target language conventions, not the source:

| Source English | Spanish (formal) | Spanish (casual) | Japanese |
|---------------|------------------|------------------|----------|
| "Hey team" | "Estimado equipo" | "Hola equipo" | チームの皆様 |
| "Thanks!" | "Muchas gracias" | "Gracias!" | ありがとうございます |
| "Quick question" | "Una consulta" | "Una pregunta rápida" | 簡単な質問があります |
| "Let's discuss" | "Me gustaría tratar" | "Hablemos" | ご相談させてください |

## Language-Specific Rules

### English → Spanish
- **Formality**: `tú` for internal, `usted` for client/external
- **Gender**: "The user" → "el usuario" or "la persona usuaria" for inclusive
- **Length**: Spanish is ~25% longer. Account for UI space constraints
- **Passive voice**: Spanish prefers active or reflexive. "It was decided" → "Se decidió"

### English → Japanese
- **Politeness**: 3 levels — casual (だ), polite (です), honorific (敬語). Default polite
- **Subject omission**: Drop subjects when clear from context
- **Pronouns**: Minimize 私/あなた. Overuse sounds unnatural
- **Loan words**: Prefer native Japanese terms over katakana English
- **Counter words**: Use correct counters (本 for long, 枚 for flat, etc.)

### English → French
- **Formality**: `vous` for professional, `tu` for casual. Critical distinction
- **Gender**: Everything has gender. Ensure agreement across sentences
- **Punctuation**: Non-breaking space before `?`, `!`, `:`, `;`
- **Length**: ~20% longer than English

### English → German
- **Compound nouns**: "cloud storage" → "Cloud-Speicher"
- **Capitalization**: All nouns capitalized
- **Verb position**: Main verb second, modal at end in subordinate clauses
- **Formality**: `Sie` for professional, `du` for casual

### English → Portuguese
- **Formality**: `você` for general, `o senhor/a senhora` for formal
- **Gender**: Same as Spanish — nouns have gender, ensure agreement
- **Contractions**: Use `de + o = do`, `em + o = no`, `a + aquele = àquele`
- **Personal infinitive**: Portuguese has inflected infinitive — use when subject differs from main clause
- **Length**: ~20-25% longer than English

## Localization Checklist

- [ ] Placeholders (`{name}`, `{{variable}}`) preserved and repositioned
- [ ] Date formats converted (MM/DD → DD/MM)
- [ ] Time formats converted (AM/PM → 24h)
- [ ] Currency adapted ($1,000.50 → 1.000,50 €)
- [ ] Units converted (miles → km, Fahrenheit → Celsius)
- [ ] Phone number formats adapted
- [ ] Address formats restructured
- [ ] Cultural references explained or replaced
- [ ] Idioms replaced with equivalent, not literal
- [ ] Formality level consistent throughout
- [ ] Gender agreement checked across sentences
- [ ] Character encoding verified (UTF-8)

## Workflow

1. **Identify**: Source language, target language, audience (internal/external, technical/general), medium (UI, email, docs, marketing)
2. **Translate**: Apply language-specific rules above
3. **Adapt**: Adjust tone, register, and cultural references
4. **Localize**: Run localization checklist
5. **Review**: Read in target language only — if it sounds like a translation, redo

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Literal idioms | "break a leg" is NOT "romper una pierna" |
| False friends | "embarrassed" ≠ "embarazada" (pregnant). "sensible" ≠ "sensible" (sensitive in FR) |
| Untranslated jargon | Assume reader needs localization, not English loanwords |
| Inconsistent formality | Don't mix "tú" and "usted" in the same document |
| Word-for-word structure | "I am 20 years old" → "Tengo 20 años" not "Soy 20 años viejo" |
| No space adaptation | English is shorter than Spanish/French. UI breaks if not accounted for |

## Sources

- ATA (American Translators Association) professional standards
- Mozilla localization (l10n) best practices
- Airbnb translation style guide
- Microsoft Language Portal terminology
- UN Translation guidelines
- Linguee/DeepL corpus patterns
