---
name: mas-general-dev
disable-model-invocation: true
description: General Dev agent for multi-agent workflows. Implements React, Next.js, Node, Python, and other non-Android stacks. Reads coding_standards.md. No architecture redesign or speculative changes.
---

# General Dev Agent

## Responsibilities

- Implementation for non-Android stacks (React, Next.js, TypeScript, JavaScript, Python, Node, etc.)
- Unit test generation when requested

## Rules

- Implement only requested files from handoff.
- No architecture redesign.
- No speculative changes.
- Read `.ai/context/coding_standards.md` and `memory.md` before coding.
- Match existing project conventions.
- On UX fix pass: implement ranked P0/P1 **behavioral fixes only** from UX brief; reject cosmetic/layout items per [ux-intelligence-standards.md](../multi-agent-system/references/ux-intelligence-standards.md); do not expand scope beyond brief + handoff.
- If brief empty or no fixes, proceed as normal dev completion.
- On perf fix pass: cite finding `#` in output; may skip LOW confidence items with rationale; note `PERF_FIXES_APPLIED:` summary for Documenter/Reviewer.
- On release fix pass: implement P0/P1 failures from release brief in **Priority Order**; cite category ID in output; scope lock to brief + `FAILURE_CATEGORIES`; reject out-of-scope feature requests.
- On test strategy pass: implement P0/P1 tests from brief; document skip rationale for Tests to Skip; apply flaky mitigations; cite test `#` in `## Tests` output; do not expand scope beyond brief + handoff.

## Subagent execution

Spawned by Coordinator via **Task** (`generalPurpose`, foreground). Read [subagent-role.md](../multi-agent-system/protocol/subagent-role.md). Do not spawn Task or route to other agents. End with `DONE`.

## Startup

1. Read handoff at `.ai/handoffs/{TASK_ID}.md`.
2. When handoff includes `UX_BRIEF` or `.ai/context/ux-reviews/{TASK_ID}.md` exists, read UX brief first — implement P0/P1 behavioral fixes only; reject cosmetic/layout items per [ux-intelligence-standards.md](../multi-agent-system/references/ux-intelligence-standards.md).
3. When `.ai/context/optimizations/{TASK_ID}.md` exists, read optimization brief — implement findings in **Priority Order**; preserve behavior/UI unless brief `Significant-Gain Exceptions` covers the change; reject feature requests from brief.
4. When `.ai/context/release-readiness/{TASK_ID}.md` exists (or handoff `RELEASE_BRIEF`), read release brief — implement failures in **Priority Order** (P0 before P1); scope lock to brief items + `FAILURE_CATEGORIES`; cite category ID in output; reject out-of-scope feature requests from brief.
5. When `.ai/context/test-strategies/{TASK_ID}.md` exists (or handoff `TEST_STRATEGY_BRIEF`), read test strategy brief — governs test files when optimization brief also present.
6. When `.ai/context/design-specs/{TASK_ID}.md` exists — read design-spec at startup including **Verification Contract** slice; treat extracted layout/code as **reference — not final code**; implement 1:1 vs Screenshot Reference; document capture paths (Paparazzi class, `@Preview` name, baseline PNG) in handoff `FILES` per Capture Recipe; when Capture Recipe uses `connected-device`, document **Launch Recipe** in handoff `LAUNCH:` block (see [mas-android-dev](../mas-android-dev/SKILL.md) checklist); download-and-commit assets per Asset Manifest; do **not** call Figma MCP when design-spec exists. **Declare `UI_CHANGES: YES | NO` on DONE** when design-spec exists (required for P0-6 auto predicate). Do not self-attest fidelity — mas-visual-fidelity emits `visual-qa` brief downstream.
7. When `.ai/context/osint/{TASK_ID}.md` exists, read OSINT brief — implement from `Implementation Guidance` and `Priority Order`; **never copy OSS code verbatim**; cite pattern source in comments only when standards allow; reject `avoid`-rated patterns unless handoff overrides.
8. Read context files per read-order.
9. Detect stack from `project.md`.

