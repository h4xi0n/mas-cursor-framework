# Handoff Format

All agent communication uses structured handoffs written to `.ai/handoffs/{TASK_ID}.md`.

## Coordinator Handoff Template

```
TASK_ID: <id>
MODE: FULL | LITE
TIER: S | M | L | L+ | none
TARGET_AGENT: <spec-reader|brainstorm|planner|architect|mas-figma|mas-visual-fidelity|android-dev|general-dev|osint|imaginer|ux-intelligence|perf-optimizer|release-readiness|test-strategy|security-auditor|dependency-risk|api-contract|test-executor|a11y|i18n|compliance|bug-fix|documenter|reviewer|commit|debate-synthesizer|token-auditor>
SPAWN_STATUS: spawned
MODEL_CLASS: fast | normal | thinking    # optional; default from spawn-model-policy.md
BRIEF_PATH: .ai/context/plans/{TASK_ID}.md # optional artifact forward — path only, not body
SECTIONS: Tasks, Dependencies            # optional slice; omit = read full brief
UI_SCOPE: logic-only | ui-allowed
GOAL: <single sentence>
DOCS:
* path/to/requirements or openapi (optional)
CONTEXT:
* item
* item
FILES:
* path (optional)
MODULES:
* :app (optional, Android)
UI_CHANGES: YES | NO
DELIVERABLE: <expected result>
NEXT_AGENT: <agent or none>
DONE
```

### Coordinator → Debate Synthesizer Handoff

Trigger: `reviewer_loop_count >= 2` and `debate_used == false` in session JSON (Coordinator-only).

```
TASK_ID: <id>
TARGET_AGENT: debate-synthesizer
DEBATE_TRIGGER: reviewer-rejection-2
GOAL: Synthesize security and simplicity perspectives on Reviewer rejection.
FILES:
* patched paths from Reviewer handoff
CONTEXT:
* Reviewer findings summary (filtered — not full chain)
BRIEF_PATH: .ai/context/debates/{TASK_ID}.md
DELIVERABLE: Brief at .ai/context/debates/{TASK_ID}.md
NEXT_AGENT: bug-fix
DONE
```

Coordinator sets `debate_used: true` in session after debate Task returns. Max one debate session per `TASK_ID`.

### Coordinator → Token Auditor Handoff

Trigger: post `finalize-workflow-usage.ps1`, `Approved: YES`, non-empty `FILES`. Optional — skip planning-only and lite default.

```
TASK_ID: <id>
TARGET_AGENT: token-auditor
GOAL: Advisory token usage audit for completed workflow.
BRIEF_PATH: .ai/context/workflow-sessions/{TASK_ID}.json
DELIVERABLE: Brief at .ai/context/audits/{TASK_ID}.md
NEXT_AGENT: none
DONE
```

Auditor never blocks approval.

### Coordinator → Imaginer Handoff

```
TASK_ID: <id>
TARGET_AGENT: imaginer
SYMPTOM: <user-visible problem or stack trace>
USER_ACTION: <what user did before failure>
REPRO_STEPS:
* step
FILES:
* seed paths (optional)
TRACE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/imaginations/{TASK_ID}.md
NEXT_AGENT: bug-fix | none
DONE
```

`TRACE_ONLY: false` (default) → `NEXT_AGENT: bug-fix`. `TRACE_ONLY: true` → `NEXT_AGENT: none`.

### MAS-04 Phase A routing flags (optional — predicates also fire from FILES/SCOPE)

| Flag | Specialist | Default trigger |
|------|------------|-----------------|
| `SECURITY_AUDIT: yes` | security-auditor | Auth/crypto/API in `SCOPE`; post-dev pre-reviewer |
| `API_CONTRACT: yes` | api-contract | OpenAPI/GraphQL/Proto in `FILES`; REST/BFF in `SCOPE` |
| `SUPPLY_CHAIN: yes` | dependency-risk | Lockfile/manifest/MCP/skills/hooks delta in `FILES` |
| `RUN_TESTS: yes` | test-executor | Explicit test run; or test-strategy brief exists |
| `SECURITY_BLOCKER: yes` | (reviewer opt-in) | User opt-in — reviewer treats security Blockers as merge-blocking |
| `RE_AUDIT: yes` | any specialist | Allow re-spawn of same slug (idempotency exception) |

Omit flags when predicates do not apply — existing handoffs without flags remain valid.

### MAS-04 Phase B routing flags (optional — predicates also fire from FILES/SCOPE/release-readiness FAIL)

