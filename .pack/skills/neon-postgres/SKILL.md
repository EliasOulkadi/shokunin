---
name: neon-postgres
description: Guides and best practices for working with Neon Serverless Postgres. Covers getting started, local development with Neon, choosing a connection method, Neon features, authentication (@neondatabase/auth), PostgREST-style data API (@neondatabase/neon-js), Neon CLI, and Neon's Platform API/SDKs. Use for any Neon-related questions.
triggers:
  - "Neon"
  - "Neon Postgres"
  - "serverless Postgres"
  - "connection pooling"
  - "neonctl"
  - "@neondatabase"
  - "Neon MCP"
  - "Postgres branching"
negatives:
  - "self-hosted Postgres"
  - "RDS"
  - "Aurora"
  - "Supabase"
  - "PlanetScale"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: backend
  audience: developers
---


# Neon Serverless Postgres

Neon is a serverless Postgres platform that separates compute and storage to offer autoscaling, branching, instant restore, and scale-to-zero. It's fully compatible with Postgres and works with any language, framework, or ORM that supports Postgres.

## Neon Documentation

The Neon documentation is the source of truth for all Neon-related information. Always verify claims against the official docs before responding. Neon features and APIs evolve, so prefer fetching current docs over relying on training data.

### Fetching Docs as Markdown

Any Neon doc page can be fetched as markdown in two ways:

1. **Append `.md` to the URL** (simplest): https://neon.com/docs/introduction/branching.md
2. **Request `text/markdown`** on the standard URL: `curl -H "Accept: text/markdown" https://neon.com/docs/introduction/branching`

Both return the same markdown content. Use whichever method your tools support.

### Finding the Right Page

The docs index lists every available page with its URL and a short description:

```
https://neon.com/docs/llms.txt
```

Common doc URLs are organized in the topic links below. If you need a page not listed here, search the docs index: https://neon.com/docs/llms.txt — don't guess URLs.

## What Is Neon

Use this for architecture explanations and terminology (organizations, projects, branches, endpoints) before giving implementation advice.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/what-is-neon.md

## Getting Started

Use this for first-time setup: org/project selection, connection strings, driver installation, optional auth, and initial schema setup.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/getting-started.md

## Connection Methods & Drivers

Use this when you need to pick the correct transport and driver based on runtime constraints (TCP, HTTP, WebSocket, edge, serverless, long-running).

Link: https://neon.com/docs/ai/skills/neon-postgres/references/connection-methods.md

### Serverless Driver

Use this for `@neondatabase/serverless` patterns, including HTTP queries, WebSocket transactions, and runtime-specific optimizations.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-serverless.md

### Neon JS SDK

Use this for combined Neon Auth + Data API workflows with PostgREST-style querying and typed client setup.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-js.md

## Developer Tools

Use this for local development enablement with `npx neonctl@latest init`, VSCode extension setup, and Neon MCP server configuration.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/devtools.md

### Neon CLI

Use this for terminal-first workflows, scripts, and CI/CD automation with `neonctl`.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-cli.md

## Neon Admin API

The Neon Admin API can be used to manage Neon resources programmatically. It is used behind the scenes by the Neon CLI and MCP server, but can also be used directly for more complex automation workflows or when embedding Neon in other applications.

### Neon REST API

Use this for direct HTTP automation, endpoint-level control, API key auth, rate-limit handling, and operation polling.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-rest-api.md

### Neon TypeScript SDK

Use this when implementing typed programmatic control of Neon resources in TypeScript via `@neondatabase/api-client`.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-typescript-sdk.md

### Neon Python SDK

Use this when implementing programmatic Neon management in Python with the `neon-api` package.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-python-sdk.md

## Neon Auth

Use this for managed user authentication setup, UI components, auth methods, and Neon Auth integration pitfalls in Next.js and React apps.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/neon-auth.md

Neon Auth is also embedded in the Neon JS SDK - so depending on your use case, you may want to use the Neon JS SDK instead of Neon Auth. See https://neon.com/docs/ai/skills/neon-postgres/references/connection-methods.md for more details.

## Branching

Use this when the user is planning isolated environments, schema migration testing, preview deployments, or branch lifecycle automation.

Key points:

- Branches are instant, copy-on-write clones (no full data copy).
- Each branch has its own compute endpoint.
- Use the neonctl CLI or MCP server to create, inspect, and compare branches.

Link: https://neon.com/docs/ai/skills/neon-postgres/references/branching.md

## Autoscaling

Use this when the user needs compute to scale automatically with workload and wants guidance on CU sizing and runtime behavior.

Link: https://neon.com/docs/introduction/autoscaling.md

## Scale to Zero

Use this when optimizing idle costs and discussing suspend/resume behavior, including cold-start trade-offs.

Key points:

- Idle computes suspend automatically (default 5 minutes, configurable) (unless disabled - launch & scale plan only)
- First query after suspend typically has a cold-start penalty (around hundreds of ms)
- Storage remains active while compute is suspended.

Link: https://neon.com/docs/introduction/scale-to-zero.md

## Instant Restore

Use this when the user needs point-in-time recovery or wants to restore data state without traditional backup restore workflows.

Key points:

- Restore windows depend on plan limits.
- Users can create branches from historical points-in-time.
- Time Travel queries can be used for historical inspection workflows.

Link: https://neon.com/docs/introduction/branch-restore.md

