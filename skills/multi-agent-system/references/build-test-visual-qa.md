# Build, Test & Visual QA

Shared reference for Android Dev, Bug Fix, and Reviewer agents.
Read the sections relevant to the handoff.

## Gradle Build (Android)

Determine affected module(s) from changed file paths (e.g. `:app`, `:videoeditorsdk`).

**Minimum before Reviewer approval:**

```bash
./gradlew :<module>:compileDebugKotlin
```

**When UI, resources, manifest, or cross-module wiring changed:**

```bash
./gradlew :<module>:assembleDebug
```

**When handoff touches multiple modules** — compile each affected module or run:

```bash
./gradlew assembleDebug
```

Record exact command, exit code, and error summary. Build failure → **blocks approval**.

## Unit & Instrumentation Tests

**Android Dev** must add/update tests for non-trivial ViewModel, repository, or export logic.

**Reviewer** must run targeted tests when they exist for changed code:

```bash
./gradlew :<module>:testDebugUnitTest --tests "com.example.YourTest"
```

If test class unknown, run module unit tests:

```bash
./gradlew :<module>:testDebugUnitTest
```

For Compose UI changes on critical screens (when tests exist):

```bash
./gradlew :<module>:connectedDebugAndroidTest
```

**Device prep gate (MAS-07 v1.5.0):** Before any `connected*AndroidTest`, tier-3 `adb exec-out screencap`, or Maestro command, test-executor **Step 0** must run `android-device-prep.{ps1|sh}` and obtain PASS. Export `ANDROID_SERIAL` for Gradle/adb. Prep FAIL → skip device commands (avoid misleading AGP "no devices" traces). Enrollment: [device-prep-automation.md](device-prep-automation.md). test-run **Device** section records prep evidence for reviewer 0d-ext.

Only skip tests with explicit reason: `NOT_RUN — no tests exist for changed surface; recommend adding`.

Test failure → **blocks approval** unless handoff explicitly accepts debt with reason.

## Visual QA (Imagined — mandatory for UI work)

Reviewer and Android Dev **mentally render** the UI as a user would see it when no design-spec artifact exists. When design-spec exists, artifact-backed rules below apply.

### Artifact-backed Visual QA (MAS-06 — when design-spec exists)

| Condition | Visual QA behavior |
|-----------|-------------------|
| No design-spec | Imagined checklist (unchanged — below) |
| design-spec exists, **no** visual-qa brief | Layout/Typography/Color/Spacing imagined rows → **N/A** (cannot PASS on imagination) |
| visual-qa brief exists | P0/P1 sourced from brief at reviewer step **0k**; P2 polish rows remain imagined |

Reviewer **0k** consumes `.ai/context/visual-qa/{TASK_ID}.md` only — does not re-call Figma MCP or re-capture. Unresolved P0 `blocker` rows → `Approved: NO`. P1 PARTIAL → PASS with Major note on regions.

Standards: [visual-fidelity-standards.md](visual-fidelity-standards.md)

### When Visual QA applies

Any handoff that adds or changes: Composables, layouts, bottom sheets, timelines, overlays, export preview, recording UI, themes, dimensions, animations.

Skip only for pure logic/data changes with **no UI delta** — mark `N/A — no UI changes`.

### Visual QA checklist (imagine each)

| Check | Question to answer |
|-------|-------------------|
| **Layout** | Alignment, spacing, clipping, overflow on small + large width |
| **States** | Loading, empty, error, success — all visually distinct and on-brand |
| **Typography** | Uses theme styles; readable at default and large fontScale |
| **Color** | Theme tokens only; contrast sufficient; dark/light if supported |
| **Touch** | Targets ≥ 48dp; controls reachable in landscape |
| **Motion** | Animations purposeful; no jank triggers (heavy work in composition) |
| **Media/editor** | Preview matches export intent; overlays sized/positioned as designed |
| **Consistency** | Matches sibling screens (GIF vs sticker vs image overlay patterns) |
| **Insets** | System bars, IME, cutouts — content not hidden under bars |
| **Polish** | Would a PM ship this without visual tweaks? |

### Responsive imagination

Explicitly imagine at least three configurations:

1. **Compact phone** (portrait)
2. **Large fontScale** (accessibility)
3. **Landscape or expanded width** (tablet/foldable) — when layout is not trivial

Note breakage: truncated text, overlapping controls, unreachable buttons, wrong aspect preview.

### Visual QA output

Use **PASS / FAIL / N/A** per row. Any **FAIL** on layout, states, or consistency for user-facing UI → **Major** minimum; ship-blocking issues → **Critical**.

## Agent Responsibilities Summary

| Agent | Build | Tests | Visual QA |
|-------|-------|-------|-----------|
| **Android Dev** | Run compile on touched modules before DONE | Add + run unit tests for new logic | Document expected look in Responsive/Visual Notes |
| **Bug Fix** | Compile after patch | Run failing test + related suite | Re-imagine repro UI path after fix |
| **Reviewer** | Mandatory compile/assemble | Mandatory targeted or module tests | Mandatory imagined walkthrough for UI changes; **0k artifact-backed** when design-spec + visual-qa exist |
| **Planner** | Task: verify build in review phase | Task: test plan listed | Task: visual QA scenarios listed |
| **mas-visual-fidelity** | N/A (read-only) | N/A | P0 measurement + P1 screenshot compare → visual-qa brief; connected-device PNG from `capture-connected-device.{ps1\|sh}` is valid Implementation Capture source |

## Approval Blockers

Reviewer `Approved: YES` requires:

- Build: **PASS** (or NOT_RUN with valid reason for docs-only change)
- Tests: **PASS** (or NOT_RUN with explicit gap noted as Major if logic changed)
- Visual QA: **PASS** on all non-N/A rows (or N/A for non-UI handoffs)
- **Design fidelity (0k):** when design-spec exists for Figma-driven UI — `visual-qa` brief required; Implementation Capture paths non-empty (`paparazzi`, `compose-preview`, or `connected-device`); no unresolved P0 `blocker` rows