| Flag | Specialist | Default trigger |
|------|------------|-----------------|
| `A11Y_AUDIT: yes` | a11y | Post-dev after ux-intelligence when `UI_CHANGES: yes`; or release-readiness Accessibility FAIL; or interactive widgets in `FILES` |
| `I18N_AUDIT: yes` | i18n | After a11y when both triggered (sequential); or new strings/locale/RTL in `SCOPE`; or release-readiness Localization FAIL |
| `COMPLIANCE_FRAMEWORK: SOC2 \| GDPR \| HIPAA \| EU_AI_ACT \| FedRAMP` | compliance | Post-dev or pre-release-readiness — **only when framework value set**; full `/mas` only |

**Spawn rule:** ux-intelligence → a11y → i18n are **sequential only** (a11y before i18n when both). No parallel unless deferred `PARALLEL_READ: YES`. P1 segment completes **before** test-executor when both triggered.

Lite abbreviations: `A11Y:y`, `I18N:y` per [handoff-format-lite.md](handoff-format-lite.md). Compliance has no lite abbreviation.

### MAS-05 Figma routing flags (optional — predicates also fire from FILES/SCOPE)

| Flag | Specialist | Default trigger |
|------|------------|-----------------|
| `FIGMA_SPEC: yes` | mas-figma | Explicit UI-from-design extraction |
| `SOURCES_HINT` | mas-figma | Figma URL with `node-id` in hint (node-id required for extraction) |
| `SCOPE: ui-from-figma` | mas-figma | Implementation-from-design scope |
| `RE_EXTRACT: yes` | mas-figma | Allow re-spawn on same `TASK_ID` (idempotency override; mirrors `RE_AUDIT`) |
| `FIGMA_COMPLEXITY: high` | mas-figma | Escalate `MODEL_CLASS` normal → thinking |

**Predicate (P0-5):** `FIGMA_SPEC: yes` **OR** Figma URL/`node-id` in `SOURCES_HINT`/`FILES` **OR** `SCOPE: ui-from-figma` → spawn **mas-figma** after architect/planner, **before** android-dev/general-dev.

**Suppression:** Skip mas-figma when UI already exists and only behavioral friction (→ ux-intelligence) or WCAG (→ a11y) is in scope — even if Figma URL is incidentally present.

**node-id requirement:** URL without `node-id` still triggers routing; mas-figma writes Blocked brief + HITL (never guesses node). Coordinator does not pre-validate node-id.

Lite abbreviation: `FIG:y` per [handoff-format-lite.md](handoff-format-lite.md).

### MAS-06 Visual fidelity routing flags (optional — predicates also fire from design-spec + UI_CHANGES)

| Flag | Specialist | Default trigger |
|------|------------|-----------------|
| `VISUAL_FIDELITY: yes` | mas-visual-fidelity | Force spawn (full `/mas`) |
| `VISUAL_FIDELITY: auto` | mas-visual-fidelity | Coordinator predicate when design-spec exists AND dev `UI_CHANGES: YES` |
| `UI_CHANGES: YES` \| `UI_CHANGES: NO` | (dev handoff) | **Required on dev DONE** for auto predicate when design-spec exists |
| `RE_VERIFY: yes` | mas-visual-fidelity | Allow re-spawn on same `TASK_ID` (idempotency; mirrors `RE_EXTRACT`) |
| `BASELINE_STALE: no` | mas-visual-fidelity | Trust committed design-spec PNG when MCP blocked |
| `DEVICE_CAPTURE: yes` | mas-visual-fidelity | Force tier-3 adb even if Paparazzi/Preview exist |
| `ADB_SERIAL: {serial}` | mas-visual-fidelity | Multi-device override (mirrors contract `adb-serial`) |

**Predicate (P0-6):** `VISUAL_FIDELITY: yes` **OR** (`VISUAL_FIDELITY: auto` AND `.ai/context/design-specs/{TASK_ID}.md` exists AND dev handoff `UI_CHANGES: YES` [or `FILES` touch Composables/resources/themes/dimensions]) → spawn **mas-visual-fidelity** after android-dev/general-dev; **before** ux-intelligence.

**Suppression:** Skip when `UI_CHANGES: NO`; skip when no design-spec; skip when only behavioral friction/WCAG on existing UI with no new impl from spec. Lite: no auto predicate — `VFID:y` explicit only; skip + warn "Figma fidelity unverified".

Lite abbreviation: `VFID:y` per [handoff-format-lite.md](handoff-format-lite.md).

### Coordinator → Mas-Visual-Fidelity Handoff

