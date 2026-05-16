# Index Strategies

Complete reference on PostgreSQL index types with use cases, EXPLAIN ANALYZE examples, and selection criteria.

## Decision Matrix

| Index Type | Lookup | Range | Sort | FTS | JSON | Geo | Array | Write Cost | Size |
|------------|--------|-------|------|-----|------|-----|-------|------------|------|
| B-tree | ⚡ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Low | Small |
| GIN | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | High | Large |
| GiST | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | Medium | Medium |
| BRIN | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Very Low | Tiny |
| Hash | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Low | Small |
| SP-GiST | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Medium | Medium |

---

## 1. B-tree (Default)

### When to use
- Equality: `WHERE id = 42`
- Range: `WHERE price BETWEEN 10 AND 100`
- Sort: `ORDER BY created_at DESC`
- Join columns: `ON users.id = orders.user_id`
- Unique constraints, primary keys
- Most general-purpose queries

### How it works
Balanced tree structure. All leaf nodes are at the same depth. Each node contains sorted key values and pointers. Lookup is O(log n).

```
Root:        [50]
           /      \
Internal: [25]    [75]
         /   \    /   \
Leaf:   1-24  26-49 51-74 76-100
```

### EXPLAIN ANALYZE

Equality scan:
```
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'alice@example.com';
                                                   QUERY PLAN
─────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_users_email on users  (cost=0.28..8.30 rows=1 width=72)
   Index Cond: ((email)::text = 'alice@example.com'::text)
   Planning Time: 0.073 ms
   Execution Time: 0.051 ms
```

Range scan:
```
EXPLAIN ANALYZE SELECT * FROM orders WHERE created_at >= '2025-01-01';
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_orders_created on orders  (cost=0.28..124.50 rows=5230 width=128)
   Index Cond: (created_at >= '2025-01-01'::date)
   Planning Time: 0.091 ms
   Execution time: 2.34 ms
```

### Composite B-tree — column order matters

**Rule of thumb**: most selective column first (highest cardinality first).

❌ **Wrong order** (status has only 4 distinct values):
```sql
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
```
- Can't skip `status` to search `created_at` alone
- `status` filter narrows poorly → still scans many rows

✅ **Right order** (created_at is unique per row):
```sql
CREATE INDEX idx_orders_created_status ON orders (created_at, status);
```
- Can still filter by `created_at` alone (prefix matching)
- `created_at` range filter efficiently narrows before status check

### Partial B-tree

Index only the rows you actually query. Smaller index = faster writes.

```sql
-- Only index active subscriptions (90% of rows excluded)
CREATE INDEX idx_subscriptions_active
ON subscriptions (current_period_end)
WHERE status = 'active';

-- Before: Seq Scan on subscriptions (320K rows)
-- After: Index Scan (1.2K rows)
```

```sql
-- Only index unread notifications
CREATE INDEX idx_notifications_unread
ON notifications (user_id, created_at DESC)
WHERE read_at IS NULL;
```

### Covering Index (INCLUDE)

Skip heap fetches by storing extra columns in the index. For read-heavy queries with small payloads.

```sql
-- Without covering: 2 blocks read per row (index + heap)
CREATE INDEX idx_orders_user ON orders (user_id);

-- With covering: index-only scan
CREATE INDEX idx_orders_user_covering
ON orders (user_id)
INCLUDE (status, total, created_at);

SELECT user_id, status, total, created_at
FROM orders
WHERE user_id = 'abc-123';
-- ↑ Index-Only Scan, no heap fetch needed
```

### Sorting support

B-tree indexes store values in order. PostgreSQL can read them backwards for DESC.

```sql
CREATE INDEX idx_posts_published ON posts (published_at DESC NULLS LAST);

EXPLAIN ANALYZE SELECT title, published_at FROM posts
WHERE published_at IS NOT NULL
ORDER BY published_at DESC
LIMIT 20;
                                                        QUERY PLAN
───────────────────────────────────────────────────────────────────────────────────────────
 Limit  (cost=0.29..1.06 rows=20 width=56)
   ->  Index Scan Backward using idx_posts_published on posts  (cost=0.29..156.23 rows=4050 width=56)
         Index Cond: (published_at IS NOT NULL)
```

