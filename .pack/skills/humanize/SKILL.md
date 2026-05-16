---
name: humanize
---
# humanize · 人間

**人間 · にんげん** — "human being". Makes AI-generated text sound like a real person wrote it.

Based on research from: Grammarly, MIT Technology Review, GPTZero, QuillBot, Reddit (r/auscorp, r/cybersecurity), Hacker News, Stack Overflow, JustDone, print-css.rocks, BrowserStack, pdf4.dev benchmarks, and professional writing guides (2024–2026).

---

## Core metrics AI detectors measure

| Metric | What it means | Human text | AI text |
|--------|---------------|------------|---------|
| **Perplexity** | How predictable each word is | High — uses unexpected words | Low — always picks the most probable word |
| **Burstiness** | Variance in sentence length | High — mixes short/long sentences | Low — uniform sentence length |
| **Word frequency** | Rate of common vs rare words | Balanced — uses uncommon terms | Skewed — overuses "the", "it", "is" |
| **Repetition** | Recurring patterns | Low — natural variation | High — same structures repeat |

Sources: GPTZero, QuillBot, MIT Technology Review, Google Brain research (Ippolito et al. 2020)

---

## The 16 AI tells (con qué se nota)

### 1. Palabras comodín sobreutilizadas (Grammarly 2026, Reddit)

| Palabra AI | Alternativa humana |
|------------|-------------------|
| delve into | analizar, profundizar, explorar |
| pivotal | clave, determinante, crítico |
| underscore | destacar, señalar, remarcar |
| multifaceted | complejo, con varios aspectos |
| landscape | ecosistema, panorama, situación |
| paradigm | modelo, enfoque, esquema |
| robust | sólido, fiable, resistente |
| leverage | aprovechar, usar, sacar partido |
| seamless | fluido, sin fricción, natural |
| transformative | disruptivo, profundo, radical |

### 2. Conectores mecánicos (GPTZero research)

- "Moreover", "Furthermore", "Nevertheless", "Consequently" → usar "Además", "También", "Pero", "Por eso" o nada
- "Sin embargo" cada 3 párrafos → tachar la mitad, dejar que fluya
- "No obstante", "Por lo tanto", "En consecuencia" → reemplazar por "Así que", "Entonces", "Eso significa que"

### 3. Estructura perfecta y simétrica (MIT Tech Review)

Los LLMs generan párrafos del mismo largo, misma estructura: intro → punto → ejemplo → conclusión.

**Fix:** Romper el patrón. Párrafo de una línea. Luego uno largo. Lista. Luego otro corto.

### 4. Burstiness baja (QuillBot, pdf4.dev)

AI produce frases de largo parejo. Los humanos alternan:
- Frase corta. Impacto.
- Luego una más larga que desarrolla la idea con más detalle y matices, añadiendo contexto.
- Otra corta.

### 5. Neutralidad absoluta (r/auscorp, Reddit)

La IA nunca toma posición. Suena a wiki.
**Fix:** Meter opinión, juicio, sesgo reconocido. "Esto no nos gusta", "Esto está bien hecho", "Es debatible".

### 6. Transiciones forzadas (HN, cybersecurity forums)

"Es importante destacar que...", "Cabe mencionar que...", "Vale la pena señalar que..." → borrar todas. Si la frase no funciona sin la muleta, reescríbela.

### 7. Números y estadísticas sin fuente

AI inventa datos que "suenan bien". Ej: "Estudios demuestran que el 80% de los usuarios..."
**Fix:** Si no hay fuente real, no pongas número. Usa "muchos", "la mayoría", "es frecuente".

### 8. Voz pasiva excesiva

"Fue realizado", "Se ha determinado", "Puede ser observado"
**Fix:** Activa. "Realizamos", "Determinamos", "Se observa"

### 9. Hipérbole vacía (r/cybersecurity)

"Crítico", "Masivo", "Transformador", "Revolucionario" sin respaldo.
**Fix:** Datos concretos o lenguaje mesurado.

### 10. Cierre con pregunta retórica

"¿Estás listo para el futuro?", "¿Te imaginas un mundo donde...?"
**Fix:** Cerrar con afirmación o call to action directo.

### 11. Longitud uniforme de párrafos

AI: todos los párrafos 3-5 líneas.
Humano: mezcla naturale de 1 línea con 8 líneas.

### 12. F alta de coloquialismos

