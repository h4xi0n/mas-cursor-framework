# Review Profile: Bug Fix (`bugfix`)

Specialized domain checklist for reviewing bug fixes and defect remediations.

---

## Invariants

1. **Root Cause Depth:** The patch must fix the underlying root cause, not merely suppress, swallow, or mask the visible symptom.
2. **Repro Steps Re-Run:** The reviewer must trace the documented `REPRO_STEPS` on the patched code. The failure path must no longer execute.
3. **Automated Regression Test:** An automated unit or integration test reproducing the defect and asserting the fix is **mandatory**. If no test was added and no valid rationale was approved, emit `[MAJOR-01]`.
4. **Anti-Symptom-Masking:** Catching generic `Throwable`/`Exception` to silence crashes without proper state recovery or user feedback is strictly prohibited.
5. **Issue Resolved Gate:** `Approved: YES` requires `Issue Resolved: YES`.

---

## Domain Checklist

Evaluate each criterion as `PASS`, `FAIL`, or `N/A`:

| # | Check Item | Invariant Rule | Status | Notes |
|---|------------|----------------|--------|-------|
| 1 | **Root Cause Addressed** | Flaw resolved at the source; not caught/silenced at call site. | | |
| 2 | **Repro Steps Re-Run** | Original symptom cannot recur via documented trigger sequence. | | |
| 3 | **Regression Test Added** | Automated test covers defect scenario and asserts correct state. | | |
| 4 | **No Symptom Masking** | No empty catch blocks, fallback nulls, or hidden errors. | | |
| 5 | **Zero Behavioral Regression** | Unmodified functional paths remain intact and unimpacted. | | |
| 6 | **Edge States Covered** | Boundary conditions that triggered the bug are cleanly handled. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: bugfix)`:

```markdown
## Bug Resolution Verification

| Verification Item | Status | Evidence / Notes |
|-------------------|:------:|------------------|
| Root Cause Fixed | PASS / FAIL | <analysis of code mechanism> |
| Repro Steps Re-Run | PASS / FAIL | <trace outcome> |
| Regression Test | PASS / FAIL | <test class and method path> |
| No Symptom Masking | PASS / FAIL | <clean exception/state handling> |
| Zero Regressions | PASS / FAIL | <impact analysis> |

Issue Resolved: YES | NO
```

If `Issue Resolved: NO` → Mandates `Approved: NO` with actionable remediation for the remaining defect.