---

## 2. GIN (Generalized Inverted Index)

### When to use
- Full-text search: `to_tsvector('english', body) @@ to_tsquery('cat & dog')`
- JSONB containment/existence: `WHERE metadata @> '{"key": "val"}'`
- Arrays: `WHERE tags @> ARRAY['urgent']`
- Trigram similarity: `pg_trgm` extension

### How it works
Inverted index — maps each element/word to the rows containing it. Unlike B-tree which stores complete values, GIN stores posting lists.

```
Document 1: "the quick brown fox"
Document 2: "the lazy dog"

Index entries:
brown → [1]
dog   → [2]
fox   → [1]
lazy  → [2]
quick → [1]
the   → [1, 2]
```

### EXPLAIN ANALYZE

JSONB containment:
```sql
EXPLAIN ANALYZE SELECT * FROM events WHERE payload @> '{"type": "purchase"}';
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Bitmap Heap Scan on events  (cost=12.04..1456.30 rows=430 width=256)
   Recheck Cond: (payload @> '{"type": "purchase"}'::jsonb)
   ->  Bitmap Index Scan on idx_events_payload  (cost=0.00..11.93 rows=430 width=0)
         Index Cond: (payload @> '{"type": "purchase"}'::jsonb)
         Planning Time: 0.12 ms
         Execution Time: 1.84 ms
```

Full-text search:
```sql
EXPLAIN ANALYZE SELECT title FROM documents
WHERE to_tsvector('english', body) @@ to_tsquery('database & indexing');
                                                         QUERY PLAN
─────────────────────────────────────────────────────────────────────────────────────────────
 Bitmap Heap Scan on documents  (cost=28.40..1452.10 rows=340 width=80)
   Recheck Cond: (to_tsvector('english', body) @@ to_tsquery('database & indexing'::tsquery))
   ->  Bitmap Index Scan on idx_documents_fts  (cost=0.00..28.32 rows=340 width=0)
         Index Cond: (to_tsvector('english', body) @@ to_tsquery('database & indexing'::tsquery))
```

### GIN maintenance

GIN indexes are write-heavy. For write-heavy tables:

```sql
-- Faster inserts with fastupdate (default: on)
CREATE INDEX idx_documents_fts ON documents USING GIN (to_tsvector('english', body))
WITH (fastupdate = on, gin_pending_list_limit = 4096);

-- Periodically clean up pending list
REINDEX INDEX idx_documents_fts; -- or VACUUM
```

---

## 3. GiST (Generalized Search Tree)

### When to use
- Geographic data (PostGIS): `ST_DWithin(geom, ST_MakePoint(-73.9, 40.7), 1000)`
- Range types: `&&` (overlap), `@>` (contains), `<@` (contained by)
- Full-text search with ranking (less common than GIN)
- Nearest-neighbor: `ORDER BY geom <-> point`
- IP range lookups (inet/cidr)

### How it works
Balanced tree that supports data splitting based on the data type's natural clustering. For geodata it groups nearby points into bounding boxes.

```
Level 1: [BBox covering North America][BBox covering Europe]
Level 2: [US West][US East][UK][Germany]
Level 3: [CA][OR][WA][NY][MA][London][Berlin][Munich]
```

### EXPLAIN ANALYZE

Spatial query:
```sql
EXPLAIN ANALYZE SELECT name FROM venues
WHERE ST_DWithin(location, ST_MakePoint(-73.9857, 40.7484), 500);
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_venues_location on venues  (cost=0.28..84.30 rows=12 width=64)
   Index Cond: (location && st_make_point(-73.9857, 40.7484)::geometry)
   Filter: st_dwithin(location, '-73.9857 40.7484'::geometry, '500'::double precision)
   Planning Time: 0.15 ms
   Execution Time: 0.42 ms
```

