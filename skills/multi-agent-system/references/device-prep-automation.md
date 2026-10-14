# Device Prep Automation (MAS-07 v1.5.0)

Single source of truth for the **android-device-prep** gate: enrollment, state machine, selection policy, grants, blockers, and cloud skip paths.

Scripts: `skills/multi-agent-system/scripts/android-device-prep.{ps1|sh}`

Consumers: **test-executor** Step 0, Gradle `connected*AndroidTest`, **mas-visual-fidelity** tier-3 (via `ANDROID_SERIAL`), `capture-connected-device` (connectivity-only re-check).

---

## One-time enrollment checklist

1. Enable **Developer options** on the device.
2. Enable **USB debugging** (or pair wireless adb — v1.5.1).
3. Connect USB; unlock the phone.
4. On the RSA prompt, tap **Always allow from this computer**.
5. Verify: `adb devices -l` shows serial in `device` state (not `unauthorized`).

**Honesty:** First connect requires human unlock + RSA trust. Repeat runs assume enrollment. Prep **never** bypasses RSA (`UNAUTHORIZED` cites this checklist).

---

## Prep gate state machine

Parsed from `adb devices -l`:

| State / condition | Action | `exit_code` | Process exit |
|-------------------|--------|-------------|--------------|
| Zero rows in `device` state | FAIL | `NO_DEVICE` | 10 |
| Any `unauthorized`, no `device` yet | FAIL — enrollment | `UNAUTHORIZED` | 11 |
| Selected target `offline` after retry | FAIL | `OFFLINE` | 12 |
| Exactly one `device` row | Select → continue | — | — |
| Multiple `device` rows | Apply selection policy | `AMBIGUOUS_DEVICE` if unresolved | 13 |
| `--serial` not in `device` state | FAIL | `SERIAL_NOT_FOUND` | 14 |
| Boot wait exceeds timeout | FAIL | `BOOT_TIMEOUT` | 15 |
| Pipeline complete | PASS | `PASS` | 0 |
| `adb` not on PATH | FAIL | `ADB_NOT_FOUND` | 1 |
| Invalid arguments | FAIL | `INVALID_ARGS` | 7 |

**Offline retry:** `adb kill-server && adb start-server` once before failing `OFFLINE`.

---

## ANDROID_SERIAL selection policy

Priority (first match wins):

| Priority | Condition | Selected serial |
|----------|-----------|-----------------|
| 1 | `--serial` / handoff `DEVICE_SERIAL` | Exact match in `device` state; else `SERIAL_NOT_FOUND` |
| 2 | Exactly one `device` row | That serial |
| 3 | `DEVICE_POLICY: physical` | Sole hardware (`emulator-*` excluded) |
| 4 | `DEVICE_POLICY: emulator` | Sole `emulator-*` serial |
| 5 | `DEVICE_POLICY: auto` | Prefer sole hardware over emulators; single emulator when no hardware |
| 6 | Multiple hardware, no override | FAIL `AMBIGUOUS_DEVICE` |

**MAS-06 coupling:** `VISUAL_FIDELITY` or connected-device capture defaults `DEVICE_POLICY: physical`.

Canonical env: **`ANDROID_SERIAL`** (exported on PASS). **`ADB_SERIAL`** accepted as read alias in capture script.

---

## JSON stdout contract

Always emit a single JSON object on stdout (last line if warnings on stderr).

### PASS (example)

```json
{
  "status": "PASS",
  "serial": "R58M90ABCDE",
  "exit_code": "PASS",
  "message": "Device ready; ANDROID_SERIAL=R58M90ABCDE",
  "policy_applied": "physical",
  "boot_wait_ms": 3200,
  "grants_applied": ["android.permission.CAMERA"],
  "grants_skipped": [],
  "reverse_applied": ["tcp:8080:8080"],
  "animations_disabled": true,
  "warnings": []
}
```

### FAIL (example)

```json
{
  "status": "FAIL",
  "serial": null,
  "exit_code": "UNAUTHORIZED",
  "message": "Device unauthorized — unlock phone and tap Always allow on USB debugging prompt. See device-prep-automation.md enrollment checklist.",
  "policy_applied": "physical",
  "boot_wait_ms": null,
  "grants_applied": [],
  "grants_skipped": [],
  "reverse_applied": [],
  "animations_disabled": false,
  "warnings": []
}
```

**Agent rule:** exit 0 + `status: PASS` → proceed; non-zero OR `status: FAIL` → Device FAIL, skip device commands.

---

## Permission pre-grant

```bash
adb -s $ANDROID_SERIAL shell pm grant <package> <permission>
```

Non-grantable permissions (`MANAGE_EXTERNAL_STORAGE`, etc.) → `grants_skipped` + warning; status remains PASS.

---

## Fixture testing (framework dogfood)

Set `ADB_DEVICES_FIXTURE` to a file with mock `adb devices -l` output:

```powershell
$env:ADB_DEVICES_FIXTURE = ".ai/fixtures/MAS-07-ADB-PREP/adb-devices-single.txt"
powershell -File skills/multi-agent-system/scripts/android-device-prep.ps1 -Policy auto -JsonOnly
```

Optional: `ADB_BOOT_COMPLETED=0` to simulate incomplete boot (BOOT_TIMEOUT with low `-BootTimeout`).

Fixtures: `.ai/fixtures/MAS-07-ADB-PREP/`

---

## Skip paths

| Scenario | Prep gate | test-run Device |
|----------|-----------|-----------------|
| JVM-only (unit, Paparazzi, Compose Preview) | skip + rationale | SKIPPED |
| `managed-ftl` / Firebase Test Lab | skip | SKIPPED; cloud command in strategy |
| Cursor Cloud / no adb on host | skip | SKIPPED; Gaps `BLOCKED: no adb on agent host` |
| Prep FAIL | attempted | FAIL; device cmds SKIP |

---

## Serialization

No parallel adb in one workflow turn: **Step 0 completes** before Gradle connected, capture, or Maestro.

**Division of responsibility:**

| Concern | Owner |
|---------|--------|
| Discovery + selection | `android-device-prep` |
| Boot wait, animation off, grants, reverse | `android-device-prep` |
| Launch + screencap | `capture-connected-device` |
| P0/P1 fidelity diff | mas-visual-fidelity |

---

## Log capture (MAS-09 v1.7.0)

Downstream consumer: `capture-device-logs.{ps1|sh}` — chained **after** prep Step 0 PASS.

| Step | Script subcommand | When |
|------|-------------------|------|
| 0b | `clear-and-marker` | `LOG_CAPTURE: yes` + prep PASS |
| Post | `dump` | After repro / test commands |
| Hook `stop` | `dump` | `LOG_CAPTURE: yes` + session completed |

**Prep coupling (D2):** Capture script reads `ANDROID_SERIAL` from prep; does **not** call `android-device-prep` inline. Unset serial → `NO_SERIAL` (exit 10).

Artifacts: `.ai/context/device-logs/{TASK_ID}/` — see [device-log-capture.md](device-log-capture.md).

Fixture dogfood: `.ai/fixtures/MAS-09-LOG-CAPTURE/` with `ADB_LOGCAT_FIXTURE` + MAS-07 `ADB_DEVICES_FIXTURE`.

---

## Future (v1.5.1)

- `--connect host:port` for wireless-only workflows
- Optional animator scale restore after session
