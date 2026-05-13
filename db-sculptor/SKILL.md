---
name: db-sculptor
description: Design database schemas with Prisma/Drizzle, PostgreSQL index strategy (B-tree, GIN, GiST, BRIN, Hash), query optimization (EXPLAIN ANALYZE), migration safety (expand/contract, zero-downtime), and sharding/partitioning. Use when user asks to design schema, create migrations, optimize slow queries, add indexes, choose between SQL/NoSQL, or set up Prisma/Drizzle. Do NOT use for data warehouse dimensional modeling, ETL pipeline design, or non-relational (MongoDB, DynamoDB) schema design.
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---

# DB Sculptor

Design performant database schemas. Model for access patterns first, normalize later. Based on PostgreSQL internals, Prisma/Drizzle best practices, and production patterns from PlanetScale and Neon.

## Workflow

### Step 1: Model for access patterns

| Question | What to determine |
|----------|-------------------|
| What queries will this support? | Read/write ratio, join patterns, filters |
| Data volume? | Current rows, growth rate/month |
| Consistency requirements? | ACID vs eventual, read replicas OK? |
| Latency budget? | p50/p95/p99 targets |

**Decision tree:**
- High write volume, simple reads → Normalize more (3NF), fewer indexes
- High read volume, complex queries → Denormalize, add composite indexes
- Time-series data → Partition by time (BRIN indexes)
- Full-text search needed → GIN index with `tsvector`

### Step 2: Generate schema

Use the scaffold script:
```bash
scripts/generate-schema.sh --type user  # Generates a user model with all fields, indexes, relations
scripts/generate-schema.sh --type product --provider drizzle
scripts/generate-schema.sh --type order --include-relations
```

See [assets/prisma-schema.template.prisma](assets/prisma-schema.template.prisma) for the complete production schema template with 24 models, enums, composite keys, GIN indexes, and soft delete patterns.

### Step 3: Add indexes strategically

See [references/index-strategies.md](references/index-strategies.md) for the complete reference. Quick reference:

| Index type | Use case | Example |
|-----------|----------|---------|
| B-tree (default) | Equality, range, sort | `CREATE INDEX ON users (email)` |
| Composite | Multi-column filters | `CREATE INDEX ON orders (status, created_at DESC)` |
| Partial | Filtered queries | `CREATE INDEX ON orders (created_at) WHERE status = 'active'` |
| Covering (INCLUDE) | Avoid heap fetches | `CREATE INDEX ON users (email) INCLUDE (name)` |
| GIN | FTS, arrays, JSONB | `CREATE INDEX ON articles USING GIN (search_vector)` |
| BRIN | Large ordered data | `CREATE INDEX ON events USING BRIN (created_at)` |

**Rules:**
- Max 3 indexes per table for write-heavy
- Order composite by selectivity (most selective first)
- Use partial indexes for common WHERE filters
- Use `INCLUDE` for read-heavy queries with small columns

### Step 4: Optimize queries

See [references/query-optimization.md](references/query-optimization.md) for the complete guide.

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = 123 AND status = 'active';
```

**Diagnosis:**
- `Seq Scan` on large table → missing index → add composite index
- `Nested Loop` on large join → missing FK index → add index on FK
- `Sort` on unindexed column → add index with DESC/ASC
- `Bitmap Heap Scan` → consider covering index

```sql
-- Slow (~235ms): Seq Scan on 50k rows
-- Fix:
CREATE INDEX CONCURRENTLY idx_orders_user_status ON orders (user_id, status);
```

### Step 5: Plan safe migrations

See [references/migration-patterns.md](references/migration-patterns.md) for zero-downtime patterns.

**Expand/Contract pattern for risky changes:**
```sql
-- Phase 1 (expand): Add column as nullable
ALTER TABLE users ADD COLUMN timezone text;

-- Phase 2 (backfill): Fill data (separate deployment)
UPDATE users SET timezone = 'UTC' WHERE timezone IS NULL;

-- Phase 3 (contract): Make NOT NULL
ALTER TABLE users ALTER COLUMN timezone SET NOT NULL;
DROP COLUMN IF EXISTS old_timezone;
```

**Safety rules:**
- `CREATE INDEX CONCURRENTLY` (never blocking)
- `lock_timeout = '5s'` on migration connections
- One logical change per migration
- Backfill in separate migration from schema change
- Rollback migration written before applying forward

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Migration lock timeout | Long-running query on same table | Set `lock_timeout`, run during low traffic |
| Query slow in prod, fast in dev | Different data distribution | Anonymize prod data, test with real volume |
| `CREATE INDEX` blocks writes | Non-concurrent CREATE | Use `CREATE INDEX CONCURRENTLY` |
| N+1 queries in production | ORM lazy loading | Use `include`, `JOIN`, or DataLoader |
| Sequence gap on PK | ROLLBACK increments sequence | Accept gaps. Use UUIDv7 instead. |

## Production Checklist

- [ ] Primary key strategy: UUIDv7 (preferred) or bigint
- [ ] `created_at` + `updated_at` on every table
- [ ] Indexes match query patterns (verified with EXPLAIN ANALYZE)
- [ ] Partial indexes for filtered queries
- [ ] Composite indexes ordered by selectivity
- [ ] Lock timeout set on migration connections
- [ ] Migrations tested in staging with production-like data
- [ ] Connection pooling configured

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| No primary key | Every table needs one (UUIDv7) |
| Index on every column | Max 3 per write-heavy table |
| `SELECT *` in app code | Name explicit columns |
| Functions on indexed columns | Use expression index |
| Varchar(255) on all strings | TEXT or actual max length |
| Migrations without testing | Test against prod copy (anonymized) |
| ENUM that may need new values | VARCHAR with CHECK or reference table |

## Sources

- PostgreSQL docs (postgresql.org/docs)
- Use the Index, Luke!
- pganalyze EXPLAIN analyzer
- Prisma migration docs
- Drizzle ORM docs
- PlanetScale schema migration patterns
- Stormatics — composite and partial indexes