Range overlap:
```sql
EXPLAIN ANALYZE SELECT * FROM bookings
WHERE booked_duration && '[2025-06-01, 2025-06-07]'::tsrange;
                                                         QUERY PLAN
─────────────────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_bookings_duration on bookings  (cost=0.28..38.20 rows=15 width=48)
   Index Cond: (booked_duration && '[2025-06-01,2025-06-07]'::tsrange)
```

---

## 4. BRIN (Block Range Index)

### When to use
- **Very large tables** (10M+ rows) with **naturally ordered** or **clustered** data
- Append-only or insert-mostly tables (logs, events, time series)
- Columns with high correlation to physical storage order (e.g., auto-increment, timestamps)
- Tables where you want **1,000x smaller index** than B-tree

### How it works
Summarizes blocks of pages (default 128 pages per range) with min/max values. If a query's value falls outside a range's min/max, the entire block range is skipped.

```
Table pages: [1-128] [129-256] [257-384] [385-512] ...
BRIN entry:  1-1000   1001-2000 2001-3000 3001-4000

Query: WHERE created_at = 1500
→ Scan page range 2 only (129-256)
→ 75% of pages skipped immediately
```

### EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE SELECT * FROM events
WHERE created_at >= '2025-04-01' AND created_at < '2025-04-02';
                                                        QUERY PLAN
───────────────────────────────────────────────────────────────────────────────────────────
 Bitmap Heap Scan on events  (cost=42.30..1820.40 rows=24500 width=128)
   Recheck Cond: ((created_at >= '2025-04-01'::date) AND (created_at < '2025-04-02'::date))
   ->  Bitmap Index Scan on idx_events_created_brin  (cost=0.00..36.17 rows=24500 width=0)
         Index Cond: ((created_at >= '2025-04-01'::date) AND (created_at < '2025-04-02'::date))
         Planning Time: 0.09 ms
         Execution Time: 3.21 ms
```

Compare with B-tree on same table (100M rows):
```
 Index Scan using idx_events_created_btree  (cost=0.58..1245.30 rows=24500 width=128)
   Execution Time: 2.94 ms

→ BRIN is almost as fast but uses <10MB vs B-tree's 2.1GB
```

### BRIN parameters

```sql
-- Default pages_per_range = 128 (good balance)
CREATE INDEX idx_orders_created_brin ON orders USING BRIN (created_at);

-- More aggressive compression (faster scans, more false positives)
CREATE INDEX idx_orders_created_brin_fast ON orders USING BRIN (created_at)
WITH (pages_per_range = 32);

-- More precise (slower scan, fewer false positives)
CREATE INDEX idx_events_created_brin_precise ON events USING BRIN (created_at)
WITH (pages_per_range = 4);
```

### When BRIN fails

```sql
-- Useless: random UUID column has no correlation with physical order
CREATE INDEX idx_users_id_brin ON users USING BRIN (id);
-- ↑ Will scan nearly all pages. B-tree is always better for random values.

-- Check correlation:
SELECT tablename, attname, correlation
FROM pg_stats
WHERE tablename = 'users' AND attname = 'id';
-- correlation near 0 → BRIN useless
-- correlation near 1 or -1 → BRIN excellent
```

---

## 5. Hash

### When to use
- Equality only: `WHERE id = 42`
- **No range queries, no sorting, no partial matching**
- Rarely the best choice — B-tree does equality just as well and does everything else

### How it works
Applies a hash function to the key, stores entries in buckets. Fixed-size output (32-bit integer). No ordering preserved.

```
Key: "alice@example.com"
Hash: 0xA3F72B1 → Bucket 15

Key: "bob@example.com"
Hash: 0x81C4E9F → Bucket 7
```

### When to actually consider Hash

- Very large tables with only equality lookups (same as B-tree performance, slightly smaller index)
- Partition pruning in partitioned tables (Postgres 17+ improved hash partition pruning)

```sql
CREATE INDEX idx_sessions_token_hash ON sessions USING HASH (session_token);