## Read Replicas

Use this for read-heavy workloads where the user needs dedicated read-only compute without duplicating storage.

Key points:

- Replicas are read-only compute endpoints sharing the same storage.
- Creation is fast and scaling is independent from primary compute.
- Typical use cases: analytics, reporting, and read-heavy APIs.

Link: https://neon.com/docs/introduction/read-replicas.md

## Connection Pooling

Use this when the user is in serverless or high-concurrency environments and needs safe, scalable Postgres connection management.

Key points:

- Neon pooling uses PgBouncer.
- Add `-pooler` to endpoint hostnames to use pooled connections.
- Pooling is especially important in serverless runtimes with bursty concurrency.

Link: https://neon.com/docs/connect/connection-pooling.md

## IP Allow Lists

Use this when the user needs to restrict database access by trusted networks, IPs, or CIDR ranges.

Link: https://neon.com/docs/introduction/ip-allow.md

## Logical Replication

Use this when integrating CDC pipelines, external Postgres sync, or replication-based data movement.

Key points:

- Neon supports native logical replication workflows.
- Useful for replicating to/from external Postgres systems.

Link: https://neon.com/docs/guides/logical-replication-guide.md

---

## Workflow

1. **Identify the use case** — serverless function, long-running server, edge runtime, or CI/CD automation. Determines connection method and driver.
2. **Select connection method** — TCP for servers (pooled with `-pooler` in hostname), HTTP for serverless/edge (@neondatabase/serverless), WebSocket for transactions.
3. **Set up the project** — run `npx neonctl@latest init` for guided setup. Or create a project via Neon Console and copy the connection string.
4. **Install the correct driver** — `@neondatabase/serverless` for serverless/edge. Standard `pg` for Node.js servers with TCP. `@neondatabase/neon-js` for auth + data workflows.
5. **Configure pooling** — add `-pooler` to endpoint hostname in serverless environments. PgBouncer under the hood.
6. **Implement branching if needed** — create preview branches per PR for isolated testing. Use copy-on-write for instant clones.
7. **Set up scale-to-zero awareness** — account for cold-start penalty (~hundreds of ms) on first query after idle. Configure suspend timeout if needed.

## Error Handling

| Cause | Fix |
|-------|-----|
| Cold-start timeout on first query after idle | Account for ~hundreds of ms latency. Warm up with a lightweight query on startup. Disable scale-to-zero on launch & scale plan. |
| "Too many connections" in serverless environment | Add `-pooler` to endpoint hostname for PgBouncer connection pooling. |
| `@neondatabase/serverless` HTTP query fails with large payload | Switch to WebSocket transactions for queries with large data. |
| Branch creation fails with "quota exceeded" | Check plan limits. Free plan: 1 branch per project. Delete unused branches first. |
| Connection string not working from Vercel/Netlify | Verify the connection string includes `sslmode=require`. Use pooled connection string for serverless. |
| Migration fails on preview branch but works on main | Branch may have diverged. Reset branch from parent or use `neonctl branches create --parent main`. |
| `neonctl` CLI returns authentication error | Run `neonctl auth` to re-authenticate. Verify API key is valid and not expired. |
| Restore point-in-time outside retention window | Check plan limits. Free: 7 days. Scale: 30 days. Business: 90 days. Use closest available point. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Using standard TCP driver in serverless functions | Connection overhead per invocation. Exhausts available connections rapidly. | Use `@neondatabase/serverless` with HTTP queries or WebSocket. |
| Not using pooling in high-concurrency environments | Each request opens a new Postgres connection. Hits connection limits fast. | Add `-pooler` to hostname. PgBouncer handles connection multiplexing. |
| Long-running transactions on the serverless driver | HTTP queries have timeouts. Long transactions exceed function execution limits. | Split into smaller transactions. Use WebSocket mode for longer operations. |
| Hardcoding connection strings in source code | Credential exposure in version control | Use environment variables. Neon Console provides `.env` ready connection strings. |
| Creating a full database clone for testing instead of branching | Slow, expensive storage duplication. Wastes credits. | Use Neon branching (copy-on-write) for instant, zero-cost test databases. |
| Ignoring IP allow lists in production | Database exposed to the internet if not configured | Set up IP allow lists to restrict access to known IPs/CIDRs only. |
| Using the same branch for development and production | Schema changes in dev affect production data | Create a dev branch from main. Merge changes only after testing. |
| Disabling scale-to-zero on hobby projects unnecessarily | Pays for idle compute time | Keep default scale-to-zero unless continuous availability is required. |

## Checklist

- [ ] Connection method chosen correctly (pooled HTTP vs direct TCP for use case)
- [ ] Connection string loaded from env var, not hardcoded
- [ ] Pool configured with appropriate min/max connections
- [ ] Prepared statements used for all user-facing queries
- [ ] Branching strategy defined (dev branch per PR, main for production)

## Sources

- Neon Documentation — neon.com/docs
- Neon Blog — "How Neon Works: Compute-Storage Separation" (neon.com/blog)
- PgBouncer Documentation — pgbouncer.github.io
- Postgres Documentation — "Connection Pooling" (postgresql.org/docs)
- Vercel + Neon Integration Guide — vercel.com/docs/storage/vercel-postgres
- Neon YouTube — "Getting Started with Neon" tutorials (youtube.com/@neondatabase)
- Hacker News discussions on serverless Postgres architectures
