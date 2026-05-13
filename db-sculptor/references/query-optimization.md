# Query Optimization

Step-by-step guide to diagnosing and fixing slow queries in PostgreSQL.

---

## 1. Reading EXPLAIN Output

### Anatomy of a query plan

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE, FORMAT TEXT)
SELECT o.order_number, o.total, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at >= '2025-01-01'
ORDER BY o.total DESC
LIMIT 20;
```

Output:
```
                                                                         QUERY PLAN
─────────────────────────────────────────────────────────────────────────────────────────────────────────────
 Limit  (cost=1724.30..1724.35 rows=20 width=96) (actual time=15.42..15.42 rows=20 loops=1)
   ->  Sort  (cost=1724.30..1737.28 rows=5192 width=96) (actual time=15.41..15.41 rows=20 loops=1)
         Sort Key: o.total DESC
         Sort Method: top-N heapsort  Memory: 33kB
         ->  Hash Join  (cost=308.42..1591.18 rows=5192 width=96) (actual time=2.14..12.83 rows=5192 loops=1)
               Hash Cond: (o.user_id = u.id)
               ->  Index Scan using idx_orders_created on orders o  (cost=0.28..1245.30 rows=5230 width=76)
                     Index Cond: (created_at >= '2025-01-01'::date)
                     Buffers: shared hit=482
               ->  Hash  (cost=184.20..184.20 rows=9920 width=28) (actual time=1.82..1.82 rows=9920 loops=1)
                     Buckets: 16384  Batches: 1  Memory Usage: 1024kB
                     ->  Seq Scan on users u  (cost=0.00..184.20 rows=9920 width=28) (actual time=0.01..0.85 rows=9920 loops=1)
                           Buffers: shared hit=364
 Planning:
   Buffers: shared hit=24
 Planning Time: 0.24 ms
 Execution Time: 15.52 ms
```

### Reading node by node

| Field | What it means | Good/Bad |
|-------|---------------|----------|
| `cost=308.42..1591.18` | Estimated startup..total cost in arbitrary units | Relative, compare between plans |
| `actual time=2.14..12.83` | Actual startup..total time in ms | Lower is better |
| `rows=5192` | Estimated vs actual row count | Big mismatch → bad statistics |
| `loops=1` | How many times this node ran | >1 suggests nested loop issues |
| `Buffers: shared hit=482` | Pages read from cache (hit) vs disk (read) | More hits = faster |
| `Planning Time` | Time to plan the query | Usually <1ms, >10ms = complex |
| `Execution Time` | Total time to execute | This is your query time |

### Node types (most common)

| Node | Meaning | Performance |
|------|---------|-------------|
| `Seq Scan` | Full table scan (reads every row) | 🟢 Small tables, 🔴 large tables |
| `Index Scan` | Walks B-tree, fetches from heap | 🟢 Selective queries |
| `Index Only Scan` | All data in index, no heap fetch | 🟢🟢 Fastest |
| `Bitmap Index Scan + Heap Scan` | Index scan + bitmapped heap access | 🟢 Medium selectivity |
| `Nested Loop` | For each outer row, scan inner | 🟢 Small inner, 🔴 large inner |
| `Hash Join` | Build hash table on inner, probe outer | 🟢 Medium-large tables |
| `Merge Join` | Sort both, merge | 🟢 Pre-sorted inputs |
| `Sort` | Explicit sort operation | 🟢 Small sorts, 🔴 disk sorts |
| `Materialize` | Cache inner result | 🟢 If reused 🟡 Memory |

---

## 2. Identifying Sequential Scans

### Why Seq Scan is bad

Reading every row in a 100M row table when you only need 20.

### How to find them

```sql
EXPLAIN ANALYZE SELECT * FROM logs WHERE level = 'error' AND created_at >= '2025-04-01';
```

🔴 **Problem**:
```
 Seq Scan on logs  (cost=0.00..892450.00 rows=12340 width=128)
   Filter: ((level)::text = 'error'::text) AND (created_at >= '2025-04-01'::date)
   Planning Time: 0.05 ms
   Execution Time: 4230.12 ms