EXPLAIN ANALYZE SELECT * FROM sessions WHERE session_token = 'abc123...';
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_sessions_token_hash on sessions  (cost=0.00..8.02 rows=1 width=64)
   Index Cond: (session_token = 'abc123...'::text)
   Planning Time: 0.06 ms
   Execution Time: 0.03 ms
```

### Why you probably don't need Hash

- B-tree does `=` equally fast
- B-tree also does `IN`, `=` `>`, `<`, `ORDER BY`, `GROUP BY`
- Hash indexes are not WAL-logged (pre-10) or have replication caveats
- In 99% of cases, just use B-tree

---

## 6. SP-GiST (Space-Partitioned GiST)

### When to use
- Quad-trees for 2D points
- K-d trees for multi-dimensional data
- Radix trees for string prefix matching
- Geographical partitioning (non-overlapping regions)
- `ORDER BY point <-> '(x,y)'` nearest-neighbor

### How it works
Recursively partitions the search space into non-overlapping regions. Each level subdivides the space differently depending on the opclass.

```
Quad-tree (2D points):
┌──────────────┐
│     │        │
│  A  │   B    │
│─────┼────    │
│     │        │
│  C  │   D    │
│     │        │
└──────────────┘

Each quadrant splits into 4 sub-quadrants recursively.
```

### EXPLAIN ANALYZE

Nearest-neighbor with points:
```sql
EXPLAIN ANALYZE SELECT * FROM locations
ORDER BY point <-> '(40.7128, -74.0060)'::point
LIMIT 10;
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Limit  (cost=0.28..12.45 rows=10 width=48)
   ->  Index Scan using idx_locations_point on locations  (cost=0.28..1245.30 rows=1050 width=48)
         Order By: (point <-> '(40.7128,-74.006)'::point)
         Planning Time: 0.11 ms
         Execution Time: 0.38 ms
```

Prefix search with radix tree:
```sql
CREATE INDEX idx_names_prefix ON names USING SPGIST (name text_ops);

EXPLAIN ANALYZE SELECT * FROM names WHERE name LIKE 'thom%';
                                                       QUERY PLAN
──────────────────────────────────────────────────────────────────────────────────────────
 Index Scan using idx_names_prefix on names  (cost=0.28..18.40 rows=45 width=32)
   Index Cond: (name ~>=~ 'thom'::text AND name ~<~ 'thos'::text)
   Planning Time: 0.08 ms
   Execution Time: 0.21 ms
```

---

## Real-World Scenarios

### Scenario 1: E-commerce order dashboard

Requirements: filter orders by status + date range, sorted by date descending.

```sql
-- ❌ Bad: status first (low cardinality)
CREATE INDEX idx_orders_status_date ON orders (status, created_at DESC);

-- ✅ Better: date first (high cardinality), use partial + covering
CREATE INDEX idx_orders_recent_active
ON orders (created_at DESC)
INCLUDE (status, total, user_id)
WHERE status IN ('PENDING', 'PROCESSING', 'SHIPPED');

SELECT status, total, user_id FROM orders
WHERE status IN ('PENDING', 'PROCESSING', 'SHIPPED')
AND created_at >= '2025-03-01'
ORDER BY created_at DESC;
-- ↑ Index-Only Scan, ~50x faster than no index
```

### Scenario 2: SaaS audit log (500M rows)

Write-heavy, append-only, queried by time range + user.

```sql
-- B-tree would be 8GB+ — use BRIN for the time column
CREATE INDEX idx_audit_created_brin ON audit_logs USING BRIN (created_at)
WITH (pages_per_range = 16);

-- Partial B-tree for hot users (queried often, subset of rows)
CREATE INDEX idx_audit_hot_users ON audit_logs (user_id, created_at DESC)
INCLUDE (action, ip_address)
WHERE user_id IN (
  SELECT id FROM users WHERE plan = 'enterprise'
);
```

### Scenario 3: Full-text search on articles

```sql
-- GIN for FTS + partial for published only
CREATE INDEX idx_articles_fts
ON articles USING GIN (to_tsvector('english', title || ' ' || body))
WHERE status = 'published';

