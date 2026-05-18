---
name: research
description: Deep research with web search, source verification, and fact-checking. Runs before humanize + kami in the document pipeline. Use when user asks to research a topic, verify facts, gather sources, or do deep web investigation. Covers source validation, citation, and evidence hierarchy.
---
# research · 調査

**調査 · ちょうさ** — "investigation". Source verification and fact-checking for document generation.

Pre-loads facts before writing. Runs BEFORE humanize + kami + kagen in the document pipeline. Prevents hallucinated data, fake citations, unverified claims.

Based on: CIA Structured Analytic Techniques (Heuer & Pherson), US Government Tradecraft Primer, NPR Training verification guide, Princeton triangulation methodology, OSINT verification tiers (War Intel Hub), journalistic cross-verification research (Godler & Reich), AI hallucination benchmarks (Vectara HHEM 2026), and evidence hierarchy frameworks (NHMRC).

---

## Core principle

**Sources before phrasing.** Do not write a claim without verifying it first. Every number, date, name, version, and citation must be traced to a primary or reputable secondary source.

---

## Evidence hierarchy (adapted from NHMRC + intelligence community)

Usar esta jerarquía para determinar el peso de cada fuente:

| Nivel | Tipo | Ejemplo |
|-------|------|---------|
| **1 — Primaria directa** | Documento oficial, captura directa, dato observado | Response HTTP real, código fuente, DB dump, screenshot |
| **2 — Primaria oficial** | Comunicado oficial, documentación pública, filing | SEC filing, CVE entry, changelog oficial, press release |
| **3 — Secundaria reputada** | Medio establecido, paper revisado, base de datos curada | NVD, Wordfence, OWASP, Reuters, arXiv |
| **4 — Múltiples fuentes independientes** | 3+ fuentes no relacionadas reportan lo mismo | Cross-reference entre blogs técnicos + foros + docs |
| **5 — Fuente única con evidencia** | Un source verificable pero sin corroboración | Blog de investigador con evidencia reproducible |
| **6 — Sin verificar** | Afirmación sin respaldo, rumor, especulación | NO usar como hecho en un documento |

**Regla:** un documento profesional solo usa niveles 1–4 para afirmaciones factuales. Nivel 5 para contexto o citas directas, marcado como tal. Nivel 6 no se publica.

---

## Source verification protocol (NPR + Princeton triangulation)

### Step 1: The direct knowledge test (antes de citar)

Preguntar sobre cada fuente:

- **First-hand:** ¿La fuente presenció el evento, participó directamente, o tiene documentación? → Fuerte, pero requiere corroboración
- **Second-hand:** ¿La fuente escuchó de alguien más? → Útil para leads, insuficiente para publicar
- **Third-hand+:** ¿Rumor, hearsay, especulación? → No publicable como hecho

### Step 2: Triangulation (Princeton method)

Cruce cada afirmación contra múltiples fuentes independientes:

```
Afirmación: "WordPress 6.7 tiene una vulnerabilidad X"
  → Fuente A: advisory oficial de WordPress
  → Fuente B: entrada en NVD/CVE
  → Fuente C: análisis de Wordfence o similar
  → ¿Coinciden? → VERIFICADO
  → ¿Solo una fuente? → NO VERIFICADO
```

### Step 3: Bias and agenda assessment (NPR)

Por cada fuente, identificar:

- **Financial interest:** ¿La fuente se beneficia económicamente de una narrativa particular?
- **Professional interest:** ¿Su reputación/carrera depende de cierto resultado?
- **Personal relationships:** ¿Amigos, familia, enemigos del sujeto?
- **Funding:** ¿Quién financia a la fuente? ¿Qué intereses tiene ese financiador?

### Step 4: The five-minute background check (NPR)

Cuando hay poco tiempo:

1. Leer bio y "About" de la fuente
2. Identificar quién financia o respalda
3. Buscar patrones de comportamiento o reclamos previos
4. Verificar si hay conflictos de interés visibles

---

## Verification tiers (adaptado de OSINT + War Intel Hub)

Cada afirmación en el documento debe tener un tier asignado:

| Tier | Label | Requisito | Color en documento |
|------|-------|-----------|-------------------|
| ✓ | **VERIFIED** | 2+ fuentes primarias o 1 primaria + evidencia directa | Normal (sin marca) |
| o | **CORROBORATED** | Multiples fuentes independientes reportan lo mismo, sin fuente primaria directa | Normal (sin marca) |
| X | **UNVERIFIED** | Fuente unica o no confirmable | Marcar explicitamente "no verificado" o no incluir |