```

### Fixes

**A. Add index**:
```sql
CREATE INDEX idx_logs_level_created ON logs (level, created_at);
-- Or partial:
CREATE INDEX idx_logs_errors ON logs (created_at) WHERE level = 'error';
```

**B. After fix** 🟢:
```
 Bitmap Index Scan on idx_logs_errors  (cost=0.00..28.40 rows=12340 width=0)
   Index Cond: (created_at >= '2025-04-01'::date)
 Execution Time: 14.20 ms
```

### When Seq Scan is fine

- Table < 1000 rows
- Query returns > 25% of table (index would be slower)
- `SELECT COUNT(*)` on small table

---

## 3. Nested Loops vs Hash Joins

### Nested Loop Join

```sql
EXPLAIN ANALYZE SELECT * FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.email = 'alice@example.com';
```

🟢 **Works well** (small outer, indexed inner):
```
 Nested Loop  (cost=0.28..16.35 rows=5 width=144)
   ->  Index Scan using idx_users_email on users u  (cost=0.28..8.30 rows=1 width=72)
         Index Cond: ((email)::text = 'alice@example.com'::text)
   ->  Index Scan using idx_orders_user on orders o  (cost=0.00..8.03 rows=5 width=76)
         Index Cond: (user_id = u.id)
 Execution Time: 0.18 ms
```

🔴 **Problem** (large outer, no inner index):
```
 Nested Loop  (cost=0.00..892450.00 rows=50000 width=144)
   ->  Seq Scan on users u  (cost=0.00..184.20 rows=9920 width=72)
   ->  Seq Scan on orders o  (cost=0.00..89.10 rows=5 width=76)
         Filter: (o.user_id = u.id)
 Execution Time: 8450.00 ms
-- 9920 × full seq scan on orders = disaster
```

**Fix**: Add index on `orders.user_id`.

### Hash Join

```sql
EXPLAIN ANALYZE SELECT * FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'SHIPPED';
```

🟢 **Good for mid-size**:
```
 Hash Join  (cost=152.40..1834.20 rows=12000 width=144)
   Hash Cond: (o.user_id = u.id)
   ->  Index Scan using idx_orders_status on orders o  (cost=0.28..1245.30 rows=12000 width=76)
         Index Cond: ((status)::text = 'SHIPPED'::text)
   ->  Hash  (cost=84.20..84.20 rows=9920 width=72)
         ->  Seq Scan on users u  (cost=0.00..84.20 rows=9920 width=72)
 Execution Time: 18.40 ms
```

🔴 **Problem** (hash table too large, spills to disk):
```
 Hash  (cost=184200.00..184200.00 rows=5M width=72)
   Buckets: 131072  Batches: 16  Memory Usage: 8192kB
   ->  Seq Scan on huge_table
 Execution Time: 45230.12 ms
-- 16 batches = hash table spilled to disk 16 times
```

**Fix**: Increase `work_mem` or optimize the join order:
```sql
SET work_mem = '256MB';
```

### Merge Join

Best when both inputs are already sorted:

```
 Merge Join  (cost=0.56..1834.20 rows=50000 width=144)
   Merge Cond: (u.id = o.user_id)
   ->  Index Scan using users_pkey on users u  (cost=0.28..284.20 rows=9920 width=72)
   ->  Index Scan using idx_orders_user on orders o  (cost=0.28..1245.30 rows=50000 width=76)
```

---

## 4. Identifying Index-Only Scans

The fastest scan type. All needed columns exist in the index — no heap visit.

🔴 Without covering index:
```
 Index Scan using idx_recent_orders on orders o  (cost=0.28..1245.30 rows=5000 width=76)
   Index Cond: (created_at >= '2025-01-01'::date)
 Buffers: shared hit=482 (index) + 520 (heap)
```

🟢 With covering index:
```sql
CREATE INDEX idx_recent_orders_covering
ON orders (created_at DESC)
INCLUDE (status, total, user_id);
```

```
 Index Only Scan using idx_recent_orders_covering on orders o  (cost=0.28..845.30 rows=5000 width=76)
   Index Cond: (created_at >= '2025-01-01'::date)
   Heap Fetches: 0
 Buffers: shared hit=482 (index only)
```

### Visibility map

If `Heap Fetches: 1200` appears in an index-only scan, autovacuum isn't keeping up:
```sql
-- Check visibility map
SELECT relname, relallvisible,
  pg_size_pretty(pg_relation_size(relid)) as size
FROM pg_class WHERE relname = 'orders';

