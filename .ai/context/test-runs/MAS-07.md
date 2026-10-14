# Test Run — MAS-07

TASK_ID: MAS-07
EXECUTOR: test-executor
STRATEGY: .ai/context/test-strategies/MAS-07.md
DATE: 2026-09-28
HOST: win32 (PowerShell; bash unavailable)

## Device

| Field | Value |
|-------|-------|
| Prep gate | PASS |
| Serial | R58M90ABCDE |
| Policy | auto |
| Exit code | PASS |
| Grants applied | — |
| Message | Device ready; ANDROID_SERIAL=R58M90ABCDE |

**Step 0 invocation:** `ADB_DEVICES_FIXTURE=.ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt` with `android-device-prep.ps1 -Policy auto -JsonOnly -BootTimeout 5`. Exit 0; `ANDROID_SERIAL` exported for downstream commands.

**Additional fixture outcomes (Step 0 matrix):**

| Fixture | Exit | JSON exit_code | Result |
|---------|------|----------------|--------|
| adb-devices-empty.txt | 10 | NO_DEVICE | PASS |
| adb-devices-unauthorized.txt | 11 | UNAUTHORIZED | PASS |
| adb-devices-single.txt | 0 | PASS | PASS |
| adb-devices-ambiguous.txt | 13 | AMBIGUOUS_DEVICE | PASS |
| adb-devices-emulator-plus-phone.txt (`-Policy physical`) | 0 | PASS (serial=R58M90ABCDE) | PASS |
| adb-devices-single.txt (`-Serial FAKE123`) | 14 | SERIAL_NOT_FOUND | PASS |
| (no fixture, PATH stripped) | 1 | ADB_NOT_FOUND | PASS |
| `-Policy invalid` | 7 | INVALID_ARGS | PASS |

## Commands

| # | Command | Source | Result |
|---|---------|--------|--------|
| 1 | `android-device-prep.ps1` + `adb-devices-empty.txt` → NO_DEVICE exit 10 | strategy #1 | PASS |
| 2 | `android-device-prep.ps1` + `adb-devices-unauthorized.txt` → UNAUTHORIZED exit 11 | strategy #2 | PASS |
| 3 | `android-device-prep.ps1` + `adb-devices-single.txt` → PASS exit 0 | strategy #3 | PASS |
| 4 | `android-device-prep.ps1` + `adb-devices-ambiguous.txt` → AMBIGUOUS_DEVICE exit 13 | strategy #4 | PASS |
| 5 | `android-device-prep.ps1 -Policy physical` + `adb-devices-emulator-plus-phone.txt` → hardware serial | strategy #5 | PASS |
| 6 | `android-device-prep.ps1 -Serial FAKE123` + single fixture → SERIAL_NOT_FOUND exit 14 | strategy #6 | PASS |
| 7 | PATH stripped (no adb) → ADB_NOT_FOUND exit 1 | strategy #7 | PASS |
| 8 | `android-device-prep.ps1 -Policy invalid` → INVALID_ARGS exit 7 | strategy #8 | PASS |
| 9 | `android-device-prep.sh` POSIX parity rows 1–5 | strategy #9 | SKIP |
| 10 | JSON stdout vs `expected-prep-output.json` required_fields | strategy #10 | PASS |
| 11 | Step 0 dogfood → Device section written (this brief) | strategy #11 | PASS |
| 12 | Unauthorized fixture FAIL path validated (row #2) | strategy #12 | PASS |
| 13 | JVM-only prep skip stub (`MAS-07-PREP-SKIP-JVM`) | strategy #13 | SKIP |
| 14 | `rg "## Device" skills/multi-agent-system/protocol/brief-schemas.md` | strategy #14 | FAIL |
| 15 | Device Prerequisites table in test-strategy brief | strategy #15 | PASS |
| 16 | `rg "Device Prerequisites\|android-device-prep\|DEVICE_POLICY\|DEVICE_SERIAL\|Prep gate" skills/` | strategy #16 | PASS |
| 17 | `rg "Step 0" skills/mas-test-executor/SKILL.md` | strategy Recommended | PASS |
| 18 | `android-device-prep.ps1 -Help` sanity | strategy Recommended | PASS |

## Pass/fail

Overall: PARTIAL
P0 commands: PARTIAL (14/16 PASS; 1 FAIL; 1 SKIP)

## Failures

| # | Command | Error summary | Flaky | Route |
|---|---------|---------------|-------|-------|
| 1 | `rg "## Device" skills/multi-agent-system/protocol/brief-schemas.md` | 0 matches — brief-schemas documents Device section in prose (`**Device** section`) but lacks `## Device` heading expected by strategy grep | no | bug-fix |

## Gaps

| # | Test | Reason |
|---|------|--------|
| 9 | POSIX `android-device-prep.sh` parity (rows 1–5) | `bash` not available on win32 agent host; defer to Linux/macOS CI |
| 13 | Prep gate skip path (`MAS-07-PREP-SKIP-JVM` stub) | Out of scope for this executor spawn — fixture harness only; skip rationale documented in strategy Tests to Skip |
| 17–26 | P1 rows (dry-run, BOOT_TIMEOUT, OFFLINE, grants, capture coupling, live smoke, manifest semver, Maestro, cloud BLOCKED) | P1 defer per strategy ship gate — P0 fixture matrix prioritized |

**Tests to Skip (from strategy):** Gradle/Paparazzi in MAS repo N/A; live physical device substituted by fixtures; Maestro execution P1 defer; RSA enrollment HITL only.

## Evidence

### Fixture JSON samples

**PASS (single):**
```json
{"status":"PASS","serial":"R58M90ABCDE","exit_code":"PASS","message":"Device ready; ANDROID_SERIAL=R58M90ABCDE","policy_applied":"auto","boot_wait_ms":2,"grants_applied":[],"grants_skipped":[],"reverse_applied":[],"animations_disabled":true,"warnings":[]}
```

**FAIL (unauthorized):**
```json
{"status":"FAIL","serial":"","exit_code":"UNAUTHORIZED","message":"Device unauthorized - unlock phone and tap Always allow on USB debugging prompt. See device-prep-automation.md enrollment checklist.","policy_applied":"auto","boot_wait_ms":0,"grants_applied":[],"grants_skipped":[],"reverse_applied":[],"animations_disabled":false,"warnings":[]}
```

### JSON schema (#10)

All 11 `required_fields` from `expected-prep-output.json` present on PASS sample (`status`, `serial`, `exit_code`, `message`, `policy_applied`, `boot_wait_ms`, `grants_applied`, `grants_skipped`, `reverse_applied`, `animations_disabled`, `warnings`).

### Protocol grep (#16)

Cross-links found in: `android-device-prep.ps1`, `android-device-prep.sh`, `device-prep-automation.md`, `brief-schemas.md`, `handoff-format.md`, `mas-test-executor/SKILL.md`, `mas-test-strategy/SKILL.md`, `mas-coordinator/SKILL.md`, `multi-agent-system/SKILL.md`, `scripts/README.md`, `read-order.md`, `test-strategy-standards.md`.

### Step 0 in mas-test-executor SKILL.md

```
### Step 0 — Device prep (before load commands)
```

Match confirmed; Step 0 workflow documents prep invocation, JSON parse, FAIL-closed skip, and `ANDROID_SERIAL` export.

### Observation (non-blocking)

`-Policy physical` on emulator+phone fixture returns `policy_applied: auto` in JSON while correctly selecting hardware serial `R58M90ABCDE` (not `emulator-5554`). Selection behavior PASS; policy field reporting may need review in bug-fix if schema strictness required.
