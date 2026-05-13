# Contribuyendo a Shokunin

Gracias por interesarte en contribuir. Esto es lo que necesitas saber.

## Cómo contribuir skills

1. Crea un directorio con el nombre de tu skill
2. Dentro, un `SKILL.md` con frontmatter YAML:

```yaml
---
name: tu-skill
description: Qué hace y cuándo usarla. Incluye "Use when" y "Do NOT use for".
license: MIT
compatibility: opencode
metadata:
  workflow: backend|frontend|devops|marketing|productivity
  audience: developers|designers|devops
  version: "1.0"
  author: tu-nombre
---
```

3. Si aplica, añade `scripts/`, `references/`, `assets/`
4. El `name` debe coincidir con el nombre del directorio
5. Haz un PR

## Estándares

- Descripción con trigger phrases conversacionales
- Workflow numerado paso a paso
- Tabla de errores (escenario → causa → fix)
- Production checklist
- Anti-patterns
- Fuentes reales citadas

## Código de conducta

Sé respetuoso. Las contribuciones tóxicas serán rechazadas.
