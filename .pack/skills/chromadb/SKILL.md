---
name: chromadb
description: Manages ChromaDB memory base: view storage, search entries, delete, backup, and reset. Use when user asks to manage memory, check what's stored in ChromaDB, delete memory entries, backup the vector database, or reset the memory. Do NOT use for general question answering about past sessions (use memory skill for that).
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "1.0"
  author: shokunin
---

# ChromaDB Manager

Manages the vector database that stores the ecosystem's persistent memory.

## Commands

| Command | Description |
|---------|-------------|
| /memory-status | Shows number of entries, disk size, collections |
| /memory-search [query] | Searches for specific entries in memory |
| /memory-delete [id] | Deletes a specific entry |
| /memory-backup | Creates a ChromaDB backup |
| /memory-reset | Deletes ALL memory (confirmation required) |

## Workflow

### Check memory status
The agent uses `search_context` with `query: "__stats__"` to count entries.
Or run:
```powershell
$stats = @"
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search_context","arguments":{"query":"stats"}}}
"@ | python ~/.shokunin/memory/mcp-server.py 2>&1
```

### Memory backup
Data is stored in `~/.shokunin/memory/chroma_db/`. Backup:
```powershell
$backupDir = "$env:USERPROFILE\.shokunin\backups"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$date = Get-Date -Format 'yyyy-MM-dd'
Compress-Archive -Path "$env:USERPROFILE\.shokunin\memory" -DestinationPath "$backupDir\memory-$date.zip" -Force
Write-Host "Backup: $backupDir\memory-$date.zip"
```

### Full reset (if you want to start from scratch)
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.shokunin\memory\chroma_db"
Write-Host "Memory deleted. It will recreate itself on next use."
```

## Automation
Automatic backup every Sunday with the weekly cleanup (already configured in Task Scheduler).

## Where the data is
- Database: `~/.shokunin/memory/chroma_db/`
- Backups: `~/.shokunin/backups/`
- Typical size: ~400 KB (grows ~1 KB per entry)
