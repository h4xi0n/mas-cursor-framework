# Test Strategy — MAS-09

## Feature

MAS-09 (v1.7.0) — **Two-layer composite repro observability**: prep-gated `capture-device-logs.{ps1|sh}` host scripts + `device-log-capture.md` reference + Cursor hook recipes (`stop` dump, optional `beforeSubmitPrompt` clear) + test-executor Step 0b/Post + test-run **Device Logs** slice + handoff flags (`LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG`) + app structured-logging convention slice. Bug-repro workflows **clear log buffers before repro**, **dump filtered logcat after repro** to `.ai/context/device-logs/{TASK_ID}/`, and surface **path-only metadata** to agents via hooks (never full log bodies). Logic-only in MAS framework repo — no target app patches, no Android modules.

**Upstream coupling:** MAS-07 `android-device-prep` exports `ANDROID_SERIAL` (Step 0); MAS-08 project hooks (fail-open v1.6, artifact-forward invariant); `capture-connected-device.{ps1|sh}` sibling adb script pattern.

## Scope

| Layer | Paths |
|-------|-------|
| Log capture scripts (new) | `skills/multi-agent-system/scripts/capture-device-logs.ps1`, `capture-device-logs.sh` |
| Reference SOT (new) | `skills/multi-agent-system/references/device-log-capture.md` |
| Prep cross-ref (extend) | `skills/multi-agent-system/references/device-prep-automation.md` |
| Hook scripts (new) | `hooks/capture-device-logs-hook.ps1`, `hooks/capture-device-logs-hook.sh` |
| Hook bootstrap (extend) | `install/templates/hooks.project.template.json`, `init-mas-project.ps1` (+ `.sh`) |
| Protocol | `brief-schemas.md`, `handoff-format.md`, `handoff-format-lite.md`, `read-order.md`, `platform-parity.md`, `test-strategy-standards.md` |
| Specialists | `mas-test-executor/SKILL.md`, `mas-test-strategy/SKILL.md`, `mas-coordinator/SKILL.md`, `mas-android-dev/SKILL.md`, `mas-general-dev/SKILL.md` |
| Workflow telemetry (extend) | `record-workflow-step.ps1` |
| Install | `install/manifest.json` (`1.7.0`) |
| Dogfood fixtures (new) | `.ai/fixtures/MAS-09-LOG-CAPTURE/` |
| Context | `.ai/context/architecture/MAS-09.md`, `.ai/context/plans/MAS-09.md` |
| Dogfood outputs | `.ai/context/test-strategies/MAS-09.md` (this brief), `.ai/context/test-runs/MAS-09.md` (test-executor) |

**Out of scope:** Gradle unit/UI tests in MAS repo, live physical-device CI, target app Timber/OkHttp implementation, `LOG_ESCALATION: full-bugreport` (P2), `mas-observability` prod telemetry (P2), production app source patches.

## Test Surfaces

`integration` (prep → clear → dump chain, executor Step 0b/Post, hook wiring) · `schema` (JSON stdout, `capture-meta.json`, test-run **Device Logs** headings) · `fixture` (mocked adb/logcat state machine) · `manual` (optional live APP_TRACE smoke on consumer project)

No JVM unit-test pyramid — framework is markdown/skills/scripts only.

---

## Device Prerequisites

### MAS-09 dogfood (this TASK_ID — fixture validation)

| Field | Value |
|-------|-------|
| Enrollment | enrolled (assumed) — fixtures mock `adb devices` / logcat; no RSA in CI |
| Target | none (fixture harness) — live smoke optional HITL |
| Prep gate | required for log capture fixture rows; skip for schema-only grep rows |
| DEVICE_SERIAL | — (fixture exports mock serial via `ADB_DEVICES_FIXTURE`) |
| DEVICE_POLICY | auto (fixture default) |
| Package | `com.example.app` (fixture dogfood default for PID filter rows) |
| Permissions to pre-grant | — |
| adb reverse | — |
| Skip rationale | Schema/grep-only verification rows: no adb invocation; JVM-only rows: `LOG_CAPTURE: no` |

