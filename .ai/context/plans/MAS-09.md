# Plan Brief — MAS-09

## Plan

Goal:
Ship **Option 3 — Two-layer composite repro observability** (per `.ai/context/brainstorms/MAS-09.md` Recommended and `.ai/context/osint/MAS-09.md` Recommended Approach): prep-gated `capture-device-logs.{ps1|sh}` host scripts + `device-log-capture.md` reference + Cursor hook recipes (`stop` dump, optional `beforeSubmitPrompt` clear) + test-executor Step 0b/Post + test-run **Device Logs** slice + handoff flags (`LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG`) + app structured-logging convention doc — so `/mas` bug-repro workflows **clear log buffers before repro**, **dump filtered logcat after repro** to `.ai/context/device-logs/{TASK_ID}/`, and surface **path-only metadata** to agents via hooks (never full log bodies). **Logic-only** in MAS framework repo — no target app patches, no Compose debug UI.

**Upstream context:** `.ai/handoffs/MAS-09-planner.md`; brainstorm Logic Flow A–F, Domain & Contracts; OSINT Findings #1–#8 (HIGH confidence on P0/P1 items).

**Complements:** MAS-07 `android-device-prep` gate + test-run **Device** section; MAS-08 project hooks, fail-open v1.6, artifact-forward invariant; `capture-connected-device.{ps1|sh}` sibling script pattern.

**Version target:** `1.7.0` — additive scripts + hooks + protocol; architect confirms semver.

**Resolved open questions (D1–D8 — architect confirms in Phase 0):**

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | **test-run Device Logs slice first** — not standalone `device-logs` brief type until bug-fix-only workflows need logs without test execution | Brainstorm Q1; lower schema churn; promote to brief type in P2 if needed |
| D2 | **`capture-device-logs` requires prior prep PASS** — does not invoke prep inline; FAIL `NO_SERIAL` if `ANDROID_SERIAL` unset | Single serial SOT with MAS-07; matches prep-first invariant in OSINT Finding #2 |
| D3 | **Handoff flags:** `LOG_CAPTURE: yes\|no` (default no), `LOG_PACKAGE`, `LOG_TAG` (default `APP_TRACE`), `LOG_BUFFERS` (default `main,crash`), `LOG_FORMAT` (`json\|threadtime`); lite alias `LOG:y` | Brainstorm Q3; align MAS-08 handoff extension process |
| D4 | **Default format:** API 30+ → `-v json`; else `-v threadtime` with warning in `capture-meta.json` | Brainstorm Q4; OSINT API-level guidance |
| D5 | **P0 unbounded dump; P1 `--max-lines 5000` default** with truncation warning in meta | Brainstorm Q5; balance token cost vs completeness |
| D6 | **Convention doc: lightweight custom Timber tree** — structlog-timber optional mention only, not framework dependency | Brainstorm Q6; avoid supply-chain in MAS repo |
| D7 | **Workflow session field:** `log_capture_path` (string) pointing to `capture-meta.json`; optional nested `line_count` in session step record only | Brainstorm Q7; minimal schema delta |
| D8 | **`beforeSubmitPrompt` auto-clear opt-in only** via handoff `LOG_CAPTURE: yes` + repro keywords — never default-on | OSINT + brainstorm edge case; avoids clearing non-bug sessions |

**Non-negotiable invariants:**

