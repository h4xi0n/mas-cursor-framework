# Project Memory

Durable knowledge only. Do not store conversations, generated code, or temporary decisions.

## MAS Framework

### Daily Changelog (MAS-01)

> Ephemeral same-day work log at `.ai/context/daily-changelog.md`. Policy: daily-changelog-policy.md

### Workflow Usage (MAS-02)

> Durable per-workflow telemetry (mode, tier, agent chain, models, tokens). One line per approved workflow. Policy: workflow-usage-policy.md

## Entries
- **MAS-01** (2026-07-27, feature, FULL/none): chain=osint→brainstorm→planner→architect→general-dev→documenter; models=default,default,default,default,default,composer-2.5-fast; classes=normal,normal,normal,normal,normal,fast; tokens=unknown
- **MAS-04** (2026-07-28, feature, FULL/none): chain=osint→brainstorm→planner→architect→reviewer→test-strategy→general-dev→documenter; models=default,default,default,default,default,default,default,composer-2.5-fast; classes=thinking,thinking,normal,thinking,thinking,normal,normal,fast; tokens=unknown
- **MAS-04-FIX-P0-ALL** (2026-07-28, feature, FULL/none): chain=general-dev→dependency-risk→api-contract→test-strategy→security-auditor→test-executor→reviewer; models=default,composer-2.5-fast,default,default,default,default,default; classes=normal,fast,normal,normal,thinking,normal,thinking; tokens=unknown
- **MAS-04-B** (2026-07-28, feature, FULL/none): chain=test-strategy→general-dev→documenter→reviewer; models=default,default,composer-2.5-fast,default; classes=normal,normal,fast,thinking; tokens=unknown
- **MAS-04-B-FIX-ALL** (2026-07-28, feature, FULL/none): chain=general-dev→ux-intelligence→a11y→i18n→compliance→reviewer; models=default,default,default,default,default,default; classes=normal,normal,normal,normal,thinking,thinking; tokens=unknown
- **MAS-05** (2026-08-05, feature, FULL/none): chain=osint→brainstorm→planner→architect→test-strategy→general-dev→documenter; models=default,default,default,default,default,default,composer-2.5-fast; classes=thinking,thinking,normal,thinking,normal,normal,fast; tokens=unknown
- **MAS-06** (2026-09-28, feature, FULL/none): chain=osint→brainstorm→planner→architect→test-strategy→general-dev→documenter→reviewer; models=default,default,default,default,default,default,composer-2.5-fast,default; classes=thinking,thinking,normal,thinking,normal,normal,fast,thinking; tokens=unknown
- **MAS-07** (2026-09-28, feature, FULL/none): chain=planner→osint→architect→brainstorm→general-dev→documenter→test-strategy→test-executor→bug-fix→reviewer; models=inherit,inherit,inherit,inherit,default,composer-2.5-fast,inherit,inherit,inherit,default; classes=normal,thinking,thinking,thinking,normal,fast,normal,normal,normal,thinking; tokens=unknown
- **MAS-09** (2026-10-06, feature, FULL/none): chain=osint→brainstorm→planner→architect→test-strategy→general-dev→test-executor→bug-fix→documenter→reviewer; models=default,default,default,default,default,default,default,default,composer-2.5-fast,default; classes=thinking,thinking,normal,thinking,normal,normal,normal,normal,fast,thinking; tokens=unknown

## Architecture Decisions

