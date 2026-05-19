---
name: db-sculptor
description: Design database schemas with Prisma/Drizzle, PostgreSQL index strategy (B-tree, GIN, GiST, BRIN, Hash), query optimization (EXPLAIN ANALYZE), migration safety (expand/contract, zero-downtime), and sharding/partitioning. Use when user asks to design schema, create migrations, optimize slow queries, add indexes, choose between SQL/NoSQL, or set up Prisma/Drizzle. Do NOT use for data warehouse dimensional modeling, ETL pipeline design, or non-relational (MongoDB, DynamoDB) schema design.
triggers:
  - "design database schema"
  - "Prisma schema"
  - "Drizzle schema"
  - "PostgreSQL index"
  - "optimize query"
  - "EXPLAIN ANALYZE"
  - "create migration"
  - "zero-downtime migration"
  - "database design"
  - "SQL schema"
  - "data model"
  - "ORM setup"
negatives:
  - "database backup"
  - "database administration"
  - "data warehouse"
  - "ETL pipeline"
  - "MongoDB"
  - "DynamoDB"
  - "non-relational"
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "4.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---


# DB Sculptor

Design performant database schemas. Model for access patterns first, normalize later. Based on PostgreSQL internals, Prisma/Drizzle best practices, and production patterns from PlanetScale, Neon, and pganalyze.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `design` | Design a schema from access patterns and data volume estimates |
| `index` | Analyze queries and recommend/create optimal indexes |
| `optimize` | Diagnose slow queries with EXPLAIN ANALYZE and fix them |
| `migrate` | Create a safe, zero-downtime migration (expand/contract) |
| `audit` | Audit existing schema against best practices and anti-patterns |

## Workflow

### Step 1: Model for access patterns

| Question | Determine |
|----------|-----------|
| Read/write ratio? | How many indexes can the table support |
| Data volume? | Current rows, growth rate/month |
| Consistency requirements? | ACID vs eventual, read replicas OK? |
| Latency budget? | p50 < 5ms, p95 < 50ms, p99 < 200ms |

**Decision tree:**
- High write volume, simple reads → Normalize (3NF). Minimum indexes.
- High read volume, complex joins → Denormalize strategically. Add composite + covering indexes.
- Time-series data → Partition by time (monthly). BRIN indexes on timestamp.
- Full-text search needed → GIN index with `tsvector` + `tsquery`.
- JSON queries → GIN index on JSONB column.

### Step 2: Primary key strategy

| PK type | Pros | Cons | When |
|---------|------|------|------|
| UUIDv7 | Time-sortable, globally unique, no collision risk | Larger than bigint (16 bytes vs 8) | Default for user-facing. Distributed systems. |
| UUIDv4 | Random, globally unique | Non-sortable = index fragmentation | Legacy. Avoid for new schemas. |
| bigint (auto-increment) | Fast, compact, sequential | Predictable, not globally unique | Internal/analytics tables. Never for user-facing. |
| ULID | Time-sortable, URL-safe | 26 chars | When human-readable time ordering matters. |

**Default: UUIDv7 for all user-facing tables.**

### Step 3: Add indexes strategically

| Index type | Use case | Example |
|-----------|----------|---------|
| B-tree (default) | Equality, range, sort, ORDER BY | `CREATE INDEX ON users (email)` |
| Composite | Multi-column WHERE, ORDER BY | `CREATE INDEX ON orders (user_id, status, created_at DESC)` |
| Partial | Filtered queries (WHERE clause) | `CREATE INDEX ON orders (created_at) WHERE status = 'active'` |
| Covering (INCLUDE) | Avoid heap fetches | `CREATE INDEX ON users (email) INCLUDE (name, avatar)` |
| GIN | FTS, arrays, JSONB, trigram | `CREATE INDEX ON articles USING GIN (to_tsvector('english', body))` |
| GiST | Geometric, range queries | `CREATE INDEX ON events USING GiST (tsrange(start_date, end_date))` |
| BRIN | Very large tables, ordered data | `CREATE INDEX ON events USING BRIN (created_at) WITH (pages_per_range = 32)` |

