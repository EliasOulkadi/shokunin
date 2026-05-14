---
name: cleanup-surgeon
description: Scan directories, detect old/unused files, analyze importance with AI, and move junk to Recycle Bin. Presents a categorized report and asks confirmation before acting. Use when user says "clean up", "declutter", "organize files", "remove old stuff", "clear desktop", "free up space", "disk cleanup", "borrar archivos viejos", "ordenar carpetas", "limpiar". Do NOT use for system file cleanup, registry cleaning, or any destructive operation.
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: admin
  version: "1.0"
  author: shokunin
allowed-tools: Read Bash Write
---

# Cleanup Surgeon

Scans Desktop, Downloads, TEMP, and other directories for old/unused files. Analyzes each file's metadata (creation date, last modified, last accessed, size, type). The agent uses AI judgment to classify files as safe-to-delete, review-needed, or keep. Always moves to Recycle Bin — never permanent delete.

## Workflow

### Step 1: Run scan

Execute the scanner to gather file data:

```powershell
python "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py" save "CHECKPOINT: Cleanup scan started" "cleanup-$(Get-Date -Format 'yyyyMMdd')" "checkpoint" "cleanup-surgeon,scan" "$(Get-Location)" 2>$null
```

Run the scan script:
```powershell
$scanResult = & "$env:USERPROFILE\.shokunin\scripts\scan-cleanup.ps1" -Scan
```

This returns JSON with all scanned files grouped by directory.

### Step 2: Analyze results with AI

For each file in the scan results, analyze:

| Attribute | Source | What to infer |
|-----------|--------|---------------|
| Name | JSON | Does it look AI-generated? (contains "shokunin", "kami", "changelog", "ecosystem") |
| Extension | JSON | Installer (.exe/.msi), document (.pdf), archive (.zip), image (.png/.jpg) |
| Size | JSON | Is it large? (>100 MB worth investigating) |
| Created | JSON | When was it first created? |
| LastWriteTime | JSON | When was it last modified? |
| LastAccessTime | JSON | When was it last opened? |
| DaysSinceAccess | JSON | Calculated: how many days since last use |
| Directory | JSON | Desktop, Downloads, TEMP, .shokunin/docs |
| InGitHub | Inferred | For PDFs: does the filename match docs/ in the repo? |

Use these rules to classify each file:

**🟢 Papelera (safe to delete)** — at least 2 of:
- Not accessed in >30 days
- Extension is .exe/.msi/.zip/.rar (installer or archive)
- Name matches known AI-generated patterns (shokunin, kami, changelog)
- Located in TEMP or Downloads
- PDFs that exist in the GitHub repo docs/