```
TASK_ID: <id>
TARGET_AGENT: mas-visual-fidelity
MODEL_CLASS: normal | thinking
VISUAL_FIDELITY: yes | auto
DEVICE_CAPTURE: yes              # optional — force tier-3 adb
ADB_SERIAL: emulator-5554        # optional — multi-device override
BRIEF_PATH: .ai/context/design-specs/{TASK_ID}.md
GOAL: <one sentence fidelity verification objective>
FILES:
* dev implementation paths + capture artifact paths
DELIVERABLE: Brief at .ai/context/visual-qa/{TASK_ID}.md
NEXT_AGENT: ux-intelligence | test-executor
DONE
```

### Dev handoff LAUNCH block (when Capture Recipe uses connected-device)

```
LAUNCH:
  package: com.example.app
  deeplink-uri: myapp://fidelity/default
  # OR activity: .FidelityActivity
  post-launch-wait-ms: 2000
```

Coordinator passes `DEVICE_CAPTURE` and `ADB_SERIAL` to mas-visual-fidelity handoff when present.

Advisory v1 — read-only verification; P0 blockers route to dev fix (max 2 iterations via `RE_VERIFY: yes`); reviewer remains sole `Approved:` gate. MCP scope: `get_screenshot` only.

### Coordinator → Mas-Figma Handoff

```
TASK_ID: <id>
TARGET_AGENT: mas-figma
MODEL_CLASS: normal | thinking
FIGMA_SPEC: yes
SOURCES_HINT: <Figma URL with node-id>
BRIEF_PATH: .ai/context/architecture/{TASK_ID}.md
GOAL: <one sentence extraction objective>
SCOPE:
* target screens/nodes from architecture brief
FILES:
* optional seed paths
DELIVERABLE: Brief at .ai/context/design-specs/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev
DONE
```

Advisory v1 — read-only extraction; dev implements from design-spec; reviewer remains sole `Approved:` gate. Local desktop MCP strongly preferred for `get_variable_defs`.

### Coordinator → A11y Handoff

```
TASK_ID: <id>
TARGET_AGENT: a11y
MODEL_CLASS: normal
GOAL: <one sentence WCAG 2.2 AA accessibility audit objective>
SCOPE:
* screens, flows, or interactive components
FILES:
* UI component paths (optional)
A11Y_AUDIT: yes
DELIVERABLE: Brief at .ai/context/a11y-reviews/{TASK_ID}.md
NEXT_AGENT: i18n | test-executor | documenter | reviewer | none
DONE
```

Advisory v1 — WCAG/ARIA/keyboard depth only; behavioral friction → ux-intelligence; no layout/cosmetic redesign.

### Coordinator → I18n Handoff

```
TASK_ID: <id>
TARGET_AGENT: i18n
MODEL_CLASS: normal
GOAL: <one sentence localization/string architecture audit objective>
SCOPE:
* locales, RTL, pluralization, string extraction surfaces
FILES:
* strings.xml, locales, i18n resource paths (optional)
I18N_AUDIT: yes
DELIVERABLE: Brief at .ai/context/i18n-reviews/{TASK_ID}.md
NEXT_AGENT: compliance | test-executor | documenter | reviewer | none
DONE
```

Does not own translation vendor workflow — routes fixes to dev.

### Coordinator → Compliance Handoff

```
TASK_ID: <id>
TARGET_AGENT: compliance
MODEL_CLASS: thinking
GOAL: <one sentence regulatory evidence gap audit objective>
COMPLIANCE_FRAMEWORK: SOC2 | GDPR | HIPAA | EU_AI_ACT | FedRAMP
SCOPE:
* systems, data flows, or controls in scope for framework
FILES:
* seed paths (optional)
DELIVERABLE: Brief at .ai/context/compliance/{TASK_ID}.md
NEXT_AGENT: test-executor | documenter | reviewer | release-readiness | none
DONE
```

**Not legal advice** — skill header + brief disclaimer required. Never auto-approves compliance; HITL for legal/prod remediation. Spawn only when `COMPLIANCE_FRAMEWORK` set.

### Coordinator → Dependency Risk Handoff

```
TASK_ID: <id>
TARGET_AGENT: dependency-risk
MODEL_CLASS: fast
GOAL: <one sentence supply-chain audit objective>
SCOPE:
* modules, lockfiles, or mas-framework self-scan
FILES:
* package-lock.json, manifest.json, skills paths (optional)
SUPPLY_CHAIN: yes
DELIVERABLE: Brief at .ai/context/supply-chain/{TASK_ID}.md
NEXT_AGENT: planner | architect | dev | documenter | reviewer | none
DONE
```

### Coordinator → API Contract Handoff