### Device Logs Prerequisites (MAS-09 dogfood)

| Field | Value |
|-------|-------|
| Log capture gate | **required** — handoff `LOG_CAPTURE: yes` for dogfood TASK_ID |
| Tag namespace | `APP_TRACE` (default per D3) |
| Package | `com.example.app` (fixture PID filter validation) |
| Buffers | `main,crash` (default) |
| Format | API-aware — `json` when `ADB_API_LEVEL_FIXTURE=30+`; else `threadtime` with warning |
| Clear before repro | **yes** — Step 0b `clear-and-marker` before repro window |
| Skip rationale | JVM-only strategy (`LOG_CAPTURE: no`): omit Device Logs section with documented skip; Cloud Agent / no adb: SKIPPED per D12 |

### Consumer workflow template (target Android project — reference for downstream strategies)

| Field | Value |
|-------|-------|
| Log capture gate | required \| skip |
| Tag namespace | `APP_TRACE` or handoff `LOG_TAG` |
| Package | `<applicationId>` or — (tag-only fallback when PID not found) |
| Buffers | `main,crash` or handoff `LOG_BUFFERS` |
| Format | `json` \| `threadtime` or API-aware default |
| Clear before repro | yes when `LOG_CAPTURE: yes` |
| Skip rationale | mandatory when Log capture gate = skip (JVM-only, no adb, Cloud Agent) |

### Prep gate + log capture matrix

| Condition | Prep gate | Log capture gate | Expected Device Logs |
|-----------|-----------|------------------|----------------------|
| `LOG_CAPTURE: yes` + adb commands | **required** (Step 0) | **required** (Step 0b + Post) | PASS/FAIL/SKIPPED per outcome |
| `LOG_CAPTURE: no`, JVM-only | skip | skip | Section omitted + skip rationale |
| Prep FAIL (Step 0) | required (failed) | blocked | **SKIPPED** — clear/dump not invoked |
| `ANDROID_SERIAL` unset | required (failed) | blocked | Script `NO_SERIAL` exit 10; no adb |
| Cloud Agent / no adb | skip (blocked) | skip | SKIPPED — platform-parity rationale |
| Dump succeeds, 0 lines | prep PASS | attempted | `CAPTURE_EMPTY` warn; exit 0 |
| Hook dump failure | prep PASS | attempted | fail-open `{}`; agent stop not blocked |

### Permissions sub-table

N/A for MAS-09 framework dogfood — log capture does not require runtime permission grants. Consumer apps must emit `APP_TRACE` logs per `mas-android-dev` convention slice (documented, not tested in MAS repo).

---

## Synthetic Fixture TASK_IDs

| Fixture ID | Purpose | LOG_CAPTURE | Prep gate | Expected outcome |
|------------|---------|-------------|-----------|------------------|
| `MAS-09-LOG-CAPTURE` | Primary dogfood — fixture state machine | yes | required (mocked) | Script JSON + exit codes + artifacts per fixture |
| `MAS-09-LOG-SKIP-JVM` | JVM-only negative | no | skip | Device Logs omitted; skip rationale documented |
| `MAS-09-LOG-NO-SERIAL` | Prep not run / serial unset | yes | failed | `NO_SERIAL` exit 10; no adb invoked |
| `MAS-09-LOG-EMPTY` | Dump with zero lines | yes | required | `CAPTURE_EMPTY` warn; exit 0; meta `line_count: 0` |
| `MAS-09-LOG-UNAUTH` | Unauthorized device | yes | required | `UNAUTHORIZED` exit 11; capture blocked |
| `MAS-09-LOG-CLOUD` | Agent without adb | yes | skip (blocked) | Device Logs SKIPPED; workflow not FAIL |
| `MAS-09-LOG-THREADTIME` | API < 30 format fallback | yes | required | meta `format: threadtime`; `FORMAT_FALLBACK` warning |

