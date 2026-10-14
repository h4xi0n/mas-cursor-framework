# Plan Brief — MAS-07

## Plan

Goal:
Integrate **Option 3 — Composite device prep gate** (per `.ai/context/brainstorms/MAS-07.md` Recommended and `.ai/context/osint/MAS-07.md` Recommended Approach): shared `android-device-prep` scripts + `device-prep-automation.md` reference + **test-strategy Device Prerequisites** section + **test-executor Step 0** prep invocation + **test-run Device** evidence section — so repeat `/mas` workflows that need `adb`, `connected*AndroidTest`, or tier-3 screencap run a **deterministic preflight** (serial pin, boot/animation stabilization, permission pre-grant) before Gradle/device commands, with actionable blockers on `unauthorized`, `NO_DEVICE`, and `AMBIGUOUS_DEVICE`. **Logic-only** in MAS framework repo — no target app patches. Closes MAS-04 test-executor gap (run-only, no device contract) and MAS-06 tier-3 assumption that a device is already stable.

**Upstream context:** `.ai/handoffs/MAS-07-planner.md`; brainstorm Domain & Contracts §1–6; OSINT Findings #1–#6 (HIGH confidence).

**Resolved open questions (D1–D6 — architect confirms in Phase 0):**

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | **Both** `android-device-prep.ps1` (win32 primary) and `android-device-prep.sh` (bash CI) | User host is win32; shared JSON stdout schema |
| D2 | **Shared script** invoked by test-executor Step 0 and referenced by mas-visual-fidelity tier-3 / build-test-visual-qa | Single SOT; no inline adb duplication across specialists |
| D3 | Default `DEVICE_POLICY: physical` when `TEST_SURFACE` includes `ui`, `connected` commands, or handoff `VISUAL_FIDELITY`; else `auto` | Prevents emulator capture when phone connected (MAS-06 coupling) |
| D4 | **Maestro P1** — document optional command template in test-strategy; prep gate still runs when `maestro` in Recommended Commands | Defer Maestro-specific skill steps to v1.1 unless architect promotes |
| D5 | **Cursor Cloud / no USB** — hard SKIP with `BLOCKED: no adb on agent host` in test-run Gaps | Honest limitation; user runs locally or managed-ftl strategy |
| D6 | **Wireless `adb connect`** — defer v1.1 | Optional `--connect host:port` in prep script when strategy lists endpoint |

**Enrollment honesty (non-negotiable):** "Zero user intervention" applies to **repeat runs after RSA trust**. First connect requires human unlock + "Always allow". Prep FAIL `UNAUTHORIZED` cites enrollment checklist — no RSA bypass promise.

**Version target:** `1.4.1` (additive protocol + scripts; no new specialist slug) — architect may recommend `1.5.0` if treating as minor feature release.

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms device prep topology, script contract, and chain wiring** — Validate prep gate state machine, `ANDROID_SERIAL` selection policy, test-strategy ↔ test-executor mutual exclusion, test-run **Device** schema registration, MAS-06 tier-3 coupling, semver, and D1–D6 resolutions above.
   - **Files:** `.ai/context/architecture/MAS-07.md` (new)
   - **Decisions required:**
     - Script I/O contract: flags (`--policy`, `--serial`, `--package`, `--grants`, `--boot-timeout`, `--reverse`, `--no-animation-off`); stdout JSON shape; exit codes (`NO_DEVICE`, `UNAUTHORIZED`, `OFFLINE`, `AMBIGUOUS_DEVICE`, `BOOT_TIMEOUT`, `PASS`)
     - Selection policy priority table (handoff `DEVICE_SERIAL` → single device → `DEVICE_POLICY` physical/emulator/auto → FAIL ambiguous hardware)
     - test-run **Device** section: required when prep attempted or any device command in strategy; fields per brainstorm §G
     - brief-schemas test-run delta: add **Device** to required sections (or conditional rule architect documents)
     - handoff fields: `DEVICE_SERIAL`, `DEVICE_POLICY` — when Coordinator sets them
     - Prep skip path: JVM-only (`testDebugUnitTest`, Paparazzi, Compose Preview) → `Prep gate: skip` with rationale
     - visual-fidelity tier-3: references same prep script vs duplicate gate (recommend: invoke shared script before `adb exec-out screencap`)
     - Framework dogfood: fixture-based script tests (mocked `adb devices` output) — no physical device in mas-cursor-framework CI
     - Semver: `1.4.1` vs `1.5.0`
   - **Acceptance:** Architecture brief documents end-to-end flow (enrollment → strategy prerequisites → executor Step 0 → commands → test-run Device → reviewer 0d), script as SOT, and references brainstorm Domain & Contracts without re-litigating options.

