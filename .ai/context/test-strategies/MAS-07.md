# Test Strategy — MAS-07

## Feature

MAS-07 (v1.5.0) — **Composite device prep gate**: shared `android-device-prep.{ps1|sh}` scripts + `device-prep-automation.md` reference + **test-strategy Device Prerequisites** section + **test-executor Step 0** prep invocation + **test-run Device** evidence section. Deterministic preflight (serial pin, boot/animation stabilization, permission pre-grant) before Gradle connected tests, adb capture, or Maestro. Logic-only in MAS framework repo — no target app patches, no Android modules.

**Upstream coupling:** MAS-04 test-executor run-only gap; MAS-06 tier-3 `capture-connected-device` defers selection to prep gate (reads `ANDROID_SERIAL` post-Step 0).

## Scope

| Layer | Paths |
|-------|-------|
| Prep scripts (new) | `skills/multi-agent-system/scripts/android-device-prep.ps1`, `android-device-prep.sh` |
| Reference SOT (new) | `skills/multi-agent-system/references/device-prep-automation.md` |
| Protocol | `skills/multi-agent-system/protocol/brief-schemas.md`, `handoff-format.md`, `handoff-format-lite.md`, `read-order.md` |
| References | `skills/multi-agent-system/references/test-strategy-standards.md`, `build-test-visual-qa.md`, `visual-fidelity-standards.md` |
| Specialists | `skills/mas-test-strategy/SKILL.md`, `skills/mas-test-executor/SKILL.md`, `skills/mas-visual-fidelity/SKILL.md`, `skills/mas-coordinator/SKILL.md` |
| Capture scripts (update) | `skills/multi-agent-system/scripts/capture-connected-device.{ps1|sh}`, `scripts/README.md` |
| Install | `skills/multi-agent-system/install/manifest.json` (`1.4.x` → `1.5.0`) |
| Dogfood fixtures (new) | `.ai/fixtures/MAS-07-ADB-PREP/` |
| Context | `.ai/context/architecture/MAS-07.md`, `.ai/context/plans/MAS-07.md` |
| Dogfood outputs | `.ai/context/test-strategies/MAS-07.md` (this brief), `.ai/context/test-runs/MAS-07.md` (test-executor) |

**Out of scope:** Gradle unit/UI tests in MAS repo, live physical-device CI, Maestro skill steps (P1 defer D4), wireless `--connect` (v1.5.1 defer D6), production app source patches.

## Test Surfaces

`integration` (protocol chain, Step 0 → Device section) · `schema` (JSON stdout, brief headings) · `fixture` (mocked `adb devices` state machine) · `manual` (optional live phone smoke)

No JVM unit-test pyramid — framework is markdown/skills/scripts only.

---

## Device Prerequisites

### MAS-07 dogfood (this TASK_ID — fixture validation)

| Field | Value |
|-------|-------|
| Enrollment | enrolled (assumed) — fixtures mock `adb devices`; no RSA in CI |
| Target | none (fixture harness) — live smoke optional HITL |
| Prep gate | required for fixture script validation rows; skip for schema-only grep rows |
| DEVICE_SERIAL | — |
| DEVICE_POLICY | auto (fixture default); `physical` for emulator+phone selection fixture |
| Package | — (grant loop tested via dedicated fixture row with stub package) |
| Permissions to pre-grant | — |
| adb reverse | — |
| Skip rationale | Schema/grep-only verification rows: no adb invocation; rationale per Tests to Skip |

### Consumer workflow template (target Android project — reference for downstream strategies)

| Field | Value |
|-------|-------|
| Enrollment | required (first run) \| enrolled (repeat) |
| Target | physical \| emulator \| managed-ftl \| none |
| Prep gate | required \| skip |
| DEVICE_SERIAL | `<serial>` or — |
| DEVICE_POLICY | physical \| emulator \| auto |
| Package | `<applicationId>` or — |
| Permissions to pre-grant | minimum set or — |
| adb reverse | `tcp:host:device` pairs or — |
| Skip rationale | mandatory when Prep gate = skip |

### Prep gate required / skip matrix