**Fixture artifact paths (expected after general-dev Phase P0):**

- `.ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-empty.txt`
- `.ai/fixtures/MAS-09-LOG-CAPTURE/capture-meta-expected.json`
- `.ai/fixtures/MAS-09-LOG-CAPTURE/script-stdout-pass.json`
- `.ai/fixtures/MAS-09-LOG-CAPTURE/script-stdout-capture-empty.json`
- `.ai/fixtures/MAS-09-LOG-CAPTURE/handoff-stub.md`
- `.ai/fixtures/MAS-09-LOG-CAPTURE/test-run-expected-shape.md`

---

## Chain Permutation Matrix (log capture focus)

| # | Permutation | Triggers | Expected Step 0 / 0b / Post | Notes |
|---|-------------|----------|-----------------------------|-------|
| 1 | LOG_CAPTURE yes + prep PASS + dump with lines | Default dogfood | Step 0 PASS → 0b clear-and-marker → Post dump PASS | Device Logs Capture gate = PASS |
| 2 | LOG_CAPTURE no, JVM-only | Paparazzi/unit only | Device Logs omitted + skip rationale | No capture script invocation |
| 3 | Prep FAIL | Step 0 unauthorized/empty | Device Logs SKIPPED; clear/dump not invoked | Gaps cite prep blocker |
| 4 | NO_SERIAL (prep skipped) | `ANDROID_SERIAL` unset | Script exit 10; no adb | Prep-first invariant D2 |
| 5 | CAPTURE_EMPTY | Empty logcat fixture | exit 0 + `CAPTURE_EMPTY` warn | Proceed with caution |
| 6 | PID_NOT_FOUND | Package set; `pidof` empty | Tag-only filter + warning in meta | Stale-PID fallback D13 |
| 7 | API < 30 threadtime | `ADB_API_LEVEL_FIXTURE=29` | meta `format: threadtime` | D4 format fallback |
| 8 | POSIX parity | bash CI | Same JSON/exit codes as `.ps1` | Cross-platform contract |
| 9 | stop hook dump | `LOG_CAPTURE: yes` + completed | Path-only `additional_context` | No log body in hook stdout |
| 10 | Hook failure | adb error on dump | fail-open `{}` | MAS-08 D6 invariant |
| 11 | beforeSubmitPrompt clear | Opt-in D8 + repro keywords | `clear` only; no dump | Never default-on |
| 12 | Cloud Agent no adb | D12 | Device Logs SKIPPED | Honest degrade; not FAIL |
| 13 | Parallel adb blocked | prep + capture + dump | Serialize Step 0 → 0b → cmds → Post | Architecture invariant |
| 14 | Re-run dump idempotent | Second dump | Overwrites artifacts; later wins | Idempotent contract |
| 15 | Reviewer Device Logs gate | LOG_CAPTURE attempted + FAIL dump | Overall cannot PASS without Gaps | Schema gate |

**Ordering invariants (P0):**