-- Tune autovacuum for this table
ALTER TABLE orders SET (autovacuum_vacuum_scale_factor = 0.01);
```

---

## 5. CTE Optimization

### CTE as optimization fence (bad)

PostgreSQL materializes CTEs by default — they block pushdown of WHERE clauses:

🔴 **Slow**:
```sql
EXPLAIN ANALYZE
WITH recent_orders AS (
  SELECT * FROM orders WHERE created_at >= '2025-01-01'
)
SELECT * FROM recent_orders WHERE user_id = 'abc-123';
```

This still scans ALL rows matching `created_at >= '2025-01-01'` before filtering by user.

### CTE as optimization fence (good, with planning)

Use `NOT MATERIALIZED` (PG 12+):

🟢 **Fast**:
```sql
EXPLAIN ANALYZE
WITH recent_orders AS NOT MATERIALIZED (
  SELECT * FROM orders WHERE created_at >= '2025-01-01'
)
SELECT * FROM recent_orders WHERE user_id = 'abc-123';
```

Now the planner pushes `user_id` filter inside — uses composite index directly.

### Recursive CTEs (use with caution)

```sql
WITH RECURSIVE org_tree AS (
  SELECT id, name, parent_id, 1 as depth
  FROM employees WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.name, e.parent_id, ot.depth + 1
  FROM employees e
  JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT * FROM org_tree;
```

Limit depth to prevent infinite loops:
```sql
WITH RECURSIVE org_tree AS (
  ...
  UNION ALL
  SELECT ...
  FROM employees e JOIN org_tree ot ON e.manager_id = ot.id
  WHERE ot.depth < 10  -- ← safety limit
)
```

---

## 6. Common Anti-Patterns with Fixes

### Anti-pattern 1: SELECT * in production

```sql
SELECT * FROM orders WHERE user_id = 'abc';
-- Fetches all columns, including text blobs, JSON, etc.
```

Before: `Execution Time: 45.20 ms`, 480 buffers read
After (select only needed columns):
```sql
SELECT id, order_number, status, total FROM orders WHERE user_id = 'abc';
```
`Execution Time: 2.34 ms`, 24 buffers read

### Anti-pattern 2: Implicit type coercion

```sql
SELECT * FROM orders WHERE total = '99.99';
-- total is DECIMAL(10,2), comparing to TEXT → table-wide type cast
```

Before: `Seq Scan on orders (cost=0.00..892.00 rows=10 width=76) Filter: ((total)::numeric = '99.99'::numeric)`
After: `Index Scan using idx_orders_total on orders (cost=0.28..8.30 rows=1 width=76) Index Cond: (total = 99.99)`

### Anti-pattern 3: Wrapping columns in functions

```sql
SELECT * FROM orders WHERE DATE(created_at) = '2025-04-01';
-- DATE() prevents index usage
```

Before: Seq Scan (full table)
After — use range:
```sql
SELECT * FROM orders
WHERE created_at >= '2025-04-01' AND created_at < '2025-04-02';
```

Or use a functional index:
```sql
CREATE INDEX idx_orders_created_date ON orders (DATE(created_at));
```

### Anti-pattern 4: OR conditions that kill index usage

```sql
SELECT * FROM orders
WHERE status = 'PENDING' OR user_id = 'abc-123';
```

Before: Seq Scan (can't use separate indexes for OR efficiently)

Fixes:
- **A) UNION ALL**:
```sql
SELECT * FROM orders WHERE status = 'PENDING'
UNION ALL
SELECT * FROM orders WHERE user_id = 'abc-123' AND status != 'PENDING';
```

- **B) Composite bitmap scan** (if indexes exist, PG may use BitmapOr):
```
 BitmapOr
   → Bitmap Index Scan on idx_orders_status
   → Bitmap Index Scan on idx_orders_user
```

- **C) IN list** if you can refactor.

### Anti-pattern 5: Large IN lists

```sql
SELECT * FROM products WHERE id IN (1, 2, 3, ..., 5000);
```

Before: Long list parsing overhead, possible plan explosion.
After — use a VALUES list or temp table:
```sql
SELECT p.* FROM products p
JOIN (VALUES (1), (2), (3), ..., (5000)) AS v(id) ON v.id = p.id;
```

Or:
```sql
CREATE TEMP TABLE filter_ids (id UUID PRIMARY KEY);
INSERT INTO filter_ids VALUES ...; -- batch insert

SELECT p.* FROM products p
JOIN filter_ids f ON f.id = p.id;
```

### Anti-pattern 6: ORDER BY + LIMIT without matching index

```sql
SELECT * FROM orders
WHERE user_id = 'abc'
ORDER BY created_at DESC
LIMIT 10;
```

Without index on `(user_id, created_at)`:
```
 Sort  (cost=124.30..124.32 rows=10 width=76)
   Sort Key: created_at DESC
   ->  Index Scan using idx_orders_user on orders
         Index Cond: (user_id = 'abc'::uuid)
         (scans all orders for this user, then sorts)
```

With `CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC)`:
```
 Limit  (cost=0.28..1.45 rows=10 width=76)
   ->  Index Scan Backward using idx_orders_user_created on orders
         Index Cond: (user_id = 'abc'::uuid)
         (walks index in order, stops after 10)
