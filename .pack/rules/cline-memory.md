---
description: "Shokunin memory system: persistent context across sessions"
alwaysApply: true
---

# Shokunin Memory Instructions

This project uses ChromaDB for persistent memory between sessions.

## On Session Start (Mandatory)
- Search memory for relevant context using the current project and topic
- Present past session highlights to the user

## During Session
- Save a checkpoint every 3-5 interactions
- Save after each: decision made, file created/modified, command executed, user preference discovered
- Use: `python ~/.shokunin/scripts/chroma-helper.py save "text" "session_id" "type" "tags" "project"`

## Session ID
- Written to `~/.shokunin/current-session.json`
- Also available as `$env:SHOKUNIN_SESSION_ID`

## On Session End
- Save a complete summary: decisions, files changed, commands run, next steps
- Use type "session_end"