```
TASK_ID: <id>
TARGET_AGENT: api-contract
MODEL_CLASS: normal
GOAL: <one sentence API contract audit objective>
SCOPE:
* REST/BFF surface or spec paths
FILES:
* openapi.yaml, graphql schema, proto files (optional)
API_CONTRACT: yes
DELIVERABLE: Brief at .ai/context/api-contracts/{TASK_ID}.md
NEXT_AGENT: test-strategy | dev | documenter | reviewer | none
DONE
```

### Coordinator → Security Auditor Handoff

```
TASK_ID: <id>
TARGET_AGENT: security-auditor
MODEL_CLASS: thinking
GOAL: <one sentence security audit objective>
SCOPE:
* auth, crypto, API surface, or changed security-sensitive paths
FILES:
* seed paths (optional)
SECURITY_AUDIT: yes
DELIVERABLE: Brief at .ai/context/security-audits/{TASK_ID}.md
NEXT_AGENT: test-executor | documenter | reviewer | none
DONE
```

Advisory v1 — findings route to dev/bug-fix. Merge-blocking Blockers only when handoff also sets `SECURITY_BLOCKER: yes`.

### Coordinator → Test Executor Handoff

```
TASK_ID: <id>
TARGET_AGENT: test-executor
MODEL_CLASS: normal
GOAL: Execute tests per test-strategy brief and document results.
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/{TASK_ID}.md
RUN_TESTS: yes
DEVICE_SERIAL: R58M90ABCDE          # optional — multi-phone desk
DEVICE_POLICY: physical             # optional — physical | emulator | auto
FILES:
* paths from strategy brief (optional)
DELIVERABLE: Brief at .ai/context/test-runs/{TASK_ID}.md
NEXT_AGENT: documenter | reviewer | bug-fix | none
DONE
```

Requires test-strategy brief **or** `RUN_TESTS: yes`. Run-only v1 — failures route to **bug-fix**; executor does not patch code.

**MAS-07 (v1.5.0) device fields:** Copy `DEVICE_SERIAL` / `DEVICE_POLICY` from coordinator handoff when device commands are in scope. test-executor passes them to `android-device-prep.{ps1|sh}` as `--serial` / `--policy`. On prep PASS, export `ANDROID_SERIAL` for subsequent Gradle/adb commands. `ADB_SERIAL` on visual-fidelity handoff is a read alias — prefer `DEVICE_SERIAL` on coordinator handoff post-v1.5.0.

### MAS-09 log capture routing flags (optional — default `LOG_CAPTURE: no`)

| Flag | Values | Set by | Consumed by |
|------|--------|--------|-------------|
| `LOG_CAPTURE: yes\|no` | default `no` | Coordinator when user requests repro logging | test-executor, hooks, test-strategy |
| `LOG_PACKAGE: <id>` | applicationId | Coordinator or user | capture script `--package` |
| `LOG_TAG: <name>` | default `APP_TRACE` | Coordinator or convention | capture script `--tag` |
| `LOG_BUFFERS: <list>` | default `main,crash` | Coordinator | capture script `--buffers` |
| `LOG_FORMAT: json\|threadtime` | optional override | Coordinator | capture script `--format` |
| `LOG_ESCALATION: full-bugreport` | P2 only | Coordinator | escalation subcommand (deferred) |

Lite alias: `LOG:y` per [handoff-format-lite.md](handoff-format-lite.md).

**Routing:** Set flags on test-executor and bug-fix handoffs when user requests repro logging. After dump, bug-fix may receive `BRIEF_PATH: .ai/context/device-logs/{TASK_ID}/capture-meta.json`.

**Coordinator → test-executor example (log capture):**

```
LOG_CAPTURE: yes
LOG_PACKAGE: com.example.app
LOG_TAG: APP_TRACE
```

### Coordinator → Perf Optimizer Handoff

```
TASK_ID: <id>
TARGET_AGENT: perf-optimizer
GOAL: <one sentence optimization objective>
PERF_SYMPTOM: <user-visible perf problem>
SCOPE:
* screens, modules, flows, or file prefixes
METRICS: <baseline numbers or unknown>
FILES:
* seed paths (optional)
ANALYZE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/optimizations/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev | none
DONE
```

`ANALYZE_ONLY: false` (default) → `NEXT_AGENT: android-dev` | `general-dev` (platform from `project.md` or stack detection). `ANALYZE_ONLY: true` → `NEXT_AGENT: none`.

### Coordinator → Release Readiness Handoff

```
TASK_ID: <id>
TARGET_AGENT: release-readiness
GOAL: <one sentence release audit objective>
RELEASE_TARGET: <version / build / channel or unknown>
SCOPE:
* modules, screens, flows, or file prefixes
FILES:
* seed paths (optional)
RELEASE_ONLY: true | false
DELIVERABLE: Brief at .ai/context/release-readiness/{TASK_ID}.md
NEXT_AGENT: bug-fix | android-dev | general-dev | none | commit
DONE
```

