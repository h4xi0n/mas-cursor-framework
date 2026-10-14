# Design Spec — MAS-07-DEVICE-CAPTURE (STUB)

> **Mock artifact** for MAS-07 connected-device capture schema validation. Not extracted from live Figma MCP.

## Node Map

| node-id | name | type | x | y | width | height | parent-id |
|---------|------|------|---|---|--------|--------|-----------|
| 3:10 | DeviceCaptureCard | FRAME | 0 | 0 | 360 | 800 | 0:1 |
| 3:11 | Title | TEXT | 16 | 24 | 200 | 28 | 3:10 |
| 3:12 | Body | TEXT | 16 | 60 | 328 | 48 | 3:10 |

## Design Tokens

| figma token name | category | raw value | → intended MaterialTheme/CompositionLocal ref |
|------------------|----------|-----------|-----------------------------------------------|
| color/primary | color | #6750A4 | MaterialTheme.colorScheme.primary |
| spacing/md | spacing | 16px | LocalSpacing.md |

## Layout Spec

### node 3:10 — DeviceCaptureCard (reference — not final code)

- Auto-layout: vertical
- Padding: 16px
- Viewport frame: 360×800

## Component Reuse Table

| figma node / mainComponentId | existing composable or theme token | source | reuse | regenerate |
|------------------------------|-------------------------------------|--------|-------|------------|
| 3:10 | DeviceCaptureCard | repo-scan (unverified) | reuse | — |

## Asset Manifest

| node-id | asset type | exported URL | intended drawable/resource | expiry flag |
|---------|------------|--------------|----------------------------|-------------|
| — | — | — | — | — |

## Screenshot Reference

- Path: `.ai/fixtures/MAS-07-DEVICE-CAPTURE/screenshot-placeholder.png` (optional)
- node-id: `3:10`
- captured-at: 2026-09-28 (stub)

## Verification Contract

| Field | Value |
|-------|-------|
| Viewport | 360×800 @ mdpi; density 1.0; fontScale 1.0 (default) |
| default state-id | `default` |
| Capture Recipe | `connected-device` |
| Baseline Policy | `re-fetch` (default) |
| Tolerance | Dimension px slack: 2; color/token: exact |
| Metric Keys | Node Map width/height columns; Design Tokens color/spacing |

### Launch Recipe

| Field | Value |
|-------|-------|
| package | `com.example.dogfood` |
| deeplink-uri | `myapp://fidelity/default` |
| action | `android.intent.action.VIEW` |
| post-launch-wait-ms | `2000` |
| clear-task | `false` |
| state-id | `default` |

### Device Target

| Field | Value |
|-------|-------|
| adb-serial | `emulator-5554` (when multi-device) |
| form-factor | `phone` |
| orientation | `portrait` |

### Pre-Capture

| Field | Value |
|-------|-------|
| fontScale | — |
| uiMode | — |
| hide-system-bars | `false` |

### Output Path

| Field | Value |
|-------|-------|
| path | `.ai/context/visual-qa/captures/MAS-07-DEVICE-CAPTURE/device-default.png` |

## Open Questions

- [STUB] Mock brief for MAS-07 offline schema validation — deeplink populated by dev; mas-figma would emit `TBD` placeholder.
- Auth state for deeplink launch may require test account — document in dev handoff.
