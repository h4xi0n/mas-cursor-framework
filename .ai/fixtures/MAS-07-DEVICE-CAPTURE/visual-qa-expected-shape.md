# Visual QA — MAS-07-DEVICE-CAPTURE (EXPECTED SHAPE)

> **Mock artifact** for schema validation. Copy to `.ai/context/visual-qa/MAS-07-DEVICE-CAPTURE.md` for offline reviewer 0k dogfood.

## Viewport & State

| Field | Value |
|-------|-------|
| width | 360 |
| height | 800 |
| density | mdpi (1.0) |
| fontScale | 1.0 |
| uiMode | light |
| state-id | default |

## Baseline Source

| Field | Value |
|-------|-------|
| source | design-spec-png |
| node-id | 3:10 |
| path | `.ai/fixtures/MAS-07-DEVICE-CAPTURE/screenshot-placeholder.png` |
| captured-at | 2026-09-28 |

> [STUB] MCP blocked for offline validation — committed PNG trusted per `BASELINE_STALE: no`.

## Implementation Capture

| Field | Value |
|-------|-------|
| path(s) | `.ai/context/visual-qa/captures/MAS-07-DEVICE-CAPTURE/device-default.png` |
| capture-method | connected-device |
| adb-serial | emulator-5554 |
| git-revision | stub (offline dogfood) |
| width | 1080 |
| height | 2400 |
| timestamp | 2026-09-28T12:00:00.000Z |

## Measurement Diff

| property | expected | actual | delta | severity |
|----------|----------|--------|-------|----------|
| DeviceCaptureCard.width | 360 | 360 | 0 | — |
| DeviceCaptureCard.height | 800 | 800 | 0 | — |
| color/primary | #6750A4 | #6750A4 | 0 | — |
| spacing/md | 16px | 16px | 0 | — |

## Screenshot Compare

| Field | Value |
|-------|-------|
| result | PASS |
| regions[] | — (full frame match) |
| diff-artifact-path | — |

## Open Questions / Accepted Debt

- [STUB] Expected shape for offline schema validation — not live device capture.
- Status bar / nav bar visible in full-frame device capture may cause P1 PARTIAL per MAS-07 D5.
- Reviewer should flag stub provenance before `Approved: YES` on Figma-driven UI.
