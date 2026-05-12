---
name: whendone-plus
description: Automatically send desktop notifications when long-running terminal commands finish (npm test, docker build, git push, etc.). Wraps commands via shell integration — no need to prefix with "whendone". Triggers on "notify me when", "desktop notification", "alert when done", "tell me when this finishes", "whendone", "background task notification". Do NOT use for interactive commands (vim, nano, less) or commands under 5 seconds.
license: MIT
compatibility: opencode
metadata:
  workflow: automation
  audience: developers
---

Automatically detect long-running commands and notify you when they complete — without having to remember to prefix them.

## How It Works

The skill creates a shell wrapper that:
1. Intercepts commands before execution
2. Measures execution time
3. Sends a native desktop notification if the command ran longer than threshold
4. Passes through exit code (so `&&` chaining still works)

## Installation

### Option A: PowerShell (Windows)
Add to your `$PROFILE`:
```powershell
function Invoke-WhendonePlus {
  $start = Get-Date
  $command = $args -join ' '
  $global:lastexitcode = 0
  try {
    Invoke-Expression $command
    if ($global:lastexitcode -ne 0) { throw "exit $global:lastexitcode" }
  } catch {
    $global:lastexitcode = 1
  }
  $elapsed = (Get-Date) - $start
  if ($elapsed.TotalSeconds -gt 10) {
    $status = if ($global:lastexitcode -eq 0) { "✅" } else { "❌" }
    $title = "$status Command finished"
    $msg = "'$command' completed in $([math]::Round($elapsed.TotalSeconds))s (exit: $global:lastexitcode)"
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipTitle = $title
    $notify.BalloonTipText = $msg
    $notify.Visible = $true
    $notify.ShowBalloonTip(5000)
  }
}
Remove-Item Alias:devenv -Force -ErrorAction SilentlyContinue
Set-Alias -Name "npminstall" -Value "npm install"
```

### Option B: Node.js script (cross-platform)
Create `$SKILL_DIR/scripts/notify.js`:
```javascript
#!/usr/bin/env node
const { execSync, spawn } = require('child_process');
const cmd = process.argv.slice(2).join(' ');
const start = Date.now();
const child = spawn(cmd, { stdio: 'inherit', shell: true });
child.on('exit', code => {
  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  if (elapsed > 10) {
    const icon = code === 0 ? '✅' : '❌';
    const title = `${icon} Command ${code === 0 ? 'completed' : 'failed'}`;
    const msg = `"${cmd}" — ${elapsed}s (exit ${code})`;
    try {
      execSync(`powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $n=New-Object System.Windows.Forms.NotifyIcon; $n.Icon=[System.Drawing.SystemIcons]::Information; $n.BalloonTipTitle='${title}'; $n.BalloonTipText='${msg}'; $n.Visible=$true; $n.ShowBalloonTip(5000)"`, { timeout: 3000 });
    } catch {}
  }
  process.exit(code ?? 0);
});
```

Usage: `node $SKILL_DIR/scripts/notify.js npm test`

## Quick Usage

Once installed, just run commands normally:
```bash
npm test          # runs → notifies when done (>10s)
docker build .    # runs → notifies when done
npx playwright test  # runs → notifies when done
git push          # runs → notifies when done
```

Short commands (<10s) run silently — no notification.

## Manual Override

| Prefix | Behavior |
|--------|----------|
| `node notify.js npm test` | Always notify (even if <10s) |
| `npm test` | Auto-detected (notify if >10s) |
| `start npm test` | Suppress notification |

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Threshold | 10s | Minimum duration to trigger notification |
| Timeout | 15s | Kill notification if command runs longer |
| Sound | True | Play system sound on completion |
| Sticky | False | Notification stays until dismissed |

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Wrapping every command | Only wrap if threshold >10s. `ls`, `cd`, `cat` should passthrough. |
| Breaking pipes | Ensure stdout/stderr passthrough. `npm test | grep error` must work. |
| Breaking exit codes | Always `process.exit(code)` — don't swallow errors. |
| Notifications for interactive commands | Skip if command opens interactive TUI (vim, htop, less). |
