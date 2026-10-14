# OSINT Brief — MAS-09

## Research Mode

FEATURE

## Topic

How do Android dev tools, AOSP, OSS libraries, and Cursor hooks automate logcat capture and structured logging (exceptions, API calls, lifecycle) during user bug reproduction?

## Scope

MAS framework extension — plugin/hooks/scripts for connected-device log capture; complements MAS-07 `android-device-prep` gate; target Android Kotlin/Retrofit/OkHttp stacks; integrated with Cursor project hooks (MAS-08 v1.6).

## Research Summary

Industry practice splits **host-side log capture** (adb clear → reproduce → dump with tag/PID/buffer filters, optionally JSON on API 30+) from **app-side structured instrumentation** (Timber trees + OkHttp `EventListener` + lifecycle observers emitting a stable tag namespace). Dev inspectors (Chucker, Flipper) excel at human debugging but are poor MAS automation inputs because they require desktop UI or in-app screens. For MAS, the winning pattern mirrors MAS-07: a prep-gated script emitting JSON stdout, invoked from Cursor `stop` / `afterShellExecution` hooks with artifact paths surfaced via `additional_context` (never full log bodies). App teams should standardize on machine-parseable log lines (JSON sink or `-v json` logcat) covering exceptions, HTTP events, and navigation/lifecycle breadcrumbs — aligned with the planned `mas-observability` brief type from MAS-04 Phase C.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | https://developer.android.com/tools/logcat | official | 2026-10-06 | current | Buffer model, filter expressions, format flags |
| 2 | https://developer.android.com/studio/debug/bug-report | official | 2026-10-06 | current | `adb bugreport` vs targeted logcat |
| 3 | https://source.android.com/docs/core/tests/debug/read-bug-reports | official | 2026-10-06 | current | Cross-log correlation (logcat, events, ANR) |
| 4 | https://github.com/skydoves/android-testing-skills/blob/main/adb/observability/extracting-logs-with-logcat/SKILL.md | maintained OSS | 2026-10-06 | main | CI repro pattern: `-c` → scenario → `-d`; JSON + `--pid` |
| 5 | https://square.github.io/okhttp/features/events/ | official | 2026-10-06 | OkHttp 5.x | Per-call `EventListener.Factory`; stable format = custom listener |
| 6 | https://github.com/ChuckerTeam/chucker | maintained OSS | 2026-10-06 | active | OkHttp network interceptor; debug-only UI |
| 7 | https://github.com/facebook/flipper | maintained OSS | 2026-10-06 | 0.x | Desktop network plugin; shared `NetworkFlipperPlugin` instance required |
| 8 | https://github.com/JakeWharton/timber | maintained OSS | 2026-10-06 | 5.x | Tree-based logging; debug vs release planting |
| 9 | https://github.com/CASL0/structlog-timber | maintained OSS | 2026-10-06 | recent | Key-value fields + pluggable sinks (logcat, Crashlytics) |
| 10 | https://developer.android.com/reference/androidx/lifecycle/ProcessLifecycleOwner | official | 2026-10-06 | lifecycle 2.6+ | App foreground/background lifecycle |
| 11 | https://firebase.google.com/docs/crashlytics/android/customize-crash-reports | official | 2026-10-06 | current | Breadcrumbs for prod; not primary for local repro |
| 12 | https://cursor.com/docs/hooks | official | 2026-10-06 | hooks v1 | `afterShellExecution`, `stop`, `postToolUse`, `subagentStop` |
| 13 | Local: `skills/multi-agent-system/scripts/android-device-prep.ps1` | local seed | 2026-10-06 | MAS-07 v1.5 | JSON stdout contract, `ANDROID_SERIAL`, exit codes |
| 14 | Local: `hooks/mas-session-context.sh` | local seed | 2026-10-06 | MAS-08 | `subagentStop` followup pattern |
| 15 | Local: `.ai/context/architecture/MAS-08.md` | local seed | 2026-10-06 | v1.6.0 | Project hooks topology, fail-open, artifact-forward |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | Android logcat docs + skydoves skill | Reproducible bug log attachment | **Clear → reproduce → dump**: `adb logcat -c`; user/agent reproduces; `adb logcat -d -b main,crash -v threadtime` or `-v json -v UTC -v year` (API 30+); filter `AppTag:D *:S` or `--pid=$(pidof -s pkg)`; write to `.ai/context/device-logs/{TASK_ID}/logcat.jsonl` | Large dumps without filters; PID changes on restart (re-resolve); R8 may strip `Log.d` in release | Direct complement to MAS-07 prep; same serial selection policy | **adopt** — host capture script | HIGH |
| 2 | MAS-07 prep + device-prep-automation.md | Device must be authorized before any adb log op | Chain: `android-device-prep` PASS → export `ANDROID_SERIAL` → log script uses `-s $SERIAL`; on FAIL emit same exit-code vocabulary; optional `-Package` for `pidof` | Cloud Agent has no adb (MAS-08 parity matrix) | Identical gate to visual-fidelity / test-executor | **adopt** — prep-first invariant | HIGH |
| 3 | OkHttp EventListener + Timber + ProcessLifecycleOwner | Structured exceptions, API calls, lifecycle during repro | App `Application`: plant `Timber.DebugTree` (debug) + custom `Tree` with fixed tag (e.g. `APP_TRACE`); OkHttp `EventListener.Factory` logs JSON lines (method, url host, status, duration_ms — redact bodies); `ProcessLifecycleOwner` + `ActivityLifecycleCallbacks` log screen transitions; `Thread.setDefaultUncaughtExceptionHandler` delegates after `Timber.e(throwable)` | Custom EventListener maintenance; Flipper/Chucker formats not stable for agents | Kotlin/Retrofit/OkHttp target stack | **adapt** — convention + thin wrappers, not copy OSS | HIGH |
| 4 | Chucker / Flipper | HTTP inspection during manual debug | Chucker: `addNetworkInterceptor(ChuckerInterceptor)` persists requests in-app UI; Flipper: single shared `NetworkFlipperPlugin` + `FlipperOkhttpInterceptor` | Desktop Flipper required; Chucker UI-only; both debugImplementation; not machine-ingestible for MAS | Developer convenience alongside MAS, not automation path | **adapt** — optional debug dep; MAS reads logcat not Chucker DB | MEDIUM |
| 5 | structlog-timber / Crashlytics | Machine-parseable fields + prod breadcrumbs | `StructuredTimber` with `LogcatSink` emitting flat JSON key-values; Crashlytics `log()` for WARN+ with main-thread posting caveat (firebase-android-sdk #8034) | Extra dependency; Crashlytics is prod-oriented | Optional sink for teams already on Firebase; MAS repro uses logcat first | **adapt** — optional sink; avoid Crashlytics-only repro | MEDIUM |
| 6 | Stetho / LeakCanary (SOURCES_HINT) | Legacy network DB / memory leaks | Stetho largely superseded by Flipper/Chucker; LeakCanary targets heap leaks not general repro logs | Stetho unmaintained pattern; LeakCanary narrow scope | Mentioned in handoff only | **avoid** for MAS logging extension | HIGH |
| 7 | `adb bugreport` (Android Studio docs) | Full system diagnostic | Zip with dumpsys + full logcat; heavy (100MB+) | Overkill per-bug MAS loop; slow | Escalation tier when logcat insufficient (ANR, system_server) | **adapt** — optional `LOG_CAPTURE: full-bugreport` flag | MEDIUM |
| 8 | Cursor hooks (MAS-08) | Automate capture at repro window end | Extend project `.cursor/hooks.json`: (a) `beforeSubmitPrompt` matcher for repro keywords → invoke clear+marker script; (b) `stop` with `status: completed` → dump logcat to task artifact dir; (c) `afterShellExecution` matcher `adb` → persist output path metadata; return `additional_context` with brief path only; use `loop_limit` on `subagentStop` | Hooks fail-open v1.6; stdout must be valid JSON only; Cloud Agent adb SKIP | Aligns with MAS-08 ProjectHooks module; artifact-forward invariant | **adopt** — hook recipes in plugin bundle | HIGH |

## Recommended Approach

### Architecture: two-layer repro observability

```
[Layer A — Host / MAS plugin]
  android-device-prep (MAS-07) → PASS + ANDROID_SERIAL
        ↓
  capture-device-logs.{ps1|sh}
    --clear | --dump | --marker | --package <id> | --tag <ns>
    emits JSON: { status, serial, paths[], line_count, buffers[], format }
        ↓
  .ai/context/device-logs/{TASK_ID}/
    logcat-main.jsonl, logcat-crash.txt, capture-meta.json
        ↓
  Cursor hooks (stop / afterShellExecution) → additional_context: path only

[Layer B — Target Android app (convention doc, not framework code)]
  Application.onCreate:
    Timber trees (debug + structured release tree)
    OkHttp EventListener → APP_TRACE JSON lines
    Lifecycle observers → navigation breadcrumbs
    UncaughtExceptionHandler → Timber.e then default handler
```

### MAS plugin extension (v1.7 direction)

| Component | Purpose | Phase |
|-----------|---------|-------|
| `capture-device-logs.{ps1\|sh}` | Prep-gated clear/dump; mirrors prep JSON contract | P0 |
| `device-log-capture.md` reference | Tag namespace, buffer list, redaction rules | P0 |
| `.cursor/hooks.json` entries | `stop` dump, optional `beforeSubmitPrompt` clear | P0 |
| `mas-repro-logging` skill slice OR extend `mas-test-executor` | Step 0b: clear logs before repro; Step N: attach Device Logs section to test-run brief | P1 |
| Handoff flags: `LOG_CAPTURE: yes`, `LOG_PACKAGE`, `LOG_TAG` | Coordinator routing to test-executor / bug-fix | P1 |
| `device-logs` brief type (or test-run **Device Logs** slice) | Paths, filters, line counts — consumed by imaginer/bug-fix | P1 |
| Optional `mas-observability` linkage (MAS-04 C) | Prod telemetry vs local logcat boundary | P2 |

### Structured logging contract (app teams)

| Signal | Mechanism | Log tag / field |
|--------|-----------|-----------------|
| Exceptions | `Timber.e(t, msg)` + default uncaught handler | `priority=E`, `event=uncaught` |
| API calls | Custom OkHttp `EventListener` (not `LoggingEventListener` format) | `event=http`, `method`, `host`, `path`, `status`, `duration_ms` |
| Lifecycle | `ProcessLifecycleOwner` + `ActivityLifecycleCallbacks` | `event=lifecycle`, `screen`, `state` |
| User repro step | App exposes debug-only `adb am broadcast` or log line `event=repro_marker` | Correlates host `--marker` timestamp |

**Redaction:** never log auth headers, tokens, PII; document R8 `-assumenosideeffects` for `Log.d` in release (skydoves skill).

### Cursor hook integration (MAS-08 compatible)

1. **Do not** inject log bodies into `additional_context` — path + metadata only (MAS-08 invariant).
2. **`stop` hook:** when `status=completed` and handoff `LOG_CAPTURE: yes`, run dump script; append path to workflow session JSON (extend `record-workflow-step` fields: `log_capture_path`).
3. **`beforeSubmitPrompt` (optional):** detect repro intent (`repro`, `bug`, `logcat`) → clear buffers idempotently.
4. **`afterShellExecution`:** matcher for `adb.*logcat` — record artifact path from script stdout JSON.
5. **`subagentStop`:** unchanged chain reminder; bug-fix handoff includes `BRIEF_PATH: .ai/context/device-logs/{TASK_ID}/capture-meta.json`.
6. **Platform parity:** document adb/log capture as IDE+CLI local only; Cloud Agent SKIP (same as MAS-07).

### Differentiation from dev inspectors

| Tool | Role in MAS |
|------|-------------|
| Chucker / Flipper | Human debug; optional `debugImplementation` |
| Crashlytics | Production triage; not local repro primary |
| `adb bugreport` | Escalation for ANR/system issues |
| MAS capture script | **Authoritative** automation artifact for bug-fix / imaginer |

## Priority Order

1. **Finding #1 + #2** — Host `capture-device-logs` script chained after MAS-07 prep; highest ROI, no app code required for basic repro.
2. **Finding #8** — Cursor `stop` hook wiring with artifact-forward paths; completes user bug-repro loop in IDE.
3. **Finding #3** — App structured logging convention (Timber + EventListener + lifecycle); enables filtered `-v json` dumps agents can parse.
4. **Finding #4** — Chucker as optional dev companion; explicitly not the MAS ingestion path.
5. **Finding #7** — Full bugreport as opt-in escalation for ANR/crash-buffer-empty cases.

## Anti-Patterns Avoided

- Piping `adb logcat | grep` on host instead of logcat filter expressions (skydoves: expensive, lossy).
- Using OkHttp `LoggingEventListener` as stable machine format (Square docs: format not stable).
- Separate Flipper `NetworkFlipperPlugin` instances for client vs interceptor (common integration bug).
- Stetho for new work (superseded; handoff SOURCES_HINT legacy only).
- Injecting full logcat into hook `additional_context` (token blow-up; violates MAS-08).
- Crashlytics-only repro (requires network; breadcrumb thread caveats).
- Spawning background logcat without prep gate (ambiguous serial / unauthorized device).

## Implementation Guidance

**For general-dev (framework repo):**

1. Add `skills/multi-agent-system/scripts/capture-device-logs.ps1` (+ `.sh`) sibling to `android-device-prep.ps1`:
   - Accept `-Serial` (default `$env:ANDROID_SERIAL`), `-Package`, `-Tag`, `-Buffers main,crash`, `-Format json|threadtime`, `-OutputDir`.
   - Subcommands: `clear`, `dump`, `clear-and-marker` (writes ISO timestamp file).
   - Exit codes: reuse prep map where applicable + `CAPTURE_EMPTY` (warn, not fail).
   - Last stdout line: JSON matching prep style.

2. Extend `device-prep-automation.md` with **Log capture** section (prep prerequisite, pid re-resolution loop note).

3. Add hook template `hooks/capture-device-logs-hook.ps1` invoked from `stop` — reads latest handoff `TASK_ID`, calls dump, returns `{ "additional_context": "Device logs: .ai/context/device-logs/TASK_ID/..." }`.

4. Update `install/manifest.json` scripts array; bootstrap copies to `.cursor/hooks/`.

**For android-dev (target apps — convention only in framework docs):**

1. Single log tag namespace (e.g. `APP_TRACE`) for MAS filter: `adb logcat APP_TRACE:D OkHttp:D *:S`.
2. Retrofit client: shared `OkHttpClient` with custom `EventListener.Factory` logging structured single-line JSON.
3. `debugImplementation` Chucker optional; release uses tree-only logging.
4. Document repro marker: host script writes `repro_started_at` file; app logs matching `event=repro_marker` line.

**For test-executor:** Step 0 = prep; Step 0b = `capture-device-logs clear` when `LOG_CAPTURE: yes`; post-test `dump` → test-run brief **Device Logs** table (mirror **Device** section from MAS-07).

**For bug-fix / imaginer:** Read `device-logs/{TASK_ID}/capture-meta.json` before local trace; correlate timestamps with repro marker.

## License / Copy Guardrails

- Chucker: Apache-2.0 — pattern description only; do not vendor interceptor code into MAS scripts.
- Flipper: MIT — debug-only; noop release artifact pattern only.
- Timber: Apache-2.0 — planting pattern only.
- structlog-timber: Apache-2.0 — optional third-party; evaluate version pin separately.
- OkHttp EventListener: Apache-2.0 — implement custom listener; do not paste `LoggingEventListener` source.
- MAS scripts: same license as framework repo; no GPL tooling in default path.

## Regression Notes

N/A — FEATURE mode. Related: MAS-07 prep gate regression fixtures (`.ai/fixtures/MAS-07-ADB-PREP/`); add `MAS-09-LOG-CAPTURE` fixtures for dry-run dump JSON.

## Local Files Referenced

- `skills/multi-agent-system/scripts/android-device-prep.ps1`
- `hooks/mas-session-context.sh`
- `.ai/context/architecture/MAS-08.md`
- `skills/multi-agent-system/references/device-prep-automation.md` (consumer pattern)

## Open Questions

- Should `device-logs` be a new brief type or a test-run / imaginer slice? (Recommend test-run **Device Logs** slice first; promote to brief type if bug-fix-only workflows need it without test execution.)
- Minimum API level for `-v json` logcat in MAS default recipe (recommend API 30+ default, threadtime fallback).
- Coordinator flag naming: `LOG_CAPTURE` vs `DEVICE_LOGS` vs lite `LOG:y` — align with MAS-08 handoff extension process.
- Whether `beforeSubmitPrompt` auto-clear is too aggressive for non-bug sessions (recommend opt-in via handoff flag only).

## Overall Confidence

**HIGH** — Official Android logcat and Cursor hooks documentation align with maintained OSS CI patterns (skydoves) and existing MAS-07/MAS-08 architecture. Medium uncertainty only on exact hook payload fields across Cursor versions and optional structlog-timber adoption vs lightweight custom Timber tree.
