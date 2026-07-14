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

Only skip tests with explicit reason: `NOT_RUN — no tests exist for changed surface; recommend adding`.

Test failure → **blocks approval** unless handoff explicitly accepts debt with reason.

## Visual QA (Imagined — mandatory for UI work)

Reviewer and Android Dev **mentally render** the UI as a user would see it. No screenshot tool required — imagine from Compose tree, modifiers, theme, and similar screens.

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
| **Reviewer** | Mandatory compile/assemble | Mandatory targeted or module tests | Mandatory imagined walkthrough for UI changes |
| **Planner** | Task: verify build in review phase | Task: test plan listed | Task: visual QA scenarios listed |

## Approval Blockers

Reviewer `Approved: YES` requires:

- Build: **PASS** (or NOT_RUN with valid reason for docs-only change)
- Tests: **PASS** (or NOT_RUN with explicit gap noted as Major if logic changed)
- Visual QA: **PASS** on all non-N/A rows (or N/A for non-UI handoffs)