**🟡 Revisar (ask user)** — any of:
- Accessed in last 7 days
- Previously unknown extension (the agent doesn't recognize it)
- Located on Desktop and not AI-generated
- Large file (>100 MB) that might be important

**🔴 Conservar (keep)** — any of:
- Modified today or yesterday
- Path contains `.git`, `memory/`, `chroma_db/`, `sessions/`
- Located in `~/.shokunin/memory/`
- System directories (Windows, Program Files, etc.)

### Step 3: Present results

Format the output as:

```
Escaneando C:\Users\swagger...
📁 DESKTOP (8 archivos)
  → Shokunin-Quickstart.pdf        (14 may, 116 KB) → AI-generated 🟢 Papelera
  → Shokunin-v4.2-Linux-Port.pdf   (14 may, 111 KB) → AI-generated, reciente 🔍 ¿usas?
  → setup.exe                      (2 may, 50 MB)   → instalador obsoleto 🟢 Papelera
  → imagen-random.png              (10 may, 2 MB)    → sin carpeta 🟡 ¿Mover?
📁 DOWNLOADS (23 archivos)
  → node-v22.0.0-x64.msi          (20 abr, 35 MB)   → instalado 🟢 Papelera
  → proyecto-cliente-docs.pdf     (12 may, 3 MB)    → importante 🔴 Conservar

💾 85 MB recuperables · 12 🟢 · 5 🟡 · 2 🔴
```

Present the report to the user naturally: "Encontré 19 archivos (~85 MB). 12 son candidatos seguros para la papelera, 5 habría que revisarlos, 2 parecen importantes. ¿Qué hago?"

### Step 4: Get confirmation

Ask by category, not by individual file:
- "¿Borro los 4 PDFs viejos que ya están en GitHub?"
- "¿Y los 6 instaladores de programas que ya tienes instalados?"
- "¿Muevo los archivos sueltos del escritorio a Documentos/?"

If user says yes or selects categories:

```powershell
& "$env:USERPROFILE\.shokunin\scripts\scan-cleanup.ps1" -Clean @(ids)
```

### Step 5: Execute cleanup

The script will:
1. Move each file to Recycle Bin using `Microsoft.VisualBasic.FileIO`
2. Write a log entry to `~/.shokunin/logs/cleanup.log`
3. Return a summary of what was done

### Step 6: Report results

```
✅ Hecho: 8 archivos a la papelera (62 MB)
📦 3 archivos organizados a Documentos/
📝 Log: ~/.shokunin/logs/cleanup.log
```

## Categories

The scanner groups files into these categories:

| Category | Extensions | Default action |
|----------|------------|----------------|
| AI-generated PDFs | `.pdf` matching shokunin/changelog/kami patterns | 🟢 Papelera if in GitHub |
| Installers | `.exe`, `.msi`, `.dmg`, `.AppImage` | 🟢 Papelera if >30 days |
| Archives | `.zip`, `.rar`, `.7z`, `.tar.gz` | 🟢 Papelera if >60 days |
| Temp files | `%TEMP%/*` | 🟢 Papelera if >7 days |
| Cache | npm, pip, docker cache dirs | 🟢 Papelera if >30 days |
| Desktop orphans | Files directly on Desktop (not shortcuts) | 🟡 Review |
| Important docs | `.pdf`, `.docx`, `.xlsx` in Documents | 🔴 Keep |
| Recent | Any file <7 days old | 🔍 Ask |

## Safety Rules

- **NEVER** use `Remove-Item` — always move to Recycle Bin via `Microsoft.VisualBasic.FileIO`
- **NEVER** touch `~/.shokunin/memory/`, `chroma_db/`, `sessions/`
- **NEVER** touch system directories: `Windows`, `Program Files`, `System32`
- **NEVER** touch directories containing `.git` (active projects)
- **ALWAYS** ask before deleting anything marked 🟡
- **ALWAYS** show a summary before executing
- **ALWAYS** log all actions to `~/.shokunin/logs/cleanup.log`

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Path not found | User removed the directory | Skip and continue |
| Access denied | File in use by another program | Skip, report at end |
| Recycle Bin unavailable | Network location | Skip, mark as manual |
| Scan returns nothing | All clean | Report "Nothing to clean" |

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| Deleting files permanently | User loses data they wanted | Always use Recycle Bin via Shell.Application or Microsoft.VisualBasic |
| Scanning system directories | Can break Windows | Exclude Windows, Program Files, System32 |
| Deleting by age only | Ignores file importance | AI must analyze content before classifying |
| No confirmation step | User feels unsafe | Always summarize categories before acting |
| Scanning without exclusion paths | Memory data could be deleted | Hardcode exclusion for chroma_db, sessions, .git |
| Processing files one by one via COM | Slow, shows progress dialogs | Batch with silent flags or permanent delete for TEMP |
| Using Remove-Item -Force | Permanent data loss | Never use for user-visible files; only for TEMP |
| Classifying PDFs solely by extension | Important docs get deleted | Check name for AI-generation patterns |

## Sources

- Microsoft Shell.Application documentation (learn.microsoft.com)
- Microsoft.VisualBasic.FileIO documentation (learn.microsoft.com)
- PowerShell scripting best practices (learn.microsoft.com)
- Windows Temp directory management best practices
