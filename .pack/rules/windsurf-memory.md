---
description: "Shokunin memory system: persistent context across sessions"
trigger: always_on
---

# Shokunin Memory Instructions

This project uses ChromaDB for persistent memory between sessions.

## On Session Start
- Search memory for relevant context
- Present past session highlights to the user
- Session ID is at `~/.shokunin/current-session.json`

## During Session
- Save checkpoint every 3-5 interactions
- Save after: decisions, file changes, commands
- Use: `python ~/.shokunin/scripts/chroma-helper.py save`

## On Session End
- Save complete summary with type "session_end"
