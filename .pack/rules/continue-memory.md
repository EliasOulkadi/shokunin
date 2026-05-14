---
name: shokunin-memory
description: "Shokunin persistent memory using ChromaDB"
---

# Shokunin Memory Instructions

This project uses ChromaDB for persistent memory between sessions.

## On Session Start
- Search memory for relevant context using `chroma-helper.py`
- Session ID is at `~/.shokunin/current-session.json`
- Present past session highlights to the user

## During Session
- Save checkpoint every 3-5 interactions
- Save after each: decision, file change, command, preference
- Run: `python ~/.shokunin/scripts/chroma-helper.py save "text" "session_id" "type" "tags" "project"`

## On Session End
- Save complete summary with type "session_end"
- Include: decisions, files, commands, next steps