- Prep coupling: never run log ops without resolved `ANDROID_SERIAL` (same as MAS-07)
- Artifact-forward: hooks and `additional_context` expose paths only (~200 chars max)
- Fail-open hooks: log capture failure must not block agent `stop` or subagent chain
- Security: no tokens/PII in logs or meta; redaction checklist in convention doc
- Chucker/Flipper: optional human debug only — MAS reads logcat artifacts, not inspector DB

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms log capture topology and contracts** — Validate script state machine, `capture-meta.json` schema, stdout JSON contract, exit codes, hook event wiring, test-run **Device Logs** slice registration, handoff flags, bug-fix ingestion path, platform-parity (Cloud SKIP), and D1–D8 resolutions above.
   - **Files:** `.ai/context/architecture/MAS-09.md` (new)
   - **Decisions required:**
     - Subcommands: `clear`, `dump`, `marker`, `clear-and-marker`; flags (`--serial`, `--package`, `--tag`, `--buffers`, `--format`, `--output-dir`, `--task-id`, `--max-lines` P1)
     - Prep gate: require `ANDROID_SERIAL` from Step 0 PASS; no inline prep call
     - PID resolution: `pidof -s $PACKAGE` at dump time; stale-PID fallback documented
     - `capture-meta.json` + `repro-marker.json` schema; script stdout JSON (last line, prep-style)
     - Exit codes: reuse prep map (10–15) + `CAPTURE_EMPTY` (warn, exit 0), `DUMP_FAILED` (21), `INVALID_ARGS` (7)
     - Hook contracts: `stop` dump when `LOG_CAPTURE: yes`; optional `beforeSubmitPrompt` clear; `afterShellExecution` matcher for script/adb logcat; extend `record-workflow-step` with `log_capture_path`
     - test-run **Device Logs** section fields (conditional on `LOG_CAPTURE: yes`)
     - brief-schemas delta: register **Device Logs** slice rule (parallel to MAS-07 **Device**)
     - bug-fix / imaginer: `BRIEF_PATH` → `capture-meta.json`; parse priority crash → APP_TRACE → main tail
     - Fixture dry-run mode mirroring MAS-07 (`ADB_DEVICES_FIXTURE`, no live adb)
     - Semver `1.7.0`; manifest scripts array entry
     - P2 boundary: `LOG_ESCALATION: full-bugreport`, `mas-observability` prod vs local logcat
   - **Acceptance:** Architecture brief documents end-to-end flow (handoff flags → prep → clear → repro → dump → hook path → bug-fix ingestion) without re-litigating brainstorm options.

### Phase P0 — Host scripts + reference + hooks (v1.7.0 core)

2. **Create `device-log-capture.md`** — Framework reference for log capture workflow, tag namespace, buffer list, format fallback, redaction rules, prep prerequisite, PID re-resolution, Cloud SKIP path.
   - **Files:** `skills/multi-agent-system/references/device-log-capture.md` (new)
   - **Content:** Prep-first invariant; subcommand state machine; filter expressions (`$TAG:D *:S`); API 30+ json vs threadtime; artifact dir layout; `capture-meta.json` field glossary; enrollment/blocker cross-ref to `device-prep-automation.md`; Chucker/Flipper as optional debug companion (not ingestion); escalation tier note (P2 bugreport)
   - **Acceptance:** Referenced from test-executor, test-strategy, mas-android-dev convention slice; single SOT with script.

3. **Create `capture-device-logs.ps1`** — Windows-first prep-gated log capture script (sibling to `android-device-prep.ps1`).
   - **Files:** `skills/multi-agent-system/scripts/capture-device-logs.ps1` (new)
   - **Pipeline:** Validate serial → subcommand dispatch → `adb -s $SERIAL logcat -c` (clear) / `-d -b main,crash` (dump) with format + tag + optional PID filter → write `.ai/context/device-logs/{TASK_ID}/` artifacts → JSON stdout last line
   - **Artifacts:** `logcat-main.jsonl`, `logcat-crash.txt`, `capture-meta.json`, `repro-marker.json` (marker/clear-and-marker)
   - **Stdout JSON:** `{ "status", "exit_code", "message", "capture_meta_path", "line_count" }`
   - **Acceptance:** `-Help` documents flags/subcommands; idempotent clear/dump; prep FAIL path does not call adb; matches architect contract from Task 1.

4. **Create `capture-device-logs.sh`** — POSIX twin for bash CI / Linux agents.
   - **Files:** `skills/multi-agent-system/scripts/capture-device-logs.sh` (new)
   - **Acceptance:** Same JSON schema, exit codes, and artifact layout as `.ps1`; executable bit noted for documenter.

5. **Extend `device-prep-automation.md`** — Add **Log capture** section: prep prerequisite, chaining after Step 0, serial export, relationship to visual-fidelity / test-executor.
   - **Files:** `skills/multi-agent-system/references/device-prep-automation.md` (extend)
   - **Acceptance:** Cross-ref `device-log-capture.md`; no duplicate state machine logic.