```

### Anti-pattern 7: COUNT(*) on large table

```sql
SELECT COUNT(*) FROM events;
-- Requires sequence scan of full table or exact index scan
```

Before: `Execution Time: 1850ms`

After — use estimated count (if approximate is OK):
```sql
SELECT reltuples::bigint AS estimated_count
FROM pg_class WHERE relname = 'events';
```

Or use incremental counters (trigger-based or external).

For exact count with filters:
```sql
-- If table is partitioned, count in parallel
SELECT SUM(cnt) FROM (
  SELECT COUNT(*) as cnt FROM events_2025_01
  UNION ALL
  SELECT COUNT(*) FROM events_2025_02
) counts;
```

### Anti-pattern 8: N+1 queries (ORM style)

```sql
-- N+1: 1 query for posts + N queries for comments
SELECT * FROM posts WHERE status = 'published'; -- 1 query
foreach post:
  SELECT * FROM comments WHERE post_id = post.id; -- N queries
```

Before: 1 + 100 queries, 450ms total
After — batch load:
```sql
SELECT * FROM posts WHERE status = 'published'; -- 1 query
SELECT * FROM comments WHERE post_id = ANY($1); -- 1 query for all
```
2 queries, 15ms total

---

## 7. Practical Optimization Workflow

### Step-by-step triage

```
1. Capture slow query
   ↓
2. Run EXPLAIN (ANALYZE, BUFFERS)
   ↓
3. Identify most expensive node (highest actual time)
   ↓
4. Is it a Seq Scan? → Add index
   Is it a Nested Loop with full inner scan? → Add index
   Is it a Sort on disk? → Add index or increase work_mem
   Is row estimate way off? → ANALYZE
   ↓
5. Apply fix
   ↓
6. Re-run EXPLAIN ANALYZE
   ↓
7. Verify improvement
```

### Diagnostic queries

```sql
-- Slow queries (requires pg_stat_statements)
SELECT
  queryid,
  round(total_exec_time::numeric, 2) AS total_ms,
  round(mean_exec_time::numeric, 2) AS avg_ms,
  calls,
  round(100 * total_exec_time / SUM(total_exec_time) OVER (), 2) AS pct,
  LEFT(query, 80) AS query_preview
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Missing indexes (sequential scans on large tables)
SELECT
  schemaname,
  tablename,
  seq_scan,
  seq_tup_read,
  seq_tup_read / NULLIF(seq_scan, 0) AS avg_rows_per_seq_scan,
  idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > 1000
  AND seq_tup_read / NULLIF(seq_scan, 0) > 10000
ORDER BY seq_tup_read DESC;

-- Table bloat
SELECT
  nspname AS schema,
  relname AS table,
  pg_size_pretty(pg_relation_size(relid)) AS size,
  round(100 * (1 - COALESCE(s.avg_leaf_density, 1))::numeric, 2) AS bloat_pct
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN (
  SELECT indexrelid, avg(avg_leaf_density) AS avg_leaf_density
  FROM pg_stat_user_indexes
  GROUP BY indexrelid
) s ON s.indexrelid = c.oid
WHERE c.relkind = 'r' AND nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_relation_size(relid) DESC;
```

---

## 8. Configuration Tuning

```sql
-- Settings that affect query performance
SHOW work_mem;           -- per sort/hash (default 4MB)
SHOW shared_buffers;     -- cache size (default 128MB)
SHOW effective_cache_size; -- planner's estimate (default 4GB)
SHOW random_page_cost;   -- SSD=1.1, HDD=4.0 (default 4.0)
SHOW default_statistics_target; -- histogram bins (default 100)
```

### Quick wins

```sql
-- If on SSD
SET random_page_cost = 1.1;
ALTER SYSTEM SET random_page_cost = 1.1;

