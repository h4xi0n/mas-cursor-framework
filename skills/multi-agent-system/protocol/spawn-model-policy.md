# Spawn Model Policy

Maps specialist agent slugs to `MODEL_CLASS` and Cursor Task `model` hints. Coordinator resolves on every spawn.

## Resolution order

1. Handoff `MODEL_CLASS:` (full `/mas`) or lite `MC:` abbreviation
2. Default table below (this file)
3. Task spawn with `model: default` if hint unsupported

Record resolved `model_class` via `record-workflow-step.ps1 -ModelClass`.

## Default map

| Agent slug | `MODEL_CLASS` | Task `model` hint |
|------------|---------------|-------------------|
| osint | `fast` | `composer-2.5-fast` |
| imaginer | `fast` | `composer-2.5-fast` |
| documenter | `fast` | `composer-2.5-fast` |
| spec-reader | `fast` | `composer-2.5-fast` |
| token-auditor | `fast` | `composer-2.5-fast` |
| planner | `normal` | default / `composer-2.5` |
| brainstorm | `normal` | default / `composer-2.5` |
| test-strategy | `normal` | default / `composer-2.5` |
| ux-intelligence | `normal` | default / `composer-2.5` |
| android-dev | `normal` | default / `composer-2.5` |
| general-dev | `normal` | default / `composer-2.5` |
| bug-fix | `normal` | default / `composer-2.5` |
| perf-optimizer | `normal` | default / `composer-2.5` |
| release-readiness | `normal` | default / `composer-2.5` |
| commit | `normal` | default / `composer-2.5` |
| coordinator | `normal` | inline routing only — not Task-spawned |
| architect | `thinking` | `claude-opus-4-7-thinking-high` or latest thinking-high family |
| reviewer | `thinking` | `claude-opus-4-7-thinking-high` or latest thinking-high family |
| debate-synthesizer | `thinking` | `claude-opus-4-7-thinking-high` or latest thinking-high family |

Lite Reviewer with `REVIEWER_MODE: lite` may use `fast` when Coordinator sets `MC: fast` on handoff.

## Override rules

| Field | Full `/mas` | Lite |
|-------|-------------|------|
| Model class | `MODEL_CLASS: fast \| normal \| thinking` | `MC: fast \| normal \| thinking` |
| Example | `MODEL_CLASS: thinking` on architect handoff | `MC: fast` on osint handoff |

Coordinator passes Task `model` only when Cursor supports the hint for the selected slug. On rejection or unsupported slug:

- Spawn with default model
- Record `model: default` and `model_class` per policy table in session step

## Lite cross-reference

Lite handoffs use `MC:` instead of `MODEL_CLASS:` — see [handoff-format-lite.md](handoff-format-lite.md).

## Related

- [subagent-spawn.md](subagent-spawn.md) — Task prompt and spawn sequence
- [workflow-usage-policy.md](workflow-usage-policy.md) — `model_class` telemetry
