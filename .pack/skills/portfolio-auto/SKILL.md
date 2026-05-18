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

## Error Handling

| Cause | Fix |
|-------|-----|
| GitHub API returns 401 Unauthorized | No token or expired token. Set `GITHUB_TOKEN` environment variable. Generate a new Personal Access Token at github.com/settings/tokens with `public_repo` scope. |
| GitHub API rate limit exceeded (403) | Unauthenticated requests are limited to 60/hour. Authenticated: 5000/hour. Add token. If already authenticated, wait for reset (check `X-RateLimit-Reset` header). |
| Repository has no `homepage` field and no deploy URL | Cannot capture a screenshot. Mark the repo as "no live preview" in the output. Use the GitHub URL as fallback link. |
| Playwright browser fails to launch | Chromium not installed. Run `npx playwright install chromium`. On headless server, add `--no-sandbox` flag: `chromium.launch({ headless: true, args: ['--no-sandbox'] })`. |
| Screenshot URL returns 404 or times out after 15s | Deploy URL is stale or site is down. Skip screenshot for this repo. Log the URL and error to a `failed-screenshots.json` file for manual review. |
| `projects-data.js` has custom formatting that auto-generation would break | A regex-based insert could corrupt handwritten code. Read the file first to detect non-standard structure. If detected, append a comment block with the new entries and ask user to merge manually. |
| Supabase API insert fails with foreign key or schema constraint | Portfolio schema might differ from the auto-generated payload shape. Read the Supabase table schema first. Map fields explicitly (not spread operator). Validate with a dry-run POST that returns 200 before committing. |
| `last-sync.json` is corrupted or manually edited | Parse as JSON in a try-catch. On failure, rename to `last-sync.json.bak` and start fresh sync from scratch. Warn user that incremental detection is lost. |

## Sources

- GitHub REST API v3 documentation (docs.github.com/en/rest/repos/repos) — repository listing, filtering, and pagination
- Playwright documentation (playwright.dev/docs/api/class-playwright) — headless browser launch, screenshot, and viewport configuration
- Supabase JavaScript client documentation (supabase.com/docs/reference/javascript) — API insert, upsert, and auth patterns
- Node.js `fs` module documentation (nodejs.org/api/fs.html) — file read/write with atomic rename for sync state safety
- Personal Access Token best practices (docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) — scopes, expiration, and secure storage
- GitHub Actions cron scheduling (docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#schedule) — weekly sync automation pattern
- "Automate the Boring Stuff with Python" by Al Sweigart (No Starch Press, 2nd Edition, 2019) — automation reliability patterns applicable to JavaScript automation tasks

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Syncing without checking for existing customizations | Auto-generated entries may overwrite handcrafted project descriptions, featured flags, or custom ordering set by the user. | Read the target file first. Detect non-standard structure. For `featured: true` entries, preserve all fields. Only upsert new or changed repos. |
| Capturing screenshots for every repo indiscriminately | Repos without live demos waste Playwright launch time (~3s each). Repos with broken URLs produce useless error screenshots. | Pre-filter: only screenshot repos where `homepage` field is non-empty and returns 200 on a HEAD request. |
| Running sync on a metered or slow connection | Cloning or screenshotting dozens of repos can consume significant bandwidth and time. | Run in batches of 10. Add a `--dry-run` flag that lists what would change without executing. |
| Using the Supabase anon key instead of service_role key for writes | Anon key has row-level security restrictions that block upserts. | Use service_role key with caution. Store in environment variable, never in code. Add table-level RLS policies for the sync function. |
| Not cleaning up Playwright browser processes after sync | Each `chromium.launch()` spawns a process. Orphaned processes accumulate memory and can exhaust system resources. | Always call `browser.close()` in a `finally` block. Track launched browsers in an array and force-close on SIGINT/SIGTERM. |
| Hardcoding the portfolio data path instead of reading from config | Paths change between projects. A hardcoded path breaks on first use on a different machine. | Ask for portfolio directory in Step 1. Derive `projects-data.js` path from that base. Store in sync state for reuse. |