-- Increase statistics target for problematic columns
ALTER TABLE orders ALTER COLUMN status SET STATISTICS 1000;
ANALYZE orders;

-- Increase work_mem for queries with large sorts/hashes
SET work_mem = '64MB';
-- ⚠️ Don't set globally too high (multiplied by connections)
```

---

## 9. Before/After Examples

### Example: Slow dashboard query

```sql
-- Show orders with user info, filtered by date and status
SELECT o.order_number, o.total, o.status, u.email, u.name
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at >= '2025-03-01'
  AND o.status IN ('PENDING', 'PROCESSING')
ORDER BY o.created_at DESC
LIMIT 50;
```

**Before** (no useful indexes):
```
 Sort  (cost=48920.00..48920.12 rows=50 width=96)
   Sort Key: o.created_at DESC
   Sort Method: top-N heapsort  Memory: 32kB
   ->  Hash Join  (cost=18420.00..48918.00 rows=5020 width=96)
         Hash Cond: (o.user_id = u.id)
         ->  Seq Scan on orders o  (cost=0.00..28420.00 rows=45020 width=76)
               Filter: ((created_at >= '2025-03-01'::date)
                   AND (status = ANY ('{PENDING,PROCESSING}'::text[])))
         ->  Hash  (cost=8420.00..8420.00 rows=50000 width=28)
               ->  Seq Scan on users u  (cost=0.00..8420.00 rows=50000 width=28)
 Execution Time: 8452.10 ms
```

**After** (create index on `(status, created_at DESC)` covering selected columns + join column, `ANALYZE`):
```sql
CREATE INDEX idx_orders_active_recent
ON orders (status, created_at DESC)
INCLUDE (total, user_id)
WHERE status IN ('PENDING', 'PROCESSING');
```

```
 Limit  (cost=0.28..4.20 rows=50 width=96)
   ->  Nested Loop  (cost=0.28..425.30 rows=5020 width=96)
         ->  Index Only Scan Backward using idx_orders_active_recent on orders o
               Index Cond: (status = ANY ('{PENDING,PROCESSING}'::text[]))
               Heap Fetches: 0
         ->  Index Scan using users_pkey on users u  (cost=0.00..8.02 rows=1 width=28)
               Index Cond: (id = o.user_id)
 Execution Time: 4.85 ms
```

**Improvement**: 8452ms → 4.85ms (**~1700x faster**)

### Example: Report query with aggregation

```sql
-- Monthly revenue by product category
SELECT
  c.name AS category,
  DATE_TRUNC('month', o.created_at) AS month,
  SUM(oi.total_price) AS revenue,
  COUNT(DISTINCT o.id) AS orders
FROM categories c
JOIN products p ON p.category_id = c.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status = 'DELIVERED'
  AND o.created_at >= '2024-01-01'
GROUP BY c.name, DATE_TRUNC('month', o.created_at)
ORDER BY c.name, month;
```

**Before** (2.3s execution, sequential scans, 50K buffers):
- Missing index on `orders(created_at, status)` and `order_items(order_id)`
- No materialized view for reporting

**After**:
```sql
-- Create materialized view for reporting
CREATE MATERIALIZED VIEW monthly_category_revenue AS
SELECT
  c.id AS category_id,
  DATE_TRUNC('month', o.created_at) AS month,
  SUM(oi.total_price) AS revenue,
  COUNT(DISTINCT o.id) AS orders
FROM categories c
JOIN products p ON p.category_id = c.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status = 'DELIVERED'
GROUP BY c.id, DATE_TRUNC('month', o.created_at)
ORDER BY c.id, month;

CREATE UNIQUE INDEX idx_mv_monthly_cat ON monthly_category_revenue (category_id, month);

-- Refresh nightly or after ETL
REFRESH MATERIALIZED VIEW monthly_category_revenue;
```

`Execution Time: 42ms` (after cache warm) — **~55x faster**.
