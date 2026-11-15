# Review Profile: Backend & Data (`backend`)

Specialized domain checklist for reviewing backend services, server endpoints, repositories, and database migrations.

---

## Invariants

1. **Clean Architecture Layering:** Strict unidirectional boundaries between presentation/controller, domain/use-case, repository, and data source layers. Domain models must never expose database entities or HTTP DTOs.
2. **SQL Injection Defense:** All database queries must use prepared statements or ORM parameterization. Zero raw string concatenation in SQL queries.
3. **Database Migration Safety:** Migrations must be forward-only, non-destructive, and safely handle existing production data (no un-backfilled non-nullable columns without defaults).
4. **Mutative Idempotency:** Non-idempotent HTTP mutations (POST/PATCH) or payment/order transactions must accept and validate an idempotency key.
5. **Authorization & Tenant Isolation:** Every data access call must validate caller identity, RBAC permissions, and enforce multi-tenant account scoping.
6. **Exception & Driver Mapping:** Driver-level database exceptions (e.g. SQLiteConstraintException, PG DuplicateKey) must be translated into clean domain exceptions.

---

## Domain Checklist

Evaluate each item as `PASS`, `FAIL`, or `N/A`:

| Check Item | Requirement | Status | Notes |
|---|---|:---:|---|
| **Layering Integrity** | Presentation $\rightarrow$ Domain $\rightarrow$ Data; no reverse leakage. | | |
| **SQL Parameterization** | Prepared statements only; zero string interpolation in queries. | | |
| **Migration Safety** | Forward-only, rollback-safe, non-destructive schema changes. | | |
| **Idempotency Keys** | Mutative endpoints validate idempotency headers/tokens. | | |
| **Auth & Scoping** | Caller tenant and role verified before read or write operations. | | |
| **Error Handling** | Constraint/connection failures caught and mapped to domain errors. | | |
| **Resource Hygiene** | Connections, transactions, and streams deterministically closed. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: backend)`:

```markdown
## Backend Architecture & Data Verification

| Check | Status | Notes |
|-------|:------:|-------|
| Clean Architecture Layering | PASS / FAIL | <layer boundary check> |
| SQL Parameterization & Safety | PASS / FAIL | <query parameter analysis> |
| Migration Compatibility | PASS / FAIL / N/A | <schema evolution safety> |
| Idempotency & Concurrency | PASS / FAIL | <mutative key validation> |
| Auth & Tenant Scoping | PASS / FAIL | <security check> |
```
