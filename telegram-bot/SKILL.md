---
name: telegram-bot
description: Mobile access to the AI ecosystem via Telegram. Send commands from your phone to query the system, ask questions, check status, search memory, and receive notifications. Use when user wants to interact from mobile, receive alerts on Telegram, or check system status remotely. Do NOT use for desktop interactions (use direct OpenCode session).
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "1.0"
  author: shokunin
---

# Telegram Bot

Mobile access to your AI engineering ecosystem from anywhere. Query, command, and monitor via Telegram.

## How It Works

A Python Telegram bot runs on your Windows machine. It connects Telegram messages to OpenCode's REST API and the memory system.

- **Bot script**: `~/.shokunin/telegram/bot.py`
- **Queue**: `~/.shokunin/telegram/queue.jsonl` (pending questions when OpenCode is offline)
- **Token**: Set via environment variable `TELEGRAM_BOT_TOKEN`

## Setup

### Step 1: Create a Telegram bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow the prompts
3. Save the API token you receive
4. Set it as an environment variable:

```powershell
[System.Environment]::SetEnvironmentVariable('TELEGRAM_BOT_TOKEN', 'your-token-here', 'User')
```

### Step 2: Start the bot

```powershell
# Start in background
Start-Process -WindowStyle Hidden -FilePath "python" -ArgumentList "C:\Users\swagger\.shokunin\telegram\bot.py"

# Or schedule to start with Windows
# Add to $PROFILE:
# Start-Job -ScriptBlock { python C:\Users\swagger\.shokunin\telegram\bot.py }
```

### Step 3: Use from your phone

Open Telegram, find your bot, and send commands:

| Command | What it does |
|---------|-------------|
| `/start` | Welcome + available commands |
| `/ask [pregunta]` | Envía pregunta a OpenCode |
| `/status` | Estado del sistema (skills, uptime) |
| `/memory [query]` | Busca en memoria de sesiones pasadas |
| `/backup` | Ejecuta backup de DB |
| `/cleanup` | Ejecuta limpieza del sistema |
| `/help` | Lista completa de comandos |

## Available Commands

### /ask
Send a question to the AI ecosystem:
```
/ask create a Dockerfile for my Node.js app
/ask what skills do I have for frontend?
/ask check if my site is down
```

If OpenCode is running, it responds directly. If not, the question is queued and processed when OpenCode starts.

### /status
Returns current system status:
```
📊 System Status
• Skills: 34 installed
• Uptime: 12d 4h
• Last backup: 2026-05-13
• Pending: 0 queued questions
• Memory: 142 stored contexts
```

### /memory
Search past conversations:
```
/memory authentication implementation
/memory docker optimization tips
/memory project X architecture decision
```

### /backup
Triggers a database backup script remotely. Useful before risky operations.

### /cleanup
Triggers the system cleanup script remotely.

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Bot doesn't respond | Token not set | Set `TELEGRAM_BOT_TOKEN` env var |
| /ask returns "queued" | OpenCode not running | Start OpenCode or start its API server |
| Bot stops working | Python script crashed | Restart with the command above |
| /memory returns nothing | No data stored | Normal on first use. The memory MCP server must be running. |

## Auto-start with Windows

Add to your PowerShell profile (`$PROFILE`):

```powershell
# Auto-start Telegram bot (hidden)
$botJob = Get-Job -Name "TelegramBot" -ErrorAction SilentlyContinue
if (-not $botJob) {
    Start-Job -Name "TelegramBot" -ScriptBlock {
        python C:\Users\swagger\.shokunin\telegram\bot.py
    }
}
```

## Sources

- python-telegram-bot documentation (python-telegram-bot.org)
- OpenCode REST API documentation (opencode.ai/docs/api)
