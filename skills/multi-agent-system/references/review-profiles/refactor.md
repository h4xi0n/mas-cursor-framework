# Review Profile: Refactor & Optimization (`refactor`)

Specialized domain checklist for reviewing code reorganizations, structural refactoring, and performance optimizations.

---

## Invariants

1. **Behavioral Invariance:** Refactoring must preserve 100% of external functional behavior. Pure refactoring PRs must introduce zero functional alterations.
2. **Zero API Contract Drift:** Public class names, interface signatures, JSON schemas, route endpoints, and serialized DTO formats must remain strictly identical.
3. **Test Suite Parity:** Existing unit and integration tests must pass without weakening assertions, deleting test cases, or introducing `@Ignore` annotations.
4. **Performance Regression Defense:** Refactored algorithms and data structures must not introduce memory regressions ($O(N^2)$ loops, memory leaks). For list surfaces, page sizes and windowed containers must strictly match the optimization brief decision.
5. **No Scope Creep:** Cleanups must be scoped strictly to the target module or subsystem without speculative edits across unrelated packages.

---

## Domain Checklist

Evaluate each item as `PASS`, `FAIL`, or `N/A`:

| Check Item | Requirement | Status | Notes |
|---|---|:---:|---|
| **Behavioral Invariance** | External behavior, return values, and side effects unchanged. | | |
| **Zero Contract Drift** | Public API signatures and wire formats remain 100% stable. | | |
| **Test Parity** | Existing tests pass unmodified; no weakened assertions. | | |
| **Performance Budgets** | Memory, execution time, and recomposition count within budget. | | |
| **List Surface Decision** | Page size, paging strategy, and frozen row UI respected. | | |
| **Scope Containment** | Only target files modified; no opportunistic drive-by edits. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: refactor)`:

```markdown
## Refactor & Behavioral Invariance Verification

| Check | Status | Notes |
|-------|:------:|-------|
| Behavioral Invariance | PASS / FAIL | <functional parity check> |
| Zero Contract Drift | PASS / FAIL | <API signature diff> |
| Test Suite Parity | PASS / FAIL | <test assertion stability> |
| Performance Invariants | PASS / FAIL | <metric comparison vs baseline> |
| List Surface Decision (if applicable) | PASS / FAIL / N/A | <page size and item UI check> |
```