### Phase 1 — Prep gate scripts + reference doc

2. **Create `device-prep-automation.md`** — Framework reference for enrollment, state machine, selection policy, grants, blocker messages, cloud skip path, MAS-06 relationship.
   - **Files:** `skills/multi-agent-system/references/device-prep-automation.md` (new)
   - **Content:** One-time enrollment checklist (USB + wireless pair); prep gate state machine table; exit code → user message mapping; `ANDROID_SERIAL` / `-d` / `-e` policy; permission pre-grant template (`pm grant`); non-grantable permissions (`GRANT_SKIPPED` warn); Gradle `connected*AndroidTest` integration notes; Cursor Cloud BLOCKED path; serialization rule (no parallel adb)
   - **Acceptance:** Referenced from test-executor, test-strategy, build-test-visual-qa, visual-fidelity-standards; no third-party script paste.

3. **Create `android-device-prep.ps1`** — Windows-first idempotent prep gate script.
   - **Files:** `skills/multi-agent-system/scripts/android-device-prep.ps1` (new)
   - **Pipeline:** `adb start-server` → parse `adb devices -l` → state machine → boot wait (`sys.boot_completed`) → optional animator scales → `pm grant` loop → optional `adb reverse` → JSON stdout
   - **Stdout JSON:** `{ "status": "PASS"|"FAIL", "serial": "...", "exit_code": "...", "message": "...", "grants_applied": [...], "grants_skipped": [...] }`
   - **Exit:** 0 = PASS; non-zero = FAIL code enum
   - **Acceptance:** `-Help` documents flags; idempotent re-run safe; matches architect contract from Task 1.

4. **Create `android-device-prep.sh`** — POSIX twin for bash CI / Linux agents.
   - **Files:** `skills/multi-agent-system/scripts/android-device-prep.sh` (new)
   - **Acceptance:** Same JSON schema and exit codes as `.ps1`; executable bit noted for documenter.

5. **Create prep gate fixture harness** — Mocked `adb` output fixtures for framework dogfood (no physical device).
   - **Files:** `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-empty.txt`, `adb-devices-unauthorized.txt`, `adb-devices-single.txt`, `adb-devices-ambiguous.txt`, `adb-devices-emulator-plus-phone.txt`, `expected-prep-output.json` (shape samples)
   - **Acceptance:** Fixtures cover P0 states: empty, unauthorized, single PASS, ambiguous FAIL, physical-over-emulator selection.

### Phase 2 — Protocol + schema foundation

6. **Extend `brief-schemas.md`** — Register test-run **Device** section; note test-strategy **Device Prerequisites** in validation guidance.
   - **Files:** `skills/multi-agent-system/protocol/brief-schemas.md`
   - **test-run required sections:** `Commands`, `Pass/fail`, `Failures`, `Gaps`, **`Device`** (when prep attempted or device commands planned)
   - **Device fields:** Prep gate (PASS|FAIL|SKIPPED), Serial, Policy, Exit code, Grants applied, Message
   - **Acceptance:** Registry row updated; Reviewer 0d notes Device evidence dependency.

7. **Extend `test-strategy-standards.md`** — Add **Device Prerequisites** section template and prep-gate skip/required rules.
   - **Files:** `skills/multi-agent-system/references/test-strategy-standards.md`
   - **Fields:** Enrollment, Target, Prep gate, DEVICE_SERIAL, DEVICE_POLICY, Package, Permissions to pre-grant, adb reverse, Skip rationale
   - **Rules:** Prep required when any Recommended Command contains `adb`, `connected`, `maestro`, `am start`, `uiautomator`; skip when JVM-only with documented rationale
   - **Acceptance:** Template table matches brainstorm §F; cross-ref `device-prep-automation.md`.

