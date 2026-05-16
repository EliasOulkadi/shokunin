# Backend Performance Reference

> Production backend optimization: DB, caching, profiling, memory, and CPU.

---

## 1. Database Query Optimization

### N+1 Query Detection

```sql
-- Enable slow query log (MySQL)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

```bash
# Rails / ActiveRecord
npx bundler-exec ruby -e "ActiveRecord::Base.logger = Logger.new(STDOUT)"

# Prisma (enable query logging)
DATABASE_URL=... DEBUG="prisma:query" node server.js

# Django
django-debug-toolbar — check SQL panel
```

**Fix**: Eager loading:

```ts
// ❌ N+1
const users = await db.user.findMany();
for (const user of users) {
  const posts = await db.post.findMany({ where: { userId: user.id } });
}

// ✅ Eager
const users = await db.user.findMany({ include: { posts: true } });
```

### Indexing Strategy

```sql
-- B-tree (default) — equality + range queries
CREATE INDEX idx_users_email ON users(email);

-- Composite — order matters (most selective first)
CREATE INDEX idx_users_org_role ON users(organization_id, role);

-- Partial — filtered subset
CREATE INDEX idx_users_active ON users(created_at) WHERE active = true;

-- Covering — includes all queried columns
CREATE INDEX idx_users_list ON users(org_id, status) INCLUDE (name, email);

-- GiST / GIN — full-text, JSONB, arrays
CREATE INDEX idx_posts_search ON posts USING GIN(to_tsvector('english', body));
```

**Monitor unused / duplicate indexes**:

```sql
-- PostgreSQL
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

### Connection Pooling

| Tool | Use case |
|------|----------|
| PgBouncer | PostgreSQL — transaction pooling mode |
| pgbouncer-rr | Read-replica-aware pooling |
| Prisma Accelerate | Serverless connection pooling |
| `max_connections` | Tune per workload (25 per CPU core is a starting point) |
| `connection-limit` (PG) | `ALTER SYSTEM SET max_connections = 200;` |

### Query Analysis

```sql
-- EXPLAIN ANALYZE — real execution
EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending';

-- PostgreSQL auto_explain (log slow queries automatically)
LOAD 'auto_explain';
SET auto_explain.log_min_duration = 500;  -- ms
```

---

## 2. Caching Strategies

### Layered Cache Pattern

```
┌─────────┐     ┌──────────┐     ┌─────────────┐     ┌───────┐
│ Browser │ ──> │ CDN edge │ ──> │ App cache   │ ──> │ DB    │
│ (1 min) │     │ (5 min)  │     │ (10 min)    │     │       │
└─────────┘     └──────────┘     └─────────────┘     └───────┘
```

### HTTP Caching

```http
Cache-Control: public, max-age=3600, s-maxage=86400, stale-while-revalidate=300
Cache-Control: private, max-age=60      -- authenticated responses
Cache-Control: no-store                  -- sensitive data
ETag: "abc123"                           -- conditional validation
Last-Modified: Wed, 13 May 2026 12:00:00 GMT
```

### Redis Patterns

```bash
# Set with TTL
redis-cli SET user:42:profile '{"name":"alice"}' EX 300

# Cache-aside (lazy population)
function getUser(id) {
  const cached = redis.get(`user:${id}`);
  if (cached) return cached;
  const user = db.user.findUnique(id);
  redis.set(`user:${id}`, JSON.stringify(user), 'EX', 300);
  return user;
}

# Write-through
function updateUser(id, data) {
  db.user.update(id, data);
  redis.del(`user:${id}`);
}
```

### Application Cache

```ts
// In-memory LRU
import { LRUCache } from 'lru-cache';
const cache = new LRUCache({ max: 500, ttl: 1000 * 60 * 5 });

function expensiveQuery(id: string) {
  if (cache.has(id)) return cache.get(id);
  const result = db.query('SELECT ...', [id]);
  cache.set(id, result);
  return result;
}
```

### CDN Caching

| Service | Edge cache | Stale-while-revalidate | Purge API |
|---------|-----------|----------------------|-----------|
| Cloudflare | 30 min default | Yes | `POST /purge` |
| Fastly | Configurable | Yes | Surrogate Key |
| Akamai | Configurable | Yes | CP Code |
| Vercel Edge | Auto | Yes | `vercel purge` |

---

## 3. Profiling Tools

### Node.js

