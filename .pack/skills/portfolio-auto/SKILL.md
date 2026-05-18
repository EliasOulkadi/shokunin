---
name: portfolio-auto
description: Auto-sync GitHub repos to portfolio website. Scans GitHub repos, captures screenshots with Playwright, generates project entries, and updates projects-data.js or Supabase DB. Use when user asks to "update portfolio", "sync projects", "add my repos to portfolio", or "refresh portfolio projects". Do NOT use for one-time project additions — batch sync only.
license: MIT
compatibility: opencode
metadata:
  workflow: automation
  audience: developers
  version: "2.0"
---

> **Note:** `last-sync.json` state file is auto-created on first successful sync. Ignore "missing file" warnings on first run.

# Portfolio Auto-Sync

Automatically sync GitHub repositories to your portfolio website.

## Workflow

### Step 1: Gather configuration

Ask the user:
- **GitHub username**: (default from git config)
- **Portfolio type**: `static` (projects-data.js) or `supabase` (API)
- **Portfolio directory**: Path to portfolio project
- **Filters**: Exclude repos (archived, forks, specific names)

### Step 2: Fetch repos via GitHub API

```
GET /users/{username}/repos?per_page=100&sort=updated&direction=desc
```

Extract: `name`, `description`, `html_url`, `homepage`, `language`, `topics`, `updated_at`

Filter out:
- Forks (unless user opts in)
- Profile repos (`{username}/{username}`)
- Archived repos

### Step 3: Detect changes

Compare against `last-sync.json` (stored in skill directory).

- **New repos**: Not in last sync → full process
- **Updated repos**: `updated_at` changed → re-screenshot
- **Unchanged repos**: Skip

### Step 4: Capture screenshots

For repos with a `homepage` or deploy URL:

```javascript
const { chromium } = require('playwright');
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.setViewportSize({ width: 1280, height: 800 });
await page.goto(process.env.URL, { waitUntil: 'networkidle', timeout: 15000 });
await page.screenshot({ path: `/tmp/portfolio-${name}.png`, fullPage: false });
await browser.close();
```

Save to portfolio's screenshot directory.

### Step 5: Update portfolio data

#### Static (projects-data.js)

```javascript
{
  title: '{repo.name}',
  description: 'Auto-generated: {description}',
  tech: '{language},{topics}',
  github_url: '{html_url}',
  live_url: '{homepage || ""}',
  featured: false
}
```

#### Supabase

```javascript
const res = await fetch('https://your-site.com/api/projects', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer {token}' },
  body: JSON.stringify(projectData)
});
```

### Step 6: Save sync state

```json
{
  "lastSync": "2026-05-12T18:30:00Z",
  "repos": {
    "example-repo": { "updated_at": "2026-04-20T10:00:00Z", "screenshot": true }
  }
}
```

### Step 7: Report results

```
Sync complete:
+ 2 new (Cyberian, Image Enhancer)
+ 1 screenshot captured
+ 1 updated (Portfolio)
- 0 errors
```

## Notes

- Screenshots require Playwright + valid URL. Skip if no homepage.
- Never change `featured: true` on existing projects — only user can promote.
- Schedule via cron/GitHub Actions for weekly sync.
