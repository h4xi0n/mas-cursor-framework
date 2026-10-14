# Design Spec — MAS-06-VFID-DOGFOOD (STUB)

> **Mock artifact** for MAS-06 schema validation and offline dogfood. Not extracted from live Figma MCP.

## Node Map

| node-id | name | type | x | y | width | height | parent-id |
|---------|------|------|---|---|--------|--------|-----------|
| 2:10 | FidelityCard | FRAME | 0 | 0 | 360 | 800 | 0:1 |
| 2:11 | Title | TEXT | 16 | 24 | 200 | 28 | 2:10 |
| 2:12 | Body | TEXT | 16 | 60 | 328 | 48 | 2:10 |
| 2:13 | PrimaryButton | INSTANCE | 16 | 720 | 328 | 48 | 2:10 |

## Design Tokens

| figma token name | category | raw value | → intended MaterialTheme/CompositionLocal ref |
|------------------|----------|-----------|-----------------------------------------------|
| color/primary | color | #6750A4 | MaterialTheme.colorScheme.primary |
| color/on-primary | color | #FFFFFF | MaterialTheme.colorScheme.onPrimary |
| spacing/md | spacing | 16px | LocalSpacing.md (CompositionLocal) |
| typography/title-large | typography | 22/28 Bold | MaterialTheme.typography.titleLarge |
| typography/body-medium | typography | 14/20 Regular | MaterialTheme.typography.bodyMedium |

## Layout Spec

### node 2:10 — FidelityCard (reference — not final code)

- Auto-layout: vertical
- Padding: 16px
- Gap: 12px
- Viewport frame: 360×800

### node 2:13 — PrimaryButton (reference — not final code)

- Variant: primary / enabled
- Height: 48px
- Corner radius: 24px

## Component Reuse Table

| figma node / mainComponentId | existing composable or theme token | source | reuse | regenerate |
|------------------------------|-------------------------------------|--------|-------|------------|
| 2:13 / btn-primary | PrimaryButton (repo-scan) | repo-scan (unverified) | reuse | — |

## Asset Manifest

| node-id | asset type | exported URL | intended drawable/resource | expiry flag |
|---------|------------|--------------|----------------------------|-------------|
| — | — | — | — | — |

## Screenshot Reference

- Path: `.ai/fixtures/MAS-06-VFID-DOGFOOD/screenshot-placeholder.png` (optional; omit if unavailable)
- node-id: `2:10`
- captured-at: 2026-09-28 (stub)

## Verification Contract

| Field | Value |
|-------|-------|
| Viewport | 360×800 @ mdpi; density 1.0; fontScale 1.0 (default) |
| default state-id | `default` |
| Capture Recipe | Paparazzi: `com.example.dogfood.FidelityCardPaparazziTest#fidelityCard_default`; Preview: `@Preview(name = "FidelityCardDefault")` |
| Baseline Policy | `re-fetch` (default) |
| Tolerance | Dimension px slack: 2; color/token: exact |
| Metric Keys | Node Map width/height columns; Design Tokens color/spacing/typography |

### Gradle command fixtures (target Android repo only)

```bash
./gradlew :app:verifyPaparazziDebug --tests "com.example.dogfood.FidelityCardPaparazziTest"
./gradlew :app:validateDebugScreenshotTest
./gradlew :app:compileDebugKotlin
```

## Open Questions

- [STUB] Mock brief for MAS-06 offline schema validation — not live MCP extraction.
- Verification Contract included for P0-6 dogfood predicate testing.