| Recommended Commands contain | Prep gate | DEVICE_POLICY default | Notes |
|------------------------------|-----------|----------------------|-------|
| `connectedDebugAndroidTest`, `connectedReleaseAndroidTest` | **required** | `physical` when `TEST_SURFACE: ui` | Executor Step 0 before Gradle |
| `adb exec-out screencap`, `adb shell`, `adb pull`, `am start` | **required** | `physical` when `VISUAL_FIDELITY` or tier-3 capture | MAS-06 coupling |
| `maestro test` | **required** | `auto` unless handoff override | Maestro skill P1 defer; prep still runs |
| `android-device-prep` (fixture harness) | **required** | per fixture | Framework dogfood |
| `verifyPaparazziDebug`, `testDebugUnitTest` only | **skip** | — | JVM-only; cite skip rationale |
| `validateDebugScreenshotTest` only | **skip** | — | Compose Preview JVM |
| `managed-ftl` / Firebase Test Lab | **skip** | Target: `managed-ftl` | Cloud escape; local prep not invoked |
| No adb on agent host (Cursor Cloud) | **skip** (blocked) | — | Gaps: `BLOCKED: no adb on agent host` |

### Permissions sub-table (consumer example — not MAS-07 dogfood)

| Package | Permission | Grant method | Notes |
|---------|------------|--------------|-------|
| `com.example.app` | `android.permission.CAMERA` | `adb pm grant` | P0 connected UI |
| `com.example.app` | `android.permission.POST_NOTIFICATIONS` | `adb pm grant` | API 33+ |

Non-grantable (`MANAGE_EXTERNAL_STORAGE`, etc.) → list in strategy with in-test grant hint; prep logs `grants_skipped` warn, not FAIL.

---

## Synthetic Fixture TASK_IDs

| Fixture ID | Purpose | Prep gate | Expected outcome |
|------------|---------|-----------|------------------|
| `MAS-07-ADB-PREP` | Primary dogfood — fixture state machine | required (mocked adb) | Script JSON + exit codes per fixture file |
| `MAS-07-PREP-SKIP-JVM` | JVM-only negative | skip | Device SKIPPED; no prep invocation |
| `MAS-07-PREP-PHYSICAL` | Emulator + phone; `DEVICE_POLICY: physical` | required | Select hardware serial; exclude `emulator-*` |
| `MAS-07-PREP-AMBIGUOUS` | Two phones; no `DEVICE_SERIAL` | required | FAIL `AMBIGUOUS_DEVICE` exit 13 |
| `MAS-07-PREP-UNAUTH` | RSA not trusted | required | FAIL `UNAUTHORIZED` exit 11 + enrollment message |
| `MAS-07-PREP-CLOUD` | Agent without adb | skip (blocked) | Device SKIPPED; Gaps cite BLOCKED |
| `MAS-07-PREP-MAESTRO` | Maestro in Recommended Commands | required | Prep runs; Maestro execution P1 defer |

**Fixture artifact paths (expected after general-dev Phase 1):**

- `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-empty.txt`
- `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-unauthorized.txt`
- `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt`
- `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-ambiguous.txt`
- `.ai/fixtures/MAS-07-ADB-PREP/adb-devices-emulator-plus-phone.txt`
- `.ai/fixtures/MAS-07-ADB-PREP/expected-prep-output.json`
- `.ai/fixtures/MAS-07-ADB-PREP/handoff-stub.md`
- `.ai/fixtures/MAS-07-ADB-PREP/test-strategy-stub.md`
- `.ai/fixtures/MAS-07-ADB-PREP/test-run-expected-shape.md`

---

## Chain Permutation Matrix (prep gate focus)

| # | Permutation | Triggers | Expected Step 0 / Device | Notes |
|---|-------------|----------|--------------------------|-------|
| 1 | Connected UI P0 + grants | `TEST_SURFACE: ui`; connected in Recommended Commands | Prep PASS → `ANDROID_SERIAL` → connected Gradle | Default `DEVICE_POLICY: physical` |
| 2 | Paparazzi-only | `verifyPaparazziDebug` only | Device SKIPPED + rationale | No prep invocation |
| 3 | Tier-3 screencap after executor | MAS-06 path; prep PASS in Step 0 | capture reads env serial; connectivity-only re-check | No duplicate selection |
| 4 | Visual-fidelity without prior executor | Rare protected path | visual-fidelity invokes prep → capture | Same script SOT |
| 5 | Emulator + phone; physical policy | `DEVICE_POLICY: physical` | Select sole hardware | MAS-06 anti-emulator-capture |
| 6 | Two phones; no serial | Multi hardware | FAIL `AMBIGUOUS_DEVICE` | Coordinator sets `DEVICE_SERIAL` on retry |
| 7 | Unauthorized device | Fixture / live | FAIL `UNAUTHORIZED`; device cmds SKIP | Enrollment honesty D11 |
| 8 | Prep FAIL; JVM P0 still runnable | Mixed strategy | Device FAIL; connected SKIP; unit may PASS | Overall PARTIAL |
| 9 | Cursor Cloud / no adb | D5 | Device SKIPPED BLOCKED | HITL for connected P0 |
| 10 | managed-ftl | Cloud test command | Prep skip; Target `managed-ftl` | D12 |
| 11 | Maestro in commands | `maestro test` listed | Prep required | Maestro skill P1 defer |
| 12 | Prep PASS; Gradle connected FAIL | Test failure | Device PASS; Failures → bug-fix | Device evidence independent |
| 13 | Re-run prep (idempotent) | Same session | PASS; grants/animation no-op | Safe every spawn |
| 14 | Explicit `DEVICE_SERIAL` | Handoff serial | Match required or `SERIAL_NOT_FOUND` | Priority 1 selection |
| 15 | Reviewer 0d-ext | P0 connected + Device FAIL | Overall cannot PASS | Schema gate |