**Regla:** en documentos profesionales, todo lo que se publica sin marca debe ser VERIFIED o CORROBORATED. Lo UNVERIFIED se omite o se declara como tal.

---

## Anti-hallucination checklist (basado en Vectara HHEM benchmarks 2026)

Los LLMs alucinan 15-20% del tiempo en consultas factuales (fuente: Prompt Guardrails, Vectara benchmark March 2026). Los modelos de razonamiento alucinan más que los estándar en summarization (DeepSeek-R1: 14.3% vs V3: 6.1%).

Antes de escribir cualquier afirmación, pasar por este filtro:

| Pregunta | Check |
|----------|-------|
| ¿Este número tiene fuente verificable? | |
| ¿Esta fecha está confirmada en fuente primaria? | |
| ¿Este nombre/versión existe realmente? | |
| ¿Esta cita es textual y verificable? | |
| ¿Este CVE/ID es real y corresponde a lo que digo? | |
| ¿Esta estadística viene de un estudio real? | |
| ¿Estoy inventando un "estudio demuestra" para dar peso? | |
| ¿Esta afirmación sobre el modelo/framework es cierta hoy? | |

---

## Categorías comunes de datos inventados por IA (research flags)

| Categoría | Señal de alerta | Qué hacer |
|-----------|----------------|-----------|
| **Versiones** | "WordPress 6.8 tiene..." sin advisory | Verificar en wordpress.org/news/releases |
| **CVEs** | CVE-2026-XXXX sin entrada en NVD | Buscar en nvd.nist.gov |
| **Estadísticas** | "El 80% de los sitios..." sin estudio | No usar sin fuente |
| **Fechas** | Fechas de parches, lanzamientos | Verificar en changelog oficial |
| **Citas textuales** | "Como dijo X: '...'" | Confirmar que X realmente dijo eso |
| **Métricas de seguridad** | Tiempos de explotación, tasas | Buscar en informes reales (Veracode, Splunk, etc.) |
| **Nombres de herramientas** | Herramientas que no existen o versiones incorrectas | Verificar homepage oficial o repositorio |

---

## Context adaptation by document type

No todos los documentos necesitan el mismo nivel de verificación. Ajustar según el tipo:

| Tipo de documento | Prioridad de verificación | Campos críticos | Tolerancia |
|-------------------|---------------------------|-----------------|------------|
| **Pentest / Security** | Máxima | CVEs, versiones, fechas, capturas, exploits | Cero. Un CVE falso invalida el informe |
| **White paper / Técnico** | Alta | Estadísticas, citas, fechas, versiones, nombres de herramientas | Baja. Citas inventadas destruyen credibilidad |
| **One-pager / Ejecutivo** | Media | Métricas principales, nombres de clientes, fechas clave | Media. Errores menores tolerables si el mensaje central es correcto |
| **Resume / CV** | Máxima en datos personales | Fechas de empleo, títulos, empresas, logros cuantificables | Cero en datos personales. Las afirmaciones de logros pueden ser contextuales |
| **Letter / Carta** | Baja | Nombres, cargos, fechas | Alta. El tono importa más que la precisión factual |
| **Slides / Deck** | Media | Estadísticas clave, citas textuales, nombres | Media. El contexto visual prima sobre el detalle |

Regla: si el documento va a un cliente externo o tiene implicaciones legales/de seguridad, usar verificación máxima siempre.

## Document pipeline integration
- Una versión específica de software → buscar changelog oficial
- Un CVE o vulnerabilidad → buscar en NVD + advisory oficial
- Una estadística o métrica → buscar fuente primaria o no incluir
- Una cita textual → confirmar que existe
- Una fecha de evento → verificar en fuente oficial
- Un nombre de persona/herramienta/empresa → verificar que existe y está bien escrito

---

## Sources

- Heuer & Pherson, *Structured Analytic Techniques for Intelligence Analysis* (CIA Sherman Kent School)
- US Government, *A Tradecraft Primer: Structured Analytic Techniques for Improving Intelligence Analysis* (2009)
- NPR Training, "Don't just check the facts, check the source: a guide to verification" (March 2026)
- Princeton University Library, guia "Triangulation and Media Literacy" (2025)
- War Intel Hub, "OSINT Verification Methodology"
- Vectara HHEM hallucination benchmark leaderboard (March 2026)
- Prompt Guardrails, "AI Hallucination Detection and Prevention Guide" (2026)
- News Factory, "News Fact-Checking in 2026: Hallucination Benchmarks, RAG, and Verification Tools"
- Reuters / AP sourcing standards
- GlobalX Publications, "Fact-Checking, Triangulation, and Evidence Reliability in Research"
- NHMRC evidence hierarchy framework
