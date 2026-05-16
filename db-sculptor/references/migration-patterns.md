# Migration Patterns

Safe, zero-downtime migration strategies for PostgreSQL.

---

## 1. Expand/Contract (aka Dual-Write Pattern)

The canonical safe migration pattern. Three phases: **expand** (add new schema), **migrate** (run dual-writes), **contract** (remove old schema).

### Example: Renaming a column

**Goal**: Rename `orders.status` to `orders.payment_status`.

### Phase 1: Expand

```sql
-- Deploy 1: Add new column (nullable, no constraints yet)
BEGIN;
ALTER TABLE orders
  ADD COLUMN payment_status text;

ALTER TABLE orders
  ADD COLUMN payment_status_old text GENERATED ALWAYS AS (COALESCE(payment_status, status)) STORED;
-- Keep app writing to both columns during transition
COMMIT;
```

Application code changes:
```go
// Old write
order.Status = "paid"

// Dual write
order.Status = "paid"
order.PaymentStatus = "paid"

// Old read - still using status
fmt.Println(order.Status)
```

### Phase 2: Migrate (backfill + dual-write)

```sql
-- Backfill existing rows in batches
DO $$
DECLARE
  batch_size CONSTANT int := 1000;
  updated int;
BEGIN
  LOOP
    UPDATE orders
    SET payment_status = status
    WHERE payment_status IS NULL
      AND status IS NOT NULL
    LIMIT batch_size;

    GET DIAGNOSTICS updated = ROW_COUNT;
    EXIT WHEN updated = 0;

    COMMIT; -- commit each batch to avoid long-running tx
    pg_sleep(0.1); -- throttle
  END LOOP;
END $$;

-- Add NOT NULL after backfill complete
ALTER TABLE orders ALTER COLUMN payment_status SET NOT NULL;
```

Application code now reads from both:
```go
// Both columns are populated at this point
order.Status = input.PaymentStatus
order.PaymentStatus = input.PaymentStatus

// Reads prefer new column
fmt.Println(order.PaymentStatus)
```

### Phase 3: Contract

```sql
-- Deploy 2: Remove old column
BEGIN;
ALTER TABLE orders DROP COLUMN status;
ALTER TABLE orders DROP COLUMN payment_status_old;
COMMIT;
```

Application code removes old references:
```go
order.PaymentStatus = input.PaymentStatus
fmt.Println(order.PaymentStatus)
```

### Timeline diagram

```
Phase 1 (Expand):
  App: writes to A + B, reads A
  DB: old+new columns exist, new nullable

Phase 2 (Migrate):
  App: writes to A + B, reads B (tested)
  DB: backfill runs, NOT NULL added
  
Phase 3 (Contract):
  App: writes B, reads B
  DB: old column dropped
```

---

## 2. Zero-Downtime Migrations

### Principle

Every schema change must be backward-compatible: old app code must still work during deployment.

### Safe operations (can run without locking or breaking old code)

| Operation | Safe? | Notes |
|-----------|-------|-------|
| `ADD COLUMN ... DEFAULT NULL` | ✅ Safe | Existing rows see NULL immediately |
| `ADD COLUMN ... DEFAULT <constant>` | ✅ Safe (PG 11+) | PG 11+ doesn't rewrite table for non-volatile defaults |
| `ADD INDEX CONCURRENTLY` | ✅ Safe | No exclusive lock, but 2x slower |
| `DROP INDEX CONCURRENTLY` | ✅ Safe | No exclusive lock |
| `ADD CONSTRAINT ... NOT VALID` | ✅ Safe | No table scan during add |
| `VALIDATE CONSTRAINT` | ✅ Safe | Reads only, shared lock |
| `ALTER COLUMN ... TYPE` using trick | ⚠️ Needs steps | See below |
| `DROP COLUMN` | 🔴 Unsafe alone | Mark as unused first, drop later |
| `ADD COLUMN ... DEFAULT <volatile>` | 🔴 Unsafe | `DEFAULT gen_random_uuid()` rewrites table |
| `ALTER COLUMN ... SET NOT NULL` | 🔴 Unsafe | Requires table scan + AccessExclusiveLock |
| `ADD PRIMARY KEY` | 🔴 Unsafe | AccessExclusiveLock; use `CREATE UNIQUE INDEX CONCURRENTLY` first |
| `RENAME COLUMN` | 🔴 Unsafe | Breaks old app code immediately |
| `ALTER COLUMN ... SET TYPE` | 🔴 Unsafe | AccessExclusiveLock, table rewrite |

