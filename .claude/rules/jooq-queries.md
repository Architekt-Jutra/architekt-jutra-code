---
paths:
  - "src/main/java/**"
---

# jOOQ Queries

Generated classes live in `pl.devstyle.aj.jooq` and are rebuilt from the Liquibase changelog at `generate-sources`.

## jOOQ or JPA

| Use case | Tool |
|---|---|
| CRUD, entity relationships | JPA repository |
| Filtered/joined/aggregated reads, reports | jOOQ |
| Window functions, CTEs, bulk ops, DB-specific SQL | jOOQ |
| Authorization lookups needing a few columns | jOOQ |

Read services are named `Db*QueryService` (`DbProductQueryService`, `DbPluginObjectQueryService`), annotated `@Service`, take `DSLContext` via constructor injection, and mark methods `@Transactional(readOnly = true)`.

## Non-negotiable

- **Use the generated constants** (`PRODUCTS.NAME`), never string table/column names — string literals lose compile-time checking and survive schema changes silently.
- **Bind variables for every user-supplied value.** `.eq(email)` binds automatically. Never concatenate input into a condition string.
- **Any identifier that comes from a request** — sort column, filter key, JSON path — must be checked against an allowlist before it reaches the query. See `DbProductQueryService.ALLOWED_SORT_FIELDS`.
- **No N+1.** Load children with a JOIN or `multiset(...)`, never by looping parents and querying per row.
- **Project the columns you need.** `selectFrom(TABLE)` pulls everything; list the fields instead.

## Query rules

- `dsl.fetchExists(selectOne()...)` for existence checks — not `fetchCount(...) > 0`, which counts every match.
- `NOT EXISTS`, not `NOT IN`, whenever the subquery column is nullable — `NOT IN` returns zero rows if any value is NULL.
- Fix join duplicates with a semi-join (`whereExists`), not `SELECT DISTINCT`.
- `UNION ALL` unless you actually need duplicate elimination.
- Explicit `ORDER BY` when order matters; reference columns, never positional indexes.
- Explicit join conditions — no `NATURAL JOIN`, no `JOIN USING`.
- `.limit(n)` for top-N queries.

## Building queries

- Map results with `Records.mapping(SomeRecord::new)` or an explicit `fetch(r -> ...)` lambda into a record — that's how `DbProductQueryService` assembles `ProductResponse`.
- Dynamic filters: collect into `List<Condition>` and pass the list to `.where(conditions)`.
- Hold intermediate queries in `var`. Don't declare variables as jOOQ `*Step` interfaces and don't implement jOOQ DSL types — they're sealed and the type names shift between versions.
- Bulk writes go through `insertInto(...).valuesOfRows(...)` or `dsl.batch(...)`, not a loop of single inserts.
