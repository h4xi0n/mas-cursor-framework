# Design Spec — MAS-05-FIGMA-DOGFOOD (STUB)

> **Mock artifact** for schema validation and offline dogfood. Not extracted from live Figma MCP. Replace with mas-figma output when MCP available.

## Node Map

| node-id | name | type | x | y | width | height | parent-id |
|---------|------|------|---|---|--------|--------|-----------|
| 1:42 | DogfoodCard | FRAME | 0 | 0 | 360 | 120 | 0:1 |
| 1:43 | Title | TEXT | 16 | 16 | 200 | 24 | 1:42 |
| 1:44 | PrimaryButton | INSTANCE | 16 | 72 | 120 | 40 | 1:42 |

## Design Tokens

| figma token name | category | raw value | → intended MaterialTheme/CompositionLocal ref |
|------------------|----------|-----------|-----------------------------------------------|
| color/primary | color | #6750A4 | MaterialTheme.colorScheme.primary |
| spacing/md | spacing | 16px | LocalSpacing.md (CompositionLocal) |
| typography/title-medium | typography | 16/24 Medium | MaterialTheme.typography.titleMedium |

## Layout Spec

### node 1:42 — DogfoodCard (reference — not final code)

- Auto-layout: vertical
- Padding: 16px
- Gap: 8px
- Child nodes: Title (1:43), PrimaryButton (1:44)

### node 1:44 — PrimaryButton (reference — not final code)

- Variant: primary / enabled
- Height: 40px
- Corner radius: 20px

## Component Reuse Table

| figma node / mainComponentId | existing composable or theme token | source | reuse | regenerate |
|------------------------------|-------------------------------------|--------|-------|------------|
| 1:44 / btn-primary | PrimaryButton (repo-scan) | repo-scan (unverified) | reuse | — |

## Asset Manifest

| node-id | asset type | exported URL | intended drawable/resource | expiry flag |
|---------|------------|--------------|----------------------------|-------------|
| — | — | — | — | — |

## Screenshot Reference

- Path: `.ai/fixtures/MAS-05-FIGMA-DOGFOOD/screenshot-placeholder.png` (optional; omit if unavailable)
- node-id: `1:42`

## Open Questions

- [STUB] Mock brief for offline schema validation — not live MCP extraction.
- Verify mas-figma replaces this file on successful dogfood run.