`RELEASE_ONLY: false` (default) → `NEXT_AGENT` from top P0 fix agent per [release-readiness-standards.md](../references/release-readiness-standards.md). `RELEASE_ONLY: true` → `NEXT_AGENT: none`.

**Failure routing (category → default fix agent):**

| Category | Default fix agent |
|----------|-------------------|
| Crashes, ANRs (functional), Edge cases (functional) | `bug-fix` |
| Accessibility | `a11y` (depth WCAG audit — release-readiness does not re-audit WCAG table) |
| Localization | `i18n` (locale/string architecture — release-readiness does not duplicate ICU/RTL depth) |
| Compliance (regulatory evidence) | `compliance` when `COMPLIANCE_FRAMEWORK` set; else `general-dev` / `android-dev` per standards |
| Lint (Android), Startup, Memory, Play*, Signing, Versioning, Backups, ProGuard, Baseline, Battery, Offline | `android-dev` |
| Lint (non-Android), Versioning (generic) | `general-dev` |
| Play store listing, keystore | `android-dev` + `user` |

### Fix agent ← Release Readiness

```
TASK_ID: <id>
TARGET_AGENT: bug-fix | android-dev | general-dev
RELEASE_BRIEF: .ai/context/release-readiness/{TASK_ID}.md
SCOPE: P0/P1 failures only — items listed in brief Priority Order
FAILURE_CATEGORIES:
* Crashes
* Lint
FILES:
* paths implicated by top failures
DELIVERABLE: Fix release blockers per brief Priority Order
NEXT_AGENT: documenter | reviewer
DONE
```

### Coordinator → Test Strategy Handoff

```
TASK_ID: <id>
TARGET_AGENT: test-strategy
FEATURE: <screen or module>
SCOPE:
* layers and modules
TEST_SURFACE: unit | integration | ui | mixed
FILES:
* paths from planner
PLAN_PATH: .ai/context/plans/{TASK_ID}.md
STRATEGY_ONLY: true | false
DEVICE_SERIAL: R58M90ABCDE          # optional — multi-phone desk
DEVICE_POLICY: physical             # optional — physical | emulator | auto
DELIVERABLE: Brief at .ai/context/test-strategies/{TASK_ID}.md
NEXT_AGENT: android-dev | general-dev | bug-fix | none
DONE
```

`STRATEGY_ONLY: false` (default) → `NEXT_AGENT: android-dev` | `general-dev` (platform from `project.md` or stack detection); optional `bug-fix` when spawned post-Imaginer. `STRATEGY_ONLY: true` → `NEXT_AGENT: none`.

**MAS-07 (v1.5.0):** When device commands are in scope, set `DEVICE_SERIAL` / `DEVICE_POLICY` on test-strategy handoff; test-strategy echoes values in **Device Prerequisites** table.

### Planner → Test Strategy

When non-trivial testable scope, Planner output / Coordinator sets `NEXT_AGENT: test-strategy` (not `android-dev`/`general-dev`).

```
DELIVERABLE: Task decomposition complete — test strategy required
NEXT_AGENT: test-strategy
```

### Test Strategy → Dev

```
TASK_ID: <id>
TARGET_AGENT: android-dev | general-dev
TEST_STRATEGY_BRIEF: .ai/context/test-strategies/{TASK_ID}.md
SCOPE: implement P0/P1 tests per brief; document skips
FILES:
* paths from brief
DELIVERABLE: Implementation + tests per test strategy brief
NEXT_AGENT: documenter
```

### Coordinator → OSINT Handoff

```
TASK_ID: <id>
TARGET_AGENT: osint
GOAL: <one sentence research objective>
RESEARCH_MODE: FEATURE | BUG
TOPIC: <one-line research question>
SCOPE: <feature area / symptom / stack component>
SOURCES_HINT:
* optional repos, docs, URLs
FILES:
* seed paths (optional, local context only)
RESEARCH_ONLY: true | false
DELIVERABLE: Brief at .ai/context/osint/{TASK_ID}.md
NEXT_AGENT: brainstorm | planner | imaginer | bug-fix | none
DONE
```

**`NEXT_AGENT` resolution:**

| Condition | `NEXT_AGENT` |
|-----------|--------------|
| `RESEARCH_ONLY: true` | `none` |
| `RESEARCH_MODE: FEATURE` + logic unclear | `brainstorm` |
| `RESEARCH_MODE: FEATURE` + scope clear | `planner` |
| `RESEARCH_MODE: BUG` + non-trivial data flow | `imaginer` |
| `RESEARCH_MODE: BUG` + fix pattern clear, trivial local trace | `bug-fix` |