8. **Extend `handoff-format.md` + lite format** — Document `DEVICE_SERIAL`, `DEVICE_POLICY` coordinator fields.
   - **Files:** `skills/multi-agent-system/protocol/handoff-format.md`, `skills/multi-agent-system/protocol/handoff-format-lite.md`
   - **Fields:** `DEVICE_SERIAL: <id>` (multi-phone desk); `DEVICE_POLICY: physical|emulator|auto` (override default)
   - **Acceptance:** test-strategy and test-executor handoffs inherit fields; lite equivalent if applicable.

9. **Extend `read-order.md`** — Subscription matrix for device prep pipeline.
   - **Files:** `skills/multi-agent-system/protocol/read-order.md`
   - **test-executor reads:** `device-prep-automation.md` when strategy Device Prerequisites present
   - **test-strategy reads:** `device-prep-automation.md` at startup (slice: prerequisites + skip rules)
   - **reviewer add:** test-run **Device** section at step 0d-ext
   - **Acceptance:** Matrix complete; no broad repo scan added.

### Phase 3 — Specialist skill updates

10. **Update `mas-test-executor/SKILL.md`** — Add Step 0 device prep workflow, Device section in brief, startup read of `device-prep-automation.md`.
    - **Files:** `skills/mas-test-executor/SKILL.md`
    - **Step 0:** Read Device Prerequisites → skip with rationale OR invoke prep script → parse JSON → export `ANDROID_SERIAL` on PASS → on FAIL set Overall PARTIAL/FAIL, skip device commands
    - **Rules:** Serialize adb (prep before capture/connected); generous `block_until_ms` for connected suites (≥10 min P0); no connected tasks when prep FAIL
    - **Output template:** Add **Device** summary row for full `/mas`
    - **Acceptance:** Mutual exclusion with test-strategy preserved; run-only boundary unchanged.

11. **Update `mas-test-strategy/SKILL.md`** — Emit **Device Prerequisites** section in brief workflow; read prep reference at startup.
    - **Files:** `skills/mas-test-strategy/SKILL.md`
    - **Additions:** Workflow step for Device Prerequisites table; honor handoff `DEVICE_SERIAL` / `DEVICE_POLICY`; declare grants and skip rationale
    - **Acceptance:** Brief template includes section when `TEST_SURFACE` includes `ui` or connected commands listed.

12. **Update `build-test-visual-qa.md`** — Document prep gate before connected tests and adb capture; reviewer 0d Device evidence.
    - **Files:** `skills/multi-agent-system/references/build-test-visual-qa.md`
    - **Additions:** Device prep gate paragraph; `connectedDebugAndroidTest` requires prep PASS; tier-3 screencap requires prep PASS; enrollment prerequisite link
    - **Acceptance:** test-executor row references Step 0; no contradiction with MAS-06 capture tiers.

13. **Update `visual-fidelity-standards.md`** — Tier-3 adb screencap requires prep gate PASS (cross-ref shared script).
    - **Files:** `skills/multi-agent-system/references/visual-fidelity-standards.md`
    - **Acceptance:** Capture matrix row notes prep dependency; defers to `device-prep-automation.md` not duplicate logic.

14. **Update `mas-visual-fidelity/SKILL.md`** — Note tier-3 fallback invokes shared prep script before `adb exec-out screencap` (or relies on prior test-executor prep in same workflow).
    - **Files:** `skills/mas-visual-fidelity/SKILL.md`
    - **Acceptance:** Read-only boundary unchanged; no new measurement responsibilities.

15. **Update `mas-coordinator/SKILL.md`** — Pass `DEVICE_POLICY` / `DEVICE_SERIAL` on test-strategy and test-executor handoffs when user provides or multi-device ambiguity likely.
    - **Files:** `skills/mas-coordinator/SKILL.md`
    - **Acceptance:** Optional fields documented; no new predicate slug.

### Phase 4 — Install, manifest, dogfood

16. **Update `install/manifest.json`** — Version bump per architect semver decision.
    - **Files:** `skills/multi-agent-system/install/manifest.json`

17. **Update `multi-agent-system/SKILL.md`** — MAS-07 roster note: device prep gate integration.

18. **Create dogfood handoff + strategy stubs** — Fixture TASK_ID for prep-gate validation without live device.
    - **Files:** `.ai/fixtures/MAS-07-ADB-PREP/handoff-stub.md`, `test-strategy-stub.md`, `test-run-expected-shape.md`
    - **Cases:** prep required + mocked PASS; prep FAIL unauthorized; prep SKIPPED (JVM-only); ambiguous device FAIL