1. test-strategy plans Device Prerequisites + Device Logs Prerequisites; test-executor runs prep then capture — mutual exclusion preserved.
2. Step 0 completes before Step 0b — never invoke `capture-device-logs` without `ANDROID_SERIAL`.
3. `capture-device-logs` does **not** call `android-device-prep` inline (D2).
4. Serialize adb: prep → clear-and-marker → test commands → Post dump.
5. Hooks fail-open — capture failure must not block agent `stop`.
6. Hooks and `additional_context` expose paths only (~200 chars max) — never log bodies.
7. Framework dogfood validates P0 exit codes via fixtures — no physical device in CI.

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | fixture | `capture-device-logs.ps1` | `ANDROID_SERIAL` unset → JSON `NO_SERIAL`, exit 10; no adb | P0 prep-first gate D2 | **P0** | LOW | No env serial; no fixture serial override | `powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 dump -TaskId MAS-09` |
| 2 | fixture | `capture-device-logs.ps1` | Mock unauthorized device → `UNAUTHORIZED`, exit 11 | P0 connectivity gate | **P0** | LOW | `ADB_DEVICES_FIXTURE` unauthorized | Same + fixture env |
| 3 | fixture | `capture-device-logs.ps1` | Mock offline device → `OFFLINE`, exit 12 | P0 connectivity gate | **P0** | LOW | Fixture offline state | Same + fixture |
| 4 | fixture | `capture-device-logs.ps1` | `clear-and-marker` with fixture serial → `repro-marker.json` written | P0 Step 0b contract | **P0** | LOW | Export mock `ANDROID_SERIAL` via fixture | `clear-and-marker -TaskId MAS-09 -Tag APP_TRACE` |
| 5 | fixture | `capture-device-logs.ps1` | `dump` with logcat fixture → artifacts + `capture-meta.json` | P0 happy path | **P0** | LOW | `ADB_LOGCAT_FIXTURE` + serial fixture | `dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE` |
| 6 | fixture | `capture-device-logs.ps1` | Dump with empty logcat → `CAPTURE_EMPTY` warn, exit 0 | P0 warn-not-fail path | **P0** | LOW | Fixture `adb-logcat-empty.txt` | Same + empty fixture |
| 7 | fixture | `capture-device-logs.ps1` | `adb` not on PATH → `ADB_NOT_FOUND`, exit 1 | P0 host precheck | **P0** | LOW | Temporarily unset PATH or mock | Env without adb |
| 8 | fixture | `capture-device-logs.ps1` | Missing `--task-id` on dump → `INVALID_ARGS`, exit 7 | P0 arg validation | **P0** | LOW | Deterministic bad args | `dump` without `-TaskId` |
| 9 | fixture | `capture-device-logs.ps1` | `pidof` returns empty → tag-only filter + `PID_NOT_FOUND` warning | P0 stale-PID fallback D13 | **P0** | LOW | Fixture with empty pidof | `dump -Package com.example.app` |
| 10 | fixture | `capture-device-logs.ps1` | API < 30 → `threadtime` format + `FORMAT_FALLBACK` warning | P0 format fallback D4 | **P0** | LOW | `ADB_API_LEVEL_FIXTURE=29` | `dump -TaskId MAS-09` |
| 11 | fixture | `capture-device-logs.sh` | Rows 1–6 parity on POSIX twin | P0 cross-platform contract | **P0** | LOW | Same fixtures on bash CI | `bash skills/multi-agent-system/scripts/capture-device-logs.sh dump --task-id MAS-09` |
| 12 | schema | JSON stdout | Parse last line against `script-stdout-pass.json` / `script-stdout-capture-empty.json` | P0 agent parsing contract | **P0** | LOW | `ConvertFrom-Json` / `jq` | Parse stdout last line |
| 13 | schema | `capture-meta.json` | Validate dump output against `capture-meta-expected.json` | P0 artifact contract | **P0** | LOW | Schema field registry from architecture | Compare fixture output |
| 14 | integration | test-executor Step 0b | Prep PASS fixture → `clear-and-marker` → test-run Clear executed = yes | P0 executor wiring | **P0** | MED | Fixture mock prep + capture | test-executor dogfood → `.ai/context/test-runs/MAS-09.md` |
| 15 | integration | test-executor Post | After repro window → `dump` → Device Logs section populated | P0 Post dump contract | **P0** | MED | Fixture chain | Same dogfood path |
| 16 | integration | test-executor | Prep FAIL → Device Logs SKIPPED; clear/dump not invoked | P0 fail-closed path | **P0** | LOW | Unauthorized/no-serial fixture | Same dogfood path |
| 17 | integration | test-executor | `LOG_CAPTURE: no` → Device Logs omitted + skip rationale | P0 JVM-only skip | **P0** | LOW | Strategy stub `MAS-09-LOG-SKIP-JVM` | test-executor with skip strategy |
| 18 | schema | `brief-schemas.md` | test-run includes **Device Logs** section when capture attempted | P0 reviewer evidence | **P0** | LOW | Grep + shape vs `test-run-expected-shape.md` | `rg "Device Logs" skills/multi-agent-system/protocol/brief-schemas.md` |
| 19 | schema | test-strategy brief | **Device Logs Prerequisites** table when `LOG_CAPTURE: yes` | P0 strategy contract | **P0** | LOW | Review this brief | Manual schema check |
| 20 | integration | protocol cross-links | Grep `LOG_CAPTURE`, `capture-device-logs`, `Device Logs`, `LOG_TAG` | P0 wiring completeness | **P0** | LOW | Deterministic grep | See Recommended Commands |
| 21 | integration | `capture-device-logs-hook.ps1` | `stop` + `LOG_CAPTURE: yes` → path-only `additional_context` | P0 hook contract | **P0** | MED | Mock handoff + fixture dump | Invoke hook with test payload |
| 22 | integration | `capture-device-logs-hook.ps1` | Hook failure on dump → returns `{}` (fail-open) | P0 MAS-08 invariant | **P0** | LOW | Force adb error | Assert empty JSON stdout |
| 23 | schema | hook stdout | No log body in `additional_context`; max ~200 chars | P0 artifact-forward | **P0** | LOW | Grep hook output | `rg -v "logcat-main" .cursor/hooks/` |
| 24 | fixture | `capture-device-logs.ps1` | `--dry-run` emits planned adb ops; no device required | P1 agent/local sanity | **P1** | LOW | No fixture needed | `-DryRun dump -TaskId MAS-09` |
| 25 | fixture | `capture-device-logs.ps1` | `--max-lines 5000` truncates with `TRUNCATED: main` warning | P1 token cap D5 | **P1** | LOW | Large fixture logcat | `dump -MaxLines 5000` |
| 26 | fixture | `capture-device-logs.ps1` | `clear` subcommand only → logcat cleared; no marker | P1 subcommand isolation | **P1** | LOW | Fixture serial | `clear` |
| 27 | fixture | `capture-device-logs.ps1` | `marker` subcommand only → `repro-marker.json` without clear | P1 subcommand isolation | **P1** | LOW | Fixture serial | `marker -TaskId MAS-09` |
| 28 | integration | `record-workflow-step.ps1` | `-LogCapturePath` writes `log_capture_path` to session JSON | P1 telemetry D7 | **P1** | LOW | Post-dump hook path | Extend workflow session test |
| 29 | integration | `beforeSubmitPrompt` hook | Opt-in clear when repro keywords match | P1 D8 opt-in | **P1** | MED | Matcher `repro\|bug\|logcat` | Hook test with keyword prompt |
| 30 | schema | `install/manifest.json` | Version `1.7.0`; scripts include `capture-device-logs` | P1 semver D10 | **P1** | LOW | JSON parse | `Get-Content skills/multi-agent-system/install/manifest.json` |
| 31 | schema | `handoff-format.md` | `LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG` documented | P1 protocol D3 | **P1** | LOW | Grep | `rg "LOG_CAPTURE" skills/multi-agent-system/protocol/` |
| 32 | manual | Live device smoke (optional HITL) | Prep PASS → clear-and-marker → repro → dump with real `LOG_PACKAGE` | P1 real-world validation | **P1** | HIGH | User desk phone; APP_TRACE in target app | User HITL — not CI |
| 33 | manual | Cursor Cloud agent | No adb → Device Logs SKIPPED | P1 D12 honest degrade | **P1** | LOW | Cloud spawn | test-executor on cloud |
| 34 | schema | `mas-android-dev/SKILL.md` | Repro logging convention slice present | P1 convention D9 | **P1** | LOW | Grep `APP_TRACE` | `rg "Repro logging" skills/mas-android-dev/` |

