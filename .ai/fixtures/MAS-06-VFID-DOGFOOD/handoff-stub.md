# Handoff stub — MAS-06-VFID-DOGFOOD

Synthetic handoff inputs for post-dev visual-fidelity dogfood when live Figma MCP or Android capture infra is unavailable.

## Pre-requisites

1. Copy `design-spec-stub.md` → `.ai/context/design-specs/MAS-06-VFID-DOGFOOD.md`
2. Dev handoff declares `UI_CHANGES: YES` and documents capture paths in `FILES`

## Dev handoff flags (full `/mas`)

```
TASK_ID: MAS-06-VFID-DOGFOOD
UI_CHANGES: YES
FILES:
  - app/src/main/java/com/example/dogfood/FidelityCard.kt
  - app/src/test/java/com/example/dogfood/FidelityCardPaparazziTest.kt
BRIEF_PATH: .ai/context/design-specs/MAS-06-VFID-DOGFOOD.md
```

## Coordinator → mas-visual-fidelity handoff (expected)

```
TASK_ID: MAS-06-VFID-DOGFOOD
TARGET_AGENT: mas-visual-fidelity
VISUAL_FIDELITY: auto
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/design-specs/MAS-06-VFID-DOGFOOD.md
DELIVERABLE: Brief at .ai/context/visual-qa/MAS-06-VFID-DOGFOOD.md
NEXT_AGENT: ux-intelligence
SPAWN_STATUS: spawned
```

## Visual fidelity flags (full `/mas`)

| Flag | Effect |
|------|--------|
| `VISUAL_FIDELITY: yes` | Force spawn |
| `VISUAL_FIDELITY: auto` | Predicate: design-spec exists + `UI_CHANGES: YES` |
| `UI_CHANGES: NO` | Suppress spawn |
| `RE_VERIFY: yes` | Re-spawn after dev fix (iteration ≤ 2) |
| `BASELINE_STALE: no` | Trust committed design-spec PNG when MCP blocked |

## Lite handoff

```
VFID:y
```

Lite without `VFID:y` → skip spawn + warn "Figma fidelity unverified".

## Degrade-path stubs

| Case | Setup | Expected mas-visual-fidelity behavior |
|------|-------|--------------------------------------|
| MCP blocked | Network down; PNG age ≤ 7d + `BASELINE_STALE: no` | BLOCKED baseline note; P0 from metrics if extractable |
| No capture infra | Target project lacks Paparazzi/Preview | BLOCKED Implementation Capture; reviewer 0k FAIL |
| P0 blocker | Token mismatch in stub | Coordinator routes dev fix → `RE_VERIFY: yes` |
| Iteration cap | 2 failed iterations | User escalation with P0 table |
| Option 6 fallback | User accepts cap relief | test-executor visual section; no `get_screenshot` re-baseline |

## Capture command fixtures (target Android — contract shapes only)

MAS framework repo has **no Gradle modules**. Document for downstream projects:

```bash
# Priority 1 — Paparazzi
./gradlew :app:verifyPaparazziDebug

# Priority 2 — Compose Preview Screenshot Testing
./gradlew :app:validateDebugScreenshotTest

# Priority 3 — Emulator (manual)
adb exec-out screencap -p > capture.png
```

Test class / preview names must match Verification Contract in design-spec stub.
