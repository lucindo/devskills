Run a strict data review of code changes — find data-correctness, integrity, and migration-safety defects. Store-agnostic (relational or NoSQL). Reports a findings list; changes nothing.

When invoked, audit the code in scope against one question: **is the data correct, consistent, and well-modeled?** Not "can it be injected" (that's `/ds-security-review` — assume queries are parameterized here), not "is the query fast" (that's `/ds-perf-plan`; the line is *consequence* — a slow query is perf, a query that returns *wrong or duplicate data* is here), not general code logic (that's `/ds-bug-review`). Every finding names the concrete condition that produces wrong, lost, or inconsistent data; a "best practice" with no demonstrated hazard is noise. Adapt to the store — don't demand relational constructs from a document database. **Do not edit any files.** When a finding is confirmed, `/ds-verify-this` proves the fix against real before/after data.

## Arguments

- Treat positional args as scope (files, directories, globs — including schema and migration files). With no scope, review the code changed on the current branch.
- Freeform scope ("the orders schema", "the reporting queries") is interpreted reasonably.
- State the store/engine if you know it (Postgres, MySQL, SQLite, Mongo, DynamoDB…) — isolation defaults and SQL dialects differ. Otherwise infer from config/driver and **state the assumption**.

## What to check

**1. Schema & data modeling.** Missing constraints (`NOT NULL`, `FK`, `UNIQUE`, `CHECK`) that let invalid state exist; wrong types (money as float, naive timestamps without timezone, enums as free text, ids as nullable); normalization/denormalization that doesn't fit the access pattern; referential integrity gaps (deletes that orphan rows). NoSQL: embedding vs referencing for the read pattern, hot/low-cardinality partition keys, documents that grow without bound, multiple sources of truth that can diverge.

**2. Integrity & invariants.** Invariants the application *assumes* but only enforces in app code (so a concurrent path or a second writer breaks them) — uniqueness, sums that must reconcile, state machines. Prefer the store enforcing them (constraint, unique index) over a check-then-write that races.

**3. Query result correctness.** Wrong JOIN type silently dropping or duplicating rows; `NULL` semantics in `WHERE`/comparisons and aggregates (`NULL != NULL`, `COUNT(col)` skipping NULLs, `AVG`/`SUM` over NULLs); implicit type coercion; timezone/precision loss in aggregates; `LIMIT` without a total `ORDER BY` giving nondeterministic rows; pagination drift (OFFSET over a changing set).

**4. Transactions & consistency.** Multi-statement invariants not wrapped in a transaction (partial writes on failure); wrong or assumed isolation level (lost updates, non-repeatable reads, phantoms under the engine's *actual* default); read-modify-write races; cross-aggregate writes assuming atomicity a NoSQL store doesn't provide; eventual-consistency reads treated as strongly consistent.

**5. Migration safety.** Backward-incompatible schema changes deployed against running code (drop/rename a column the old version still reads); locking DDL on large tables (add-column-with-volatile-default, non-concurrent index build, type change that rewrites the table); non-idempotent migrations; backfills that are wrong, unbatched, or racy against live writes; missing or untested rollback path.

## Output

A prioritized findings list, ordered by severity (likelihood × impact):

1. **Critical** — silent data loss or corruption, or a migration that can lock/break production.
2. **Wrong results** — queries that return incorrect, duplicated, or missing data under normal use.
3. **Integrity gap** — an invariant the app assumes but the store doesn't enforce (breakable by a race or a second writer).
4. **Hardening** — a constraint or type that would prevent a class of future data bug, not yet causing one.

For each finding:

- Anchor to `file:line` (or the schema/migration file).
- State the hazard in one line, **name the exact condition or data that triggers wrong/lost/inconsistent data**, then the fix — prefer a store-enforced constraint over an app-side check when it removes a race.
- Give your confidence and state the store/engine assumption it rests on (isolation level, dialect).

Rules:

- Real data hazards only. Name the path to wrong, lost, or inconsistent data; a "weakness" with no such path is hardening at most.
- Store-agnostic: don't flag the absence of relational constructs in a document store — judge against *that* store's correctness model.
- A short, high-confidence list beats a long speculative one.
- Change nothing. The output is the list.