### Adding a column with a default value (safe)

```sql
-- PG 11+: table is NOT rewritten for immutable defaults
ALTER TABLE orders
  ADD COLUMN currency text NOT NULL DEFAULT 'USD';
```

To verify no rewrite:
```sql
-- Check if table was rewritten
SELECT pg_size_pretty(pg_relation_size('orders'));
-- Before/after should be identical for PG 11+
```

### Adding a column with a volatile default (must be safe)

```sql
-- 🔴 Bad: rewrites the entire table
ALTER TABLE orders ADD COLUMN slug text DEFAULT gen_random_uuid() NOT NULL;

-- ✅ Good: add nullable, backfill, then set default + NOT NULL
ALTER TABLE orders ADD COLUMN slug text;

-- Backfill in batches
UPDATE orders SET slug = gen_random_uuid() WHERE slug IS NULL LIMIT 1000;
-- ... repeat ...

ALTER TABLE orders ALTER COLUMN slug SET DEFAULT gen_random_uuid();
ALTER TABLE orders ALTER COLUMN slug SET NOT NULL;
```

### Adding a foreign key (safe)

```sql
-- Step 1: Add constraint as NOT VALID (no table scan)
ALTER TABLE order_items
  ADD CONSTRAINT fk_order_items_product
  FOREIGN KEY (product_id) REFERENCES products(id)
  NOT VALID;

-- Step 2: Validate in a separate transaction
ALTER TABLE order_items
  VALIDATE CONSTRAINT fk_order_items_product;
```

Why: `ADD CONSTRAINT` without `NOT VALID` takes `AccessExclusiveLock` and scans the table. With `NOT VALID`, it only adds the constraint metadata — no scan. Validation later only needs `ShareLock`.

### Adding a NOT NULL column without downtime

```sql
-- ❌ Don't do this:
ALTER TABLE users ADD COLUMN phone text NOT NULL;
-- Fails if any row exists: "column contains null values"

-- ✅ Do this:
ALTER TABLE users ADD COLUMN phone text; -- nullable
UPDATE users SET phone = '' WHERE phone IS NULL; -- backfill
ALTER TABLE users ALTER COLUMN phone SET NOT NULL; -- now safe
```

### Changing a column type

```sql
-- Step 1: Add new column with new type
ALTER TABLE products ADD COLUMN price_new numeric(12, 2);

-- Step 2: Dual-write (app writes to both old and new)
-- Application code:
--   product.Price = input.Amount  -- old column
--   product.PriceNew = input.Amount  -- new column with new type

-- Step 3: Backfill in batches
UPDATE products
SET price_new = price::numeric(12, 2)
WHERE price_new IS NULL
LIMIT 1000;

-- Step 4: Backfill on read (app reads from new column if populated, else old)
--   if product.PriceNew != nil { return product.PriceNew }
--   return product.Price

-- Step 5: Drop old column when no longer needed
ALTER TABLE products DROP COLUMN price;
ALTER TABLE products RENAME COLUMN price_new TO price;
```

---

## 3. Index Creation (Lock-Free)

### The problem

```sql
CREATE INDEX idx_orders_user ON orders (user_id);
-- Blocks writes for entire duration (potentially hours on large tables)
```

### The solution: CONCURRENTLY

```sql
CREATE INDEX CONCURRENTLY idx_orders_user ON orders (user_id);
```

| Aspect | Regular | CONCURRENTLY |
|--------|---------|-------------|
| Table lock | AccessExclusiveLock | ShareUpdateExclusiveLock |
| Blocks writes | ✅ Yes | ❌ No |
| Time | 1x | ~2x (two passes) |
| Failures | Rollback | Creates "invalid" index (must DROP) |

### CONCURRENTLY best practices

