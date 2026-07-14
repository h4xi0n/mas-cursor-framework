# Logic-First Brainstorm Standards

Product-level, industry-standard ideation **without UI** unless handoff sets `UI_SCOPE: ui-allowed`.

## Scope boundary

| In scope (default) | Out of scope (unless `UI_SCOPE: ui-allowed`) |
|--------------------|-----------------------------------------------|
| Domain model, entities, invariants | Composable layout, spacing, colors, typography |
| API contracts, DTOs, error codes | Screen wireframes, component trees |
| State machines, UiState *contracts* (fields/events) | Visual design, animations, theme tokens |
| Use cases, orchestration, side effects | Navigation graphs as UI structure |
| Concurrency, caching, offline, idempotency | Accessibility *visual* polish |
| Security, authz, PII, rate limits | Asset placement, icons, copy tone |
| Test strategy (unit/integration) | Compose/XML layout files |
| Performance budgets (logic layer) | Responsive breakpoints as UI work |
| Observability, feature flags, rollout | |

**UiState contract** = data shape + events + reducers intent — not how it is drawn.

## Industry-standard lenses

Apply what fits the stack (from `project.md`):

1. **SOLID / clean boundaries** — domain vs data vs presentation logic
2. **UDF / unidirectional flow** — events → reducer/use-case → state
3. **Repository pattern** — single source of truth, cache policy explicit
4. **Fail-safe** — explicit error taxonomy; no silent swallow
5. **Idempotency** — retries, duplicate taps, process death
6. **12-factor / cloud-native** — config externalized, stateless where possible
7. **API design** — REST/OpenAPI semantics, versioning, pagination
8. **Android** — coroutines + structured concurrency, Hilt scopes, WorkManager for deferrable work
9. **Testing pyramid** — domain/use-case tests first; UI last and only if handoff allows UI

## Product-quality bar

- **User outcome** stated in one sentence before options
- **Acceptance criteria** testable without pixels
- **Edge cases** table: empty, offline, timeout, permission denied, concurrent use
- **Rollback / feature flag** when risk is medium+
- **Observability**: what to log/metric without PII
- **Similar code** in repo — align with existing patterns (name 1–2 files)

## Option format

Each option: name, summary, pros, cons, risk (L/M/H), effort (S/M/L), fits memory? (Y/N).

End with **one recommended option** and why — not a vague "it depends."

## Brief file

Persist full brief to `.ai/context/brainstorms/{TASK_ID}.md` for Planner/Architect/Dev.