6. **Create log capture hook script + template entries** — `stop` dump hook; optional `beforeSubmitPrompt` clear; fail-open JSON stdout.
   - **Files:** `skills/multi-agent-system/hooks/capture-device-logs-hook.ps1`, `.sh` (or `.cursor/hooks/` copies); `.cursor/hooks.json` template extension in install bundle
   - **Behavior:** Read latest handoff `TASK_ID` + `LOG_CAPTURE`; on `stop` + `status=completed` invoke dump; return `{ "additional_context": "Device logs: .ai/context/device-logs/{TASK_ID}/capture-meta.json" }` only
   - **Acceptance:** Hook failure returns `{}`; no log body in stdout; Cloud Agent documents SKIP in platform-parity.

7. **Extend bootstrap / init for log capture hooks** — Copy hook scripts; emit `stop` + optional `beforeSubmitPrompt` entries when MAS project initialized.
   - **Files:** `skills/multi-agent-system/install/init-mas-context.ps1` or project init script (extend); install bundle templates
   - **Acceptance:** Fresh bootstrap includes log capture hook entries; fail-open defaults preserved.

8. **Update `install/manifest.json`** — Version bump to `1.7.0`; add `capture-device-logs.{ps1|sh}` to scripts array; hook script paths.
   - **Files:** `skills/multi-agent-system/install/manifest.json`

9. **Create log capture fixture harness** — Mocked adb / dry-run fixtures for framework dogfood (no physical device).
   - **Files:** `.ai/fixtures/MAS-09-LOG-CAPTURE/` — `adb-logcat-empty.txt`, `capture-meta-expected.json`, `script-stdout-pass.json`, `script-stdout-capture-empty.json`, `handoff-stub.md`, `test-run-expected-shape.md`
   - **Cases:** prep FAIL → no adb; clear PASS; dump PASS with lines; dump CAPTURE_EMPTY warn; unauthorized serial blocked
   - **Acceptance:** Fixtures cover P0 exit codes and JSON shapes for reviewer contract tests.

### Phase P1 — Protocol, executor, convention, coordinator

