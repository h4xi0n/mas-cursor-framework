# Brief Schema Registry

Required markdown headings per brief type. Specialists complete even when sections are missing; **Reviewer** flags gaps as `Approved: NO` with schema gap notes.

## Registry

| Type | Path pattern | Required sections |
|------|--------------|-------------------|
| osint | `.ai/context/osint/{TASK_ID}.md` | Research Summary, Findings table, Recommended Approach (FEATURE) or Recommended Fix Strategy (BUG), Confidence |
| brainstorm | `.ai/context/brainstorms/{TASK_ID}.md` | Options table, Recommended, Logic Flow, Risks |
| plan | `.ai/context/plans/{TASK_ID}.md` | Tasks, Dependencies, Acceptance criteria |
| architecture | `.ai/context/architecture/{TASK_ID}.md` | Architecture, Modules, Layers, Contracts, Files |
| debate | `.ai/context/debates/{TASK_ID}.md` | Critics, Consensus, Action items, Dissent |
| audit | `.ai/context/audits/{TASK_ID}.md` | Step breakdown, Outliers, Recommendations |
| security-audit | `.ai/context/security-audits/{TASK_ID}.md` | Threat model, Findings, Validation, Blockers |
| api-contract | `.ai/context/api-contracts/{TASK_ID}.md` | Spec inventory, Breaking changes, Drift, Recommendations |
| supply-chain | `.ai/context/supply-chain/{TASK_ID}.md` | Dependency delta, CVE summary, Blast radius, Remediation |
| test-run | `.ai/context/test-runs/{TASK_ID}.md` | Commands, Pass/fail, Failures, Gaps, **Device** (conditional), **Device Logs** (conditional) |
| a11y-review | `.ai/context/a11y-reviews/{TASK_ID}.md` | WCAG table, Findings, Fix priority, Manual checklist |
| i18n-review | `.ai/context/i18n-reviews/{TASK_ID}.md` | String inventory, Locale gaps, RTL, Recommendations |
| compliance | `.ai/context/compliance/{TASK_ID}.md` | Framework map, Gaps, Evidence, Remediation, Not legal advice |
| design-spec | `.ai/context/design-specs/{TASK_ID}.md` | Node Map, Design Tokens, Layout Spec, Component Reuse Table, Asset Manifest, Screenshot Reference, Open Questions; optional **Verification Contract** slice (required at fidelity gate) |
| visual-qa | `.ai/context/visual-qa/{TASK_ID}.md` | Viewport & State, Baseline Source, Implementation Capture, Measurement Diff, Screenshot Compare, Open Questions / Accepted Debt |

**Phase A (v1.2.0):** The four P0 types above are advisory-only — specialists never patch code; reviewer remains sole `Approved:` gate. Coordinator routing: [handoff-format.md](handoff-format.md) flags or FILES/SCOPE predicates.

**Phase B (v1.2.1):** P1 trio (`a11y`, `i18n`, `compliance`) — same advisory-only contract. `compliance` brief **must** include **Not legal advice** section. Spawn `compliance` only when handoff `COMPLIANCE_FRAMEWORK` is set.

**MAS-05 (v1.3.0):** `design-spec` — read-only Figma extraction brief produced by `mas-figma`; consumed by android-dev/general-dev at startup and reviewer (conditional). Section field contracts: [figma-extraction-standards.md](../references/figma-extraction-standards.md). Layout Spec blocks must be marked **reference — not final code**.

**MAS-06 (v1.4.0):** `visual-qa` — read-only post-dev fidelity brief produced by `mas-visual-fidelity`; consumed by reviewer (step 0k) and coordinator (iteration routing). Section field contracts: [visual-fidelity-standards.md](../references/visual-fidelity-standards.md). **Invariant:** parity results live in `visual-qa` only — never append mutable verification rows to design-spec extraction sections.

**MAS-07 (v1.4.1):** Verification Contract extended with **Launch Recipe**, **Device Target**, **Pre-Capture** (optional), **Output Path** when Capture Recipe = `connected-device` or handoff `DEVICE_CAPTURE: yes`. `visual-qa` Implementation Capture `capture-method` enum adds `connected-device` (alias read: `adb-device`, `emulator`). Field contracts: [figma-extraction-standards.md](../references/figma-extraction-standards.md) §8 + [architecture/MAS-07.md](../../../.ai/context/architecture/MAS-07.md) Device capture contract.

**MAS-07 prep gate (v1.5.0):** test-run **Device** section required when test-strategy `Prep gate: required`, prep was attempted (including FAIL), or any executed/skipped command matched device surface. Omit only when `Prep gate: skip` with documented JVM-only rationale **and** no prep invocation. Fields: Prep gate (`PASS` \| `FAIL` \| `SKIPPED`), Serial, Policy, Exit code, Grants applied, Message. test-strategy **Device Prerequisites** section required when Recommended Commands touch adb, connected instrumentation, screencap, or Maestro — template in [test-strategy-standards.md](../references/test-strategy-standards.md). Prep SOT: [device-prep-automation.md](../references/device-prep-automation.md).

