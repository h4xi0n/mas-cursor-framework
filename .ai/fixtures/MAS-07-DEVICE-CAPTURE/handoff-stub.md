# Handoff stub — MAS-07-DEVICE-CAPTURE

Synthetic handoff inputs for connected-device capture dogfood when live device unavailable.

## Pre-requisites

1. Copy `design-spec-stub.md` → `.ai/context/design-specs/MAS-07-DEVICE-CAPTURE.md`
2. Dev handoff declares `UI_CHANGES: YES` and documents Launch Recipe

## Dev handoff flags (full `/mas`)

```
TASK_ID: MAS-07-DEVICE-CAPTURE
UI_CHANGES: YES
LAUNCH:
  package: com.example.dogfood
  deeplink-uri: myapp://fidelity/default
  post-launch-wait-ms: 2000
FILES:
  - app/src/main/java/com/example/dogfood/DeviceCaptureCard.kt
BRIEF_PATH: .ai/context/design-specs/MAS-07-DEVICE-CAPTURE.md
```

## Coordinator → mas-visual-fidelity handoff (expected)

```
TASK_ID: MAS-07-DEVICE-CAPTURE
TARGET_AGENT: mas-visual-fidelity
VISUAL_FIDELITY: auto
DEVICE_CAPTURE: yes
ADB_SERIAL: emulator-5554
MODEL_CLASS: normal
BRIEF_PATH: .ai/context/design-specs/MAS-07-DEVICE-CAPTURE.md
DELIVERABLE: Brief at .ai/context/visual-qa/MAS-07-DEVICE-CAPTURE.md
NEXT_AGENT: ux-intelligence
SPAWN_STATUS: spawned
```

## Visual fidelity flags (MAS-07)

| Flag | Effect |
|------|--------|
| `DEVICE_CAPTURE: yes` | Force tier-3 adb even if Paparazzi exists |
| `ADB_SERIAL: {serial}` | Multi-device override |
| `VISUAL_FIDELITY: auto` | Predicate: design-spec exists + `UI_CHANGES: YES` |
| `UI_CHANGES: NO` | Suppress spawn |

## Script dry-run validation (no device required)

```powershell
powershell -File skills/multi-agent-system/scripts/capture-connected-device.ps1 `
  -DryRun `
  -Package com.example.dogfood `
  -Deeplink "myapp://fidelity/default" `
  -Output ".ai/context/visual-qa/captures/MAS-07-DEVICE-CAPTURE/device-default.png" `
  -WaitMs 2000
```

## Degrade-path stubs

| Case | Setup | Expected behavior |
|------|-------|-------------------|
| No device | adb devices empty | Script exit 2; BLOCKED Implementation Capture |
| Multi-device, no serial | 2+ devices, no `ADB_SERIAL` | Script exit 3; BLOCKED brief |
| App not installed | Launch fails | Script exit 5; BLOCKED + HITL |
| Paparazzi exists + `DEVICE_CAPTURE: yes` | Override | Tier-3 script used |
| Dry-run | `-DryRun` flag | JSON stdout; exit 0 |

## Pre-install (dev or test-executor — not fidelity)

```bash
./gradlew :app:installDebug
```
