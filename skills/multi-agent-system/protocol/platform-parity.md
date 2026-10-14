# Platform Parity (MAS-07 / MAS-09)

Honest boundaries for adb-dependent workflows across Cursor environments.

## Local IDE + CLI

| Capability | Supported |
|------------|-----------|
| `android-device-prep` (MAS-07) | Yes — requires `adb` on PATH |
| `capture-connected-device` (MAS-07) | Yes |
| `capture-device-logs` (MAS-09) | Yes — requires prior prep PASS + `ANDROID_SERIAL` |

## Cursor Cloud Agent

| Capability | Behavior |
|------------|----------|
| Device prep | `SKIPPED` — Gaps cite `BLOCKED: no adb on agent host` |
| Log capture (`LOG_CAPTURE: yes`) | `SKIPPED` — same rationale; workflow not FAIL (D12) |
| Hook `stop` dump | fail-open `{}` when adb unavailable |

## Hook payload drift

MAS-08 fail-open v1.6: log capture hook failure returns `{}` — agent `stop` not blocked. Hooks expose path-only `additional_context` (~200 chars max); never log bodies.

## Fixture dogfood

Framework CI validates scripts via `ADB_DEVICES_FIXTURE` / `ADB_LOGCAT_FIXTURE` — no physical device required. See `.ai/fixtures/MAS-07-ADB-PREP/` and `.ai/fixtures/MAS-09-LOG-CAPTURE/`.