#### 0x — Flamegraphs

```bash
npm i -g 0x
0x -o ./flamegraphs server.js
# Generates interactive flamegraph HTML
```

#### Clinic.js

```bash
npm i -g clinic

# Flamegraph
clinic flame -- node server.js

# Doctor (high-level diagnosis)
clinic doctor -- node server.js

# Bubbleprof (async traces)
clinic bubbleprof -- node server.js
```

#### Built-in Profiling

```bash
# CPU profile
node --cpu-prof --cpu-prof-dir=./profiles server.js

# Heap snapshot
node --heap-prof --heap-prof-dir=./profiles server.js

# Generate flamegraph from v8 profile
npm i -g flamebearer
node --prof server.js
node --prof-process --preprocess -j isolate-*.log | flamebearer
```

### Python

```bash
# py-spy (sampling profiler, no code changes)
pip install py-spy
py-spy record -o profile.svg --pid 1234
py-spy top --pid 1234

# cProfile (deterministic)
python -m cProfile -o profile.stats server.py
python -m pstats profile.stats

# Scalene (CPU + memory + GPU line-by-line)
pip install scalene
scalene server.py
```

### General

```bash
# Linux perf (kernel-level)
perf record -F 99 -p 1234 -- sleep 30
perf report

# Windows Process Explorer / WPR
wpr -start cpu -filemode
# ... wait ...
wpr -stop profile.etl

# strace / procmon
strace -p 1234 -c         # syscall summary
strace -p 1234 -e trace=network  # network syscalls only
```

---

## 4. Memory Leak Detection

### Node.js

```bash
# Take heap snapshot programmatically
node -e "
const v8 = require('v8');
const fs = require('fs');
fs.writeFileSync('heap.heapsnapshot', JSON.stringify(v8.getHeapSnapshot()));
"

# Auto heap dump on high usage
node --max-old-space-size=512 --heapsnapshot-signal=SIGUSR2 server.js
# kill -USR2 <pid>
```

**Common leaks:**
- Closures retaining large objects
- Growing Maps/Sets without cleanup
- Event listeners not removed
- `global` / `globalThis` pollution
- `setInterval` without `clearInterval`
- Cache without eviction policy

### Python

```bash
# objgraph — find reference chains
pip install objgraph
objgraph.show_most_common_types(limit=20)

# tracemalloc — track allocations
python -X tracemalloc server.py
```

### Memory Pressure Response

1. **Set heap limits** — `--max-old-space-size=512` (MB)
2. **Enable GC tracing** — `--trace-gc`
3. **Auto-restart** — PM2 `max_memory_restart: "500M"`
4. **Alert on RSS** — Prometheus + Grafana at 80% of limit

---

## 5. CPU Profiling

### Identify hot paths

```bash
# Node.js — 5 seconds of CPU profile
node --cpu-prof --cpu-prof-duration=5000 server.js
# Outputs isolate-*.cpuprofile — load into DevTools Performance tab

# Python
py-spy record -o cpu.svg -d 10 -p $PID
```

### Flamegraph reading

```
Bottom: kernel / I/O wait
Middle: runtime / framework
Top: your application code
```

- **Plateaus** (wide flat tops) = expensive functions to optimize
- **Tall towers** = deep recursion → consider memoization or iterative rewrite
- **Broad shoulders** = frequently called → inline or cache

### Optimization priorities

| Signal | Action |
|--------|--------|
| High CPU in JSON serialization | Use `fast-json-stringify` or streaming |
| High CPU in crypto | Offload to worker thread or native addon |
| High CPU in template rendering | Cache rendered output, use precompiled templates |
| High CPU in DB driver | Add connection pooling, batch queries |
| High GC pause | Reduce allocation rate, reuse objects, increase heap |

---

## 6. Observability Checklist

- [ ] Slow query logging enabled (threshold: 500 ms)
- [ ] Redis `SLOWLOG` monitored — `SLOWLOG GET 10`
- [ ] Heap snapshots automated on OOM
- [ ] CPU flamegraphs in CI on benchmark runs
- [ ] `process.hrtime.bigint()` for custom instrumentation
- [ ] OpenTelemetry traces exported to Jaeger/Grafana Tempo
- [ ] Memory limit alerts at 80% of container limit
- [ ] Connection pool saturation alerts
- [ ] Event loop lag alert (threshold: 50 ms)
