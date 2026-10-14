# Visual QA — MAS-06-VFID-DOGFOOD (EXPECTED SHAPE)

> **Mock artifact** for schema validation. Copy to `.ai/context/visual-qa/MAS-06-VFID-DOGFOOD.md` for offline reviewer 0k dogfood.

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
| node-id | 2:10 |
| path | `.ai/fixtures/MAS-06-VFID-DOGFOOD/screenshot-placeholder.png` |
| captured-at | 2026-09-28 |

> [STUB] MCP blocked for offline validation — committed PNG trusted per `BASELINE_STALE: no`.

## Implementation Capture

| Field | Value |
|-------|-------|
| path(s) | `app/src/test/snapshots/images/com.example.dogfood.FidelityCardPaparazziTest/fidelityCard_default.png` |
| capture-method | paparazzi |
| git-revision | stub (offline dogfood) |

## Measurement Diff

| property | expected | actual | delta | severity |
|----------|----------|--------|-------|----------|
| FidelityCard.width | 360 | 360 | 0 | — |
| FidelityCard.height | 800 | 800 | 0 | — |
| color/primary | #6750A4 | #6750A4 | 0 | — |
| PrimaryButton.height | 48 | 48 | 0 | — |
| spacing/md | 16px | 16px | 0 | — |

## Screenshot Compare

| Field | Value |
|-------|-------|
| result | PASS |
| regions[] | — (full frame match) |
| diff-artifact-path | — |

## Open Questions / Accepted Debt

- [STUB] Expected shape for offline schema validation — not live fidelity run.
- Reviewer should flag stub provenance before `Approved: YES` on Figma-driven UI.
