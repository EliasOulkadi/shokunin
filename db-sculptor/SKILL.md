---
name: db-sculptor
description: Design database schemas with Prisma/Drizzle, indexing strategy, migration safety, query optimization (EXPLAIN ANALYZE), and performance patterns. Use when user asks to design a database schema, create tables, write migrations, optimize queries, add indexes, or choose between SQL and NoSQL. Do NOT use for data warehouse schema design, dimensional modeling, or ETL pipeline design.
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "2.0"
---

# DB Sculptor

Design database schemas that perform at any scale. Based on PostgreSQL internals, production patterns from PlanetScale, Neon, and the Prisma ecosystem.

## Workflow

### Step 1: Model for access patterns

The rule: model for your queries first. Normalize later. A beautiful 3NF schema is useless if your queries are slow.

| Question | What to determine |
|----------|-------------------|
| What queries will this support? | Read/write ratio, join patterns, filters |
| What's the data volume? | Rows, growth rate per month |
| What consistency is needed? | ACID vs eventual, read replicas ok? |
| What's the latency budget? | p50/p95/p99 targets |

### Step 2: Schema design

- Primary key: UUIDv7 (sorts chronologically, unlike UUIDv4) or `bigint` for auto-increment
- Timestamps on every table: `created_at`, `updated_at` (let the DB set them)
- Soft deletes with `deleted_at` or separate archive table
- Max 3 indexes per table for write-heavy workloads
- Consider partitioning for tables over 10M rows

### Step 3: Naming conventions

| Element | Convention | Example |
|---------|------------|---------|
| Tables | plural snake_case | `users`, `order_items` |
| Columns | singular snake_case | `first_name` |
| Foreign keys | `{singular_table}_id` | `user_id` |
| Indexes | `idx_{table}_{column}` | `idx_users_email` |
| Unique constraints | `uq_{table}_{column}` | `uq_users_email` |
| Primary keys | `pk_{table}` | `pk_users` |
| Check constraints | `ck_{table}_{column}` | `ck_users_age` |

### Step 4: Index strategy

#### B-tree (default)
Use for: equality, range, sort, join columns.

#### Composite
Order columns by selectivity (most selective first):
```sql
-- Good: status filters to 3 values, created_at is high cardinality
CREATE INDEX idx_orders_status_date ON orders (status, created_at DESC);

-- Bad: selectivity backwards
CREATE INDEX idx_orders_date_status ON orders (created_at, status); -- if status is the main filter
```

#### Partial
Only index rows you query often. Smaller index, faster writes:
```sql
CREATE INDEX idx_orders_active ON orders (created_at) WHERE status = 'active';
```

#### Covering (INCLUDE)
Avoid heap fetches. Use for read-heavy queries with small columns:
```sql
CREATE INDEX idx_users_email ON users (email) INCLUDE (name, avatar_url);
```

#### Specialized indexes

| Index type | Use case | When |
|-----------|----------|------|
| GIN | Full-text search, arrays, JSONB | `tsvector` columns, `jsonb_path_ops` |
| GiST | Geospatial, range types, fuzzy search | `earthdistance`, `tsrange`, `ltree` |
| BRIN | Large tables with naturally ordered data | Time-series with `ORDER BY` on timestamp |
| Hash | Equality on large values | Rarely useful. B-tree is usually better. |

### Step 5: Query optimization workflow

```
1. Identify slow query (pg_stat_statements, RDS Performance Insights)
2. Run EXPLAIN (BUFFERS, ANALYZE)
3. Identify seq scans on large tables → missing index
4. Identify nested loops on large tables → composite index
5. Apply index
6. Verify with EXPLAIN (BUFFERS, ANALYZE)
7. Test with production-like data volume
```

#### EXPLAIN examples

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = 123 AND status = 'active';

-- Sequential scan (bad):
-- Seq Scan on orders (cost=0.00..4350.00 rows=1 width=100) (actual time=45.2..235.1 rows=1)
--   Filter: ((user_id = 123) AND (status = 'active'::text))
--   Buffers: shared hit=5000

