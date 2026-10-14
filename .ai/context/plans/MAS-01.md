# Plan Brief — MAS-01

## Plan

Goal:
Implement **Option 2 — Incremental upgrade** (per `.ai/context/brainstorms/MAS-01.md`): tiered model spawn policy, artifact-forwarding handoffs, brief schema registry, explicit loop caps, capped debate micro-chain on 2nd Reviewer rejection, optional post-workflow token auditor, and install-path deduplication — without changing deterministic Coordinator routing or sequential foreground spawn defaults.

Tasks:

### Phase 1 — Install dedup + spawn model policy (S)

1. **Install canonical source decision** — Architect confirms: root `install/` becomes export-generated stub OR pointer-only; canonical = `skills/multi-agent-system/install/`.
   - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1`, root `install/` (remove or replace), `README.md`, `skills/multi-agent-system/install/README.md`
   - **Acceptance:** `export-mas-framework.ps1` copies nested install to root `install/` on export (or root `install/README.md` points to nested path only); no hand-edited duplicate scripts in repo; hash guard in export script fails if nested vs exported root install diverge when both exist.

2. **Create `protocol/spawn-model-policy.md`** — Default `MODEL_CLASS` map per agent slug; Task `model` hint column; override rules via handoff `MODEL_CLASS:`; lite `MC:` abbreviation cross-ref.
   - **Files:** `skills/multi-agent-system/protocol/spawn-model-policy.md` (new)
   - **Acceptance:** Table covers all 17 existing slugs + `debate-synthesizer` + `token-auditor`; documents `fast` → `composer-2.5-fast`, `thinking` → thinking-high family, `normal` → default; fallback when Task `model` unsupported.

3. **Extend handoff formats with `MODEL_CLASS`, `BRIEF_PATH`, `SECTIONS:`**
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`
   - **Acceptance:** Coordinator template includes optional `MODEL_CLASS:`; `BRIEF_PATH:` + optional `SECTIONS:` documented with examples; lite format documents `MC:` / `BP:` abbreviations within 12-line cap; existing handoffs without new fields remain valid.

4. **Update `subagent-spawn.md`** — Map `MODEL_CLASS` to Task `model` param; add slug rows for `debate-synthesizer` and `token-auditor`; prompt template references `spawn-model-policy.md`.
   - **Files:** `skills/multi-agent-system/protocol/subagent-spawn.md`
   - **Acceptance:** Spawn sequence step documents model resolution order (handoff override → policy default → `default`); new agent slug table entries present; `run_in_background: false` preserved.

5. **Update `mas-coordinator/SKILL.md`** — Spawn with Task `model` from policy; record `model_class` on `record-workflow-step.ps1`; artifact-forward user summary rule (one line + path, no brief body paste).
   - **Files:** `skills/mas-coordinator/SKILL.md`
   - **Acceptance:** Routing Rules section references spawn-model-policy; spawn sequence includes `-ModelClass` derivation; user-facing summaries explicitly forbid paraphrasing full briefs.

6. **Update install manifest** — Register new skills when created (placeholder entries OK in Phase 1 if skills deferred).
   - **Files:** `skills/multi-agent-system/install/manifest.json`
   - **Acceptance:** `skills` array includes `mas-debate`, `mas-token-auditor` (add in Phase 3/4 if not Phase 1).

### Phase 2 — Artifact forwarding + schemas + caps (S)

