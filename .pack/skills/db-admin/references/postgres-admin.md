# PostgreSQL Administration Reference

## Connection Pooling (PgBouncer)

### Key Configuration (`pgbouncer.ini`)

```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Pool mode: session, transaction, or statement
pool_mode = transaction

# Per-pool limits
default_pool_size = 40
max_client_conn = 200
max_db_connections = 50

# Timeouts
server_idle_timeout = 600
query_timeout = 30
client_idle_timeout = 0

# Connection rotation
server_round_robin = 0
dns_max_ttl = 15.0
```

### Pool Modes

| Mode | Use Case | Notes |
|------|----------|-------|
| **session** | Long-lived connections (Django, Rails) | No multiplexing — each client gets a dedicated server conn |
| **transaction** | APIs, web apps | **Recommended.** Server conn reused between transactions |
| **statement** | Batch jobs, ETL | Most aggressive pooling — conn reused per statement |

### Connection String

```
postgresql://user:pass@pgbouncer-host:6432/mydb?application_name=myapp
```

### Internal Connection Pooling (Application-Level)

For applications that manage their own pool (e.g., Npgsql in .NET, Pgx in Go, psycopg2 pool):

```csharp
// Npgsql connection string with built-in pooling
"Host=localhost;Port=5432;Database=mydb;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=20;Connection Idle Lifetime=300;Connection Pruning Interval=60"
```

Set `application_name` for each pool to identify connection sources in `pg_stat_activity`.

---

## Streaming Replication

### Primary Setup (`postgresql.conf`)

```ini
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1024   # MB
max_replication_slots = 10
hot_standby = on
listen_addresses = '*'
```

### Replica Setup (`postgresql.conf`)

```ini
hot_standby = on
primary_conninfo = 'host=primary-host port=5432 user=replicator password=... application_name=replica1'
primary_slot_name = replica1
recovery_target_timeline = 'latest'
```

### Create Replication Slot

```sql
SELECT pg_create_physical_replication_slot('replica1');
```

### Base Backup for Replica

```powershell
pg_basebackup -h primary-host -D D:\pgdata\16\data -U replicator -P -v --slot=replica1 --wal-method=stream
```

### Monitoring Replication

```sql
-- Lag in bytes
SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes,
       pid, application_name, state, sync_state
FROM pg_stat_replication;

-- Lag in time
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

---

## Logical Replication

### Publisher

```sql
-- Create publication
CREATE PUBLICATION mypub FOR TABLE users, orders, products;
CREATE PUBLICATION all_tables FOR ALL TABLES;

-- Add tables to existing publication
ALTER PUBLICATION mypub ADD TABLE payments;
```

### Subscriber

```sql
-- Create subscription
CREATE SUBSCRIPTION mysub
CONNECTION 'host=publisher-host port=5432 dbname=mydb user=replicator password=...'
PUBLICATION mypub;
```

### Monitoring Logical Replication

```sql
SELECT slot_name, slot_type, database, active, restart_lsn, confirmed_flush_lsn
FROM pg_replication_slots
WHERE slot_type = 'logical';

SELECT subname, subscription_owner, subenabled, subslotname
FROM pg_subscription;
```

### When to Use Logical vs Streaming

| Feature | Streaming | Logical |
|---------|-----------|---------|
| Full DB copy | Yes | No (selective) |
| Version mismatch | Same major | Different versions |
| DDL replication | No | No (pglogical extension adds this) |
| Bidirectional | No | Possible (conflict resolution needed) |
| Use case | HA, failover | Migration, partial sync, upgrade |

---

## WAL Archiving for PITR

### Configuration (`postgresql.conf`)

```ini
wal_level = replica
archive_mode = on
archive_command = 'copy "%p" "\\\\archive-server\\wal\\%f"'
archive_timeout = 60   # seconds — forces WAL segment switch
```

### Windows Archive Command

```powershell
# archive_command (adjust paths to your env):
archive_command = 'powershell -Command "Copy-Item -LiteralPath \"%p\" -Destination \"D:\\wal_archive\\%f\""'
```

### Point-in-Time Recovery (`recovery.conf` for PG <12, or `postgresql.conf` for PG >=12)

```ini
restore_command = 'copy "\\\\archive-server\\wal\\%f" "%p"'
recovery_target_time = '2026-05-13 14:30:00 UTC'
recovery_target_action = promote
```

### Full PITR Workflow

```powershell
# 1. Take base backup
pg_basebackup -h localhost -D D:\pgdata\pitr_base -U postgres -P -v --wal-method=stream

# 2. Restore to point in time
# Copy base backup to recovery location
# Set restore_command and recovery_target_time in postgresql.conf
# Start PostgreSQL — it replays WAL to target time and promotes

# 3. Verify recovery
SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn(), pg_last_xact_replay_timestamp();
```

---

## Vacuum & Autovacuum Tuning

### Key Parameters

```ini
# Autovacuum master switch
autovacuum = on

# Aggressiveness
autovacuum_vacuum_scale_factor = 0.01    # Default 0.2 — too lazy for OLTP
autovacuum_vacuum_threshold = 50
autovacuum_analyze_scale_factor = 0.005
autovacuum_analyze_threshold = 50
autovacuum_naptime = 15     # seconds between checks (default 60)

# Resource usage
autovacuum_max_workers = 4
autovacuum_work_mem = 256MB  # per worker
vacuum_cost_limit = 2000     # higher = less throttling

