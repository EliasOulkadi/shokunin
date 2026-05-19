---
name: whendone-plus
description: Automatically notify the user when long-running terminal commands finish (npm test, docker build, git push, etc.). The agent monitors command execution and sends a desktop notification on completion if the command ran longer than threshold (default 10s). Use when user asks to "notify me when done", "desktop notification when command finishes", "alert when done", or "tell me when this completes". Do NOT use for interactive commands (vim, nano, less, htop), commands that always complete in <5s, or streaming commands (tail -f).
triggers:
  - "notify me when done"
  - "desktop notification"
  - "alert when done"
  - "tell me when this completes"
  - "notify when finished"
  - "ping me when"
  - "remind me when"
  - "notification on completion"
  - "when done"
negatives:
  - "interactive commands"
  - "vim"
  - "nano"
  - "less"
  - "htop"
  - "streaming commands"
  - "tail -f"
  - "short commands"
license: MIT
compatibility: opencode
metadata:
  workflow: automation
  audience: developers
  version: "3.0.0"
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
- `docker build`, `docker compose up`, `docker compose down`
- `git push`, `git pull`, `git clone`
- `pip install`, `npm install`, `pnpm install`, `yarn install`
- `cargo build`, `cargo test`, `go build`, `dotnet build`
- Custom scripts, database migrations, data processing pipelines
- `ffmpeg`, `rsync`, `scp`, large file transfers

### Step 2: Monitor execution

Start a background timer when the command begins. Track:
- Elapsed wall-clock time
- Peak memory usage (if available)
- Child process tree (for pipeline awareness)

### Step 3: Notify on completion

Basic notification format:
```
✅ "Command finished: npm test completed in 142s (exit 0)"
❌ "Command finished: docker build failed in 89s (exit 1)"
```

Include:
- Command name (first word + key args)
- Execution time (rounded to seconds)
- Exit code (success/failure)
- Optional: memory peak, output file path if redirected

### Step 4: Handle edge cases

- Commands completing under 10s: no notification (too fast to matter)
- Interactive/TUI commands (vim, nano, htop): skip (user is watching)
- Piped commands (e.g. `npm test | grep error`): monitor the pipeline, not the first process
- Backgrounded commands (`&`): notify on background process completion
- Chained commands (`;`): notify per-segment or in aggregate
- Commands killed by signal: notify with signal name (e.g. "killed by SIGTERM")

## Notification Mechanisms

### Windows Toast Notification (PowerShell)

```powershell
Add-Type -AssemblyName System.Windows.Forms
$balloon = New-Object System.Windows.Forms.NotifyIcon
$balloon.Icon = [System.Drawing.SystemIcons]::Information
$balloon.BalloonTipTitle = "Command Complete"
$balloon.BalloonTipText = "npm test finished in 142s (exit 0)"
$balloon.Visible = $true
$balloon.ShowBalloonTip(5000)
Start-Sleep -Seconds 5
$balloon.Dispose()
```

### Terminal Bell (cross-platform)

```bash
echo -e "\a"                         # ASCII bell character
printf '\a'                          # POSIX
```

### BurntToast Module (Windows 10/11)

```powershell
Import-Module BurntToast
New-BurntToastNotification -Text "Command Complete", "npm test finished in 142s (exit 0)"
```

### macOS Notification

```bash
osascript -e 'display notification "npm test finished in 142s" with title "Command Complete"'
terminal-notifier -title "Command Complete" -message "npm test finished in 142s"
```

### Linux Notification (notify-send)

```bash
notify-send "Command Complete" "npm test finished in 142s"
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Notification never fires | Command completed under threshold | Expected. Threshold is 10s by default. |
| Wrong exit code reported | Shell pipeline masking failures | Use `$PIPESTATUS` in bash, `$LASTEXITCODE` in PowerShell |
| Notification module missing | BurntToast/notify-send not installed | Fallback to terminal bell or `Write-Host` |
| Silent failure on background job | Job detached from monitor process | Use `Wait-Job` in PowerShell, `wait` in bash |
| Double notification | Parent and child process both fire | Track PID tree, notify only on root process |
| Desktop notification blocked | System focus assist or DnD mode | Fallback to terminal output with colored exit code |
| Command output lost | Notification intercepts stdout/stderr | Always tee or capture output before monitoring |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Notify for every command | Only if >10s threshold |
| Breaking pipes | Ensure stdout/stderr passthrough |
| Breaking exit codes | Pass through original exit code |
| Notifications for interactive commands | Skip if TUI detected |
| Notify and then continue working | Wait for notification confirmation or user acknowledgment |
| Assuming notification system is available | Always have a text-only fallback (Write-Host) |
| Monitoring subprocess instead of pipeline | Track the entire pipeline PID group |

## Customization

| Setting | Default | Description |
|---------|---------|-------------|
| Threshold | 10s | Minimum command duration to trigger notification |
| Notification style | Toast | toast, bell, or both |
| Include exit code | Yes | Show pass/fail in notification |
| Show elapsed time | Yes | Include duration in notification text |
| Fallback on failure | Bell | What to do if toast notification fails |

## Checklist

- [ ] Notification method matches platform (BurntToast on Windows, terminal-notifier on macOS, notify-send on Linux)
- [ ] Threshold duration set appropriately (default 10s — not too short, not too long)
- [ ] Not used for interactive commands (vim, nano, htop, less)
- [ ] Custom message includes the command name and result (success/fail)
- [ ] Fallback: terminal bell or Write-Host if notification fails

## Sources

- Windows Toast API (docs.microsoft.com/en-us/windows/apps/design/shell/tiles-and-notifications)
- BurntToast PowerShell module (github.com/Windos/BurntToast)
- notify-send (Linux Desktop Notifications Specification)
- terminal-notifier (github.com/julienXX/terminal-notifier)
- macOS osascript display notification (developer.apple.com)
- POSIX terminal bell (ASCII 0x07)
- Shell job control (bash manual, PowerShell about_Jobs)