7. **Create `protocol/brief-schemas.md`** — Required sections per brief type; validation guidance (Reviewer flags gaps).
   - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md` (new)
   - **Acceptance:** Tables for `osint`, `brainstorm`, `plan`, `debate`, `audit` brief types with path pattern and required headings; note that specialists complete even if sections missing (Reviewer enforces).

8. **Update `protocol/token-rules.md`** — Add constants `MAX_CHAIN_AGENTS`, `MAX_REVIEWER_LOOPS`, `MAX_DEBATE_ROUNDS`, `MAX_DEBATE_SESSIONS_PER_TASK`; lite tier values; artifact-forward rule.
   - **Files:** `skills/multi-agent-system/protocol/token-rules.md`
   - **Acceptance:** Full `/mas`: chain=12, reviewer loops=2, debate rounds=2, debate sessions=1; Lite: S=2, M=2, L=3, L+=4 chain agents; lite debate rounds=1; Coordinator escalation behavior documented on cap breach.

9. **Update `protocol/read-order.md`** — Subscription matrix: which agents read which `{TASK_ID}` briefs at startup.
   - **Files:** `skills/multi-agent-system/protocol/read-order.md`
   - **Acceptance:** Matrix rows for brainstorm, planner, architect, dev/bug-fix, reviewer, debate-synthesizer, token-auditor; `BRIEF_PATH` + `SECTIONS:` slice semantics documented.

10. **Extend session JSON schema** — `reviewer_loop_count`, `debate_used`, `debate_round` fields.
    - **Files:** `skills/multi-agent-system/protocol/workflow-usage-policy.md`, `skills/multi-agent-system/scripts/init-workflow-session.ps1`
    - **Acceptance:** Schema docs updated; init script seeds new fields with defaults (`0`, `false`, `0`); idempotent on existing sessions.

11. **Update specialist skills startup** — Reference `brief-schemas.md` and subscription matrix where agents write briefs (osint, brainstorm, planner, reviewer at minimum).
    - **Files:** `skills/mas-osint/SKILL.md`, `skills/mas-brainstorm/SKILL.md`, `skills/mas-planner/SKILL.md`, `skills/mas-reviewer/SKILL.md`
    - **Acceptance:** Each skill's Startup or Output section cites schema path; no full schema paste.

### Phase 3 — Debate micro-chain (M)

12. **Create `skills/mas-debate/SKILL.md`** — Debate-synthesizer role: security + simplicity personas (sequential in v1, not separate spawns); max 2 rounds; output `.ai/context/debates/{TASK_ID}.md`.
    - **Files:** `skills/mas-debate/SKILL.md` (new), `.ai/context/debates/.gitkeep` (or init script creates dir)
    - **Acceptance:** Trigger = Coordinator only, `reviewer_loop_count >= 2` and `debate_used == false`; skill forbids Task spawn; output template matches brief-schemas debate sections (Critics, Consensus, Action items, Dissent); `NEXT_AGENT: bug-fix`.

13. **Coordinator Reviewer rejection loop** — Increment `reviewer_loop_count`; loop 1 → bug-fix with filtered findings only; loop 2 → debate then bug-fix; cap → user escalation.
    - **Files:** `skills/mas-coordinator/SKILL.md`, `skills/multi-agent-system/protocol/handoff-format.md` (debate handoff subsection), `skills/multi-agent-system/protocol/subagent-spawn.md`
    - **Acceptance:** `DEBATE_TRIGGER: reviewer-rejection-2` documented; agents-as-tools pattern for bug-fix handoff (findings only); `debate_used` set true after debate spawn; no third auto-retry after `MAX_REVIEWER_LOOPS`.

14. **Update `mas-bug-fix/SKILL.md`** — Read `debates/{TASK_ID}.md` when `DEBATE_TRIGGER` or debate brief exists.
    - **Files:** `skills/mas-bug-fix/SKILL.md`
    - **Acceptance:** Startup lists debate brief in read-order; fix strategy cites consensus action items.

15. **Register `mas-debate` in manifest + export** — Ensure install copies new skill.
    - **Files:** `skills/multi-agent-system/install/manifest.json`, `skills/multi-agent-system/install/export-mas-framework.ps1` (if skill list hardcoded)
    - **Acceptance:** `mas-debate` in manifest `skills` array; export includes `skills/mas-debate/`.

### Phase 4 — Token auditor (S)

16. **Create `skills/mas-token-auditor/SKILL.md`** — Post-finalize advisory; reads `workflow-sessions/{TASK_ID}.json`; writes `.ai/context/audits/{TASK_ID}.md`.
    - **Files:** `skills/mas-token-auditor/SKILL.md` (new), `.ai/context/audits/.gitkeep`
    - **Acceptance:** Never blocks approval; trigger = post `finalize-workflow-usage.ps1` + `Approved: YES` + non-empty FILES; optional Coordinator heuristic (`tokens=unknown` on 3+ steps); output matches audit schema.

17. **Coordinator post-finalize optional spawn** — Document auditor trigger and skip conditions (planning-only, lite default skip).
    - **Files:** `skills/mas-coordinator/SKILL.md`, `skills/mas-lite/SKILL.md`
    - **Acceptance:** Full `/mas` documents opt-in spawn; lite omits unless user requests; handoff `TARGET_AGENT: token-auditor` template added.

18. **Register `mas-token-auditor` in manifest** — Same as task 15 for auditor skill.
    - **Files:** `skills/multi-agent-system/install/manifest.json`
    - **Acceptance:** `mas-token-auditor` in manifest; export includes skill tree.

### Phase 5 — Documentation + regression (S)

19. **Update root and nested READMEs** — Install path after dedup; new protocol files listed; debate/auditor overview.
    - **Files:** `README.md`, `skills/multi-agent-system/SKILL.md`, `skills/multi-agent-system/install/README.md`, root `install/README.md` (if kept as pointer)
    - **Acceptance:** No references to "mirrors by design" duplicate install without explaining export-only model; quick-install path valid.

20. **Documenter pass** — In-code comments on changed scripts only where non-obvious (init session fields, export hash guard).
    - **Files:** per general-dev deliverable
    - **Acceptance:** Documenter audits changed script headers; no comment spam on markdown protocol files.

### Deferred (v2 — do not implement in MAS-01)

- Parallel read-only OSINT ∥ Spec Reader (`PARALLEL_READ: YES` flag)
- LLM-assisted L+ dynamic routing
- Optional schema validator script (unit tests for heading check)

## Dependencies:

| Task | Depends on |
|------|------------|
| 2–5 | 1 (install path stable for manifest/export) |
| 7–9 | 2 (MODEL_CLASS field defined) |
| 10 | 7 (schema docs reference session fields) |
| 12–15 | 7, 8, 10 (schemas, caps, session fields) |
| 16–18 | 10, 5 (session JSON + coordinator finalize flow) |
| 19–20 | All implementation tasks |

**External context:** `.ai/context/osint/MAS-01.md` (priority order), `.ai/context/brainstorms/MAS-01.md` (Option 2 logic flow). No `project.md` / `memory.md` in workspace — N/A.

**Architect gate (task 1):** Install dedup strategy (remove vs export-generated root `install/`) and debate v1 persona execution model (single synthesizer vs multi-spawn) — brief architect review before Phase 1 task 2 and Phase 3 task 12 if handoff routes to architect.

## Risks:

| Risk | Mitigation |
|------|------------|
| Debate adds noise on code review (OSINT confidence MEDIUM) | Cap at 1 session / 2 rounds; Coordinator flag to skip debate |
| Lite 12-line handoff overflow with new fields | `MC:` / `BP:` abbreviations; architect validates in task 1 |
| Task `model` param unsupported in Cursor | Fallback to default; record `model: default` in session |
| Root `install/` removal breaks contributor quick-start | README + pointer stub; export regenerates on release |
| Token metadata unavailable | Auditor uses Usage Report + `unknown`; no hard dependency |
| Regression on existing chains | New fields optional; defaults preserve current behavior |

## Build & Test Plan:

**N/A — Gradle/Android.** Logic-only framework upgrade.

| Surface | Command / action | Pass criteria |
|---------|------------------|---------------|
| Init session | `powershell -File skills/multi-agent-system/scripts/init-workflow-session.ps1 -ProjectPath <ws> -TaskId MAS-01-test -Mode FULL -Tier none` | JSON contains `reviewer_loop_count`, `debate_used`, `debate_round` |
| Record step | `record-workflow-step.ps1` with `-ModelClass fast` | Step JSON has `model_class: fast` |
| Export hash guard | Run `export-mas-framework.ps1 -OutputDir <tmp>` after dedup | No duplicate drift; install bundle complete |
| Install dry-run | `install-mas-framework.ps1` against temp `.cursor` (manual) | New skills present; manifest skills count matches |
| Handoff parse | Manual: write handoff with `MODEL_CLASS`, `BRIEF_PATH`, `SECTIONS:` | Coordinator prompt resolves paths; subagent reads slice only |
| Debate chain | Manual MAS-01 workflow: force 2× Reviewer `NO` | `debates/MAS-01.md` created; `debate_used: true`; escalation on 3rd |
| Regression | Run existing `/mas` chain without new handoff fields | Unchanged routing; no errors |
| Schema check | Reviewer flags brainstorm missing `Logic Flow` | `Approved: NO` with schema gap note |

**test-strategy agent:** Optional brief for schema validator script (deferred v2); not blocking MAS-01.

## Visual QA Scenarios:

N/A — `UI_SCOPE: logic-only` per brainstorm. No Compose screens, layouts, or theme tokens.

## Required Agents:

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Before Phase 1 export dedup + Phase 3 debate structure | Install path resolution; debate persona model; lite abbreviation sign-off |
| **general-dev** | Phases 1–4 implementation | All protocol files, skills, scripts, manifest |
| **documenter** | After general-dev | README redirects, script header comments |
| **reviewer** | Final gate | Protocol consistency, regression checklist, schema compliance |
| **test-strategy** | Optional / defer v2 | Schema validator script design only if user requests |

**Not required:** android-dev, ux-intelligence, spec-reader, imaginer, perf-optimizer, release-readiness, commit (unless user opts in post-approval).

## Acceptance criteria (workflow-level)

1. Coordinator spawns specialists with `MODEL_CLASS` mapped to Task `model` per `spawn-model-policy.md`.
2. User summaries after specialist steps are one line + brief path — no inline brief bodies.
3. `token-rules.md` caps enforced; user escalation after max reviewer loops.
4. Second Reviewer `NO` triggers single debate session → bug-fix; third rejection escalates.
5. Install maintained from single canonical `skills/multi-agent-system/install/`; no duplicate hand-edited root copies.
6. `manifest.json` lists `mas-debate` and `mas-token-auditor`.
7. Existing workflows without new handoff fields behave unchanged.
