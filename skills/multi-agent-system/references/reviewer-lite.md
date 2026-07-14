# Reviewer Lite (MAS Lite)

Minimal review when handoff has `REVIEWER_MODE: lite` or `MODE: LITE`.

## Read

- Handoff `FILES` only
- Changed files (diff scope)
- `memory.md` if architecture check needed

**Do not read:** full `mas-reviewer` workflow, `build-test-visual-qa.md` (unless UI_CHANGES: YES), edge-case master list.

## Steps (short)

1. ReadLints on `FILES`
2. If Android: `./gradlew :<module>:compileDebugKotlin` on affected module
3. Run tests only if handoff names them or logic clearly requires it
4. If UI_CHANGES: YES — one paragraph imagined visual check (no full table)
5. If `.ai/context/ux-reviews/{TASK_ID}.md` exists — **Interaction QA** per [ux-intelligence-standards.md](ux-intelligence-standards.md): PASS/FAIL/N/A one line (P0 fixes applied, no cosmetic drift)
6. If perf workflow: read `.ai/context/optimizations/{TASK_ID}.md` when present — add `## Performance Verification` one line (PASS/FAIL/N/A)
7. If osint workflow: read `.ai/context/osint/{TASK_ID}.md` when present — add `## OSS Alignment` one line (aligned/partial/diverged; license PASS/N/A)
8. If `.ai/context/test-strategies/{TASK_ID}.md` exists — add `## Test Strategy` one line (PASS/FAIL/N/A): P0 tests pass, skip rationale documented
9. If release fix chain: read `.ai/context/release-readiness/{TASK_ID}.md` when present — add `Release Readiness: N/A | PASS | FAIL | PARTIAL` one line
10. Compare one similar file if unclear

## Output

```
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

## Major:

Approved: YES | NO

## Daily Summary

<one line, ≤120 chars — only when FILES non-empty>
DONE
```

**YES** if: no critical/major, lint clean, build pass. Skip Documenter/edge-case tables.

Bug fix: add `Issue Resolved: YES | NO` one line under Findings.
