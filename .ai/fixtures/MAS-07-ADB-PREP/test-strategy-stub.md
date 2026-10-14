# Test Strategy Stub — MAS-07-ADB-PREP

## Device Prerequisites

| Field | Value |
|-------|-------|
| Enrollment | enrolled (assumed) |
| Target | none (fixture harness) |
| Prep gate | required |
| DEVICE_SERIAL | — |
| DEVICE_POLICY | physical |
| Package | — |
| Permissions to pre-grant | — |
| adb reverse | — |
| Skip rationale | — |

## Recommended Commands

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-emulator-plus-phone.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy physical -JsonOnly
```
