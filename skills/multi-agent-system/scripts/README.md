# MAS Workflow Scripts

Shell and PowerShell utilities invoked by Coordinator and specialists via Shell tool.

## android-device-prep (MAS-07 v1.5.0)

Upstream device prep gate for test-executor Step 0, Gradle `connected*AndroidTest`, and tier-3 capture.

| Script | Platform |
|--------|----------|
| `android-device-prep.ps1` | Windows (primary) |
| `android-device-prep.sh` | Linux/macOS/CI |

Reference: [device-prep-automation.md](../references/device-prep-automation.md)

### Quick start

```powershell
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 `
  -Policy physical `
  -Package com.example.app `
  -Grants android.permission.CAMERA `
  -JsonOnly
```

### Fixture testing

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly
```

| Env var | Purpose |
|---------|---------|
| `ADB_DEVICES_FIXTURE` | Path to mock `adb devices -l` output |
| `ADB_BOOT_COMPLETED` | Set `0` to simulate incomplete boot |

### Exit codes

| Code | `exit_code` | Meaning |
|------|-------------|---------|
| 0 | PASS | Device ready |
| 1 | ADB_NOT_FOUND | `adb` not on PATH |
| 7 | INVALID_ARGS | Bad flags |
| 10 | NO_DEVICE | Zero devices |
| 11 | UNAUTHORIZED | RSA not trusted |
| 12 | OFFLINE | Device offline after retry |
| 13 | AMBIGUOUS_DEVICE | Policy unresolved |
| 14 | SERIAL_NOT_FOUND | Serial absent/unauthorized |
| 15 | BOOT_TIMEOUT | Boot wait exceeded |

On PASS, exports `ANDROID_SERIAL` for child commands.

## capture-connected-device (MAS-07)

Connected-device adb capture for `mas-visual-fidelity` Priority 3 pipeline.

| Script | Platform |
|--------|----------|
| `capture-connected-device.ps1` | Windows (primary MAS dev env) |
| `capture-connected-device.sh` | Linux/macOS/CI |

**Never installs APK** — debug build must be pre-installed by dev or test-executor.

### Quick start

```powershell
# Windows — deeplink launch
powershell -File skills/multi-agent-system/scripts/capture-connected-device.ps1 `
  -Serial emulator-5554 `
  -Package com.example.app `
  -Deeplink "myapp://fidelity/default" `
  -Output ".ai/context/visual-qa/captures/MAS-07/device-default.png" `
  -WaitMs 2000
```

```bash
# POSIX — explicit activity
./skills/multi-agent-system/scripts/capture-connected-device.sh \
  --serial emulator-5554 \
  --package com.example.app \
  --activity .FidelityActivity \
  --output ".ai/context/visual-qa/captures/MAS-07/device-default.png" \
  --wait-ms 2000
```

### Environment variables

| Flag | Env fallback |
|------|--------------|
| `--serial` / `-Serial` | `ANDROID_SERIAL` or `ADB_SERIAL` |
| `--package` | `PACKAGE` |
| `--activity` | `ACTIVITY` |
| `--deeplink` | `DEEPLINK` |
| `--action` | `ACTION` |
| `--extras` | `INTENT_EXTRAS` |
| `--wait-ms` | `POST_LAUNCH_WAIT_MS` |
| `--output` | `OUTPUT` |
| `--clear-task` | `CLEAR_TASK` |
| `--font-scale` | `FONT_SCALE` |
| `--ui-mode` | `UI_MODE` |
| `--crop` | `CROP_RECT` |

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success (warnings allowed) |
| 1 | `adb` not found on PATH |
| 2 | Zero authorized devices |
| 3 | Multiple devices; serial not specified |
| 4 | Device unauthorized or offline |
| 5 | Launch failed |
| 6 | Screencap or write failure |
| 7 | Invalid arguments |

### JSON stdout (success)

```json
{"serial":"emulator-5554","output":".ai/context/visual-qa/captures/TASK_ID/device-default.png","width":1080,"height":2400,"timestamp":"2026-09-28T12:00:00.000Z","warnings":[]}
```

Optional mirror: `{output}.summary.json` alongside PNG.

### Dry-run

`-DryRun` / `--dry-run` prints adb command sequence without requiring a device — used by reviewer dogfood and fixture validation.

### Artifact paths

```
.ai/context/visual-qa/captures/{TASK_ID}/
  device-default.png
  device-default.summary.json   # optional mirror of stdout
```

## capture-device-logs (MAS-09 v1.7.0)

Prep-gated logcat clear, marker, and dump for bug-repro workflows.

| Script | Platform |
|--------|----------|
| `capture-device-logs.ps1` | Windows (primary) |
| `capture-device-logs.sh` | Linux/macOS/CI |

Reference: [device-log-capture.md](../references/device-log-capture.md)

**Requires prior `android-device-prep` PASS** — reads `ANDROID_SERIAL`; does not invoke prep inline.

### Quick start

```powershell
# After prep exports ANDROID_SERIAL
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  clear-and-marker -TaskId MAS-09 -Tag APP_TRACE

# After repro window
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE -JsonOnly
```

### Subcommands

`clear` | `marker` | `dump` | `clear-and-marker`

### Fixture testing

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
$env:ADB_LOGCAT_FIXTURE = ".ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-sample.txt"
$env:ADB_CRASH_LOGCAT_FIXTURE = ".ai/fixtures/MAS-09-LOG-CAPTURE/adb-logcat-crash-sample.txt"
$env:ANDROID_SERIAL = "R58M90ABCDE"
powershell -File skills/multi-agent-system/scripts/capture-device-logs.ps1 `
  dump -TaskId MAS-09 -Package com.example.app -Tag APP_TRACE -JsonOnly
```

| Env var | Purpose |
|---------|---------|
| `ADB_DEVICES_FIXTURE` | Mock connectivity (reuse MAS-07) |
| `ADB_LOGCAT_FIXTURE` | Mock main buffer dump |
| `ADB_CRASH_LOGCAT_FIXTURE` | Mock crash buffer |
| `ADB_API_LEVEL_FIXTURE` | Override SDK level |
| `ADB_PIDOF_FIXTURE` | Override pidof (empty = PID_NOT_FOUND) |

### Exit codes

| Code | `exit_code` | Meaning |
|------|-------------|---------|
| 0 | PASS | Success |
| 0 | CAPTURE_EMPTY | 0 lines — warn only |
| 1 | ADB_NOT_FOUND | `adb` not on PATH |
| 7 | INVALID_ARGS | Bad flags |
| 10 | NO_SERIAL | `ANDROID_SERIAL` unset |
| 11 | UNAUTHORIZED | Device unauthorized |
| 12 | OFFLINE | Device offline |
| 21 | DUMP_FAILED | logcat or write error |

### JSON stdout

```json
{"status":"PASS","exit_code":"PASS","message":"Dumped 5 lines to .ai/context/device-logs/MAS-09/","capture_meta_path":".ai/context/device-logs/MAS-09/capture-meta.json","line_count":5}
```

Artifacts: `.ai/context/device-logs/{TASK_ID}/capture-meta.json`, `logcat-main.jsonl`, `logcat-crash.txt`, `repro-marker.json`

## Other scripts

See individual script header comments for `init-workflow-session`, `record-workflow-step`, `finalize-workflow-usage`, and context maintenance utilities.