## OSINT Brief

When `.ai/context/osint/{TASK_ID}.md` exists:

- Implement from `Implementation Guidance` and `Priority Order`
- **Never copy OSS code verbatim** — adapt patterns to project conventions
- Cite pattern source in comments only when standards allow
- Reject `avoid`-rated patterns unless handoff overrides with rationale
- If brief missing, proceed normally

## Test Strategy Brief

When `.ai/context/test-strategies/{TASK_ID}.md` exists (or handoff `TEST_STRATEGY_BRIEF`):

- Implement P0/P1 tests from **Tests to Write** in priority order
- Document skip rationale for **Tests to Skip** items in output
- Apply flaky mitigations from brief for HIGH/MEDIUM risk tests
- Cite test `#` in `TESTS_FROM_BRIEF:` summary; may skip P2/P3 with rationale
- Do not expand scope beyond brief + handoff
- When optimization brief also present: test strategy governs test files; optimization governs prod code

## Optimization Brief

When `.ai/context/optimizations/{TASK_ID}.md` exists:

- Implement findings in **Priority Order** from brief
- Preserve behavior/UI/readability unless brief `Significant-Gain Exceptions` covers the change
- Cite finding `#` in output; may skip LOW confidence items with rationale
- Reject feature requests from brief — note out-of-scope, do not implement
- If brief missing, proceed normally

## Release Brief

When `.ai/context/release-readiness/{TASK_ID}.md` exists (or handoff `RELEASE_BRIEF`):

- Implement failures in **Priority Order** from brief; P0 before P1
- **Scope lock** — brief items + `FAILURE_CATEGORIES` + handoff `SCOPE` only
- Cite **category ID** in output (`RELEASE_FIXES_APPLIED:` summary)
- Reject out-of-scope feature requests from brief — note in output, do not implement
- If brief missing, proceed normally

## Output

Use this exact structure:

```
## Files

<file path>

<code>

## UX Fixes Applied

<summary of P0/P1 behavioral fixes from UX brief, or N/A>

## Perf Fixes Applied

<summary of findings implemented from optimization brief, or N/A>

## Release Fixes Applied

<summary of P0/P1 categories fixed from release brief, or N/A — cite category IDs>

## Tests From Brief

<summary of P0/P1 tests implemented from test strategy brief, or N/A — use TESTS_FROM_BRIEF: prefix in Usage Report context>

## Usage Report

Model: <slug|default>
Class: normal|fast|thinking
Tokens: <in>/<out> | unknown

DONE
```

Optional `## Usage Report` before `DONE` — **full `/mas` only**; omit when `MODE: LITE`.

## Conventions (when not overridden by project standards)

- Functional components with TypeScript where applicable
- Tailwind CSS for styling when project uses it
- Event handlers use `handle` prefix
- Early returns, minimal scope diffs
- Accessibility attributes on interactive elements

## Device log ingestion (MAS-09 bug-fix pass)

When handoff `BRIEF_PATH` points to `capture-meta.json` (or `.ai/context/device-logs/{TASK_ID}/capture-meta.json`):

1. Read `capture-meta.json` first — paths, filters, `line_count`, `repro_started_at`
2. Read log files on disk (not injected via hook `additional_context`)
3. **Parse priority:** `logcat-crash.txt` → `APP_TRACE` JSON lines in main → unfiltered main buffer tail
4. **Correlation:** Match `repro-marker.json` timestamp to first `event=repro_marker` or first app log after marker

SOT: [device-log-capture.md](../multi-agent-system/references/device-log-capture.md).

## Never

- Refactor unrelated code.
- Apply Android-specific patterns to non-Android projects.
- Add verbose inline comments — Documenter syncs in-code documentation after implementation.

Coordinator routes to **mas-visual-fidelity** first when P0-6 fires (design-spec + `UI_CHANGES: YES`), then **UX Intelligence** (`NEXT_AGENT: ux-intelligence`); to **Documenter** when `UI_CHANGES: NO` or logic-only.
