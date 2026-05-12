---
name: db-sculptor
description: Design database schemas with Prisma/Drizzle
---


# DB Sculptor

Designs database schemas that perform. Based on PostgreSQL documentation, Oracle best practices (2026), Stormatics research, and production experience from PlanetScale and Neon.

## The Rule

Model for your access patterns first. Normalize later. A beautiful 3NF schema is useless if your queries are slow.

## Schema Design

- Every table needs a primary key (UUIDv7 sorts by time, unlike UUIDv4)
- Timestamps on every table: created_at, updated_at (let the DB set them)
- Soft deletes with deleted_at or a separate archive table
- Max 3 indexes per table for write-heavy workloads
- Consider partitioning for tables over 10M rows

## Naming

| Element | Convention | Example |
|---------|------------|---------|
| Tables | plural snake_case | users, order_items |
| Columns | singular snake_case | first_name |
| Foreign keys | {singular_table}_id | user_id |
| Indexes | idx_{table}_{column} | idx_users_email |

## Index Strategy

### B-tree (default)
Use for: equality, range, sort, join columns.

### Composite
Order columns by selectivity (most selective first).

### Partial
Only index rows you query often. Smaller index, faster writes.

### Covering (INCLUDE)
Avoids heap fetches. Use for read-heavy queries with small columns.

Source: PostgreSQL docs, Stormatics 2025, Oracle 2026.

## Migration Safety

- One migration per logical change
- Never edit committed migrations
- Backfill data in a separate migration from schema change
- Add columns as nullable first, then fill, then make NOT NULL
- Run migrations in transactions for multi-table changes

## Seed Data

- Factories with realistic data (not "John Doe", "test@test.com")
- At least 100 records to surface performance issues
- Idempotent seeds (can run multiple times without duplicates)

## Query Anti-Patterns

- N+1 queries (use JOIN or batch loading)
- SELECT * in production (name columns explicitly)
- UPDATE or DELETE without WHERE in a transaction
- Large IN clauses over 1000 items (use temp table or batch)

## Sources

- PostgreSQL Documentation (postgresql.org/docs)
- Oracle "PostgreSQL Best Practices" (2026)
- Stormatics "Composite and Partial Indexes" (2025)
- OneUptime "Database Indexing Strategy" (2026)
- BTH Sweden "Evaluating Composite B-tree Indexing" (peer-reviewed)







