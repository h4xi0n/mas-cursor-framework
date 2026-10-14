# Figma Extraction Standards

Reference for [mas-figma](../../mas-figma/SKILL.md). Read-only extraction — design-spec brief output only.

## Inspect-first invariant

1. **Node Map** from `get_metadata` is the positional backbone — never skip.
2. **Whole-frame `get_design_context` is forbidden** — per chosen child node only.
3. Extracted MCP code is **reference — not final code**; dev re-maps to Compose/project tokens.

## MCP tool contract

| Tool | Purpose | Transport notes |
|------|---------|-----------------|
| `get_metadata` | Node Map (hierarchy, positions, dimensions) | Local or remote |
| `get_variable_defs` | Design token names and values | **Local desktop only** (`127.0.0.1:3845`) |
| `get_design_context` | Per-node layout/typography/variant structure | Requires `figma-design-to-code` prereq |
| `get_code_connect_map` | Component Reuse Table (verified mappings) | Optional — repo-scan fallback when absent |
| `get_screenshot` | Screenshot Reference for 1:1 validation | Local or remote |

## Prerequisite: figma-design-to-code

Before every `get_design_context` call, honor Cursor `figma-design-to-code` skill. Hint priority:

1. Code Connect mappings
2. Component documentation
3. Figma annotations
4. Design tokens / variables
5. Raw hex/px (last resort — flag in Open Questions)

## Design-spec brief sections

Path: `.ai/context/design-specs/{TASK_ID}.md`

| Section | Data shape |
|---------|------------|
| Node Map | `node-id \| name \| type \| x \| y \| width \| height \| parent-id` |
| Design Tokens | `figma token \| category \| raw value \| → MaterialTheme/CompositionLocal ref` |
| Layout Spec | Per-node: auto-layout, constraints, spacing, typography, variants — **reference — not final code** |
| Component Reuse Table | `figma node \| existing composable/token \| source (code-connect \| repo-scan) \| reuse \| regenerate` |
| Asset Manifest | `node-id \| type \| exported URL \| intended resource \| expiry flag` |
| Screenshot Reference | Saved image path + node-id |
| Open Questions | Ambiguities, blocked steps, transport/token flags, HITL |
| Verification Contract | Viewport, default `state-id`, Capture Recipe, Baseline Policy, Tolerance, Metric Keys — **input for mas-visual-fidelity**; overwritten on `RE_EXTRACT: yes` only |

Schema registry: [brief-schemas.md](../protocol/brief-schemas.md).

## Verification Contract template (§8 — mas-figma step 8)

Optional until P0-6 fires; **recommended always** for new extractions. Required when `design-spec` exists at fidelity gate. Do **not** store post-dev parity results here — parity lives in `visual-qa` only.

| Field | Purpose | Default |
|-------|---------|---------|
| Viewport | w×h from Node Map root frame; density; `fontScale` variants | From root FRAME dimensions |
| default `state-id` | UI state under test | `default` (v1 scope) |
| Capture Recipe | Paparazzi class/method, `@Preview` name, or `connected-device` — dev + test-strategy fill | Placeholder until dev |
| Baseline Policy | `re-fetch` (default) \| `trust-committed` + max age 7d | `re-fetch` |
| Tolerance | Dimension px slack; color/token exact | 2px dimensions; color exact |
| Metric Keys | Design Tokens + Node Map dimension columns for P0 diff | Auto from extraction |

### Launch Recipe (when Capture Recipe = `connected-device` or `DEVICE_CAPTURE: yes`)

mas-figma emits placeholders; dev + test-strategy populate values.

| Field | Required | Default | Notes |
|-------|----------|---------|-------|
| `package` | yes | — | Application ID |
| `activity` | no* | — | Fully qualified activity |
| `deeplink-uri` | no* | — | *At least one of `activity` or `deeplink-uri` required |
| `action` | no | `android.intent.action.VIEW` | Intent action |
| `intent-extras` | no | `{}` | JSON map |
| `post-launch-wait-ms` | no | `2000` | Sleep before screencap |
| `clear-task` | no | `false` | `FLAG_ACTIVITY_CLEAR_TASK` |
| `state-id` | no | `default` | UI state under test |

Flag in Open Questions when deeplink unknown from Figma alone.

### Device Target (when Launch Recipe required)

| Field | Required | Default | Notes |
|-------|----------|---------|-------|
| `adb-serial` | when >1 device | — | Mirrors handoff `ADB_SERIAL` |
| `min-api` | no | — | Informational |
| `form-factor` | no | `phone` | `phone` \| `tablet` \| `foldable` |
| `orientation` | no | `portrait` | `portrait` \| `landscape` |

### Pre-Capture (optional)

`fontScale`, `uiMode` (`night` \| `day`), `hide-system-bars`, `crop-rect` (`{x,y,w,h}`), `dismiss-keyguard`.

### Output Path (tier 3)

Default: `.ai/context/visual-qa/captures/{TASK_ID}/device-{state-id}.png`

Flag in Open Questions when viewport ambiguous or capture recipe cannot be inferred.

## Token mapping model (Relay shape, no Relay plugin)

```
Figma style → intermediate token name → MaterialTheme.colorScheme / typography / shapes
Custom scales (spacing) → CompositionLocal
```

On remote-only MCP: record raw values; flag `tokens-unresolved (local MCP required)`.

## Degrade paths

| Condition | Action |
|-----------|--------|
| Missing `node-id` | Blocked brief — HITL; never guess node |
| MCP unreachable | Blocked brief — HITL; no fabricated layout |
| Remote-only server | Node map + screenshot continue; tokens flagged unresolved |
| No Code Connect | Reuse rows `source: repo-scan (unverified)` |
| No Figma variables | Raw values + `no design tokens defined` flag |
| Asset URL ~7 days old | `expiry flag` in Asset Manifest |

## Specialist invariants

- Read-only — never patch production source
- One brief per `TASK_ID`; max one spawn unless `RE_EXTRACT: yes`
- No Task spawn, no routing, no `Approved:` authority
- Dev does not call Figma MCP when `design-specs/{TASK_ID}.md` exists

## MODEL_CLASS escalation (v1)

Default `normal`. Escalate to `thinking` when handoff `FIGMA_COMPLEXITY: high` or:

| Trigger | Threshold |
|---------|-----------|
| Node count | `> 40` under target |
| Variant nesting depth | `≥ 3` levels |
| Unbound values ratio | `> 30%` raw hex/px without Figma variable |