### Coordinator → UX Intelligence Handoff

```
TASK_ID: <id>
TARGET_AGENT: ux-intelligence
FEATURE: <screen or flow>
USER_GOAL: <user intent>
SCOPE:
* primary path
* empty/loading/error states
FILES:
* paths from dev
UI_CHANGES: YES
UX_ONLY: true | false
DELIVERABLE: Brief at .ai/context/ux-reviews/{TASK_ID}.md
NEXT_AGENT: a11y | android-dev | general-dev | documenter | none
DONE
```

`UX_ONLY: true` → `NEXT_AGENT: none`. Brief with P0/P1 implementable fixes → `android-dev` | `general-dev`. When a11y predicate matches after UX, Coordinator routes to **a11y** next (sequential P1 chain). Advisory-only or no friction → `documenter`.

### Dev → Visual Fidelity → UX Intelligence (when UI_CHANGES: YES)

When Dev completes with `UI_CHANGES: YES`, Dev output sets `NEXT_AGENT: ux-intelligence` (Coordinator may insert **mas-visual-fidelity** first when P0-6 predicate fires — design-spec exists + `UI_CHANGES: YES`).

Dev handoff **must** declare `UI_CHANGES: YES | NO` when `.ai/context/design-specs/{TASK_ID}.md` exists. Document capture paths (Paparazzi class, `@Preview` name, baseline PNG) in `FILES` per Verification Contract.

```
UI_CHANGES: YES
DELIVERABLE: Implementation complete — UX review required
NEXT_AGENT: ux-intelligence
```

When P0-6 fires, Coordinator overrides chain: dev → **mas-visual-fidelity** → ux-intelligence. Dev does not self-attest fidelity without visual-qa brief downstream.

### UX Intelligence → Dev (second pass)

```
TASK_ID: <id>
TARGET_AGENT: android-dev | general-dev
UX_BRIEF: .ai/context/ux-reviews/{TASK_ID}.md
SCOPE: behavioral fixes only — no layout or cosmetic changes
FILES:
* paths from brief Files hint column
UI_CHANGES: YES
DELIVERABLE: Apply P0/P1 behavioral fixes from UX brief
NEXT_AGENT: documenter
```

### Post-Bug Fix Reviewer Handoff (Coordinator → Reviewer)

Required after every Bug Fix completion. `NEXT_AGENT` on Bug Fix handoff must be `reviewer`.

```
TASK_ID: <id>
TARGET_AGENT: reviewer
GOAL: Verify bug is perfectly resolved.
ORIGINAL_SYMPTOM: <user report or stack trace>
ROOT_CAUSE: <from Bug Fix>
FIX_SUMMARY: <what changed>
REPRO_STEPS:
* step
FILES:
* patched paths
UI_CHANGES: YES | NO
MODULES:
* :app
DELIVERABLE: Bug Resolution Verification + Build & Tests + Visual QA if UI
NEXT_AGENT: none
DONE
```

## Rules

- Keep handoffs under 20 lines.
- **`MODE`:** `FULL` for `/mas`; `LITE` for `/mas-lite` (required on every coordinator handoff).
- **`TIER`:** `S` | `M` | `L` | `L+` for lite; `none` or omit semantics for full `/mas`.
- **`MODEL_CLASS:`** optional — overrides [spawn-model-policy.md](spawn-model-policy.md) default for Task `model` param.
- **`BRIEF_PATH:`** + optional **`SECTIONS:`** — artifact-forward; specialist reads path (and heading slice only when `SECTIONS` set). Prefer `BRIEF_PATH` over `CONTEXT` bullets when brief exists.
- Reference `memory.md` by section name; never paste its contents.
- Never paste entire conversations or codebases.
- Coordinator writes handoff to disk; do not duplicate full handoff in chat.

## Agent Output Templates

### Spec Reader

```
## Sources

| Document | Status | Notes |

## Requirements Summary

## API Contract Summary

## Design & UX Notes

## Acceptance Criteria

## Constraints

## Assumptions

## Open Questions

## Conflicts with Memory

## Brief Path

.ai/context/specs/{TASK_ID}.md

## Recommended Next Agent

planner

DONE
```

Coordinator sets `NEXT_AGENT: brainstorm` (greenfield) or `planner` (trivial scope).

### Brainstorm