19. **test-strategy agent — dogfood brief** — Chain permutation matrix for MAS-07.
    - **Files:** `.ai/context/test-strategies/MAS-07.md`
    - **Cases:** connected UI P0 with grants; Paparazzi-only skip; `DEVICE_POLICY: physical` with emulator+phone; cloud agent skip; Maestro optional P1 row

20. **test-executor agent — dogfood run** — Execute prep gate against fixtures (mock adb) + write test-run with **Device** section.
    - **Files:** `.ai/context/test-runs/MAS-07.md`
    - **Acceptance:** Device section populated; PASS/FAIL/SKIPPED paths documented; Gaps cite blockers on prep FAIL

21. **Documenter pass** — README enrollment checklist, script paths, first-run vs repeat-run honesty, Platform Tools PATH requirement.
    - **Files:** `README.md` (slice), `skills/multi-agent-system/scripts/README.md` (new or extend)

22. **Reviewer — dogfood validation** — Schema compliance, 0d Device evidence, prep FAIL cannot yield Overall PASS on P0 connected tests.
    - **Acceptance:** Fixture test-run + strategy briefs validate; grep `Device Prerequisites`, `android-device-prep`, `DEVICE_POLICY` across protocol files; no production patches in MAS repo.

## Dependencies

| Task | Depends on | Reason |
|------|------------|--------|
| 2–5 (reference + scripts + fixtures) | 1 (architect) | JSON schema, exit codes, selection policy |
| 6–9 (protocol) | 1 | Field names, test-run Device registration, handoff flags |
| 10–15 (skills + refs) | 2, 6, 7 | Executor/strategy must match script + schema contracts |
| 16–22 (manifest, dogfood, review) | 3–15 | End-to-end validation |

**External dependencies:** `adb` on PATH (Android Platform Tools); one-time device enrollment on developer workstation; target Android project for optional live connected-test smoke (not required for MAS framework CI).

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Script drift from skill text | M | Single `device-prep-automation.md` + script as SOT; architect contract in Task 1 |
| Wrong device selected (two phones) | H | FAIL `AMBIGUOUS_DEVICE`; require handoff `DEVICE_SERIAL` |
| Animator disable left on device | L | Document optional restore v1.1; dev machine side effect acceptable |
| Grant gives excessive permissions | M | Strategy lists minimum set only; prep idempotent |
| Long `connectedAndroidTest` timeouts agent | M | Executor skill documents ≥10 min `block_until_ms` for P0 connected |
| Promising RSA bypass | H | Enrollment doc + `UNAUTHORIZED` actionable message; OSINT Finding #1 |
| Parallel adb from prep + capture | M | Executor serializes Step 0 before commands |
| Cloud agent without USB | M | SKIP `BLOCKED: no adb on agent host` in Gaps (D5) |
| Windows `exec-out screencap` corruption | M | Document `exec-out screencap -p` only in build-test-visual-qa (existing MAS-06 note) |

## Build & Test Plan

**Gradle / compile:** N/A — `UI_SCOPE: logic-only`; no Android modules in MAS framework repo.

**Verification surfaces:**

| Surface | Command / action | Owner |
|---------|------------------|-------|
| Script help | `powershell -File android-device-prep.ps1 -Help` | general-dev |
| Fixture state machine | Run script with mocked `ADB` / `adb devices` stub per fixture file | test-executor |
| JSON stdout shape | Parse output against `expected-prep-output.json` samples | reviewer |
| Manifest JSON | Parse after version bump | general-dev |
| Schema compliance | Synthetic test-run **Device** section vs `brief-schemas.md` | reviewer |
| Protocol cross-links | Grep `Device Prerequisites`, `android-device-prep`, `DEVICE_POLICY`, prep Step 0 | reviewer |
| Live smoke (optional) | Physical phone or emulator + `./gradlew :*:connectedDebugAndroidTest` after prep PASS | test-executor / user HITL |

**Framework dogfood (no physical device required):**

```powershell
# Mock adb devices - inject fixture via test harness or env wrapper (architect defines in Task 1)
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy physical `
  -BootTimeout 5 `
  # ... fixture documents expected JSON for single-device PASS
```

