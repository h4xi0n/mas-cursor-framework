# Device Log Capture (MAS-09 v1.7.0)

Single source of truth for **capture-device-logs** workflow: prep prerequisite, state machine, filters, format fallback, artifact layout, and redaction rules.

Scripts: `skills/multi-agent-system/scripts/capture-device-logs.{ps1|sh}`

Consumers: **test-executor** Step 0b/Post, Cursor hooks (`stop` dump), **bug-fix** / **general-dev** ingestion via `capture-meta.json`.

**Upstream:** MAS-07 `android-device-prep` exports `ANDROID_SERIAL` (Step 0). Capture script **does not** invoke prep inline (D2).

---

## Prep-first invariant

Never run log ops without resolved `ANDROID_SERIAL` (from prep PASS or `--serial`).

| Condition | Result |
|-----------|--------|
| `ANDROID_SERIAL` unset | FAIL `NO_SERIAL` (exit 10); no adb |
| Device unauthorized | FAIL `UNAUTHORIZED` (exit 11) |
| Device offline | FAIL `OFFLINE` (exit 12) |
| Prep FAIL (Step 0) | test-executor skips clear/dump; Device Logs `SKIPPED` |

See [device-prep-automation.md](device-prep-automation.md) for enrollment and prep state machine.

---

## Subcommand state machine

| Subcommand | Actions | Artifacts |
|------------|---------|-----------|
| `clear` | `adb logcat -c` | — |
| `marker` | Write `repro-marker.json` | `repro-marker.json` |
| `dump` | PID resolve → dump main + crash buffers | `logcat-main.*`, `logcat-crash.txt`, `capture-meta.json` |
| `clear-and-marker` | `clear` then `marker` | `repro-marker.json` |

**Serialization:** Step 0 (prep) → Step 0b (`clear-and-marker`) → repro → Post dump OR `stop` hook dump. Never parallel adb.

---

## Filter expression

Tag filter: `$TAG:D *:S` (default tag `APP_TRACE`).

```bash
adb -s $SERIAL logcat -d -b main -v json --pid=$PID APP_TRACE:D *:S
```

**PID resolution (D13):** `adb shell pidof -s $PACKAGE` at dump time only. Empty → tag-only filter + `PID_NOT_FOUND` warning in meta.

**Crash buffer:** `adb logcat -d -b crash` — no tag filter.

---

## Format fallback (D4)

| API level | Default format | Main artifact |
|-----------|----------------|---------------|
| ≥ 30 | `json` (`-v json`) | `logcat-main.jsonl` |
| < 30 | `threadtime` | `logcat-main.txt` |

Override via `--format` or handoff `LOG_FORMAT`. `FORMAT_FALLBACK: threadtime` recorded in `warnings[]` when auto-fallback applies.

---

## Artifact layout

```
.ai/context/device-logs/{TASK_ID}/
├── capture-meta.json       # Index (always on dump)
├── repro-marker.json       # ISO timestamp (marker / clear-and-marker)
├── logcat-main.jsonl       # Main buffer (json format)
│   or logcat-main.txt      # Main buffer (threadtime)
└── logcat-crash.txt        # Crash buffer (text)
```

### `capture-meta.json` fields

| Field | Type | Notes |
|-------|------|-------|
| `status` | `PASS` \| `FAIL` | Dump outcome |
| `task_id` | string | From `--task-id` |
| `serial` | string | Device serial |
| `package` | string \| null | PID filter package |
| `tag_filter` | string | e.g. `APP_TRACE` |
| `buffers` | string[] | e.g. `["main","crash"]` |
| `format` | `json` \| `threadtime` | Format used |
| `api_level` | int | SDK at dump time |
| `pid` | int \| null | Resolved PID |
| `paths` | object | Relative paths to artifacts |
| `line_count` | object | `main`, `crash`, `total` |
| `repro_started_at` | string \| null | From marker |
| `dumped_at` | string | ISO-8601 |
| `warnings` | string[] | e.g. `CAPTURE_EMPTY`, `PID_NOT_FOUND`, `TRUNCATED: main` |

---

## JSON stdout contract

Last line on stdout (mirrors prep style):