```
## Outcome

## UI Scope

logic-only | ui-allowed

## Options

| # | Option | Pros | Cons | Risk | Effort |

## Recommended

## Logic Flow

## Domain & Contracts

## Edge Cases

## Quality Bar

## Risks & Open Questions

## Brief File

.ai/context/brainstorms/{TASK_ID}.md

## Suggested Next

planner | architect

DONE
```

Coordinator sets `NEXT_AGENT: planner` (default) or `architect` per `Suggested Next`.

### Planner

```
## Plan

Goal:
...

Tasks:
1.
2.
3.

## Dependencies:

## Risks:

## Build & Test Plan:

## Visual QA Scenarios:

## Required Agents:

DONE
```

### Architect

```
## Architecture

## Modules:

## Layers:

## Contracts:

## Files:

DONE
```

### Android Dev / General Dev

```
## Files

<file path>

<code>

## Tests

<file path or N/A>

<command + PASS/FAIL>

## Build

<command + PASS/FAIL>

## Responsive Notes

## Visual Notes

DONE
```

Android Dev / General Dev output sets `NEXT_AGENT: ux-intelligence` when `UI_CHANGES: YES`; `NEXT_AGENT: documenter` when `UI_CHANGES: NO` or logic-only.

### UX Intelligence

```
## Feature

...

## Persona Journey

1.

## Friction Points

| # | Dimension | Moment | User struggle | Why it hurts | Behavioral fix | Priority | Files hint |

## Recommended Behavioral Fixes

1.

## Preserve UI Checklist

- [ ] No layout moves proposed
- [ ] No cosmetic/token changes proposed

## Confidence

HIGH | MEDIUM | LOW

## Regression Notes

...

## Brief Path

.ai/context/ux-reviews/{TASK_ID}.md

DONE
```

Standards: [ux-intelligence-standards.md](../references/ux-intelligence-standards.md). Coordinator sets `NEXT_AGENT: android-dev | general-dev | documenter | none` per brief content and `UX_ONLY` flag.

### Imaginer

```
## Symptom

...

## User Journey

1.
2.

## Data Flow

| Hop | Layer | Component | Input | Transform | Output | Events |

## Suspected Failure Points

| # | Hop | Hypothesis | Evidence | Confidence |

## Confidence

HIGH | MEDIUM | LOW

## Regression Notes

...

## Brief Path

.ai/context/imaginations/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: bug-fix` (default) or `none` when `TRACE_ONLY: true`.

### OSINT

```
## Research Mode

FEATURE | BUG

## Topic

...

## Scope

...

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |

## Recommended Approach | Recommended Fix Strategy

<mode-appropriate section>

## Priority Order

1. ...

## Overall Confidence

HIGH | MEDIUM | LOW

## Brief Path

.ai/context/osint/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT` per `RESEARCH_MODE` and `RESEARCH_ONLY` (see OSINT handoff subsection). `RESEARCH_ONLY: true` → `none`.

### Perf Optimizer

```
## Perf Symptom

...

## Scope

...

## Findings

| # | Current | Issue | Why | Impact | Recommended architecture | Optimized implementation | Confidence |

## Priority Order

1. ...

## Expected Improvement

...

## Regression Notes

...

## Brief Path

.ai/context/optimizations/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: android-dev` | `general-dev` (default) or `none` when `ANALYZE_ONLY: true`.

### Release Readiness

```
## Release Target

...

## Scope

...

## Category Results

| Category | Status | Blocker | Finding | Fix agent |
...

## Release Ready

YES | NO

## Priority Order

1. ...

## Regression Notes

...

## Brief Path

.ai/context/release-readiness/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: bug-fix` | `android-dev` | `general-dev` | `none` when `RELEASE_ONLY: true` or all pass; `commit` only when user confirmed ship.

### Test Strategy

```
## Feature

...

## Scope

...

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |

## Tests to Skip

| # | Target | Reason | Covered by |

## Edge Cases

| Case | Layer | Test approach | Priority |

## Regression Risks

...

## Flaky Test Risks

| Risk | Surface | Mitigation |

## Recommended Commands

- ...

## Confidence

HIGH | MEDIUM | LOW

## Brief Path

.ai/context/test-strategies/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: android-dev` | `general-dev` | `bug-fix` (optional bug chain) or `none` when `STRATEGY_ONLY: true`.

### Security Auditor

```
## Threat Model

...

## Findings

| # | Category | Finding | Exploit path | Severity | Validation | Recommendation |

## Validation

...

## Blockers

| # | Finding | Rationale | Fix agent |

## Brief Path

.ai/context/security-audits/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: test-executor | documenter | reviewer | none`.

### Dependency Risk

