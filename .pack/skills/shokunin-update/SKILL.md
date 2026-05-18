---
name: shokunin-update
description: Detect drift, plan updates, and apply changes to the Shokunin AI Ecosystem. Use this when user asks to update, fix, sync, or verify the ecosystem.
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
