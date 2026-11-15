# Reviewer Lite (MAS Lite)

Minimal, token-frugal review gate when handoff has `REVIEWER_MODE: lite` or `MODE: LITE`. Aligns with the 3-Stage Adaptive Review Architecture in a single fast turn.

---

## Read Scope

- Handoff `FILES` and changed lines (diff scope)
- Profile tag `RP:` (or `REVIEW_PROFILE:` if set; defaults to `lite`)
- `memory.md` only if architecture check is required

**Do not read:** full `mas-reviewer` orchestrator, full domain profile directories, or master edge-case tables.

---

## 3-Stage Lightweight Execution

### Stage 1: Fast-Fail Mechanical Check
1. Call `ReadLints` on modified `FILES`.
2. Run compilation check on affected module (`mas-host-exec` or `./gradlew :module:compileDebugKotlin` / `npm run build`).
3. If build or linter fails $\rightarrow$ fast-fail immediately: `Approved: NO`, list raw compiler error, and finish with `DONE`.

### Stage 2: Targeted Domain Slice
- If `RP: bugfix` (or bug-fix chain): verify root cause is addressed and repro steps re-run; check for regression test. Add `Issue Resolved: YES | NO`.
- If `UI_CHANGES: YES`: one-paragraph imagined visual check (compact, fontScale, error state; no full matrix).
- If UX brief exists: **Interaction QA** per [ux-intelligence-standards.md](ux-intelligence-standards.md): one line (PASS/FAIL/N/A).
- If perf workflow (`optimizations/{TASK_ID}.md`): one line (PASS/FAIL/N/A). If **List Surface Decision** present, verify page size and frozen item UI.
- If osint workflow (`osint/{TASK_ID}.md`): one line (aligned/partial/diverged).
- If test strategy brief exists: one line (PASS/FAIL/N/A).
- If release fix chain (`release-readiness/{TASK_ID}.md`): one line (PASS/FAIL/N/A).

### Stage 3: Arbiter Synthesis & False-Positive Filter
- Apply 4 False-Positive Suppression Rules:
  - Anchor every blocker to `path/to/file.ext#Lxx-Lyy` with concrete trigger.
  - No NPE claims on non-nullable language types.
  - No missing symbol/import claims if Stage 1 compilation passed.
  - Cosmetic or styling feedback is `ADVISORY` only and never blocks approval.
- `Approved: YES` requires: Stage 1 PASS, 0 Critical, 0 Major findings (and `Issue Resolved: YES` for bug fixes).

---

## Output Template

```markdown
## Findings

Lint: Clean | <issues>
Build: PASS | FAIL | NOT_RUN
Tests: PASS | FAIL | NOT_RUN
Visual: N/A | OK | FAIL — <one line>
Interaction QA: N/A | PASS | FAIL — <one line when ux brief exists>
Performance: N/A | PASS | FAIL — <one line when perf chain>
Test Strategy: N/A | PASS | FAIL — <one line when test strategy brief exists>
OSS Alignment: N/A | aligned | partial | diverged — <one line when osint chain>
Release Readiness: N/A | PASS | FAIL | PARTIAL — <one line when release fix chain>

## Critical:
<[CRITICAL-01] path/to/file.ext#Lxx-Lyy — description with trigger | None>

## Major:
<[MAJOR-01] path/to/file.ext#Lxx-Lyy — description with trigger | None>

Approved: YES | NO

## Daily Summary
<one line, ≤120 chars — only when FILES non-empty>

DONE
```

Bug fix: add `Issue Resolved: YES | NO` one line under `## Findings`.