**Rules:**
- Max 3-4 indexes per write-heavy table
- Order composite columns by selectivity (most selective FIRST)
- Use partial indexes for common WHERE filters
- Use INCLUDE for read-heavy queries with small related columns

### Step 4: Optimize queries

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = 123 AND status = 'active';
```

| Scan type | Meaning | Fix |
|-----------|---------|-----|
| Seq Scan | Reading entire table | Add index on WHERE columns |
| Index Scan | Using index + heap lookup | Good. Consider covering index. |
| Index Only Scan | Using index only (no heap) | Best. Efficient. |
| Bitmap Heap Scan | Multiple indexes → bitmap → heap | OK. Consider composite index. |
| Nested Loop | Join: outer × inner | Add FK index, or consider hash join |
| Hash Join | Build hash table, probe | Preferred for medium-large joins |

```sql
-- Slow (~235ms): Seq Scan on 500k rows
-- Fix: composite index
CREATE INDEX CONCURRENTLY idx_orders_user_status
  ON orders (user_id, status, created_at DESC);

-- After fix: Index Only Scan, ~0.3ms
```

**Common optimization patterns:**

```sql
-- Pattern 1: Function on indexed column → expression index
-- Slow: WHERE LOWER(email) = 'user@example.com'
-- Fix:
CREATE INDEX idx_users_email_lower ON users (LOWER(email));

-- Pattern 2: Missing FK index → Nested Loop join
-- Slow: SELECT * FROM orders JOIN users ON orders.user_id = users.id WHERE users.name = 'Alice'
-- Fix:
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Pattern 3: ORDER BY + LIMIT without index → full sort
-- Slow: SELECT * FROM events ORDER BY created_at DESC LIMIT 20;
-- Fix:
CREATE INDEX idx_events_created_at ON events (created_at DESC);

-- Pattern 4: COUNT on large table without WHERE → estimated count
-- Slow: SELECT COUNT(*) FROM huge_table;
-- Fix (approximate):
SELECT reltuples::bigint FROM pg_class WHERE relname = 'huge_table';

-- Pattern 5: Pagination with OFFSET → performance degrades
-- Slow: SELECT * FROM items ORDER BY id LIMIT 20 OFFSET 100000;
-- Fix (keyset pagination):
SELECT * FROM items WHERE id > 100000 ORDER BY id LIMIT 20;

-- Pattern 6: Unused indexes bloating writes
-- Identify unused indexes:
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Pattern 7: Parallel query for large scans
-- Force parallel workers on large analytical queries:
SET max_parallel_workers_per_gather = 4;
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

### Step 5: Safe migrations (expand/contract)

**Prisma example:**
```prisma
// prisma/schema.prisma
model User {
  id        String   @id @default(uuid()) @db.Uuid
  email     String   @unique
  timezone  String?  // Phase 1: nullable
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@index([email])
  @@map("users")
}
```

**Drizzle ORM example:**
```typescript
// db/schema/users.ts
import { pgTable, text, timestamp, uuid, index } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").defaultRandom().primaryKey(),
  email: text("email").notNull().unique(),
  timezone: text("timezone"), // Phase 1: nullable
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
  emailIdx: index("idx_users_email").on(table.email),
}));

// Migration command: npx drizzle-kit generate && npx drizzle-kit migrate
```

**Expand/contract SQL:**

```sql
-- Phase 1 (expand): Add column as nullable
ALTER TABLE users ADD COLUMN timezone text;

-- Phase 2 (backfill): Fill data in separate deployment
UPDATE users SET timezone = 'UTC' WHERE timezone IS NULL;

-- Phase 3 (contract): Make NOT NULL, clean up
ALTER TABLE users ALTER COLUMN timezone SET NOT NULL;

-- Phase 4 (future): Drop old column
ALTER TABLE users DROP COLUMN old_timezone;
```