-- Index scan (good):
-- Index Scan using idx_orders_user_status on orders (cost=0.28..8.29 rows=1 width=100)
--   Index Cond: ((user_id = 123) AND (status = 'active'::text))
--   Buffers: shared hit=4
-- Planning Time: 0.12 ms
-- Execution Time: 0.35 ms
```

### Step 6: Migration safety

- One migration per logical change (never combine unrelated changes)
- Never edit committed migrations — create a new one
- Backfill data in a separate migration from schema change
- Add columns as nullable first, backfill, then make NOT NULL
- Run migrations in transactions for multi-table changes (where possible)
- Lock timeout: set `lock_timeout = '5s'` to prevent blocking production

#### Zero-downtime migration pattern

```sql
-- Phase 1: Add column as nullable
ALTER TABLE users ADD COLUMN timezone text;

-- Phase 2 (separate deployment): Backfill
UPDATE users SET timezone = 'UTC' WHERE timezone IS NULL;

-- Phase 3: Make NOT NULL (only if no production code depends on it)
ALTER TABLE users ALTER COLUMN timezone SET NOT NULL;
```

### Step 7: Seed data

- Factories with realistic data (Faker, not "John Doe"/"test@test.com")
- At least 100 records minimum, 1000+ for performance-sensitive queries
- Idempotent seeds (can run multiple times without duplicates)
- Include edge cases: nulls, empty strings, maximum lengths

## Query Anti-Patterns

| Anti-pattern | Symptom | Fix |
|-------------|---------|-----|
| N+1 queries | Loop triggers separate query per row | JOIN, batch loading (DataLoader), or includes |
| `SELECT *` in production | Reads unused columns, prevents index-only scans | Name columns explicitly |
| `UPDATE`/`DELETE` without `WHERE` in transaction | Accidental mass change | Always verify WHERE in transaction, then commit |
| Large `IN` clauses > 1000 | Slow planning time | Temp table or batch processing (100 at a time) |
| No `LIMIT` | Reads entire table memory | Always paginate or limit |
| Functions on indexed columns | `WHERE LOWER(email) = 'x'` defeats index | Use expression index: `CREATE INDEX ON users (LOWER(email))` |

## Full-Text Search (PostgreSQL)

```sql
-- Add tsvector column
ALTER TABLE articles ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', title), 'A') ||
    setweight(to_tsvector('english', body), 'B')
  ) STORED;

-- Index it
CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);

-- Query
SELECT title FROM articles
WHERE search_vector @@ plainto_tsquery('english', 'search terms')
ORDER BY ts_rank(search_vector, plainto_tsquery('search terms')) DESC
LIMIT 20;
```

## Connection Pooling

| Tool | Use case | Config |
|------|----------|--------|
| PgBouncer (transaction mode) | High-connection count, serverless | Pool size = CPU cores × 2 + disk spindles |
| Internal pool (Prisma, Drizzle) | Standard server deployments | Pool size = 10-20 per instance |
| Direct connection | Admin, migrations | Single connection, no pool |

## Production Checklist

- [ ] Primary key strategy chosen (UUIDv7 or bigint)
- [ ] `created_at` + `updated_at` on every table
- [ ] Indexes match query patterns (not guessed)
- [ ] Partial indexes for filtered queries
- [ ] Composite indexes ordered by selectivity
- [ ] `EXPLAIN ANALYZE` run on all critical queries
- [ ] Migration tested in staging with production-like data
- [ ] Lock timeout set (5s) on migration connections
- [ ] Seeds are idempotent and realistic
- [ ] Connection pooling configured

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| No primary key | Every table needs one. Prefer UUIDv7. |
| Indexes on every column | Max 3 per table for write-heavy, index only what you query |
| Migrations without testing | Test against a copy of production (anonymized) |
| JOINs on unindexed foreign keys | Index every FK column |
| `SELECT *` in application code | Name specific columns |
| Varchar(255) on every string | Use TEXT or VARCHAR with actual max length |
| Enum with values that never change | Use VARCHAR or reference table (enums can't be altered without migration) |

## Sources

- PostgreSQL Documentation (postgresql.org/docs)
- Use the Index, Luke! — Indexing guide
- pganalyze — EXPLAIN analyzer
- Prisma Documentation — Migration workflows
- Drizzle ORM Documentation
- Stormatics — Composite and Partial Indexes
- PlanetScale — Schema migration best practices