-- Trigram for fuzzy search on titles
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_articles_title_trgm ON articles USING GIN (title gin_trgm_ops)
WHERE status = 'published';
```

### Scenario 4: Geolocation venue search

```sql
-- GiST for spatial queries
CREATE INDEX idx_venues_geom ON venues USING GIST (geom);

-- SP-GiST for point-only nearest-neighbor (faster than GiST for pure points)
CREATE INDEX idx_venues_point ON venues USING SPGIST (location::point);

-- Composite: category + location
CREATE INDEX idx_venues_category_geom ON venues USING GIST (category, geom);
-- Note: GIST supports multiple columns, first is exact match, second is spatial
```

---

## Anti-Patterns

### Indexing every column
```sql
CREATE INDEX idx_users_name ON users (name);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_status ON users (status);
CREATE INDEX idx_users_created ON users (created_at);
-- 5 separate indexes → 5x write overhead, query planner picks wrong one
-- Better: 2-3 composite indexes that match actual queries
```

### Redundant indexes
```sql
CREATE INDEX idx_orders_user ON orders (user_id);
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at);
-- First index is redundant — second one covers all queries on user_id
-- Drop idx_orders_user
```

### Over-indexing write-heavy tables
```sql
-- Table with 10K writes/sec
CREATE INDEX idx_logs_user ON logs (user_id);
CREATE INDEX idx_logs_action ON logs (action);
CREATE INDEX idx_logs_ip ON logs (ip_address);
CREATE INDEX idx_logs_created ON logs (created_at);
CREATE INDEX idx_logs_session ON logs (session_id);
-- Every INSERT needs to update 5 indexes → WAL amplifcation, bloat
-- Use BRIN for time, drop the rest unless query patterns demand them
```

### Index on low-cardinality column alone
```sql
CREATE INDEX idx_users_is_active ON users (is_active);
-- is_active has 2 values. Scanning 50% of the table.
-- Better: partial index or composite with a high-cardinality column
```

---

## Monitoring

```sql
-- Unused indexes (PostgreSQL 9.2+)
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelid NOT IN (
  SELECT indexrelid FROM pg_index WHERE indisprimary
)
ORDER BY tablename;

-- Index size
SELECT
  i.relname AS index_name,
  pg_size_pretty(pg_relation_size(i.oid)) AS size
FROM pg_class i
JOIN pg_index idx ON i.oid = idx.indexrelid
JOIN pg_class t ON idx.indrelid = t.oid
WHERE t.relname = 'orders'
ORDER BY pg_relation_size(i.oid) DESC;

-- Bloat estimate
SELECT
  i.relname AS index_name,
  pg_size_pretty(pg_relation_size(i.oid)) AS size,
  round(100 * (1 - s.avg_leaf_density / (
    CASE WHEN s.avg_leaf_density > 0 THEN s.avg_leaf_density ELSE 1 END
  ))) || '%' AS bloat_estimate
FROM pg_class i
JOIN pg_stat_user_indexes s ON i.oid = s.indexrelid
WHERE s.idx_scan > 100
ORDER BY pg_relation_size(i.oid) DESC;
```

---

## Quick Reference

| You need to... | Use | Because |
|---|---|---|
| Find row by ID | B-tree | Default, universal, fast |
| Filter by date range | BRIN | 1/1000th the size, nearly as fast |
| Search text | GIN | Inverted index is O(1) per word |
| Find JSON keys | GIN | JSONB @> operator requires GIN |
| Find nearby points | GiST or SP-GiST | Spatial indexing |
| Sort by column | B-tree | Index is already sorted |
| Get unique values | B-tree | Implicitly via index scan |
| Filter by boolean + date | **Partial** B-tree | Skips 90% of rows |
| Exact match on long text | B-tree | Hash is rarely better |
| Prefix LIKE 'abc%' | B-tree or SP-GiST | B-tree supports >=/<= bounds |
| Fuzzy LIKE '%abc%' | GIN trigram | pg_trgm extension |
| Array overlap | GIN | Only index that handles arrays |
| Range overlap `&&` | GiST | Intended for range types |