10. **Extend `brief-schemas.md`** — Register test-run **Device Logs** conditional section (parallel to MAS-07 **Device**).
    - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md`
    - **Fields:** Capture gate, Prep prerequisite, Clear executed, Dump path, Format, Line count, Tag filter, Package, Message
    - **Rule:** Required when `LOG_CAPTURE: yes` and capture attempted (PASS/FAIL/SKIP); omit when JVM-only with documented skip
    - **Acceptance:** Registry documents conditional rule; reviewer notes Device Logs evidence dependency.

11. **Extend `handoff-format.md` + lite format** — Document log capture coordinator fields.
    - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `handoff-format-lite.md`
    - **Fields:** `LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG`, `LOG_BUFFERS`, `LOG_FORMAT`; lite `LOG:y`; P2 `LOG_ESCALATION: full-bugreport`
    - **Routing:** Coordinator sets flags on test-executor / bug-fix handoffs when user requests repro logging
    - **Acceptance:** Existing handoffs remain valid (default `LOG_CAPTURE: no`).

12. **Extend `test-strategy-standards.md`** — Add **Device Logs Prerequisites** subsection under Device Prerequisites when `LOG_CAPTURE: yes`.
    - **Files:** `skills/multi-agent-system/references/test-strategy-standards.md`
    - **Content:** Clear-before-repro requirement; tag/package declaration; skip rationale for JVM-only; cross-ref `device-log-capture.md`
    - **Acceptance:** Template aligns with brainstorm §E test-executor extension table.

13. **Update `mas-test-executor/SKILL.md`** — Add Step 0b (clear + marker) and Post dump workflow; **Device Logs** section in output template.
    - **Files:** `skills/mas-test-executor/SKILL.md`
    - **Step 0b:** When `LOG_CAPTURE: yes` and prep PASS → `capture-device-logs clear-and-marker`
    - **Post:** After repro/test commands → `capture-device-logs dump` → populate test-run **Device Logs**
    - **Rules:** Serialize adb (prep → clear → commands → dump); skip capture on prep FAIL with SKIPPED rationale
    - **Acceptance:** Mutual exclusion with test-strategy preserved; run-only boundary unchanged.

14. **Update `mas-test-strategy/SKILL.md`** — Declare log capture prerequisites when strategy includes repro/bug surface or handoff `LOG_CAPTURE: yes`.
    - **Files:** `skills/mas-test-strategy/SKILL.md`
    - **Acceptance:** Brief template includes log capture row when applicable; honors `LOG_PACKAGE` / `LOG_TAG` from handoff.

15. **Update `mas-coordinator/SKILL.md`** — Document `LOG_CAPTURE` routing to test-executor and bug-fix; optional `BRIEF_PATH` to `capture-meta.json` on bug-fix spawn.
    - **Files:** `skills/mas-coordinator/SKILL.md`
    - **Acceptance:** Flags optional; default no; Cloud Agent SKIP documented.

16. **Extend app logging convention** — Structured repro logging guide for target Android apps (Timber + OkHttp EventListener + lifecycle); not shipped as framework code.
    - **Files:** Extend `skills/mas-android-dev/SKILL.md` with **Repro logging convention** slice OR new `skills/mas-repro-logging/SKILL.md` (architect picks in Task 1)
    - **Content:** `APP_TRACE` tag namespace; event types (`http`, `lifecycle`, `uncaught`, `nav`, `repro_marker`); OkHttp custom EventListener (not LoggingEventListener); redaction checklist; R8 `-assumenosideeffects` note; optional Chucker debugImplementation; sample Kotlin snippets (illustrative)
    - **Acceptance:** Convention doc references `device-log-capture.md` filter; no GPL/third-party code paste.

17. **Update `mas-bug-fix` / general-dev ingestion notes** — Read `capture-meta.json` at startup when `BRIEF_PATH` points to device logs; parse priority documented.
    - **Files:** `skills/mas-general-dev/SKILL.md` or dedicated bug-fix skill if exists (architect confirms target file)
    - **Acceptance:** Path-only hook context + on-disk read pattern; correlate `repro-marker.json` timestamp.

18. **Extend `read-order.md`** — Subscription matrix for log capture pipeline.
    - **Files:** `skills/multi-agent-system/protocol/read-order.md`
    - **Additions:** test-executor reads `device-log-capture.md`; test-strategy reads log capture prerequisites slice; bug-fix reads capture-meta when BRIEF_PATH set
    - **Acceptance:** Matrix complete; no broad repo scan.

19. **Extend `platform-parity.md`** — adb log capture IDE+CLI local only; Cloud Agent SKIP (same as MAS-07).
    - **Files:** `skills/multi-agent-system/protocol/platform-parity.md` (extend)
    - **Acceptance:** Honest boundary; hook payload drift note (fail-open).

20. **Extend `record-workflow-step` / session JSON** — Add `log_capture_path` field when dump succeeds.
    - **Files:** Hook scripts / workflow session schema docs (architect specifies in Task 1)
    - **Acceptance:** `.ai/context/workflow-sessions/{TASK_ID}.json` may include path after stop hook.

### Phase P2 — Escalation + observability boundary (defer unless architect promotes)

21. **Optional `LOG_ESCALATION: full-bugreport`** — Document `adb bugreport` subcommand or flag; size/time warnings; separate artifact dir.
    - **Files:** `device-log-capture.md` (extend), script `--escalation bugreport` flag
    - **Acceptance:** Opt-in only; not default MAS repro loop.

22. **Document `mas-observability` boundary** — Local logcat (MAS-09) vs prod telemetry (MAS-04 Phase C); no implementation in v1.7.0 unless scoped.
    - **Files:** Cross-ref in `device-log-capture.md` and memory.md entry (documenter)
    - **Acceptance:** Clear P2 deferral; no scope creep.

### Phase Dogfood — Validation chain

23. **test-strategy agent — dogfood brief** — Log capture prerequisite matrix for MAS-09.
    - **Files:** `.ai/context/test-strategies/MAS-09.md`
    - **Cases:** `LOG_CAPTURE: yes` + connected repro; JVM-only SKIP; prep FAIL → Device Logs SKIPPED; tag filter declared

24. **test-executor agent — dogfood run** — Step 0b + Post against fixtures; write test-run with **Device** + **Device Logs** sections.
    - **Files:** `.ai/context/test-runs/MAS-09.md`
    - **Acceptance:** Device Logs populated; CAPTURE_EMPTY warn path; Gaps cite prep blockers

25. **Documenter pass** — README log capture slice, script usage, hook setup, app convention pointer, first-run vs repeat-run.
    - **Files:** `README.md` (slice), `skills/multi-agent-system/scripts/README.md` (extend)

26. **Reviewer — dogfood validation** — Schema compliance, artifact-forward hook audit, prep FAIL cannot yield misleading Device Logs PASS, no log bodies in hook output.
    - **Acceptance:** Fixture test-run validates; grep `LOG_CAPTURE`, `capture-device-logs`, `Device Logs` across protocol files.

## Dependencies

| Task | Depends on | Reason |
|------|------------|--------|
| 2–9 (reference + scripts + hooks + fixtures) | 1 (architect) | JSON schema, exit codes, hook contracts, artifact layout |
| 10–20 (protocol + skills) | 1, 2 | Executor/strategy/coordinator must match script + schema |
| 21–22 (P2) | 1, P0 shipped | Escalation optional; observability boundary doc only |
| 23–26 (dogfood, doc, review) | 3–20 | End-to-end validation |

**External dependencies:** MAS-07 `android-device-prep` shipped (v1.5.0); MAS-08 project hooks bootstrap (v1.6.0); `adb` on PATH; target Android app optional for live APP_TRACE smoke (not required for framework CI).

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Unfiltered dumps token-blow agent context | H | Mandatory tag/PID filters; path-only hook context; P1 `--max-lines` |
| Low app adoption of structured logging | M | P0 host script works without app changes; convention additive |
| Cursor hook payload drift | M | fail-open v1.6; minimal JSON; platform-parity doc |
| `-v json` unavailable API < 30 | L | threadtime fallback; record `format` in meta |
| `beforeSubmitPrompt` clear too aggressive | M | Opt-in via handoff only (D8) |
| PID race on fast process restart | M | Re-resolve `pidof` at dump; document in reference |
| Script drift from skill text | M | Single `device-log-capture.md` + script as SOT |
| Parallel adb from prep + capture + dump | M | Executor serializes Step 0 → 0b → commands → Post dump |
| Cloud agent without USB | M | SKIP with platform-parity rationale; do not FAIL workflow |
| Wireless adb disconnect mid-dump | M | `DUMP_FAILED`; retry once; cite OFFLINE enrollment |

## Build & Test Plan

**Gradle / compile:** N/A — `UI_SCOPE: logic-only`; no Android modules in MAS framework repo.

**Verification surfaces:**

| Surface | Command / action | Owner |
|---------|------------------|-------|
| Script help | `powershell -File capture-device-logs.ps1 -Help` | general-dev |
| Fixture dry-run | Run script with `ADB_DEVICES_FIXTURE` / mocked adb per `.ai/fixtures/MAS-09-LOG-CAPTURE/` | test-executor |
| JSON stdout shape | Parse last line against fixture `script-stdout-*.json` | reviewer |
| capture-meta schema | Validate against `capture-meta-expected.json` | reviewer |
| Prep FAIL gate | prep FAIL → capture script does not invoke adb | test-executor |
| Hook stdout | Hook returns path-only `additional_context`; no log body | reviewer |
| Manifest JSON | Parse after v1.7.0 bump | general-dev |
| Protocol cross-links | Grep `LOG_CAPTURE`, `capture-device-logs`, `Device Logs` | reviewer |
| Live smoke (optional) | Prep PASS → clear → repro → dump on physical device with `LOG_PACKAGE` set | test-executor / user HITL |

**Framework dogfood (no physical device required):**

```powershell
# After mocked prep exports ANDROID_SERIAL
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  clear-and-marker -TaskId MAS-09 -Tag APP_TRACE
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE
```

**test-strategy agent:** Task 23 — fixture TASK_ID, LOG_CAPTURE required/skip matrix, tag/package declaration examples.

**test-executor agent:** Task 24 — Step 0b + Post against fixtures; test-run brief with **Device Logs** section.

**Convention doc validation:** Sample `APP_TRACE` JSON lines in convention doc → parser walkthrough (manual reviewer check; no JVM tests in MAS repo).

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only` for framework changes.

