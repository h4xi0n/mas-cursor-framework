# API Contract Brief — MAS-04-FIX-P0-ALL

**TASK_ID:** MAS-04-FIX-P0-ALL  
**MODE:** FULL (dogfood P0 spawn validation)  
**SCOPE:** REST/BFF  
**Audited:** 2026-07-28  
**Confidence:** HIGH (static spec inventory); N/A (breaking diff / drift — no baseline or handlers)

## Spec Inventory

| Spec | Version | Endpoints/Types | Notes |
|------|---------|-----------------|-------|
| `.ai/fixtures/MAS-04-FIX-P0-ALL/openapi.yaml` | OpenAPI **3.0.0**; `info.version` **1.0.0** | **1** path, **1** operation, **0** component schemas | Synthetic dogfood stub — satisfies `API_CONTRACT: yes` + OpenAPI in `FILES` predicate |

### Endpoint catalog

| Method | Path | operationId | Summary | Responses | Request body | Security |
|--------|------|-------------|---------|-----------|--------------|----------|
| `GET` | `/health` | *(missing)* | Health check | `200` — description only (`OK`) | — | — |

### Structural inventory

| Element | Present | Detail |
|---------|---------|--------|
| `openapi` | yes | `3.0.0` |
| `info.title` | yes | `Dogfood API` |
| `info.version` | yes | `1.0.0` |
| `servers` | no | No base URL declared |
| `paths` | yes | Single path `/health` |
| `components` / schemas | no | No reusable types |
| `security` / `securitySchemes` | no | Unauthenticated surface |
| `tags` | no | — |
| External `$ref` | no | Self-contained; no transitive spec imports |

### Lint / completeness (advisory)

| Check | Status | Note |
|-------|--------|------|
| Valid OpenAPI 3.0 skeleton | PASS | Parses as minimal valid document |
| Response `content` / schema | GAP | `200` has description only — no `application/json` body or schema |
| `operationId` | GAP | Missing — codegen and diff tools prefer stable IDs |
| `servers` | GAP | Missing — conformance tests need a declared base URL |
| Spectral / oasdiff CI | N/A | No prior spec or CI wiring in this TASK_ID |

## Breaking Changes

**Baseline:** None — first-party stub created for P0 quartet dogfood; no prior OpenAPI revision or live handler in `FILES` to diff.

| # | Change | Impact | Consumers | Severity |
|---|--------|--------|-----------|----------|
| — | *No breaking changes detected* | N/A | N/A | N/A |

**Forward-compat note:** When a real baseline exists, run oasdiff (or equivalent) against this stub or its successor before shipping API changes.

## Drift

**Spec vs implementation:** N/A — handoff `FILES` lists only the OpenAPI stub; no route handlers, BFF clients, or generated SDKs in scope.

| Surface | Spec | Implementation | Drift |
|---------|------|----------------|-------|
| `GET /health` | Declared | Not in `FILES` | **N/A** (spec-only dogfood) |

## Recommendations

| # | Item | Action | Priority |
|---|------|--------|----------|
| 1 | P0 spawn predicate | **accept** | P0 | Fixture is sufficient for `api-contract` coordinator routing validation |
| 2 | Response schema | **enhance** (future) | P2 | Add `content.application/json` with minimal schema (e.g. `{ "status": "ok" }`) before using as conformance target |
| 3 | `operationId` | **add** (future) | P2 | e.g. `getHealth` — stabilizes oasdiff and client codegen |
| 4 | `servers` | **add** (future) | P2 | Declare `url` (e.g. `http://localhost:8080`) for mock/conformance runners |
| 5 | CI contract gate | **document** (downstream) | P3 | When repos adopt real APIs: Spectral lint + oasdiff on PR; api-contract brief remains advisory |
| 6 | Handler pairing | **defer** | P3 | Re-audit with `RE_AUDIT: yes` when implementation files appear in handoff `FILES` |

## Validation (dogfood TASK_ID)

| Check | Result |
|-------|--------|
| `API_CONTRACT: yes` handoff received | PASS |
| OpenAPI in `FILES` audited | PASS |
| Brief written to `.ai/context/api-contracts/MAS-04-FIX-P0-ALL.md` | PASS |
| Code patches applied | **None** (advisory v1) |

## Usage Report

Model: composer-2.5  
Class: normal  
Tokens: unknown

DONE