**test-strategy agent:** Task 19 — fixture TASK_ID, skip/required matrix, grant declaration examples.

**test-executor agent:** Task 20 — Step 0 against fixtures; test-run brief with **Device** section for reviewer 0d.

**Target Android project (consumer, optional live smoke):**

```bash
# After prep gate exports ANDROID_SERIAL
./gradlew :app:connectedDebugAndroidTest --tests "com.example.FooUiTest"
adb exec-out screencap -p > .ai/artifacts/<TASK_ID>/capture.png
```

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only` for framework changes.

**Reviewer dogfood (protocol + optional live device):**

| Config | State | Expected gate |
|--------|-------|---------------|
| Strategy prep required, prep PASS, connected test PASS | default | test-run Device = PASS; Overall PASS eligible |
| `unauthorized` device | default | Device FAIL `UNAUTHORIZED`; connected cmds SKIP; Overall not PASS |
| Two phones, no `DEVICE_SERIAL` | default | `AMBIGUOUS_DEVICE`; Gaps cite handoff fix |
| JVM-only strategy (Paparazzi) | default | Device SKIPPED with rationale; no prep invocation |
| Prep PASS, Gradle connected FAIL | test failure | Device PASS; Failures route bug-fix |
| Cursor Cloud, no adb | default | Device SKIPPED `BLOCKED: no adb on agent host` |
| Tier-3 screencap after prep | MAS-06 path | Same serial as prep; visual-fidelity does not re-pick device |

## Required Agents

| Agent | When | Scope |
|-------|------|-------|
| **architect** | Task 1 — before edits | Script contract, selection policy, schema registration, semver, D1–D6 confirmation |
| **test-strategy** | Task 19 — after Phase 0 | Device Prerequisites matrix, skip/required cases, grant examples, optional live smoke checklist |
| **general-dev** | Tasks 2–17 | Reference doc, scripts, fixtures, protocol, skill + consumer updates, manifest bump |
| **test-executor** | Task 20 — after scripts + executor skill | Fixture-based Step 0 run; test-run **Device** section evidence |
| **documenter** | Task 21 | README enrollment, script usage, first-run honesty, Platform Tools PATH |
| **reviewer** | Task 22 | Schema compliance, 0d Device evidence, prep FAIL gate, no-code-patch invariant |

**Not required:** new specialist slug; android-dev in MAS repo; osint/brainstorm (briefs exist); ux-intelligence (no UI screens).

## Acceptance criteria (workflow-level)

1. **Prep scripts shipped:** `android-device-prep.ps1` + `.sh` with documented flags, JSON stdout, and P0 exit codes (`NO_DEVICE`, `UNAUTHORIZED`, `OFFLINE`, `AMBIGUOUS_DEVICE`, `BOOT_TIMEOUT`, `PASS`).
2. **Reference doc:** `device-prep-automation.md` covers enrollment, state machine, selection policy, grants, blockers, cloud skip — single SOT for skills.
3. **test-strategy contract:** **Device Prerequisites** section in standards + skill; declares prep required/skip, grants, `DEVICE_POLICY`.
4. **test-executor Step 0:** Invokes prep when required; exports `ANDROID_SERIAL` on PASS; skips device commands on FAIL; serializes adb.
5. **test-run evidence:** **Device** section registered in `brief-schemas.md`; reviewer 0d consumes serial + prep status.
6. **Handoff fields:** `DEVICE_SERIAL`, `DEVICE_POLICY` documented in handoff-format.
7. **Enrollment honesty:** First-run RSA documented; `UNAUTHORIZED` message actionable — no bypass promise.
8. **MAS-06 coupling:** Tier-3 adb screencap and connected UI tests default `DEVICE_POLICY: physical`; visual-fidelity references shared prep.
9. **Mutual exclusion:** test-strategy plans prerequisites; test-executor runs prep + commands — no strategy shell execution.
10. **Framework dogfood:** Fixture harness validates exit codes without physical device; test-executor produces test-run with **Device** section.
11. **Skip path:** JVM-only strategies document skip rationale; Paparazzi/unit tests do not invoke prep.
12. **Semver:** Manifest bumped per architect decision; additive backward-compatible extension of MAS-04/MAS-06.

## Usage Report

Model: default
Class: normal
Tokens: unknown

DONE
