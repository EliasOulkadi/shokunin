---
name: shokunin-update
description: Detect drift, plan updates, and apply changes to the Shokunin AI Ecosystem. Use this when user asks to update, fix, sync, or verify the ecosystem.
triggers:
  - "update ecosystem"
  - "sync ecosystem"
  - "fix ecosystem"
  - "verify ecosystem"
  - "shokunin update"
  - "ecosystem status"
  - "check drift"
  - "update skills"
  - "repair ecosystem"
  - "ecosystem health"
negatives:
  - "update skill content"
  - "create skill"
  - "memory operations"
  - "session management"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: system
  audience: developers
---


> **Note:** The `shokunin-update.ps1` script lives in `.pack/scripts/` and is deployed to `~/.shokunin/scripts/` by the installer.

# Shokunin Update System

Maintains the Shokunin ecosystem by detecting drift between the declarative manifest and the actual filesystem state.

## Workflow

### 1. Load the manifest

Read `~/.shokunin/shokunin.json`. This is the single source of truth. Every component, path, hash, and template is defined here.

### 2. Check status

Run `shokunin-update.ps1 status` to detect drift:

- OK: hash matches manifest
- MISSING: file doesn't exist but manifest expects it
- PROTECTED: data files (chroma_db, sessions) that must never be modified

Report results to the user with counts.

### 3. Plan changes

Run `shokunin-update.ps1 plan` to see what would change without applying anything.

Show the user a clear summary of what will be created, modified, or left alone.

### 4. Apply with confirmation

```powershell
& "$env:USERPROFILE\.shokunin\scripts\shokunin-update.ps1" apply -Confirm
```

This automatically:
1. Backs up each file to `~/.shokunin/backups/<timestamp>/`
2. Applies changes
3. Saves update event to ChromaDB
4. Runs `memory-healthcheck.ps1` to verify

### 5. Rollback if needed

```powershell
& "$env:USERPROFILE\.shokunin\scripts\shokunin-update.ps1" rollback -Timestamp 20260514-120000
```

## When to use this skill

- User notices something broken in the ecosystem
- User wants to add/remove/modify a component
- User asks "is everything up to date?"
- Pre-commit or pre-PR verification

## Do NOT

- Modify files in `protected` groups (chroma_db, sessions, logs, backups)
- Apply changes without user confirmation
- Edit the manifest without understanding every field

## Error Handling

| Cause | Fix |
|-------|-----|
| shokunin.json manifest is missing or malformed | Validate JSON syntax with `Test-Json`. If missing, run installer `~/.shokunin/install.ps1` to regenerate from template. Report exact parse error line if malformed. |
| File hash mismatch but content is identical | Encoding difference (CRLF vs LF) or trailing whitespace. Normalize line endings with `.pack/scripts/normalize-eol.ps1` before re-checking. |
| Backup directory exceeds disk quota | Old backups accumulate over time. Retention policy: keep last 5 backups. Purge older directories with `Remove-Item -Recurse`. |
| Protected file group modified by apply | A bug or misconfiguration in the manifest marked a protected path as writable. Abort immediately. Rollback from backup. Fix manifest before retry. |
| Rollback target timestamp not found | Backup was purged by retention policy or never created. Cannot recover that point in time. Run `status` to assess current state and manually fix drift. |
| Powershell execution policy blocks the script | System execution policy set to Restricted | Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` or invoke with `powershell -ExecutionPolicy Bypass -File script.ps1`. |
| ChromaDB save during apply step fails | MCP server is down or ChromaDB collection is locked | Apply still succeeded on the filesystem. Save the update event manually: `python ~/.shokunin/scripts/chroma-helper.py save "update applied" ...`. |

## Related Scripts

- `~/.shokunin/scripts/validate-skills.ps1` — Validates all installed skills for required sections, size, and referenced script existence
- `~/.shokunin/scripts/shokunin-update.ps1` — Drift detection, manifest-driven update apply, rollback, and status reporting

## Sources

- PowerShell 5.1 documentation (learn.microsoft.com/en-us/powershell/scripting) — execution policy, file hashing, and error handling
- ChromaDB Python client documentation (docs.trychroma.com) — collection management and persistence
- Semantic Versioning 2.0.0 (semver.org) — version comparison logic used in drift detection
- Git documentation on plumbing commands (git-scm.com/docs/git-hash-object) — content-addressable storage pattern inspiration
- "Infrastructure as Code" by Kief Morris (O'Reilly, 2nd Edition, 2020) — drift detection and reconciliation patterns
- NIST SP 800-88 Guidelines for Media Sanitization — secure file overwrite patterns used in backup rotation

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Running `apply` without running `plan` first | Changes are applied without user awareness of what will be modified | Always run `plan` → show summary → get confirmation → then `apply`. |
| Modifying protected paths directly instead of through manifest | Data loss: chroma_db, sessions, logs get overwritten and cannot be recovered | Never touch paths under the protected group. If they need changes, update the manifest logic, not the files. |
| Hand-editing the manifest without understanding every field | A typo in a path or hash field cascades into false drift positives or corrupted apply | Use the declarative format. Every path must be absolute. Every hash must be SHA-256. Validate with `Test-Json` after edits. |
| Ignoring drift warnings for long periods | Drift accumulates, making later applies riskier and harder to roll back | Run `status` weekly. Schedule via Task Scheduler: `shokunin-update.ps1 status > ~/.shokunin/logs/drift.log`. |
| Restoring from backup without verifying backup integrity | A corrupted backup restores corrupted files | Before rollback, verify backup checksums against the original manifest hashes. Abort if mismatch. |
| Running apply while another apply is in progress | Race condition on backup/restore directories causing incomplete state | Use a lock file: `~/.shokunin/.apply-lock`. If lock exists and process is alive, wait or abort. Stale lock (>30 min) can be removed. |

## Checklist

- [ ] Verify shokunin.json is valid JSON and all component paths resolve
- [ ] Run shokunin-update.ps1 status — 0 MISSING, no crashes
- [ ] Run shokunin-update.ps1 apply — all components sync without errors
- [ ] Verify MCP server starts: python ~/.shokunin/memory/mcp-server.py responds to tools/list
- [ ] Verify chroma-helper.py CLI works: python ~/.shokunin/scripts/chroma-helper.py count
- [ ] Verify all 62 skills present in .config/opencode/skills/
- [ ] Verify templates match installed files (no drift)
- [ ] Verify AGENTS.md version matches shokunin.json version
- [ ] Run memory-healthcheck.ps1 — all tests pass
- [ ] Run alidate-skills.ps1 — 0 failures
