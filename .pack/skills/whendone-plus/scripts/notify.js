#!/usr/bin/env node
const { execSync, spawn } = require('child_process');
const cmd = process.argv.slice(2).join(' ');
if (!cmd) { console.error('Usage: node notify.js <command>'); process.exit(1); }

const start = Date.now();
const child = spawn(cmd, { stdio: 'inherit', shell: true });

child.on('exit', code => {
  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  if (parseFloat(elapsed) > 10) {
    const icon = code === 0 ? '✅' : '❌';
    const title = `${icon} Command ${code === 0 ? 'completed' : 'failed'}`;
    const msg = `"${cmd}" — ${elapsed}s (exit ${code})`;
    try {
      execSync(`powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $n=New-Object System.Windows.Forms.NotifyIcon; $n.Icon=[System.Drawing.SystemIcons]::Information; $n.BalloonTipTitle='${title}'; $n.BalloonTipText='${msg.replace(/'/g,"''")}'; $n.Visible=$true; $n.ShowBalloonTip(5000)"`, { timeout: 3000 });
    } catch {}
  }
  process.exit(code ?? 0);
});
