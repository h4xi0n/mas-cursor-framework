# Review Profile: Feature Implementation (`feature`)

Specialized domain checklist for reviewing new features, multi-tier capabilities, and greenfield modules.

---

## Invariants

1. **PRD & Acceptance Completeness:** Every user story and Gherkin scenario defined in `.ai/context/prds/{TASK_ID}.md` (or plan brief) must have a corresponding, functional implementation.
2. **20-Point Edge Case Matrix:** The feature must account for core boundary conditions: empty states, network loss, concurrent mutations, cancellation, rapid double-tap, process death, and permission denials.
3. **Architectural Pattern Consistency:** New feature layers must match existing repository patterns (state hoisting, dependency injection, repository interfaces).
4. **Public API Documentation:** All newly introduced public classes, interfaces, and methods must have complete KDoc/TSDoc documentation. Internal trivial code must not contain redundant noise comments.
5. **No Regressions:** Implementation must not break existing test suites or diverge from established project standards.

---

## Domain Checklist: 20-Point Edge Case Matrix

| Category | Invariant Check | Status | Notes |
|---|---|:---:|---|
| **Data & Bounds** | Empty lists, 0-length strings, oversized payloads, unicode/emoji input. | | |
| **Network & I/O** | Offline mode, connection drop mid-request, 5xx server error, timeout. | | |
| **Concurrency** | Rapid tap debounce, racing async responses, state change after unmount. | | |
| **Lifecycle** | Screen rotation / configuration change, backgrounding, process death. | | |
| **Permissions** | Permission denied, permanent denial / "never ask again", revoked. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: feature)`:

```markdown
## PRD Acceptance & Edge Case Verification

| Check | Status | Notes |
|-------|:------:|-------|
| PRD Acceptance Scenarios | PASS / FAIL | <functional requirements coverage> |
| 20-Point Edge Case Matrix | PASS / FAIL | <boundary and error handling> |
| Pattern Consistency vs Codebase | PASS / FAIL | <architectural alignment> |
| Public API Documentation | PASS / FAIL | <KDoc/TSDoc completeness> |
| Error State Recovery | PASS / FAIL | <user-facing error UX> |
```