**Reviewer dogfood (protocol + optional live device):**

| Config | State | Expected gate |
|--------|-------|---------------|
| `LOG_CAPTURE: yes`, prep PASS, dump with lines | default | Device Logs Capture gate = PASS; meta path populated |
| `LOG_CAPTURE: yes`, prep FAIL | default | Device Logs SKIPPED; clear/dump not invoked |
| `LOG_CAPTURE: no`, JVM-only strategy | default | Device Logs omitted with skip rationale |
| Dump succeeds, 0 lines | empty buffer | CAPTURE_EMPTY warning; exit 0; meta records line_count 0 |
| API < 30 device | threadtime fallback | meta `format: threadtime`; warning in meta |
| `stop` hook fires without repro | minimal logs | dump still runs; meta records low line_count |
| Cloud Agent, no adb | default | LOG_CAPTURE SKIP; workflow not FAIL |
| Hook failure on dump | adb error | fail-open `{}`; agent stop not blocked |
| Bug-fix with BRIEF_PATH → capture-meta | post-dump | Reads meta first; correlates repro-marker timestamp |

## Required Agents

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task 1 — before edits | Script contract, hook wiring, schema registration, semver, D1–D8 confirmation |
| **test-strategy** | Task 23 — after Phase 0 | Device Logs prerequisites matrix, LOG_CAPTURE skip/required cases |
| **general-dev** | Tasks 2–9, 10–20 | Scripts, reference, hooks, protocol, skill updates, manifest bump |
| **test-executor** | Task 24 — after scripts + executor skill | Fixture-based Step 0b + Post; test-run **Device Logs** evidence |
| **documenter** | Task 25 | README, script usage, app convention pointer, platform parity |
| **reviewer** | Task 26 | Schema compliance, artifact-forward audit, prep FAIL gate, no-code-patch invariant |