La IA no usa "vale", "bueno", "pues", "mira", "la cosa es que", "vamos a ver". El español real tiene muletillas.
**Fix:** Meter lenguaje natural controlado. No exagerar, pero soltar.

### 13. Demasiado formal para el contexto

Un informe interno escrito como paper académico. Un correo como carta formal.
**Fix:** Adecuar el registro al canal y audiencia.

### 14. Sin errores ni imperfecciones

La IA no tiene erratas, no repite una palabra por accidente, no reformula.
**Fix:** NO introducir errores artificiales. Pero sí permitir asimetría natural.

### 15. Sin contracciones ni formas contractas

AI: "no he", "de el", "a el"
Humano: "no he", "del", "al" (en inglés: don't, can't, won't, it's, I'm, they're)

### 16. Em dash (—) como conector universal

La IA abusa del guión largo `—` (em dash) como conector todoterreno. Patrón típico:

```
❌ IA:   Black Box — sin credenciales previas
❌ IA:   WordPress — actualizado a la última versión
❌ IA:   Panel de administración — accesible sin restricciones
```

Un humano normalmente usa:

```
✅ Real: Black Box (sin credenciales previas)
✅ Real: WordPress actualizado a la última versión
✅ Real: Panel de administración sin restricciones
```

El em dash real se usa para incisos o cambios de tono, no como pegamento entre label y valor. Si ves varias líneas con `—` seguidas, es IA.

**Fix:** reemplazar `—` por paréntesis, coma, dos puntos, o simplemente nada. Si el `—` separa un label de su valor, probablemente sobra el label o sobra el dash.

---

## The humanization workflow

### Paso 1: Detectar

Lee el texto completo. Marca cada instancia de:
- Palabras comodín (lista arriba)
- Conectores mecánicos
- Párrafos de largo idéntico
- Voz pasiva encadenada
- Hipérbole sin respaldo
- Neutralidad absoluta
- Muletillas de transición

### Paso 2: Podar

Borra todo lo que sea relleno:
- "Es importante destacar que" → [borrar]
- "Cabe mencionar que" → [borrar]
- "Vale la pena señalar que" → [borrar]
- "Como se mencionó anteriormente" → [borrar]
- "En el mundo actual" → [borrar]

### Paso 3: Variar

Reescribe para romper simetría:
- Una línea corta
- Párrafo largo con datos
- Otra línea corta
- Lista o tabla
- Párrafo de cierre con opinión

### Paso 4: Personalizar

Añadir capa de juicio/perspectiva:
- "Esto es discutible porque..."
- "En nuestra experiencia..."
- "El dato que más nos preocupa es..."
- "Francamente, esta solución no convence"

### Paso 5: Verificar

Pasa el resultado por:
- Un detector de IA (GPTZero, Originality)
- Una lectura en voz alta (si suena a robot, falló)
- La prueba "¿esto lo diría un humano en una conversación?"

---

## Anti-patterns checklist

Usar esta checklist antes de entregar cualquier texto humanizado:

| Señal | Presente | Corregido |
|-------|----------|-----------|
| Delve / dive / deep dive | | |
| "En el mundo actual / hoy en día" | | |
| Párrafos todos del mismo largo | | |
| Más de 1 "sin embargo" por página | | |
| "Es importante destacar" | | |
| Pregunta retórica al final | | |
| 0 opiniones o juicios | | |
| Lenguaje más formal que el contexto | | |
| Conector "además / por otro lado" repetido | | |
| Voz pasiva en más del 30% de verbos | | |
| Números sin fuente | | |
| "No obstante / no obstante" | | |
| Em dash `—` separando label/valor repetido | | |
| Afirmaciones sin fuente atribuida | | |

---

## Sources

- Grammarly (2026): "Common Words and Phrases in AI-Generated Text"
- MIT Technology Review (2025): "How to spot AI-generated text"
- GPTZero (2025–2026): "AI Detection Benchmarking", "Perplexity and Burstiness Explained"
- QuillBot: articulo "Burstiness and Perplexity Explained"
- Reddit r/auscorp: "What's the most obvious tell that someone has used AI"
- Reddit r/cybersecurity, Hacker News discussions
- Ippolito et al., Google Brain (2020): "Automatic Detection of Generated Text"
- JustDone / AHelp: Spanish AI detection guides
- print-css.rocks, BrowserStack, pdf4.dev (document formatting research)
