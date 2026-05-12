---
name: translate-craft
description: Professional translation with cultural adaptation
---


# Translate Craft

Professional translation that goes beyond word-for-word. Preserves meaning, adapts tone, handles cultural nuances, and produces text that reads naturally in the target language â€” as if originally written in it.

Based on translation industry standards from ATA (American Translators Association), localization best practices from Mozilla and Airbnb, and linguistic research on register and pragmatics.

## Core Principle

**Translate meaning, not words.** A good translation sounds like it was originally written in the target language. If the reader can tell it's a translation, it failed.

## Translation Layers

| Layer | What it handles | Example |
|-------|----------------|---------|
| Lexical | Word choice, terminology | "robust" â†’ "sÃ³lido" not "robusto" |
| Syntactic | Sentence structure, word order | English SVO vs Japanese SOV |
| Idiomatic | Expressions, figures of speech | "It's raining cats and dogs" â†’ "Llueve a cÃ¡ntaros" |
| Pragmatic | Implied meaning, intent | "Could you..." is a request, not a question |
| Cultural | References, norms, taboos | "404 error" needs explanation in some languages |
| Register | Formality level, politeness | Japanese keigo, Spanish tÃº vs usted |

## Tone Adaptation Matrix

When translating, adapt the tone to match target language conventions â€” not the source:

| Source English | Spanish (formal) | Spanish (casual) | Japanese |
|---------------|------------------|------------------|----------|
| "Hey team" | "Estimado equipo" | "Hola equipo" | ãƒãƒ¼ãƒ ã®çš†æ§˜ |
| "Thanks!" | "Muchas gracias" | "Gracias!" | ã‚ã‚ŠãŒã¨ã†ã”ã–ã„ã¾ã™ |
| "Quick question" | "Una consulta" | "Una pregunta rÃ¡pida" | ç°¡å˜ãªè³ªå•ãŒã‚ã‚Šã¾ã™ |
| "Let's discuss" | "Me gustarÃ­a tratar" | "Hablemos" | ã”ç›¸è«‡ã•ã›ã¦ãã ã•ã„ |

## Language-Specific Rules

### English to Spanish
- **Formality**: Mark when to use `tÃº` vs `usted`. Default to `tÃº` for internal, `usted` for client/external.
- **Gender**: Resolve gendered nouns explicitly. "The user" â†’ "el usuario" (or "la persona usuaria" for inclusive).
- **Length**: Spanish is ~25% longer than English. Account for space constraints in UI.
- **Passive voice**: Spanish prefers active or reflexive. "It was decided" â†’ "Se decidiÃ³".

### English to Japanese
- **Politeness**: Three levels: casual (ã /ã§ã‚ã‚‹), polite (ã§ã™/ã¾ã™), honorific (æ•¬èªž). Default to polite.
- **Subject omission**: Japanese drops subjects when clear from context. Keep translations concise.
- **Pronouns**: Minimize "I/you" (ç§/ã‚ãªãŸ). Overuse sounds unnatural or aggressive.
- **Loan words**: Prefer native Japanese terms over katakana English when they exist.
- **Counter words**: Use correct counters (æœ¬ for long objects, æžš for flat, etc.).

### English to French
- **Formality**: `tu` vs `vous` distinction critical. Default `vous` for professional.
- **Gender**: Everything has gender. Ensure agreement across sentences.
- **Space before punctuation**: `?`, `!`, `:`, `;` need a non-breaking space before them.
- **Length**: French is ~20% longer than English.

### English to German
- **Compound nouns**: German creates compounds where English uses phrases. "cloud storage" â†’ "Cloud-Speicher".
- **Capitalization**: All nouns are capitalized.
- **Verb position**: Main verb second, modal at end in subordinate clauses.
- **Formality**: `du` vs `Sie`. Default `Sie` for professional.

## Localization Checklist

- [ ] All placeholders ({name}, {{variable}}) preserved and repositioned
- [ ] Date formats converted (MM/DD â†’ DD/MM)
- [ ] Time formats converted (AM/PM â†’ 24h)
- [ ] Currency symbols and formats adapted ($1,000.50 â†’ 1.000,50 â‚¬)
- [ ] Measurement units converted (miles â†’ km, Fahrenheit â†’ Celsius)
- [ ] Phone number formats adapted
- [ ] Address formats restructured
- [ ] Cultural references explained or replaced
- [ ] Idioms replaced with equivalent, not translated literally
- [ ] Formality level consistent throughout
- [ ] Gender agreement checked across sentences
- [ ] Character encoding verified (UTF-8)

## What NOT To Do

- **Literal idioms**: "break a leg" is NOT "romper una pierna"
- **False friends**: "embarrassed" â‰  "embarazada" (pregnant in Spanish), "sensible" â‰  "sensible" (sensitive in French)
- **Untranslated jargon**: assume the reader needs localization, not English loanwords
- **Inconsistent formality**: don't mix "tÃº" and "usted" in the same document
- **Word-for-word structure**: "I am 20 years old" â†’ "Tengo 20 aÃ±os" (NOT "Soy 20 aÃ±os viejo")

## Sources

- ATA (American Translators Association) professional standards
- Mozilla localization (l10n) best practices
- Airbnb translation style guide
- Microsoft Language Portal terminology
- UN Translation guidelines
- Linguee/DeepL corpus patterns (usage-based evidence)