**Not required:** new specialist slug (unless architect promotes `mas-repro-logging` as thin skill slice); ux-intelligence (no UI screens); osint/brainstorm (briefs exist); android-dev in MAS repo for implementation (convention doc only).

## Acceptance criteria (workflow-level)

1. **Capture scripts shipped:** `capture-device-logs.ps1` + `.sh` with subcommands (`clear`, `dump`, `marker`, `clear-and-marker`), documented flags, JSON stdout, exit codes including `CAPTURE_EMPTY` warn path.
2. **Reference doc:** `device-log-capture.md` covers prep prerequisite, state machine, filters, redaction, format fallback, artifact layout — single SOT with script.
3. **Prep coupling:** Script never runs adb without `ANDROID_SERIAL`; prep FAIL → no clear/dump (test-run Device Logs SKIPPED).
4. **Artifacts:** `.ai/context/device-logs/{TASK_ID}/` contains `capture-meta.json`, log files, optional `repro-marker.json` per architect schema.
5. **Hooks:** `stop` dump when `LOG_CAPTURE: yes`; path-only `additional_context`; fail-open on errors; bootstrap copies hook templates.
6. **test-executor:** Step 0b clear+marker and Post dump when `LOG_CAPTURE: yes`; serializes adb with prep.
7. **test-run evidence:** **Device Logs** section registered in `brief-schemas.md`; conditional on LOG_CAPTURE attempted.
8. **Handoff flags:** `LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG`, `LOG_BUFFERS`, `LOG_FORMAT` documented; lite `LOG:y`.
9. **App convention:** Timber + OkHttp EventListener + lifecycle guide published; redaction checklist; Chucker optional debug-only note.
10. **Bug-fix ingestion:** Documented read order: capture-meta → crash buffer → APP_TRACE lines → main tail; repro-marker correlation.
11. **Artifact-forward:** No full logcat in hook output or handoff injection; max ~200 char path context.
12. **Framework dogfood:** Fixture harness validates JSON/exit codes without physical device; test-executor produces test-run with **Device Logs**.
13. **Platform parity:** Cloud Agent SKIP documented; local IDE+CLI only for adb log capture.
14. **Semver:** Manifest `1.7.0`; additive extension of MAS-07/MAS-08; P2 escalation deferred unless promoted.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