**Safety rules:**
- `CREATE INDEX CONCURRENTLY` — never blocks writes
- `lock_timeout = '5s'` on migration connections
- One logical change per migration file
- Backfill in separate migration from schema change
- Rollback written BEFORE applying forward
- Never rename + change type in same migration

### PgBouncer connection pooling

```ini
# pgbouncer.ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
default_pool_size = 25
max_client_conn = 200
max_db_connections = 25
```

**Rules:**
- Use `pool_mode = transaction` (default) for most workloads — session-level pooling breaks `SET` and `LISTEN/NOTIFY`
- Use `pool_mode = session` only when you need prepared statements, `SET` session variables, or listen/notify
- Set `max_db_connections` to 25-50% of PostgreSQL `max_connections` — PgBouncer multiplexes client connections
- Set `default_pool_size` based on CPU cores: 4× cores for mixed workloads, 1× for CPU-bound
- Never use `pool_mode = statement` — breaks multi-statement transactions

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Migration lock timeout | Long-running query on same table | Set `lock_timeout = '5s'`. Run in low-traffic window. |
| Query slow in prod, fast in dev | Different data volume and distribution | Test with prod-size data (~1M+ rows) in staging |
| CREATE INDEX blocks writes | Non-concurrent CREATE | Always use `CREATE INDEX CONCURRENTLY` |
| N+1 queries | ORM lazy loading | Use eager loading (`include`/`JOIN`), DataLoader, or batch queries |
| Sequence gap on PK | ROLLBACK increments sequence | Accept gaps. Switch to UUIDv7 for new tables. |
| Deadlock | Conflicting lock order across transactions | Ensure consistent lock ordering. Keep transactions short. |

## Production Checklist

- [ ] Primary key: UUIDv7 or bigint. Never expose sequential PKs in URLs.
- [ ] `created_at` + `updated_at` on every table. `updated_at` auto-set via trigger.
- [ ] Indexes match WHERE + ORDER BY + JOIN columns. Verified with EXPLAIN ANALYZE.
- [ ] Composite indexes ordered by selectivity (most selective first)
- [ ] Partial indexes for common filtered queries
- [ ] Covering indexes (INCLUDE) for read-heavy lookups
- [ ] `lock_timeout = '5s'` on migration connections
- [ ] Migrations tested on staging with production-like data volume
- [ ] Connection pooling configured (PgBouncer for PostgreSQL)
- [ ] `TEXT` over `VARCHAR(n)` — no arbitrary length limits
- [ ] TIMESTAMPTZ over TIMESTAMP — always store with timezone
- [ ] FKs indexed — mandatory for join performance
- [ ] Soft deletes via `deleted_at TIMESTAMPTZ` (nullable)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| No primary key | Every table needs one (UUIDv7 preferred) |
| Index on every column | Max 3-4 per write-heavy table. Check usage with `pg_stat_user_indexes`. |
| `SELECT *` in application code | Name explicit columns. Avoids breaking changes + unnecessary data transfer. |
| Functions on indexed columns (`WHERE LOWER(email) = ...`) | Use expression index: `CREATE INDEX ON users (LOWER(email))` |
| `VARCHAR(255)` on all strings | `TEXT` unless max length is a business rule |
| Migrations without testing | Test against prod copy (anonymized). Never just run on dev. |
| ENUM type for evolving values | `TEXT` with CHECK constraint or reference table |
| Missing FK indexes | Every FK column needs an index for join performance |
| Sorting by unindexed column on large tables | Add composite index with sort column last |
| `COUNT(*)` on large tables without WHERE | Use estimates: `SELECT reltuples FROM pg_class WHERE relname = 'table'` |

## Sources

- PostgreSQL docs (postgresql.org/docs)
- Use the Index, Luke! (use-the-index-luke.com)
- pganalyze EXPLAIN analyzer
- Prisma migration docs
- Drizzle ORM docs
- PlanetScale schema migration patterns
- Stormatics — composite and partial indexes
- Neon serverless PostgreSQL patterns

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