# Aggressive cleanup
autovacuum_vacuum_insert_threshold = 1000   # PG14+
```

### Per-Table Tuning

```sql
-- Aggressive vacuum on high-churn tables
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.005,
    autovacuum_vacuum_threshold = 100,
    autovacuum_vacuum_cost_limit = 2000
);

-- Relaxed vacuum on static tables
ALTER TABLE lookup_codes SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_vacuum_threshold = 10000,
    autovacuum_analyze_scale_factor = 0.1
);
```

### Manual Vacuum Commands

```sql
-- Standard vacuum
VACUUM (VERBOSE, ANALYZE) orders;

-- Free up space to OS (locks table exclusively)
VACUUM (FULL, VERBOSE) orders;

-- Aggressive freeze for transaction ID wraparound prevention
VACUUM (FREEZE, VERBOSE) orders;
```

### Monitoring Vacuum Activity

```sql
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / nullif(n_live_tup + n_dead_tup, 0) * 100, 2) AS dead_pct,
       last_vacuum, last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY dead_pct DESC;
```

---

## Table Partitioning

### Range Partitioning (Common for Time-Series)

```sql
CREATE TABLE orders (
    id bigserial NOT NULL,
    created_at timestamptz NOT NULL,
    data jsonb
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2026_01 PARTITION OF orders
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE orders_2026_02 PARTITION OF orders
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE orders_2026_03 PARTITION OF orders
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE orders_default PARTITION OF orders DEFAULT;
```

### List Partitioning

```sql
CREATE TABLE tenants (
    id int NOT NULL,
    region text NOT NULL
) PARTITION BY LIST (region);

CREATE TABLE tenants_na PARTITION OF tenants FOR VALUES IN ('US', 'CA', 'MX');
CREATE TABLE tenants_eu PARTITION OF tenants FOR VALUES IN ('GB', 'DE', 'FR', 'ES');
CREATE TABLE tenants_apac PARTITION OF tenants FOR VALUES IN ('JP', 'KR', 'AU', 'SG');
CREATE TABLE tenants_other PARTITION OF tenants DEFAULT;
```

### Hash Partitioning

```sql
CREATE TABLE events (
    id bigserial NOT NULL,
    payload text
) PARTITION BY HASH (id);

CREATE TABLE events_0 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE events_1 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE events_2 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE events_3 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Partition Maintenance

```sql
-- Detach old partition (keeps data, removes from parent)
ALTER TABLE orders DETACH PARTITION orders_2020_01;

-- Attach existing table as partition
ALTER TABLE orders ATTACH PARTITION orders_2026_04
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

-- Drop old partition (irreversible!)
DROP TABLE orders_2020_01;
```

### Partition Pruning

Ensure `enable_partition_pruning = on` (default). Verify with `EXPLAIN`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01';
-- Only scans relevant partitions
```

---

## Backup & Restore Best Practices

### Strategy

| Type | Frequency | Retention | Tool |
|------|-----------|-----------|------|
| Base backup (full) | Daily | 7-14 days | `pg_basebackup` or `pg_dump -Fc` |
| WAL archiving | Continuous | Until base backup pruned | Archive command |
| Logical dump | Weekly | 1 month (for schema recovery, selective restore) | `pg_dump --format=custom` |

### pg_dump Best Practices

```powershell
# Custom format — supports parallel restore, selective restore
pg_dump -h localhost -U postgres -Fc -Z 9 -j 4 --no-owner --no-privileges -f backup.dump mydb

# Directory format — parallel dump
pg_dump -h localhost -U postgres -Fd -j 4 --no-owner --no-privileges -f backup_dir mydb

# With exclude
pg_dump -h localhost -U postgres -Fc --exclude-table=temp_logs --exclude-table=audit_trail -f backup.dump mydb
```

### pg_restore Best Practices

```powershell
# Parallel restore (best with -Fc or -Fd)
pg_restore -h localhost -U postgres -d mydb -j 4 --no-owner --no-privileges --exit-on-error backup.dump

# Selective restore (specific tables)
pg_restore -h localhost -U postgres -d mydb --table=users --table=orders backup.dump

# List contents without restoring
pg_restore --list backup.dump > restore_list.txt
```

### Integrity Verification

```powershell
# Option 1: Restore to temp database
createdb verify_mybackup
pg_restore -d verify_mybackup backup.dump
pg_dump -d verify_mybackup --schema-only | diff - mydb_schema.sql

# Option 2: pg_checksums (needs checksums enabled)
pg_checksums --check --pgdata=D:\pgdata\16\data

# Option 3: Custom verify script
pg_restore --list backup.dump | Select-String -Pattern "^[0-9]+; " | Measure-Object | % { "$($_.Count) objects" }
```

### RPO/RTL Goals

| Tier | RPO | RTL | Method |
|------|-----|-----|--------|
| Bronze | 24h | 4h | Daily pg_dump |
| Silver | 1h | 1h | pg_basebackup daily + WAL streaming |
| Gold | <5m | 15m | Streaming replication + WAL archiving |
| Platinum | <1s | 5m | Synchronous replication + PgBouncer + HA orchestration |

---

## Diagnostics Views

```sql
-- Current activity
SELECT pid, state, query_start, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Blocked queries
SELECT blocked.pid AS blocked_pid, blocker.pid AS blocker_pid,
       blocked.query AS blocked_query, blocker.query AS blocker_query
FROM pg_locks blocked
JOIN pg_locks blocker ON blocked.transactionid = blocker.transactionid
    AND blocked.pid != blocker.pid
WHERE NOT blocked.granted;

-- Table sizes
SELECT relname, n_live_tup, n_dead_tup,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- Index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read,
       idx_tup_fetch, pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```
