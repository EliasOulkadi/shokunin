---
name: whendone-plus
description: Automatically notify the user when long-running terminal commands finish (npm test, docker build, git push, etc.). The agent monitors command execution and sends a desktop notification on completion if the command ran longer than threshold (default 10s). Use when user asks to "notify me when done", "desktop notification when command finishes", "alert when done", or "tell me when this completes". Do NOT use for interactive commands (vim, nano, less, htop), commands that always complete in <5s, or streaming commands (tail -f).
license: MIT
compatibility: opencode
metadata:
  workflow: automation
  audience: developers
  version: "2.0"
---

# WhenDone Plus

Automatically notify when long-running commands complete.

## How It Works

1. User runs a long command (e.g. `npm test`, `docker build`, `git push`)
2. The agent monitors the command execution time
3. If the command runs longer than the threshold (default 10s), the agent notifies the user on completion
4. Exit code is passed through

## Workflow

### Step 1: Detect long-running command

Identify commands likely to exceed threshold:
- `npm test`, `npm run test`, `npx playwright test`
- `docker build`, `docker compose up`
- `git push`, `git pull`
- `pip install`, `npm install`
- Custom scripts, builds, or migrations

### Step 2: Notify on completion

```
✅ "Command finished: npm test completed in 142s (exit 0)"
❌ "Command finished: docker build failed in 89s (exit 1)"
```

Include:
- Command name
- Execution time (rounded to seconds)
- Exit code (success/failure)

### Step 3: Exceptions

- Commands completing under 10s: no notification (too fast to matter)
- Interactive/TUI commands (vim, nano, htop): skip (user is watching)
- Piped commands (e.g. `npm test | grep error`): monitor the pipeline, not the first process

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Notify for every command | Only if >10s threshold |
| Breaking pipes | Ensure stdout/stderr passthrough |
| Breaking exit codes | Pass through original exit code |
| Notifications for interactive commands | Skip if TUI detected |
| Notify and then continue working | Wait for notifcation confirmation or user acknowledgment |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Notification not showing | OS notifications disabled | Check system notification settings |
| Wrong threshold triggering | Threshold too low for this command type | Increase threshold per command type |
| Piped command not detected | Pipe breaks execution tracking | Use `; command` instead of `| command` |
| TUI detected incorrectly | Some CLIs look like TUIs | Add to exclude list |

## Production Checklist

- [ ] **Threshold**: set per command type (default 10s)
- [ ] **Notifications**: test on target OS (Windows Action Center, Linux notify-send, macOS Notification Center)
- [ ] **No breakage**: verify pipes and exit codes pass through correctly
- [ ] **TUI exclusion**: confirm opencode, vim, less, htop are excluded
- [ ] **Logging**: notification events logged for debugging

## Sources

- Windows Toast Notifications API (learn.microsoft.com)
- Linux notify-send documentation (man.archlinux.org)
- macOS Notification Center docs (developer.apple.com)
- PowerShell background job docs (learn.microsoft.com)
