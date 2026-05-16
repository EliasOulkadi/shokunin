---
name: chromadb
description: Gestiona la base de memoria ChromaDB: ver almacenamiento, buscar entradas, borrar, hacer backup, y resetear. Use when user asks to manage memory, check what's stored in ChromaDB, delete memory entries, backup the vector database, or reset the memory. Do NOT use for general question answering about past sessions (use memory skill for that).
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "1.0"
  author: shokunin
---

# ChromaDB Manager

Gestiona la base de vectores que almacena la memoria persistente del ecosistema.

## Comandos

| Comando | Descripción |
|---------|-------------|
| /memory-status | Muestra cuántas entradas hay, tamaño en disco, colecciones |
| /memory-search [query] | Busca entradas específicas en la memoria |
| /memory-delete [id] | Borra una entrada específica |
| /memory-backup | Crea backup de ChromaDB |
| /memory-reset | Borra TODA la memoria (confirmación requerida) |

## Workflow

### Ver estado de la memoria
El agente usa `search_context` con `query: "__stats__"` para contar entradas.
O ejecuta:
```powershell
$stats = @"
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search_context","arguments":{"query":"stats"}}}
"@ | python ~/.shokunin/memory/mcp-server.py 2>&1
```

### Backup de la memoria
Los datos están en `~/.shokunin/memory/chroma_db/`. Backup:
```powershell
$backupDir = "$env:USERPROFILE\.shokunin\backups"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$date = Get-Date -Format 'yyyy-MM-dd'
Compress-Archive -Path "$env:USERPROFILE\.shokunin\memory" -DestinationPath "$backupDir\memory-$date.zip" -Force
Write-Host "Backup: $backupDir\memory-$date.zip"
```

### Reset completo (si quieres empezar de cero)
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.shokunin\memory\chroma_db"
Write-Host "Memoria borrada. Se recreará sola al próximo uso."
```

## Automatización
Backup automático cada domingo con el cleanup semanal (ya configurado en Task Scheduler).

## Dónde están los datos
- Base de datos: `~/.shokunin/memory/chroma_db/`
- Backups: `~/.shokunin/backups/`
- Tamaño típico: ~400 KB (crece ~1 KB por entrada)