### P0 / P1 classification summary (fixture-based log capture validation)

| Class | Count | Scope |
|-------|-------|-------|
| **P0** | 23 rows (#1–23) | `NO_SERIAL`, `UNAUTHORIZED`, `OFFLINE`, clear-and-marker, dump PASS, `CAPTURE_EMPTY`, `ADB_NOT_FOUND`, `INVALID_ARGS`, PID fallback, format fallback; POSIX parity; JSON/capture-meta schema; executor Step 0b/Post/SKIP; protocol grep; hook path-only + fail-open |
| **P1** | 11 rows (#24–34) | `--dry-run`, `--max-lines`, subcommand isolation, workflow telemetry, beforeSubmitPrompt opt-in, manifest semver, handoff flags, live smoke, cloud SKIP, convention doc |

**Ship gate:** All P0 fixture rows must PASS before reviewer approval. P1 rows may PARTIAL with documented Gaps.

---

## Tests to Skip

| # | Target | Reason | Covered by |
|------|--------|--------|------------|
| 1 | Gradle `testDebugUnitTest` in MAS repo | No Android modules; logic-only framework | N/A — not applicable |
| 2 | Target app Timber/OkHttp implementation | Convention doc only; not shipped in MAS repo | `mas-android-dev` slice manual review (#34) |
| 3 | Live physical device in CI | No USB in mas-cursor-framework CI; fixtures substitute | Fixture rows #1–11 |
| 4 | `LOG_ESCALATION: full-bugreport` | P2 defer per D15 | `device-log-capture.md` future note |
| 5 | `mas-observability` prod telemetry | P2 defer per D16; local logcat only | Cross-ref in reference doc |
| 6 | Chucker/Flipper ingestion | Optional human debug only — MAS reads logcat artifacts | Architecture invariant |
| 7 | Inline prep in capture script | Architecture forbids; prep is Step 0 only | Row #1 NO_SERIAL gate |
| 8 | Parallel adb prep + capture + dump | Architecture forbids; serialized chain | Chain invariant #4 |
| 9 | Full E2E consumer app bug repro | Out of MAS repo scope | Consumer project test-strategy |
| 10 | `beforeSubmitPrompt` default-on clear | D8 opt-in only; avoids clearing non-bug sessions | Row #29 P1 |
| 11 | Unbounded dump in P1 default | P1 `--max-lines 5000` default per D5 | Row #25 |
| 12 | structlog-timber dependency | D6 — custom Timber tree in convention only | Convention doc |
| 13 | Production code patches | MAS-09 framework-only invariant | Reviewer grep |
| 14 | Paparazzi / Compose Preview | No UI modules in framework | JVM-only skip path (#17) |
| 15 | Duplicate device selection in capture script | Reads `ANDROID_SERIAL` from prep only | MAS-07 coupling |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| `ANDROID_SERIAL` unset | capture script | No adb; `NO_SERIAL` exit 10 | P0 |
| Unauthorized device | capture script | `UNAUTHORIZED` exit 11 | P0 |
| Offline device | capture script | `OFFLINE` exit 12 | P0 |
| Empty logcat after dump | capture script | `CAPTURE_EMPTY` warn; exit 0 | P0 |
| PID not found at dump | capture script | Tag-only filter + `PID_NOT_FOUND` warning | P0 |
| API < 30 format | capture script | `threadtime` + `FORMAT_FALLBACK` warning | P0 |
| Prep FAIL blocks capture | test-executor | Device Logs SKIPPED; no clear/dump | P0 |
| LOG_CAPTURE no (JVM-only) | test-strategy + executor | Omit Device Logs + skip rationale | P0 |
| Hook failure on stop | hook script | fail-open `{}`; agent continues | P0 |
| Log body in hook context | hook script | Grep audit — path only | P0 |
| Wireless adb disconnect mid-dump | capture script | `DUMP_FAILED` exit 21; retry once doc | P1 |
| Truncation at max-lines | capture script | `TRUNCATED: main` in warnings | P1 |
| Re-run dump overwrites | capture script | Idempotent; later dump wins | P1 |
| stop hook without repro | hook | Dump still runs; low line_count | P1 |
| Cloud Agent no adb | test-executor | SKIPPED; workflow not FAIL | P1 |
| beforeSubmitPrompt without keywords | hook | No clear invoked | P1 |
| Invalid JSON from script | test-executor | Gaps cite parse failure | P1 |
| Process death / state restore | N/A | Shell scripts stateless | N/A |
| Concurrent use | N/A | Serialized adb chain | N/A |

---

## Regression Risks

N/A — `.ai/context/daily-changelog.md` has no entries for 2026-10-06.

Recommend regression grep after MAS-09 merge:

- **MAS-07** (2026-09-28): `android-device-prep` + `ANDROID_SERIAL` export — ensure log capture reads same env SOT; prep FAIL still blocks capture.
- **MAS-08** (2026-10-02): fail-open hooks + artifact-forward — ensure new hook does not break `finalize-session-hook` chain or inject log bodies.
- **MAS-06/07**: `capture-connected-device` — sibling script pattern; no duplicate serial selection in capture-device-logs.

```powershell
rg "capture-connected-device|ANDROID_SERIAL|android-device-prep" skills/multi-agent-system/scripts/
rg "additional_context|fail-open" hooks/ skills/
```

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Live device logcat timing | dump script live smoke | Fixture-first CI; live smoke P1 HITL only |
| Race: prep + parallel adb | test-executor | Serialize Step 0 → 0b → cmds → Post dump |
| PID race on fast process restart | dump script | Re-resolve `pidof` at dump only; tag-only fallback |
| Mock fixture drift from script | fixture harness | Single SOT `device-log-capture.md`; version fixtures with script |
| Windows vs bash JSON whitespace | cross-platform | Parse last stdout line only; schema test #12 |
| Large logcat token blow | dump + hooks | Tag/PID filters; P1 `--max-lines`; path-only hook context |
| Hook payload drift | Cursor hooks | fail-open v1.6; minimal JSON; platform-parity doc |
| Cloud agent false PASS | no adb | Hard SKIP in Gaps — never fake Device Logs PASS |
| `beforeSubmitPrompt` aggressive clear | hook | Opt-in D8 only; matcher keywords required |

---

## Recommended Commands

### Script help (sanity — post general-dev)

```powershell
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 -Help
```

```bash
bash skills/multi-agent-system/scripts/capture-device-logs.sh --help
```

### Fixture-based log capture validation (P0 — no physical device)

```powershell
# P0 — NO_SERIAL (prep not run)
Remove-Item Env:ANDROID_SERIAL -ErrorAction SilentlyContinue
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 dump -TaskId MAS-09
# Expect: exit 10, exit_code NO_SERIAL, no adb invocation
```

```powershell
# P0 — clear-and-marker (after mock prep exports ANDROID_SERIAL)
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
$env:ANDROID_SERIAL = "R58M90ABCDE"  # or value from prep fixture stdout
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  clear-and-marker -TaskId MAS-09 -Tag APP_TRACE
# Expect: exit 0, repro-marker.json written
```

```powershell
# P0 — dump PASS with lines
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
$env:ADB_LOGCAT_FIXTURE = ".ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-sample.txt"
$env:ANDROID_SERIAL = "R58M90ABCDE"
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE
# Expect: exit 0, capture-meta.json + log files; compare to capture-meta-expected.json
```

```powershell
# P0 — CAPTURE_EMPTY warn
$env:ADB_LOGCAT_FIXTURE = ".ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-empty.txt"
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Tag APP_TRACE
# Expect: exit 0, exit_code CAPTURE_EMPTY, line_count 0
```

```powershell
# P0 — API < 30 threadtime fallback
$env:ADB_API_LEVEL_FIXTURE = "29"
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Tag APP_TRACE
# Expect: meta format threadtime; FORMAT_FALLBACK in warnings
```

```bash
# P0 — POSIX parity (CI)
export ADB_DEVICES_FIXTURE=".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
export ANDROID_SERIAL="R58M90ABCDE"
bash skills/multi-agent-system/scripts/capture-device-logs.sh \
  dump --task-id MAS-09 --tag APP_TRACE
```

```powershell
# P1 — dry-run (no device)
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  -DryRun dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE
```

### JSON schema validation

```powershell
$output = powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Tag APP_TRACE -JsonOnly
# Parse last line; compare to .ai/fixtures/MAS-09-LOG-CAPTURE/script-stdout-pass.json
```

```powershell
Get-Content .ai/context/device-logs/MAS-09/capture-meta.json | ConvertFrom-Json
# Compare fields to .ai/fixtures/MAS-09-LOG-CAPTURE/capture-meta-expected.json
```

### Protocol / schema dogfood (P0 grep)

```powershell
rg "LOG_CAPTURE|capture-device-logs|Device Logs|LOG_TAG|LOG_PACKAGE" skills/
rg "## Device Logs" skills/multi-agent-system/protocol/brief-schemas.md
rg "Step 0b|clear-and-marker" skills/mas-test-executor/SKILL.md
rg "Device Logs Prerequisites" skills/multi-agent-system/references/
```

### test-executor dogfood (post implementation)

test-executor agent runs Step 0 → 0b → Post against fixtures and writes:

```
.ai/context/test-runs/MAS-09.md
```

Expected **Device** + **Device Logs** section shape per `.ai/fixtures/MAS-09-LOG-CAPTURE/test-run-expected-shape.md`.

### Optional live smoke (P1 HITL — consumer Android project)

```powershell
# After live prep PASS exports ANDROID_SERIAL
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy physical -JsonOnly

powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  clear-and-marker -TaskId MAS-09 -Tag APP_TRACE

# User reproduces bug on device with APP_TRACE logging enabled

powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE
```

### Manifest semver check (P1)

```powershell
Get-Content skills/multi-agent-system/install/manifest.json | ConvertFrom-Json | Select-Object version
# Expect: 1.7.0
```

---

## Overall Confidence

**HIGH** — Architecture brief locks D1–D16, script JSON contract, exit codes, `capture-meta.json` schema, Device Logs Prerequisites template, hook contracts, and fixture list. Scope is framework-only with clear P0 fixture matrix chained after MAS-07 prep. Minor uncertainty on exact fixture file names for sample logcat (`adb-logcat-sample.txt` may ship as part of general-dev fixture harness).

## Files Reviewed

- `.ai/handoffs/MAS-09-test-strategy.md`
- `.ai/context/architecture/MAS-09.md`
- `.ai/context/plans/MAS-09.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `skills/multi-agent-system/references/test-strategy-standards.md`
- `.ai/context/test-strategies/MAS-07.md` (format reference)

## Open Questions

- Exact sample logcat fixture filename beyond `adb-logcat-empty.txt` — general-dev to ship in `.ai/fixtures/MAS-09-LOG-CAPTURE/`; test-executor dogfood follows shipped fixtures.
- Whether `ADB_DEVICES_FIXTURE` reuse from MAS-07 is sufficient for capture script connectivity checks or capture needs dedicated fixture files — recommend reuse per D11.
- Hook handoff resolution (latest TASK_ID + `LOG_CAPTURE` flags) — general-dev to align with MAS-08 `mas-session-context` pattern.
- Live APP_TRACE smoke optional — not blocking framework ship if P0 fixtures PASS.
