# Test Run — MAS-09

TASK_ID: MAS-09
EXECUTOR: test-executor
STRATEGY: .ai/context/test-strategies/MAS-09.md
DATE: 2026-10-06
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

**Step 0 invocation:** `ADB_DEVICES_FIXTURE=.ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt` with `android-device-prep.ps1 -Policy auto -JsonOnly -BootTimeout 5`. Exit 0; `ANDROID_SERIAL` exported for downstream capture commands.

**Prep FAIL path (strategy #16):** `ANDROID_SERIAL` unset → `capture-device-logs.ps1 dump` returns exit 10 / `NO_SERIAL` without adb invocation. Device Logs would be SKIPPED in live workflow.

## Device Logs

| Field | Value |
|-------|-------|
| Capture gate | PASS |
| Prep prerequisite | PASS (serial) |
| Clear executed | yes |
| Dump path | .ai/context/device-logs/MAS-09/capture-meta.json |
| Format | json |
| Line count | 5 |
| Tag filter | APP_TRACE |
| Package | com.example.app |
| Message | Dumped 5 lines to .ai/context/device-logs/MAS-09/ |

**Step 0b:** `clear-and-marker -TaskId MAS-09 -Tag APP_TRACE` with `ADB_DEVICES_FIXTURE` + `ANDROID_SERIAL` fixture. Exit 0; `repro-marker.json` written.

**Post dump:** `dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE` with `ADB_LOGCAT_FIXTURE=.ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-sample.txt` and `ADB_CRASH_LOGCAT_FIXTURE=.ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-crash-sample.txt`. Exit 0; artifacts at `.ai/context/device-logs/MAS-09/`.

## Commands

| # | Command | Source | Result |
|---|---------|--------|--------|
| 1 | `capture-device-logs.ps1 dump` (no `ANDROID_SERIAL`) → `NO_SERIAL` exit 10 | strategy #1 | PASS |
| 2 | `ADB_DEVICES_FIXTURE=adb-devices-unauthorized.txt` → `UNAUTHORIZED` exit 11 | strategy #2 | PASS |
| 3 | `ADB_DEVICES_FIXTURE` offline state → `OFFLINE` exit 12 | strategy #3 | PASS |
| 4 | `clear-and-marker -TaskId MAS-09 -Tag APP_TRACE` → `repro-marker.json` | strategy #4 | PASS |
| 5 | `dump` + `ADB_LOGCAT_FIXTURE=adb-logcat-sample.txt` → PASS, 5 lines | strategy #5 | PASS |
| 6 | `dump` + `ADB_LOGCAT_FIXTURE=adb-logcat-empty.txt` → `CAPTURE_EMPTY` exit 0 | strategy #6 | PASS |
| 7 | PATH stripped (no adb, no fixtures) → `ADB_NOT_FOUND` exit 1 | strategy #7 | PASS |
| 8 | `dump` without `-TaskId` → `INVALID_ARGS` exit 7 | strategy #8 | PASS |
| 9 | `ADB_PIDOF_EMPTY=1` + `-Package` → tag-only + `PID_NOT_FOUND` warning | strategy #9 | PASS |
| 10 | `ADB_API_LEVEL_FIXTURE=29` → `threadtime` + `FORMAT_FALLBACK` | strategy #10 | PASS |
| 11 | `capture-device-logs.sh` POSIX parity rows 1–6 | strategy #11 | SKIP |
| 12 | JSON stdout vs `script-stdout-pass.json` / `script-stdout-capture-empty.json` | strategy #12 | PASS |
| 13 | `capture-meta.json` core fields vs `capture-meta-expected.json` | strategy #13 | PASS |
| 14 | Executor Step 0b → clear-and-marker + Clear executed = yes | strategy #14 | PASS |
| 15 | Executor Post dump → Device Logs section populated | strategy #15 | PASS |
| 16 | Prep FAIL (`NO_SERIAL`) → capture blocked | strategy #16 | PASS |
| 17 | `LOG_CAPTURE: no` JVM-only skip stub | strategy #17 | SKIP |
| 18 | `rg "## Device Logs" brief-schemas.md` | strategy #18 | PASS |
| 19 | Device Logs Prerequisites table in test-strategy | strategy #19 | PASS |
| 20 | `rg "LOG_CAPTURE\|capture-device-logs\|Device Logs\|LOG_TAG"` skills/ | strategy #20 | PASS |
| 21 | `capture-device-logs-hook.ps1` stop → path-only `additional_context` | strategy #21 | FAIL |
| 22 | Hook dump failure → fail-open `{}` | strategy #22 | PASS |
| 23 | Hook stdout — no log body (`logcat-main` content absent) | strategy #23 | PASS |
| 24 | `capture-device-logs.ps1 -Help` sanity | strategy Recommended | PASS |
| 25 | `android-device-prep.ps1` Step 0 fixture PASS | strategy Recommended | PASS |

## Pass/fail

Overall: PARTIAL
P0 commands: PARTIAL (20/22 PASS; 1 FAIL; 2 SKIP)

## Failures

| # | Command | Error summary | Flaky | Route |
|---|---------|---------------|-------|-------|
| 1 | `capture-device-logs-hook.ps1` stop event with stdin JSON payload | Returns `{}` instead of `additional_context` with capture-meta path — PowerShell binds redirected stdin as pipeline `$Input`, triggering `ParameterBindingException` before hook reads `Console.In`; fail-open masks expected path-only context | no | bug-fix |

## Gaps

| # | Test | Reason |
|---|------|--------|
| 11 | POSIX `capture-device-logs.sh` parity (rows 1–6) | `bash` not available on win32 agent host; defer to Linux/macOS CI |
| 17 | `LOG_CAPTURE: no` JVM-only skip (`MAS-09-LOG-SKIP-JVM` stub) | Out of scope for this executor spawn — handoff has `LOG_CAPTURE: yes`; skip rationale documented in strategy Tests to Skip |
| 24–34 | P1 rows (`--dry-run`, `--max-lines`, subcommand isolation, workflow telemetry, beforeSubmitPrompt, manifest semver, live smoke, cloud SKIP, convention doc) | P1 defer per strategy ship gate — P0 fixture matrix prioritized |

**Tests to Skip (from strategy):** Gradle/Paparazzi in MAS repo N/A; live physical device substituted by fixtures; `LOG_ESCALATION: full-bugreport` P2 defer; inline prep in capture script architecture-forbidden.

## Evidence

### Fixture env vars used

```
ADB_DEVICES_FIXTURE=.ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt
ADB_LOGCAT_FIXTURE=.ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-sample.txt
ADB_CRASH_LOGCAT_FIXTURE=.ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-crash-sample.txt
ANDROID_SERIAL=R58M90ABCDE
```

### Sample stdout JSON (dump PASS, last line)

```json
{"status":"PASS","exit_code":"PASS","message":"Dumped 5 lines to .ai/context/device-logs/MAS-09/","capture_meta_path":".ai/context/device-logs/MAS-09/capture-meta.json","line_count":5}
```

### capture-meta.json snapshot (post dump PASS)

| Field | Value |
|-------|-------|
| status | PASS |
| format | json |
| api_level | 34 |
| pid | 12345 |
| line_count.total | 5 |
| warnings | (empty) |

### Protocol grep evidence

- `rg "LOG_CAPTURE|capture-device-logs|Device Logs|LOG_TAG|LOG_PACKAGE" skills/` → 73 matches
- `rg "## Device Logs" skills/multi-agent-system/protocol/brief-schemas.md` → 2 matches
- `rg "Step 0b|clear-and-marker" skills/mas-test-executor/SKILL.md` → 6 matches
- `rg "Device Logs Prerequisites" skills/multi-agent-system/references/` → 2 matches

### Artifact paths

- `.ai/context/device-logs/MAS-09/repro-marker.json`
- `.ai/context/device-logs/MAS-09/capture-meta.json`
- `.ai/context/device-logs/MAS-09/logcat-main.jsonl`
- `.ai/context/device-logs/MAS-09/logcat-crash.txt`