```sql
-- 1. Create CONCURRENTLY
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user ON orders (user_id);

-- 2. Check for failures
SELECT indexrelid::regclass, indisvalid
FROM pg_index
WHERE indrelid = 'orders'::regclass AND NOT indisvalid;
-- If any returned, the index created as "invalid" — drop and retry

-- 3. In automation (idempotent):
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    WHERE c.relname = 'idx_orders_user'
  ) THEN
    EXECUTE 'CREATE INDEX CONCURRENTLY idx_orders_user ON orders (user_id)';
  END IF;
END $$;
```

### Unique index CONCURRENTLY

```sql
-- Step 1: Create non-unique index (can't create unique CONCURRENTLY directly)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_order_number ON orders (order_number);

-- Step 2: Add unique constraint using the existing index
ALTER TABLE orders
  ADD CONSTRAINT uq_orders_order_number
  UNIQUE USING INDEX idx_orders_order_number;
-- This is a metadata-only operation — no table scan
```

---

## 4. Backfilling Data

### Batch update pattern

```sql
-- Process 1000 rows at a time
DO $$
DECLARE
  batch_size CONSTANT int := 1000;
  affected int;
BEGIN
  LOOP
    WITH batch AS (
      SELECT ctid
      FROM products
      WHERE slug IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    )
    UPDATE products p
    SET slug = lower(regexp_replace(p.name, '[^a-zA-Z0-9]+', '-', 'g'))
    FROM batch
    WHERE p.ctid = batch.ctid;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'Updated % rows', affected;
    EXIT WHEN affected = 0;

    COMMIT;
    PERFORM pg_sleep(0.1); -- throttle
  END LOOP;
END $$;
```

### Backfill with progress tracking

```sql
CREATE TABLE migration_progress (
  id bigserial PRIMARY KEY,
  table_name text NOT NULL,
  batch_start int NOT NULL,
  batch_end int,
  rows_affected int,
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

-- Backfill with tracking
DO $$
DECLARE
  batch_size CONSTANT int := 1000;
  min_id bigint;
  max_id bigint;
  current_id bigint;
  affected int;
BEGIN
  SELECT min(id), max(id) INTO min_id, max_id FROM orders;
  current_id := min_id;

  WHILE current_id <= max_id LOOP
    UPDATE orders
    SET payment_status = status
    WHERE id BETWEEN current_id AND current_id + batch_size - 1
      AND payment_status IS NULL;

    GET DIAGNOSTICS affected = ROW_COUNT;

    INSERT INTO migration_progress (table_name, batch_start, batch_end, rows_affected, completed_at)
    VALUES ('orders', current_id, current_id + batch_size - 1, affected, now());

    current_id := current_id + batch_size;
    COMMIT;
  END LOOP;
END $$;
```

---

## 5. Lock Timeouts

### Why you need them

Without timeouts, a migration can wait forever for a conflicting transaction and block all subsequent operations.

### Setting lock timeouts

```sql
-- Per-session: fail after waiting 5 seconds
SET lock_timeout = '5s';

-- Migration scripts should set this:
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE orders ADD COLUMN payment_status text;
COMMIT;
-- ↑ If lock not acquired in 5s, statement fails, tx rolls back
```

### Deadlock detection

PostgreSQL automatically detects deadlocks, but lock waits for a single resource have no timeout by default.

```sql
-- Monitor lock waits
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocked_activity.application_name AS blocked_application,
  now() - blocked_activity.query_start AS waiting_duration
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### Lock hierarchy

| Lock Mode | Conflicts With | Migration Use |
|-----------|---------------|---------------|
| `AccessShareLock` | `AccessExclusiveLock` | SELECT |
| `RowShareLock` | `AccessExclusiveLock` | SELECT FOR UPDATE |
| `RowExclusiveLock` | `Share`, `ShareRowExclusive`, `Exclusive`, `AccessExclusive` | INSERT, UPDATE, DELETE |
| `ShareLock` | `RowExclusive`, `ShareRowExclusive`, `Exclusive`, `AccessExclusive` | CREATE INDEX (non-CONCURRENTLY) |
| `ShareRowExclusiveLock` | All except `AccessShare`, `RowShare` | |
| `AccessExclusiveLock` | All | DDL (ALTER, DROP, TRUNCATE, VACUUM FULL) |

### Safe lock timeout settings by operation

```sql
-- DDL operations: short timeout (fail fast)
SET lock_timeout = '2s';
ALTER TABLE orders ADD COLUMN ...