**Ordering invariants (P0):**

1. test-strategy plans Device Prerequisites; test-executor runs prep — mutual exclusion preserved.
2. Step 0 completes before any Step 1+ adb/connected command — serialize adb.
3. Prep FAIL → never run connected/adb/maestro (avoid misleading AGP "no devices" traces).
4. `UNAUTHORIZED` cites enrollment checklist — no RSA bypass promise.
5. Framework dogfood validates P0 exit codes via fixtures — no physical device in CI.
6. `ANDROID_SERIAL` canonical; `ADB_SERIAL` read alias only in capture script.

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | fixture | `android-device-prep.ps1` | Mock `adb devices -l` empty → JSON `NO_DEVICE`, exit 10 | P0 state machine — zero devices | **P0** | LOW | Fixture inject via `ADB_DEVICES_FIXTURE` or wrapper | `powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly` (with fixture env) |
| 2 | fixture | `android-device-prep.ps1` | Mock unauthorized only → `UNAUTHORIZED`, exit 11; message cites enrollment | P0 enrollment honesty D11 | **P0** | LOW | Fixture `adb-devices-unauthorized.txt` | Same + fixture |
| 3 | fixture | `android-device-prep.ps1` | Mock single `device` row → `PASS`, exit 0; `serial` populated | P0 happy path | **P0** | LOW | Fixture `adb-devices-single.txt` | Same + fixture |
| 4 | fixture | `android-device-prep.ps1` | Mock two hardware phones, no `--serial` → `AMBIGUOUS_DEVICE`, exit 13 | P0 multi-device safety | **P0** | LOW | Fixture `adb-devices-ambiguous.txt` | `-Policy auto` + fixture |
| 5 | fixture | `android-device-prep.ps1` | Mock emulator + phone; `-Policy physical` → select hardware serial | P0 MAS-06 selection policy | **P0** | LOW | Fixture `adb-devices-emulator-plus-phone.txt` | `-Policy physical` + fixture |
| 6 | fixture | `android-device-prep.ps1` | `--serial` set but not in device list → `SERIAL_NOT_FOUND`, exit 14 | P0 explicit serial contract | **P0** | LOW | Fixture single + wrong serial | `-Serial FAKE123` + fixture |
| 7 | fixture | `android-device-prep.ps1` | `adb` not on PATH → `ADB_NOT_FOUND`, exit 1 | P0 host precheck | **P0** | LOW | Temporarily unset PATH or mock | Env without adb |
| 8 | fixture | `android-device-prep.ps1` | Invalid flag combo → `INVALID_ARGS`, exit 7 | P0 arg validation | **P0** | LOW | Deterministic bad args | `-Policy invalid` |
| 9 | fixture | `android-device-prep.sh` | Rows 1–5 parity on POSIX twin | P0 cross-platform contract D1 | **P0** | LOW | Same fixtures on bash CI | `bash skills/multi-agent-system/scripts/android-device-prep.sh --policy auto --json-only` |
| 10 | schema | JSON stdout | Parse output against `expected-prep-output.json` field registry | P0 agent parsing contract | **P0** | LOW | `jq` or PowerShell `ConvertFrom-Json` | Parse last stdout line |
| 11 | integration | test-executor Step 0 | Read Device Prerequisites → invoke prep with fixture → write test-run **Device** PASS | P0 executor wiring | **P0** | MED | Fixture mock; no live device | test-executor dogfood → `.ai/context/test-runs/MAS-07.md` |
| 12 | integration | test-executor Step 0 | Prep FAIL unauthorized → Device FAIL; connected cmds SKIP in Gaps | P0 fail-closed path | **P0** | LOW | Unauthorized fixture | Same dogfood path |
| 13 | integration | test-executor Step 0 | Prep gate skip (JVM-only stub) → Device SKIPPED + rationale | P0 skip path | **P0** | LOW | Strategy stub `MAS-07-PREP-SKIP-JVM` | test-executor with skip strategy |
| 14 | schema | `brief-schemas.md` | test-run brief includes **Device** section when prep attempted | P0 reviewer 0d-ext dependency | **P0** | LOW | Grep + shape vs `test-run-expected-shape.md` | `rg "Device" skills/multi-agent-system/protocol/brief-schemas.md` |
| 15 | schema | test-strategy brief | **Device Prerequisites** table present when device commands planned | P0 strategy contract | **P0** | LOW | Review this brief + stub | Manual schema check |
| 16 | integration | protocol cross-links | Grep `android-device-prep`, `DEVICE_POLICY`, `Device Prerequisites`, Step 0 | P0 wiring completeness | **P0** | LOW | Deterministic grep | See Recommended Commands |
| 17 | fixture | `android-device-prep.ps1` | `--dry-run` emits planned ops; no device required | P1 agent/local sanity | **P1** | LOW | No fixture needed | `-DryRun -Policy auto` |
| 18 | fixture | `android-device-prep.ps1` | Boot timeout → `BOOT_TIMEOUT`, exit 15 | P1 edge timeout | **P1** | MED | Mock slow `getprop` or `-BootTimeout 1` | `-BootTimeout 1` + boot incomplete mock |
| 19 | fixture | `android-device-prep.ps1` | Device `offline` → retry once → `OFFLINE`, exit 12 | P1 offline recovery | **P1** | MED | Fixture with offline state | Fixture + live mock if available |
| 20 | fixture | `android-device-prep.ps1` | `--package` + `--grants` → `grants_applied` / `grants_skipped` arrays | P1 grant loop | **P1** | MED | Mock `pm grant` stdout | `-Package com.stub.app -Grants android.permission.CAMERA` |
| 21 | fixture | `android-device-prep.ps1` | `--reverse tcp:8080:8080` → `reverse_applied` in JSON | P1 reverse port | **P1** | LOW | Mock or dry-run | `-Reverse tcp:8080:8080` |
| 22 | integration | `capture-connected-device.ps1` | Reads `ANDROID_SERIAL` from env; connectivity-only re-check | P1 MAS-06 coupling D8 | **P1** | MED | Post-prep env export | After prep PASS fixture |
| 23 | manual | Live device smoke (optional HITL) | Prep PASS → `./gradlew :app:connectedDebugAndroidTest` on consumer project | P1 real-world validation | **P1** | HIGH | User desk phone; ≥10 min timeout | User HITL — not CI |
| 24 | schema | `install/manifest.json` | Version `1.5.0` after bump | P1 semver D9 | **P1** | LOW | JSON parse | `Get-Content skills/multi-agent-system/install/manifest.json` |
| 25 | integration | Maestro command template | Prep required when `maestro test` in Recommended Commands | P1 D4 documentation | **P1** | HIGH | Defer Maestro execution | Strategy documents template only |
| 26 | manual | Cursor Cloud agent | No adb → Device SKIPPED BLOCKED | P1 D5 honest degrade | **P1** | LOW | Cloud spawn | test-executor on cloud |

