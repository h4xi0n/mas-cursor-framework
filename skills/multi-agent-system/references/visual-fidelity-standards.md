# Visual Fidelity Standards

Reference for [mas-visual-fidelity](../../mas-visual-fidelity/SKILL.md), dev agents, test-strategy, and reviewer step 0k. Read-only post-dev verification — parity results live in `visual-qa` only.

## Three-tier verification

| Tier | Name | Input | Output | Producer | Gate |
|------|------|-------|--------|----------|------|
| P0 | Token/layout measurement diff | design-spec Design Tokens + Node Map vs captured metrics | `property \| expected \| actual \| delta \| severity` | mas-visual-fidelity | Reviewer 0k — `blocker` → `Approved: NO` |
| P1 | Screenshot pair compare | Figma baseline PNG vs implementation PNG at contract viewport | PASS/FAIL/PARTIAL + regions | mas-visual-fidelity | Reviewer 0k — FAIL without Major note |
| P2 | Subjective polish | Gaps P0/P1 cannot catch (motion, micro-interaction) | Reviewer imagined rows | reviewer | Unchanged |

When `design-spec` exists without `visual-qa` brief, reviewer Layout/Typography/Color/Spacing imagined rows → **N/A** per [build-test-visual-qa.md](build-test-visual-qa.md).

## Baseline resolve order

1. **Default:** Re-fetch `get_screenshot` on design-spec `node-id` at fidelity gate (MCP scope: `get_screenshot` only).
2. **Fallback:** Trust committed design-spec Screenshot Reference PNG when MCP unreachable **and** PNG exists with age **≤ 7 days**.
3. **Override:** Handoff `BASELINE_STALE: no` = explicit trust committed baseline (same semantics as trusting committed PNG).
4. **Blocked:** MCP unreachable + no valid PNG → `BLOCKED` in Baseline Source; P0 still runs when layout metrics extractable from Node Map.

**Forbidden MCP at fidelity gate:** `get_design_context`, whole-frame pulls.

## Capture method matrix (target Android projects)

Evaluated by mas-visual-fidelity + dev/test-strategy; selection logic below.

| Priority | Method | Command / script | Verification Contract field |
|----------|--------|------------------|-------------------------------|
| 1 | Paparazzi | `./gradlew :<module>:verifyPaparazziDebug` | Paparazzi test class + method |
| 2 | Compose Preview Screenshot Testing | `./gradlew :<module>:validateDebugScreenshotTest` | `@Preview` name |
| 3 | **Connected device adb** | `capture-connected-device.{ps1\|sh}` | Launch Recipe + Device Target + Output Path — **requires prep gate PASS** ([device-prep-automation.md](device-prep-automation.md)); capture reads `ANDROID_SERIAL`, connectivity-only re-check |
| 3 (legacy label) | Emulator adb (manual) | Same script; `adb-serial` = emulator | Subset of tier 3 — deprecated label |

**Selection logic (Step 3):**

1. If Capture Recipe specifies `connected-device` → tier 3.
2. Else if handoff `DEVICE_CAPTURE: yes` → tier 3 (skip tiers 1–2).
3. Else evaluate tiers 1 → 2 → 3 in order; first available wins.
4. Tier 3 selected but adb gate fails → `BLOCKED` Implementation Capture + HITL.

MAS framework repo: scripts are contract shapes; dogfood validates schema + BLOCKED paths via fixtures without mandating live device.

Script path: `skills/multi-agent-system/scripts/capture-connected-device.{ps1|sh}` — see [scripts/README.md](../scripts/README.md).

## Connected-device degrade matrix (tier 3)

| Failure | Script exit | Brief handling |
|---------|-------------|----------------|
| `adb` not on PATH | 1 | `BLOCKED` Implementation Capture + HITL |
| Zero devices in `device` state | 2 | `BLOCKED` + HITL — connect device/emulator |
| Multiple devices, no serial | 3 | `BLOCKED` + HITL — set `ADB_SERIAL` |
| Unauthorized / offline device | 4 | `BLOCKED` + HITL |
| App not installed / launch failure | 5 | `BLOCKED` + HITL — dev install debug APK |
| Screencap failure | 6 | `BLOCKED` Implementation Capture |
| ImageMagick unavailable + crop requested | 0 (warn) | Full-frame capture; note in Open Questions |
| Success | 0 | Path populated; P0/P1 proceed |

## Measurement diff row shape

```
property | expected | actual | delta | severity(blocker|major|minor)
```

P0 gate is **structured measurement diff** — not LLM spatial reasoning on images.

## Tolerance policy (D4)

| Dimension type | Tolerance |
|----------------|-----------|
| width, height, padding, gap, position | **2px slack** — subpixel drift → `severity: minor`, not `blocker` |
| colors, token names, token-mapped values | **zero tolerance** — mismatch → `severity: blocker` |

## v1 scope (D5)

Default UI state only (`state-id: default`). Interaction/hover/motion/loading variants → P2 reviewer imagined rows until v1.1+.

## Multi-screen (D6)

One sectioned `visual-qa` brief per `TASK_ID` — per-screen `## Screen: {name}` subsections each containing the six required section blocks. Escalate `MODEL_CLASS` to `thinking` when **> 3** screen states in design-spec Node Map.

## Iteration loop

```
dev DONE → mas-visual-fidelity → P0 blockers?
  yes → dev fix (handoff lists delta rows) → RE_VERIFY: yes → mas-visual-fidelity (iteration ≤ 2)
  no  → continue chain → reviewer 0k PASS (P0 resolved) → imagined P2 only
```

Session JSON fields: `visual_fidelity_spawned`, `p0_blockers`, `iteration_count`.

## Android baseline import contract

Figma PNG → `screenshotTest/reference/` for Compose Preview Screenshot Testing; Paparazzi golden images per project convention. Dev documents capture paths in handoff `FILES`; fidelity agent does not patch production code.

## Immutable vs mutable separation

| Artifact | Mutability | Owner |
|----------|------------|-------|
| design-spec extraction sections | **Immutable** after mas-figma | mas-figma (write); dev/fidelity (read) |
| Verification Contract slice | Overwritten on `RE_EXTRACT: yes` only | mas-figma |
| visual-qa brief | **Mutable** — overwritten on re-run | mas-visual-fidelity |

Parity results **never** append to design-spec extraction sections.

## Commercial visual AI (D10)

Adapt brief shape only (structured diff table + region summary) — no Applitools/SmartUI SDK or API keys in framework v1.

## Option 6 fallback (D12)

When user accepts cap relief: extend `test-runs/{TASK_ID}.md` with Visual Fidelity section; test-executor runs capture commands; session `visual_fidelity_fallback: test-executor`. No `get_screenshot` re-baseline. Escape hatch only — not default.

## Specialist invariants

- Read-only verification; never patches production source
- One visual-qa brief per `TASK_ID`; overwrites on re-run
- Never spawns Task; never routes workflows; no `Approved:` authority
- MCP: `get_screenshot` only at fidelity gate
- Dev does not self-attest fidelity without visual-qa brief downstream when design-spec exists

Schema registry: [brief-schemas.md](../protocol/brief-schemas.md).