-- Backfill operations: no timeout (we're waiting for data)
SET lock_timeout = 0;
UPDATE orders SET ...

-- Index creation CONCURRENTLY: no timeout needed (no exclusive lock)
SET lock_timeout = 0;
CREATE INDEX CONCURRENTLY ...
```

---

## 6. Partitioning Existing Tables

### Problem

Table has 500M rows. Queries are slow despite indexes. Need to partition by month.

### Step-by-step zero-downtime approach

```sql
-- Step 1: Create partitioned table with same structure
CREATE TABLE orders_new (
  id uuid NOT NULL,
  order_number text NOT NULL,
  created_at timestamptz NOT NULL,
  -- ... all other columns
) PARTITION BY RANGE (created_at);

-- Step 2: Create partitions
CREATE TABLE orders_2024_01 PARTITION OF orders_new
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
-- ... create all needed partitions

-- Step 3: Create indexes on partitioned table
CREATE INDEX ON orders_new (created_at);
CREATE INDEX ON orders_new (user_id);

-- Step 4: Attach old table as a partition (PG 12+)
-- First, add check constraint matching old data
ALTER TABLE orders
  ADD CONSTRAINT orders_range_check
  CHECK (created_at >= '2023-01-01' AND created_at < '2026-01-01');

-- Then attach
ALTER TABLE orders_new ATTACH PARTITION orders
  FOR VALUES FROM ('2023-01-01') TO ('2026-01-01');
-- ↑ This is a metadata-only operation, not a data move

-- Step 5: Rename
ALTER TABLE orders RENAME TO orders_legacy;
ALTER TABLE orders_new RENAME TO orders;

-- Step 6: Optionally split the legacy partition later
-- (This is the heavy part, can be done in background)
```

### Using pg_partman for automated partition management

```sql
CREATE EXTENSION pg_partman;

-- Create monthly partition set
SELECT partman.create_parent(
  p_parent_table := 'public.orders',
  p_control := 'created_at',
  p_type := 'native',
  p_interval := '1 month',
  p_premake := 3
);

-- Automatically maintain (run via pg_cron or scheduler)
SELECT partman.run_maintenance();
```

---

## 7. Rollback Strategies

### Migration rollback file

Every migration should have a corresponding rollback.

```sql
-- migration_20250401_add_currency_to_orders.sql
-- Forward:
ALTER TABLE orders ADD COLUMN currency text NOT NULL DEFAULT 'USD';

-- Rollback:
ALTER TABLE orders DROP COLUMN currency;
```

### Rollback categories

| Category | Strategy | Rollback Cost |
|----------|----------|---------------|
| Column add (nullable) | `DROP COLUMN` | Instant |
| Column add (NOT NULL default) | `DROP COLUMN` | Instant (PG 11+) |
| Index create | `DROP INDEX` | Instant |
| Index create CONCURRENTLY | `DROP INDEX` | Instant |
| Constraint add NOT VALID | `DROP CONSTRAINT` | Instant |
| Column type change (via new column) | Drop new, rename old back | Instant |
| Table partition | Revert rename | Instant |
| Data backfill | Reverse UPDATE | Proportional to data |
| Column drop | Restore from backup ⚠️ | Hours+ |

### Point-in-time recovery (PITR) as ultimate rollback

```sql
-- If everything goes wrong:
-- 1. Stop app
-- 2. Restore from WAL archive to timestamp before migration
pg_restore --dbname=mydb --clean \
  --target-time "2025-04-01 02:00:00 UTC" \
  my_backup.dump

-- Or with physical replication:
-- 1. Promote a replica that hasn't applied the migration
-- 2. Point app to promoted replica
-- 3. Rebuild original primary from promoted replica
```

---

## 8. Large Table Migration Checklist

```markdown
## Migration Checklist

### Before
- [ ] Run migration on staging with production-sized data
- [ ] Measure timing for each step
- [ ] Set `lock_timeout` for DDL statements
- [ ] Check active connections and long-running transactions
- [ ] Verify disk space (indexes need ~1.5x table size temporarily)
- [ ] Snapshot or WAL backup ready
- [ ] Rollback script written and tested
- [ ] Notify team (read-only maintenance window if needed)

### During
- [ ] Monitor pg_locks for blocking
- [ ] Monitor replication lag (if replicas)
- [ ] Monitor disk space
- [ ] Monitor autovacuum activity
- [ ] Log every step with timestamps

### After
- [ ] Run ANALYZE on modified tables
- [ ] Verify data integrity with queries
- [ ] Check application logs for errors
- [ ] Remove rollback artifacts (temp tables, old columns) after 48h
- [ ] Update documentation/schema diagrams
- [ ] Drop unused indexes or columns in a separate deployment
```

---

## 9. Common Migration Anti-Patterns

### Running DDL inside a transaction block with SELECT

```sql
-- 🔴 Bad: locks tables for entire transaction
BEGIN;
SELECT count(*) FROM orders; -- takes AccessShareLock
ALTER TABLE orders ADD COLUMN ...; -- waits for previous locks
COMMIT;
```

Always run DDL in its own transaction:
```sql
-- ✅ Good: isolated DDL transaction
BEGIN;
  ALTER TABLE orders ADD COLUMN currency text;
COMMIT;
```

### Adding a column with a volatile DEFAULT

```sql
-- 🔴 Bad: rewrites entire table, long exclusive lock
ALTER TABLE orders ADD COLUMN slug uuid DEFAULT gen_random_uuid() NOT NULL;

-- ✅ Good: add nullable, backfill, then NOT NULL
ALTER TABLE orders ADD COLUMN slug uuid;
-- (backfill in batches)
ALTER TABLE orders ALTER COLUMN slug SET DEFAULT gen_random_uuid();
ALTER TABLE orders ALTER COLUMN slug SET NOT NULL;
```

### Dropping a column without checking usage

```sql
-- 🔴 Bad: breaks queries, views, functions that reference it
ALTER TABLE users DROP COLUMN username;

-- ✅ Good: mark as unused first, wait, then drop
ALTER TABLE users RENAME COLUMN username TO username_deprecated;
-- ... wait a week, check logs ...
ALTER TABLE users DROP COLUMN username_deprecated;
```

### Migration in a single monolithic script

```sql
-- 🔴 Bad: one script does everything
-- 01_add_columns.sql:
--   ALTER TABLE ... ADD COLUMN ...
--   ALTER TABLE ... ADD CONSTRAINT ...
--   UPDATE ... (backfill)
--   ALTER TABLE ... SET NOT NULL
-- If the UPDATE fails, the ALTER TABLE is already committed!

-- ✅ Good: one migration per logical change
-- 20250401_01_add_currency_column.sql
-- 20250401_02_backfill_currency.sql
-- 20250401_03_add_not_null_currency.sql
```

### Not testing with production-scale data

```sql
-- Migrations that take 2s on 10K rows may take 2 hours on 10M rows
-- Always test with representative data volume
```

---

## 10. Tools and Automation

### Using sqitch for migration management

```bash
# Create migration
sqitch add add_currency_to_orders \
  --require-extension pgcrypto \
  -n "Add currency column to orders"

# Deploy
sqitch deploy db:pg://localhost/mydb

# Revert
sqitch revert db:pg://localhost/mydb
```

### Using pgroll for zero-downtime migrations

```bash
# pgroll handles expand/contract automatically
pgroll start mydb \
  --add-column "orders.currency text DEFAULT 'USD' NOT NULL"

# When ready to remove old column
pgroll complete mydb orders.currency
```

### Custom migration runner

```python
# simple_migrate.py — handles locking, timeouts, and retries
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def run_migration(conn, sql, lock_timeout='5s'):
    with conn.cursor() as cur:
        cur.execute(f'SET lock_timeout = {lock_timeout}')
        cur.execute(sql)

def batch_backfill(conn, table, set_clause, where_clause, batch_size=1000):
    while True:
        with conn.cursor() as cur:
            cur.execute(f"""
                UPDATE {table}
                {set_clause}
                WHERE ctid IN (
                    SELECT ctid FROM {table}
                    WHERE {where_clause}
                    LIMIT {batch_size}
                    FOR UPDATE SKIP LOCKED
                )
            """)
            if cur.rowcount == 0:
                break
        conn.commit()
```