### P0 / P1 classification summary (fixture-based prep script validation)

| Class | Count | Scope |
|-------|-------|-------|
| **P0** | 16 rows (#1–16) | Exit codes `NO_DEVICE`, `UNAUTHORIZED`, `PASS`, `AMBIGUOUS_DEVICE`, `SERIAL_NOT_FOUND`, `ADB_NOT_FOUND`, `INVALID_ARGS`; POSIX parity (#9); JSON schema (#10); executor Step 0 PASS/FAIL/SKIP (#11–13); protocol/schema grep (#14–16) |
| **P1** | 10 rows (#17–26) | `--dry-run`, `BOOT_TIMEOUT`, `OFFLINE`, grants/reverse, capture coupling, live smoke, manifest semver, Maestro template, cloud BLOCKED |

**Ship gate:** All P0 fixture rows must PASS before reviewer approval. P1 rows may PARTIAL with documented Gaps.

---

## Tests to Skip

| # | Target | Reason | Covered by |
|------|--------|--------|------------|
| 1 | Gradle `testDebugUnitTest` in MAS repo | No Android modules; logic-only framework | N/A — not applicable |
| 2 | Paparazzi / Compose Preview in MAS repo | No UI modules in framework | Prep skip path dogfood (#13) |
| 3 | Live physical device in CI | No USB in mas-cursor-framework CI; fixtures substitute | Fixture rows #1–6, #9 |
| 4 | Maestro skill execution steps | P1 defer per architect D4 | Prep-required documentation only (#25) |
| 5 | Wireless `adb connect` | v1.5.1 defer per D6 | `device-prep-automation.md` future note |
| 6 | RSA enrollment automation | OS security model forbids bypass; human HITL once | `UNAUTHORIZED` message + enrollment doc |
| 7 | Full E2E consumer app UI suite | Out of MAS repo scope | Consumer project test-strategy |
| 8 | Parallel adb prep + capture | Architecture forbids; serialized Step 0 | Integration invariant #2 |
| 9 | Animator scale restore | Acceptable dev side effect; defer v1.5.1 | Manual doc only |
| 10 | `mas-visual-fidelity` P0 measurement diff | Unchanged MAS-06 scope; prep is upstream only | MAS-06 test-strategy |
| 11 | Duplicate device selection in capture script | Post-v1.5.0 capture is connectivity-only | Architecture D8 |
| 12 | Production code patches | MAS-07 framework-only invariant | Reviewer grep |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| Empty device list | prep script | Fixture `adb-devices-empty.txt` → `NO_DEVICE` | P0 |
| Unauthorized (RSA) | prep script | Fixture → `UNAUTHORIZED` + checklist message | P0 |
| Ambiguous multi-phone | prep script + coordinator | Fixture → `AMBIGUOUS_DEVICE`; retry with `DEVICE_SERIAL` | P0 |
| Emulator + phone selection | prep script | `-Policy physical` fixture → hardware wins | P0 |
| Serial not found | prep script | Wrong `--serial` → `SERIAL_NOT_FOUND` | P0 |
| Boot timeout | prep script | `-BootTimeout` exceeded → `BOOT_TIMEOUT` | P1 |
| Offline after retry | prep script | `OFFLINE` exit 12 | P1 |
| Grants non-grantable | prep script | `grants_skipped` warn; status still PASS | P1 |
| No adb on host | test-executor | Device SKIPPED BLOCKED; skip device cmds | P0 |
| JVM-only strategy | test-strategy + executor | Prep skip + mandatory rationale | P0 |
| Prep FAIL + JVM P0 runnable | test-executor | Overall PARTIAL | P1 |
| managed-ftl cloud | test-strategy | Prep skip; Target `managed-ftl` | P1 |
| Idempotent re-run | prep script | Second PASS; no duplicate side effects | P1 |
| Disconnect mid-workflow | capture script | Connectivity re-check FAIL → BLOCKED capture | P1 |
| Invalid JSON parse | test-executor | Gaps cite parse failure; FAIL | P1 |
| Process death / state restore | N/A | Not applicable — shell scripts stateless | N/A |

---

## Regression Risks

Possible regression related to **MAS-06** (2026-09-28): mas-visual-fidelity + tier-3 `capture-connected-device` — ensure prep gate does not break existing capture path; `ANDROID_SERIAL` env must remain compatible with `ADB_SERIAL` alias.

Recommend regression grep: `capture-connected-device`, `VISUAL_FIDELITY`, `connected-device` in updated protocol files after MAS-07 merge.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Live device boot wait variance | prep script live smoke | Fixture-first CI; `-BootTimeout` configurable; live smoke P1 HITL only |
| `connectedDebugAndroidTest` long runtime | test-executor | `block_until_ms` ≥ 600000 (10 min) for P0 connected |
| Race: prep + parallel adb | executor | Serialize Step 0 before Step 1+; document in executor skill |
| Mock fixture drift from script | fixture harness | Single SOT `device-prep-automation.md`; `expected-prep-output.json` versioned with fixtures |
| Windows vs bash JSON whitespace | cross-platform | Parse last line only; schema test #10 |
| Grant timing on slow devices | grant loop | Idempotent `pm grant`; `grants_skipped` warn not FAIL |
| Cloud agent false PASS | no adb | Hard SKIP BLOCKED in Gaps — never fake PASS |

---

## Recommended Commands

### Script help (sanity — post general-dev)

```powershell
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Help
```

```bash
bash skills/multi-agent-system/scripts/android-device-prep.sh --help
```

### Fixture-based prep validation (P0 — no physical device)

General-dev should ship a fixture wrapper or `ADB_DEVICES_FIXTURE` env hook. Until then, test-executor documents invocation shape:

```powershell
# Example: inject fixture (exact mechanism defined in device-prep-automation.md + scripts README)
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy auto `
  -JsonOnly `
  -BootTimeout 5
# Expect: exit 0, JSON status PASS, serial from fixture
```

```powershell
# P0 — unauthorized
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-unauthorized.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly
# Expect: exit 11, exit_code UNAUTHORIZED
```

```powershell
# P0 — ambiguous (two phones)
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-ambiguous.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly
# Expect: exit 13, exit_code AMBIGUOUS_DEVICE
```

```powershell
# P0 — physical policy over emulator+phone
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-emulator-plus-phone.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy physical -JsonOnly
# Expect: exit 0, serial = hardware row (not emulator-*)
```

```bash
# P0 — POSIX parity (CI)
export ADB_DEVICES_FIXTURE=".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
bash skills/multi-agent-system/scripts/android-device-prep.sh --policy auto --json-only --boot-timeout 5
```

```powershell
# P1 — dry-run (no device)
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -DryRun -Policy auto
```

### JSON schema validation

```powershell
$output = powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly -DryRun
$output | ConvertFrom-Json | Select-Object status, exit_code, serial, policy_applied
```

Compare PASS/FAIL samples to `.ai/fixtures/MAS-07-ADB-PREP/expected-prep-output.json`.

### Protocol / schema dogfood (P0 grep)

```powershell
rg "Device Prerequisites|android-device-prep|DEVICE_POLICY|DEVICE_SERIAL|Prep gate" skills/
rg "## Device" skills/multi-agent-system/protocol/brief-schemas.md
rg "Step 0" skills/mas-test-executor/SKILL.md
```

### test-executor dogfood (post implementation)

test-executor agent runs Step 0 against fixtures and writes:

```
.ai/context/test-runs/MAS-07.md
```

Expected **Device** section shape per `.ai/fixtures/MAS-07-ADB-PREP/test-run-expected-shape.md`.

### Optional live smoke (P1 HITL — consumer Android project)

```powershell
# After live prep PASS exports ANDROID_SERIAL
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy physical `
  -Package com.example.app `
  -Grants android.permission.CAMERA `
  -JsonOnly

./gradlew :app:connectedDebugAndroidTest --tests "com.example.FooUiTest"
```

```powershell
# Tier-3 capture after prep (MAS-06 path)
powershell -File skills/multi-agent-system/scripts/capture-connected-device.ps1 -OutputPath .ai/artifacts/MAS-07/capture.png
```

### Manifest semver check (P1)

```powershell
Get-Content skills/multi-agent-system/install/manifest.json | ConvertFrom-Json | Select-Object version
# Expect: 1.5.0
```

---

## Overall Confidence

**HIGH** — Architecture brief locks D1–D12, script JSON contract, exit codes, Device Prerequisites schema, and fixture list. Scope is framework-only with clear P0 fixture matrix. Minor uncertainty on exact fixture injection mechanism until general-dev ships wrapper (env var name may vary — document in `scripts/README.md`).

## Files Reviewed

- `.ai/handoffs/MAS-07-test-strategy.md`
- `.ai/context/architecture/MAS-07.md`
- `.ai/context/plans/MAS-07.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`
- `skills/mas-test-executor/SKILL.md` (partial — pre-Step 0 baseline)
- `skills/mas-test-strategy/SKILL.md` (partial)
- `skills/multi-agent-system/protocol/brief-schemas.md` (partial)
- `.ai/context/test-strategies/MAS-06.md` (format reference)

## Open Questions

- Exact fixture injection API (`ADB_DEVICES_FIXTURE` vs wrapper script) — general-dev to define in `device-prep-automation.md` + `scripts/README.md`; test-executor dogfood follows shipped mechanism.
- Whether `MAS-07-DEVICE-CAPTURE` fixtures merge with `MAS-07-ADB-PREP` or remain separate TASK_IDs — recommend single `MAS-07-ADB-PREP` for prep state machine; capture dogfood references post-prep env.
- Live smoke optional — not blocking framework ship if P0 fixtures PASS.
