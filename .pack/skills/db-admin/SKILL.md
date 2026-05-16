---
name: db-admin
description: PostgreSQL database administration — backup/restore (pg_dump, PITR, WAL archiving), health monitoring (connections, bloat, cache hit ratio, dead tuples), connection pooling (PgBouncer), replication (streaming, logical), vacuum/autovacuum tuning, and scheduled backups with retention. Use when user asks to backup a database, restore from backup, monitor database health, set up replication, or perform DBA tasks. Do NOT use for schema design (use db-sculptor), query optimization (use db-sculptor), or migration planning (use db-sculptor).
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: devops
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write
---

# Database Administrator

PostgreSQL production operations: backup, restore, monitoring, replication, and maintenance.

## Workflow

### Step 1: Run health check

```powershell
scripts/monitor-db.ps1 -Database myapp
```

Checks 7 metrics:
| Metric | Warning | Fail |
|--------|---------|------|
| Connection count | > 80% of max | > 95% of max |
| Active queries | > 10 | > 20 |
| Long-running (>5m) | Any | > 3 |
| Cache hit ratio | < 99% | < 95% |
| Dead tuple ratio | > 20% | > 40% |
| Index usage (unused) | > 5 | > 10 |

**If any metric is FAIL**: investigate immediately. See [references/postgres-admin.md](references/postgres-admin.md) for diagnosis and fix procedures.

### Step 2: Backup database

```powershell
# Full backup
scripts/backup-db.ps1 -Database myapp

# Custom output directory
scripts/backup-db.ps1 -Database myapp -OutputDir D:\backups

# Exclude large log tables
scripts/backup-db.ps1 -Database myapp -ExcludeTables @("audit_logs", "analytics_events")
```

The script creates: `myapp_2026-05-13_143022.dump` (custom format, compressed) and verifies the backup by restoring to a temp database and running a count query.

### Step 3: Set up scheduled backups

See [assets/backup-schedule-template.ps1](assets/backup-schedule-template.ps1) for the schedule template.

```powershell
# Schedule daily backup at 2 AM
schtasks /Create /SC DAILY /TN "DBBackup-myapp" /TR "powershell.exe -File C:\scripts\backup-schedule.ps1" /ST 02:00
```

**Retention policy:**
- Daily: keep 7
- Weekly: keep 4 (Sundays)
- Monthly: keep 3 (1st of month)

### Step 4: Configure connection pooling

```ini
# pgbouncer.ini for PostgreSQL pooling
[databases]
myapp = host=localhost port=5432 dbname=myapp

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = scram-sha-256
pool_mode = transaction
default_pool_size = 25
max_client_conn = 100
max_db_connections = 50
```

### Step 5: Set up replication (if needed)

See [references/postgres-admin.md](references/postgres-admin.md) for streaming and logical replication setup.

**Decision:**
| Need | Replication type |
|------|-----------------|
| Read scaling + HA | Streaming replication |
| Selective table sync | Logical replication |
| Upgrade with minimal downtime | Logical replication |
| Cross-version replication | Logical replication |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Backup fails with "out of memory" | Work_mem too high for dump | Reduce work_mem, increase maintenance_work_mem |
| PgBouncer rejects connections | pool_size exhausted | Increase default_pool_size, add more connections |
| Replication lag growing | WAL generation > apply rate | Add replicas, increase max_wal_size, tune apply workers |
| Long-running query blocking vacuum | snapshot held too long | Kill with pg_terminate_backend, tune idle_in_transaction_session_timeout |
| WAL directory filling disk | archive_command failing or wal_keep_size too high | Fix archiving, reduce wal_keep_size, increase max_wal_size |

## Production Checklist

- [ ] Automated daily backups with verification
- [ ] Retention policy configured (7 daily, 4 weekly, 3 monthly)
- [ ] PgBouncer with transaction pooling
- [ ] Monitoring dashboard (connection count, cache hit, bloat)
- [ ] Alerts for: connection > 80%, cache hit < 99%, replication lag > 60s
- [ ] Autovacuum tuned (scale_factor, threshold, naptime)
- [ ] WAL archiving for PITR
- [ ] Connection limits per database
- [ ] Statement timeout configured (30s default)
- [ ] Backups stored in different location than DB server

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| No automated backups | Schedule pg_dump with retention |
| No backup verification | Always restore-test backups |
| Default autovacuum settings | Tune for your workload |
| Direct connections in production | Always use PgBouncer |
| No replication monitoring | Check lag, WAL generation rate |
| Running out of disk for WAL | Monitor WAL directory, tune archiving |

## Sources

- PostgreSQL docs — Backup/Restore (postgresql.org/docs)
- PgBouncer documentation
- PostgreSQL wiki — Performance tuning
- WAL archiving and PITR guide
- Replication documentation
- pganalyze — Monitoring and tuning
