---
name: db-migrations
description: Use when creating or modifying database schema, writing migrations, adding indexes, or changing columns/constraints. Enforces zero-downtime patterns and explicit rollback planning.
---

# Database schema & migrations

Hard rules:

1. **Additive first, destructive last.** Never rename or drop a column in the same deploy that changes code using it. Pattern: add new → dual-write → backfill → switch reads → remove old, across separate deploys.
2. **No table-locking migrations on large tables.** Use `CREATE INDEX CONCURRENTLY` (Postgres) or online DDL (MySQL). Never add a `NOT NULL` column with a default to a large table in one statement — add nullable, backfill in batches, then set `NOT NULL`.
3. **Backfill in batches.** Row-by-row or chunked. Never `UPDATE whole_table SET ...` on large tables.
4. **Separate migration from deploy.** Migration deploys first and must be safe with old app code still running. App deploys second.
5. **Rollback plan, written.** Every migration ships with: how to revert, what data would be lost, and whether revert is safe with current app code.
6. **Indexes have a reason.** Every new index references the query it speeds up. No speculative indexes.

Blockers:
- Do not write a migration without stating its rollback in a comment or PR description.
- Flag any migration that would lock writes for more than a second on production-sized data.