- **MAS-04 (2026-07-28, research):** Phased v1.2.0–v1.3.0 roster adds 10 audit specialists — P0: security-auditor, dependency-risk, api-contract, test-executor; P1: a11y, i18n, compliance; P2: observability, migration, chaos-resilience. Advisory v1 — specialists brief only; reviewer remains sole `Approved:` gate. `MAX_CHAIN_AGENTS` overflow skip order: test-executor → api-contract → dependency-risk → security-auditor → a11y → i18n → compliance → observability → migration → chaos-resilience. Session JSON: `specialists_spawned`, `skipped_specialists`. Artifacts: `.ai/context/{osint,brainstorms,plans,architecture}/MAS-04.md`.
- **MAS-04 Phase A (2026-07-28, feature):** Shipped v1.2.0 P0 quartet — `mas-security-auditor`, `mas-dependency-risk`, `mas-api-contract`, `mas-test-executor`. Routing flags: `SECURITY_AUDIT`, `API_CONTRACT`, `SUPPLY_CHAIN`, `RUN_TESTS` (lite: `SEC:y`, `API:y`, `DEPS:y`, `TEST:y`). Brief paths: `.ai/context/{security-audits,api-contracts,supply-chain,test-runs}/`. Chain: test-strategy → dev → security-auditor → test-executor → documenter → reviewer.
- **MAS-04 task 20 dogfood (2026-07-28):** `MAS-04-FIX-P0-ALL` validated spawn chain dependency-risk→api-contract→test-strategy→security-auditor→test-executor; all four briefs + test-run PASS; advisory-only mutual exclusion confirmed.
- **MAS-04 Phase B (2026-07-28, feature):** Shipped v1.2.1 P1 trio — `mas-a11y`, `mas-i18n`, `mas-compliance`. UI chain: dev → ux-intelligence → a11y → i18n → compliance → test-executor → documenter → reviewer (sequential). Flags: `A11Y_AUDIT`/`A11Y:y`, `I18N_AUDIT`/`I18N:y`, `COMPLIANCE_FRAMEWORK` (full `/mas` only). Brief paths: `.ai/context/{a11y-reviews,i18n-reviews,compliance}/`.
- **MAS-04 task 35 dogfood (2026-07-28):** `MAS-04-B-FIX-ALL` validated sequential spawn ux→a11y→i18n→compliance; four briefs + mutual-exclusion boundary confirmed.
- **MAS-05 (2026-08-05, feature):** Shipped v1.3.0 `mas-figma` read-only Figma extraction specialist + `design-spec` brief type (`.ai/context/design-specs/{TASK_ID}.md`, 7 required sections). Coordinator predicate **P0-5** (`FIGMA_SPEC: yes` OR Figma URL/`node-id` in `SOURCES_HINT`/`FILES` OR `SCOPE: ui-from-figma`), pre-dev after architect/planner, **protected-when-triggered** (not auto-skipped in full `/mas`; Lite `FIG:y` on L/L+ only). Flags: `FIGMA_SPEC`/`SOURCES_HINT`/`RE_EXTRACT`/`FIGMA_COMPLEXITY` (lite `FIG:y`). Inspect-first (whole-frame `get_design_context` forbidden); read-only, no `Approved:` authority; dev implements 1:1 and does not call Figma MCP when brief exists.
- **MAS-06 (2026-09-28, feature):** Shipped v1.4.0 `mas-visual-fidelity` read-only post-dev fidelity specialist + `visual-qa` brief type (`.ai/context/visual-qa/{TASK_ID}.md`, 6 required sections). Coordinator predicate **P0-6** (`VISUAL_FIDELITY: yes` OR auto + design-spec + `UI_CHANGES: YES`), after dev, before ux-intelligence, **protected-when-triggered**. design-spec **Verification Contract** slice (§8) emitted by mas-figma. Reviewer step **0k** Design-Fidelity Verification (consumer-only). Flags: `VISUAL_FIDELITY`, `UI_CHANGES`, `RE_VERIFY`, `BASELINE_STALE` (lite `VFID:y`). Three-tier verification: P0 measurement diff, P1 screenshot compare, P2 imagined polish.
- **MAS-07 (2026-09-28, feature):** Shipped v1.5.0 connected-device capture for mas-visual-fidelity — `capture-connected-device.{ps1|sh}` (adb gate, intent/deeplink launch, screencap) + upstream `android-device-prep.{ps1|sh}` prep gate (`ANDROID_SERIAL` export, selection policy physical|emulator|auto, boot wait, grants). Verification Contract extended with Launch Recipe + Device Target. Flags: `DEVICE_CAPTURE: yes`, `ADB_SERIAL`/`DEVICE_SERIAL`, `DEVICE_POLICY`. test-executor Step 0 invokes prep before tier-3 capture.
- **MAS-08 (2026-10-02, research):** v1.6.0 direction — Cursor Plugin distribution (`.cursor-plugin/plugin.json`), project-level `.cursor/hooks.json` for Cloud Agent parity, `inherit` dev-class model defaults, hybrid `.cursor/agents/` stubs (top 8), built-in delegation (`explore`/`bash`/`browser`), optional `PARALLEL_AUDIT` async audit lane (default `no`). Precedence: project > plugin > global. Invariants unchanged: reviewer `Approved:` gate, foreground dev chain, self-contained Task prompts, artifact-forward hooks. Artifacts: `.ai/context/{osint,brainstorms,plans,architecture}/MAS-08.md`.

## Constraints

## API Assumptions

## Known Issues

## Lessons Learned