```json
{
  "status": "PASS",
  "exit_code": "PASS",
  "message": "Dumped 142 lines to .ai/context/device-logs/MAS-09/",
  "capture_meta_path": ".ai/context/device-logs/MAS-09/capture-meta.json",
  "line_count": 142
}
```

`CAPTURE_EMPTY`: exit 0, `exit_code: CAPTURE_EMPTY`, `line_count: 0` — warn, not failure.

---

## Exit codes

| Code | `exit_code` | Meaning |
|------|-------------|---------|
| 0 | `PASS` | Success |
| 0 | `CAPTURE_EMPTY` | 0 lines — warn only |
| 1 | `ADB_NOT_FOUND` | `adb` not on PATH |
| 7 | `INVALID_ARGS` | Missing/invalid flags |
| 10 | `NO_SERIAL` | `ANDROID_SERIAL` unset |
| 11 | `UNAUTHORIZED` | Device unauthorized |
| 12 | `OFFLINE` | Device offline |
| 21 | `DUMP_FAILED` | logcat or write error |

---

## Handoff flags (D3)

| Field | Default | Purpose |
|-------|---------|---------|
| `LOG_CAPTURE: yes\|no` | `no` | Enable capture pipeline |
| `LOG_PACKAGE` | — | Application id for PID filter |
| `LOG_TAG` | `APP_TRACE` | Logcat tag |
| `LOG_BUFFERS` | `main,crash` | Buffer list |
| `LOG_FORMAT` | API-aware | `json` \| `threadtime` override |
| `LOG_ESCALATION: full-bugreport` | P2 | Deferred — `adb bugreport` escalation |

Lite alias: `LOG:y`

---

## Hook contracts (MAS-08 compatible)

| Hook | Trigger | Action |
|------|---------|--------|
| `stop` | `status=completed` + `LOG_CAPTURE: yes` | `dump` → path-only `additional_context` |
| `beforeSubmitPrompt` | Opt-in D8 + `repro\|bug\|logcat` matcher | `clear` only |
| `afterShellExecution` | `capture-device-logs\|adb.*logcat` matcher | Record `log_capture_path` in session |

**Invariants:** fail-open (`{}` on error); no log body in hook output (~200 char max).

---

## Redaction checklist

- Never log auth headers, tokens, passwords, or PII
- OkHttp: custom `EventListener` — not BODY-level `HttpLoggingInterceptor`
- R8: `-assumenosideeffects` for debug `Log` in release builds
- Chucker/Flipper: optional `debugImplementation` only — MAS reads logcat, not inspector DB

---

## Fixture / dry-run mode (D11)

| Env var | Purpose |
|---------|---------|
| `ADB_DEVICES_FIXTURE` | Mock connectivity (reuse MAS-07 fixtures) |
| `ADB_LOGCAT_FIXTURE` | Mock main buffer dump |
| `ADB_CRASH_LOGCAT_FIXTURE` | Mock crash buffer |
| `ADB_API_LEVEL_FIXTURE` | Override SDK level |
| `ADB_PIDOF_FIXTURE` | Override pidof output |
| `ADB_PIDOF_EMPTY` | Set `1` to simulate empty pidof (PID_NOT_FOUND) |

Fixtures: `.ai/fixtures/MAS-09-LOG-CAPTURE/`

---

## Skip paths

| Scenario | Device Logs |
|----------|-------------|
| `LOG_CAPTURE: no` | Omitted + JVM-only skip rationale |
| Prep FAIL | `SKIPPED` — clear/dump not invoked |
| Cloud Agent / no adb | `SKIPPED` — platform-parity (D12) |
| Dump FAIL | `FAIL` with script message |

---

## Agent ingestion (bug-fix / general-dev)

1. Read `capture-meta.json` when `BRIEF_PATH` points to device logs
2. Parse on disk — not via hook injection
3. **Priority:** `logcat-crash.txt` → `APP_TRACE` JSON lines → main buffer tail
4. Correlate `repro-marker.json` timestamp to first app log after marker

---

## P2 boundary

- `LOG_ESCALATION: full-bugreport` — separate artifact dir; opt-in only (D15)
- Local logcat (MAS-09) vs prod telemetry (MAS-04 Phase C) — cross-ref only (D16)