```
## Dependency Delta

...

## CVE Summary

| Package | Version | CVE/EPSS | Severity | Status |

## Blast Radius

...

## Remediation

| # | Item | Action | Priority | Notes |

## Brief Path

.ai/context/supply-chain/{TASK_ID}.md

DONE
```

### API Contract

```
## Spec Inventory

| Spec | Version | Endpoints/Types | Notes |

## Breaking Changes

| # | Change | Impact | Consumers | Severity |

## Drift

...

## Recommendations

| # | Item | Action | Priority |

## Brief Path

.ai/context/api-contracts/{TASK_ID}.md

DONE
```

### Test Executor

```
## Commands

| # | Command | Source | Result |

## Pass/fail

Overall: PASS | FAIL | PARTIAL

## Failures

| # | Command | Error summary | Flaky | Route |

## Gaps

...

## Brief Path

.ai/context/test-runs/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: documenter | reviewer | bug-fix | none`.

### A11y

```
## WCAG table

| # | Criterion | Level | Status | Finding | Recommendation | Priority |

## Findings

| # | Component | Issue | WCAG ref | Severity | Fix agent |

## Fix priority

1. ...

## Manual checklist

- [ ] Keyboard navigation
- [ ] Screen reader labels
- [ ] Focus order
- [ ] Color contrast (when verifiable from code)

## Brief Path

.ai/context/a11y-reviews/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: i18n | test-executor | documenter | reviewer | none`.

### I18n

```
## String inventory

| Key / resource | File | Hardcoded | Extraction status |

## Locale gaps

| Locale | Missing keys | Notes |

## RTL

<RTL layout/string audit notes or N/A>

## Recommendations

| # | Item | Action | Priority | Fix agent |

## Brief Path

.ai/context/i18n-reviews/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: compliance | test-executor | documenter | reviewer | none`.

### Compliance

```
## Framework map

| Clause / control | Requirement | Evidence status | Gap |

## Gaps

| # | Control | Gap | Severity | Remediation owner |

## Evidence

<artifacts reviewed, logs, configs — no secrets>

## Remediation

| # | Gap | Action | Priority | HITL required |

## Not legal advice

This brief is an engineering evidence audit only — not legal counsel, certification, or sign-off. Legal and production remediation require human review.

## Brief Path

.ai/context/compliance/{TASK_ID}.md

DONE
```

Coordinator sets `NEXT_AGENT: test-executor | documenter | reviewer | release-readiness | none`.

### Bug Fix

```
## Original Symptom

...

## Repro Steps

1.
2.

## Root Cause

...

## Confidence

HIGH | MEDIUM | LOW

## Fix Strategy

*

## Files To Modify

*

## Patch

<code>

## Regression Risks

*

## Build & Tests

## Visual After Fix

DONE
```

Coordinator routes Bug Fix → **Documenter** (if FILES) → Reviewer (`NEXT_AGENT: documenter` then `reviewer`).

### Documenter

```
## Comment Audit

<file>:
- CREATED / UPDATED / DELETED: ...

## Files Updated

<file path>

## Summary

Created: N | Updated: N | Deleted: N

DONE
```

Handoff in: `FILES`, `CHANGE_SUMMARY`, `PUBLIC_API: YES | NO`.  
Handoff out: `NEXT_AGENT: reviewer`.

### Reviewer

```
## Findings

## Bug Resolution Verification:

<required after Bug Fix; N/A otherwise>

## Implementation Walkthrough:

## Lint:

## Build & Tests:

## Visual QA (Imagined):

## Similar Flow Comparison:

## Android Veteran Review:

## Edge Cases:

## Critical:

## Major:

## Minor:

Approved:
YES | NO

## Daily Summary

<one line, ≤120 chars — only when FILES non-empty; Coordinator prefers this for changelog append>

## Memory Update

<optional>

DONE
```

Post-bugfix: `Approved: YES` requires `Issue Resolved: YES`.

All Android reviews: `Approved: YES` requires build PASS, tests PASS (or documented NOT_RUN), visual QA PASS for `UI_CHANGES: YES`.

After approval, Coordinator may offer Commit agent if user opts in — Reviewer does not commit.

### Commit

```
## Change Summary

## Proposed Commit Message

```
subject

body
```

## Files to Stage

## Branch Status

## Reviewer Gate

PASS | WARN | N/A

## Confirmation

Commit: PENDING | APPROVED | SKIPPED
Push: PENDING | APPROVED | SKIPPED

## Result

DONE
```

Handoff in: `TASK_ID`, `PUSH: ASK | YES | NO`, optional Reviewer approval reference.  
Agent must obtain explicit user yes before `git commit` and separate yes before `git push`.
