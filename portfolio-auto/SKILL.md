---
name: portfolio-auto
description: Auto-update your portfolio website with new GitHub projects. Scans your GitHub repos, detects new/updated ones, captures live screenshots with Playwright, generates project descriptions, and updates the portfolio data file or Supabase. Triggers on "update portfolio", "sync projects", "add my repos to portfolio", "portfolio auto-update", "refresh portfolio projects". Do NOT use for one-time project additions — this is for batch sync of all repos.
license: MIT
compatibility: opencode
metadata:
  workflow: automation
  audience: developers
---

Automatically sync your GitHub repositories to your portfolio website. Detects new repos, captures previews, and updates your portfolio data.

## Workflow

### Step 1: Determine user and portfolio type

Ask the user:
- **GitHub username**: Default: EliasOulkadi
- **Portfolio type**: Options: `static` (projects-data.js) or `supabase` (via API)
- **Portfolio location**: Path to portfolio project folder
- **Filters**: Any repos to exclude, or only specific topics

### Step 2: Fetch repos from GitHub API

```bash
curl -s "https://api.github.com/users/EliasOulkadi/repos?per_page=100&sort=updated&direction=desc"
```

Extract for each repo:
- `name`, `description`, `html_url`, `homepage`, `language`, `topics`, `updated_at`

Filter out:
- Forks (unless user wants them)
- Repos named `EliasOulkadi` (profile repo)
- Repos with `archived: true`

### Step 3: Check what's new

Compare against the last sync state (stored in `$SKILL_DIR/.last-sync.json`).

Detect:
- **New repos**: Not in last sync → full process
- **Updated repos**: `updated_at` changed → re-screenshot
- **Unchanged repos**: Skip

### Step 4: Capture screenshots with Playwright

For repos with a `homepage` or deploy URL, use Playwright to capture a preview:

```javascript
const { chromium } = require('playwright');
const TARGET_URL = process.env.URL;

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto(TARGET_URL, { waitUntil: 'networkidle', timeout: 15000 });
  await page.screenshot({ path: `/tmp/portfolio-preview-${name}.png`, fullPage: false });
  await browser.close();
})();
```

Save screenshot to portfolio's screenshot directory.

### Step 5: Update portfolio data

#### For static portfolio (projects-data.js)

Generate the project entry:
```javascript
{
  title: 'Cyberian — API Quality Scanner',
  description: 'Auto-generated: {description from GitHub}',
  tech: '{language},{topics}',
  github_url: '{html_url}',
  live_url: '{homepage or empty}',
  featured: false
}
```

Replace `projects-data.js` content with the full updated list. Preserve existing projects with their `featured` status.

#### For Supabase portfolio

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
    "animeclips-online": { "updated_at": "2026-04-20T10:00:00Z", "screenshot": true },
    "portfolio": { "updated_at": "2026-05-10T15:00:00Z", "screenshot": false }
  }
}
```

### Step 7: Report results

```
Portfolio sync complete:
+ 2 new projects added (Cyberian, Image Enhancer)
+ 1 screenshot captured
+ 1 project updated (Portfolio)
- 0 errors
```

## Templates

### Project entry (for projects-data.js)
```javascript
{
  title: '{{repo.name}}',
  description: '{{repo.description || "Auto-imported from GitHub"}}',
  tech: '{{[repo.language, ...repo.topics].filter(Boolean).join(",")}}',
  github_url: '{{repo.html_url}}',
  live_url: '{{repo.homepage || ""}}',
  featured: false
}
```

## Notes

- Screenshots require Playwright and a valid URL. Skip if no homepage.
- Never change `featured: true` on existing projects — only user can promote.
- Runs silently. Show only the summary at the end.
- Schedule via cron/GitHub Actions for weekly auto-sync.