**design-spec Verification Contract slice** (eighth section — emitted by mas-figma): Viewport (w×h, density, fontScale variants), default `state-id`, Capture Recipe, Baseline Policy (`re-fetch` | `trust-committed` + max age 7d), Tolerance (2px dimensions, color exact), Metric Keys; optional Launch Recipe + Device Target subsections (MAS-07). Required when `design-spec` exists at fidelity gate. Overwritten on `RE_EXTRACT: yes` only.

**visual-qa Implementation Capture fields (MAS-07 extension):** `capture-method` (`paparazzi` | `compose-preview` | `connected-device`), `path`, `adb-serial`, `git-revision`, `width`, `height`, `timestamp`.

## Device

test-run brief (`.ai/context/test-runs/{TASK_ID}.md`) — required when test-strategy `Prep gate: required`, prep was attempted (including FAIL), or any executed/skipped command matched device surface. Omit only when `Prep gate: skip` with documented JVM-only rationale **and** no prep invocation. SOT: [device-prep-automation.md](../references/device-prep-automation.md); architecture: [MAS-07.md](../../../.ai/context/architecture/MAS-07.md) § test-run Device section schema.

| Field | Required when | Values |
|-------|---------------|--------|
| status | section present | `PASS` \| `FAIL` \| `SKIPPED` (maps to Prep gate in brief table) |
| serial | PASS | adb serial; `—` on FAIL/SKIP |
| policy_applied | prep attempted | `physical` \| `emulator` \| `auto` |
| prep_command | prep attempted | `android-device-prep.{ps1\|sh}` invocation with flags, or `—` |
| blocker_message | always | Actionable text from prep JSON `message`; enrollment/blocker guidance on FAIL |

```markdown
## Device

| Field | Value |
|-------|-------|
| Prep gate | PASS \| FAIL \| SKIPPED |
| Serial | <serial or —> |
| Policy | physical \| emulator \| auto |
| Exit code | PASS \| NO_DEVICE \| UNAUTHORIZED \| … \| — |
| Grants applied | <list or —> |
| Message | <actionable text from prep JSON> |
```

## Device Logs

test-run brief (`.ai/context/test-runs/{TASK_ID}.md`) — required when `LOG_CAPTURE: yes` and capture attempted (PASS/FAIL/SKIP). Omit when JVM-only with documented skip rationale. SOT: [device-log-capture.md](../references/device-log-capture.md); architecture: [MAS-09.md](../../../.ai/context/architecture/MAS-09.md).

| Field | Required when | Values |
|-------|---------------|--------|
| Capture gate | capture attempted | `PASS` \| `FAIL` \| `SKIPPED` |
| Prep prerequisite | section present | `PASS (serial)` \| `FAIL` \| `SKIPPED` |
| Clear executed | `LOG_CAPTURE: yes` | `yes` \| `no` |
| Dump path | dump attempted | `.ai/context/device-logs/{TASK_ID}/capture-meta.json` |
| Format | dump PASS | `json` \| `threadtime` |
| Line count | dump PASS | integer |
| Tag filter | dump attempted | e.g. `APP_TRACE` \| `—` |
| Package | when set | applicationId \| `—` |
| Message | always | From script stdout JSON `message` |

```markdown
## Device Logs

| Field | Value |
|-------|-------|
| Capture gate | PASS \| FAIL \| SKIPPED |
| Prep prerequisite | PASS (serial) \| FAIL \| SKIPPED |
| Clear executed | yes \| no |
| Dump path | .ai/context/device-logs/{TASK_ID}/capture-meta.json |
| Format | json \| threadtime |
| Line count | <integer> |
| Tag filter | APP_TRACE |
| Package | com.example.app \| — |
| Message | <from script stdout JSON> |
```

**MAS-09 (v1.7.0):** Device Logs slice parallels MAS-07 **Device** section. Prep FAIL → Device Logs `SKIPPED`; clear/dump not invoked.

## Validation guidance

| Role | Behavior |
|------|----------|
| Brief writers (osint, brainstorm, planner, architect, debate-synthesizer, token-auditor, security-auditor, dependency-risk, api-contract, test-executor, a11y, i18n, compliance, mas-figma, mas-visual-fidelity) | Include required sections when writing briefs; cite this file in skill Startup — do not paste full schema |
| Reviewer | On review, check briefs in chain against this registry; missing required sections → note in findings; may set `Approved: NO` for schema gaps on deliverable briefs; step **0k** requires `visual-qa` when design-spec exists and P0-6 fired |
| Coordinator | Does not validate headings inline — forwards `BRIEF_PATH` only |

## Subscription matrix

See [read-order.md](read-order.md) for which agents read which briefs at startup.

## `BRIEF_PATH` + `SECTIONS:` slice semantics

When handoff includes `BRIEF_PATH:` and optional `SECTIONS:` (lite: `BP:` / `SEC:`):

- Read only listed markdown headings from the brief file
- Invalid or missing `SECTIONS` headers → read full brief; Coordinator logs warning in user summary
- Omit `SECTIONS` → read full brief

## Related

- [handoff-format.md](handoff-format.md) — `BRIEF_PATH`, `SECTIONS:`
- [spawn-model-policy.md](spawn-model-policy.md) — model class per agent
