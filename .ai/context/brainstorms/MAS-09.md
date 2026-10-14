# Brainstorm Brief — MAS-09

## Problem & User Outcome

**Problem:** MAS v1.5–v1.6 ships device prep (MAS-07) and project hooks (MAS-08) but has no **reproducible logcat capture** contract during bug reproduction. Agents and developers manually run ad-hoc `adb logcat`, paste unstructured traces into chat (token blow-up), or rely on Chucker/Flipper UIs that are not machine-ingestible. Exceptions, HTTP calls, and lifecycle breadcrumbs are not correlated across host dump windows, and hook `additional_context` has no artifact path for log files.

**User outcome:** During a `/mas` bug-repro workflow, MAS automatically **clears log buffers before repro**, **dumps filtered logcat after repro** to a task-scoped artifact directory, and surfaces **path-only metadata** to agents via hooks — with optional app-side structured logging so dumps are parseable (exceptions, API calls, lifecycle, extensible categories).

**UI scope:** `logic-only` (per handoff). Designs host scripts, hook recipes, handoff flags, brief schema slices, and app logging *conventions* — not Compose layouts, in-app debug screens, or Chucker UI.

**OSINT delta:** OSINT (`.ai/context/osint/MAS-09.md`) converges on two-layer repro observability (HIGH): prep-gated host `capture-device-logs` script (HIGH), Cursor `stop`/`afterShellExecution` hooks with artifact-forward paths (HIGH), Timber + OkHttp `EventListener` + lifecycle observers for structured lines (HIGH). Chucker/Flipper as human debug only (MEDIUM). `adb bugreport` as escalation tier (MEDIUM). This brief evaluates placement, contracts, and integration with MAS-07/08 — does **not** re-research externally.

**Prior-art delta:** MAS-07 established `android-device-prep.{ps1|sh}` JSON stdout, exit-code vocabulary, `ANDROID_SERIAL` export, and test-run **Device** section. MAS-08 established project hooks, fail-open v1.6, artifact-forward invariant (never inject full brief/log bodies). `capture-connected-device.{ps1|sh}` proves sibling script pattern for adb ops. MAS-04 Phase C planned `mas-observability` — local logcat is repro-primary; prod telemetry is P2 boundary.

---

## Options

| # | Option | Pros | Cons | Risk | Effort | Fits memory? |
|---|--------|------|------|------|--------|--------------|
| 1 | **Host-only capture script** — `capture-device-logs.{ps1\|sh}` with `clear`/`dump`/`marker` subcommands; prep-gated; writes `.ai/context/device-logs/{TASK_ID}/`; no app code changes | Works immediately on any installed APK; mirrors MAS-07 script pattern; JSON stdout for executor; no target-app PR required | Unfiltered dumps are huge/noisy; R8 strips `Log.d` in release; no HTTP/lifecycle structure without app cooperation; PID changes on process restart | L | S | Y |
| 2 | **App structured logging convention only** — document Timber tree + OkHttp `EventListener` + lifecycle observers emitting `APP_TRACE` JSON lines; no MAS host automation | Rich, parseable signals (exceptions, HTTP, navigation); filterable via `adb logcat APP_TRACE:D *:S` | Agents still run adb manually; no hook integration; inconsistent adoption across repos; no repro window correlation | M | S | Partial |
| 3 | **Two-layer composite: host script + app convention + Cursor hooks** (recommended) — prep → clear → repro → dump; structured app logs in dump; `stop` hook emits path metadata; test-run **Device Logs** slice; handoff flags `LOG_CAPTURE`, `LOG_PACKAGE`, `LOG_TAG` | End-to-end repro loop in IDE; artifact-forward aligns MAS-08; filtered dumps reduce token cost; extensible category namespace; bug-fix reads `capture-meta.json` before trace | Requires framework scripts + hook templates + convention doc; app teams must adopt logging contract for full value; API 30+ for `-v json` default | L | M | Y |
| 4 | **Dev inspector as ingestion path** — Chucker DB export or Flipper desktop plugin as MAS input | Excellent human debugging; OkHttp visibility out of the box | Not automation-friendly; debugImplementation only; Flipper needs desktop; format unstable for agents; violates artifact-bus pattern | H | M | N |

**Fits existing patterns?** Option 3: Y — extends MAS-07 prep gate + MAS-08 hooks + `scripts/` convention. Option 1: Y but incomplete alone. Option 2: Partial — convention without orchestration. Option 4: N — OSINT explicitly avoids.

---

## Recommended

**Option 3 — Two-layer composite: prep-gated `capture-device-logs` host script + structured app logging convention + Cursor hook recipes + test-run Device Logs slice.**

**Rationale vs alternatives:**

- **vs Option 1 (host-only):** Basic repro works without app changes, but unfiltered logcat dumps overwhelm agents and lack HTTP/lifecycle correlation. Option 3 keeps host script as P0 foundation and adds convention doc so teams opt into parseable `-v json` lines.
- **vs Option 2 (app-only):** Without MAS orchestration, every agent reinvents clear→repro→dump; hooks cannot surface artifact paths. Option 3 wires the automation loop MAS-08 expects.
- **vs Option 4 (Chucker/Flipper):** Industry-standard for *human* debug; explicitly not the MAS ingestion path. Document as optional `debugImplementation` companion; MAS reads logcat artifacts only.

**Phased delivery (Planner should sequence):**

| Phase | Deliverable | Dependency |
|-------|-------------|------------|
| P0 | `capture-device-logs.{ps1\|sh}` + `device-log-capture.md` reference + manifest entry | MAS-07 prep contract |
| P0 | Hook template: `stop` dump when `LOG_CAPTURE: yes` | MAS-08 ProjectHooks |
| P1 | test-run **Device Logs** section + test-executor Step 0b/Post | MAS-07 Device section |
| P1 | Handoff flags + Coordinator routing to test-executor / bug-fix | handoff-format.md |
| P1 | App logging convention doc (`mas-repro-logging` skill slice or extend `mas-android-dev`) | — |
| P2 | Optional `LOG_CAPTURE: full-bugreport` escalation | — |
| P2 | `mas-observability` boundary (prod vs local logcat) | MAS-04 Phase C |

---

## Logic Flow

### A. End-to-end repro observability topology

```
[Coordinator] handoff LOG_CAPTURE: yes, LOG_PACKAGE, LOG_TAG (optional)
       ↓
[test-executor Step 0]  android-device-prep → PASS → export ANDROID_SERIAL
       ↓
[test-executor Step 0b] capture-device-logs clear [--marker]
       ↓
[Human / agent]  Reproduce bug on device
       ↓
[Cursor stop hook | test-executor post-step]  capture-device-logs dump
       ↓
.ai/context/device-logs/{TASK_ID}/
  logcat-main.jsonl | logcat-crash.txt | capture-meta.json | repro-marker.json
       ↓
[Hook additional_context]  path + line_count only (never log body)
       ↓
[bug-fix / imaginer]  Read capture-meta.json; correlate repro_marker timestamp
```

### B. Host script state machine (`capture-device-logs`)

| Subcommand | Preconditions | Actions | Exit |
|------------|---------------|---------|------|
| `clear` | Prep PASS or `ANDROID_SERIAL` set | `adb -s $SERIAL logcat -c`; optional write `repro-marker.json` with ISO timestamp | 0 / prep fail codes |
| `marker` | Serial known | Append marker file only (no clear) | 0 |
| `dump` | Serial known | Resolve PID via `pidof -s $PACKAGE` if set; `adb logcat -d -b main,crash` with `-v json` (API 30+) or `-v threadtime` fallback; filter `$TAG:D *:S`; write output files | 0; warn `CAPTURE_EMPTY` if 0 lines |
| `clear-and-marker` | Prep PASS | clear + marker atomically | 0 |

**Prep-first invariant:** If `ANDROID_SERIAL` unset, invoke prep gate inline (or FAIL with `NO_SERIAL` — Architect should decide: recommend **require prep PASS** for consistency with MAS-07).

### C. Structured logging contract (target Android apps — convention, not framework code)

| Signal | Mechanism | Log fields |
|--------|-----------|------------|
| Exceptions | `Timber.e(t, msg)` + `Thread.setDefaultUncaughtExceptionHandler` chaining | `event=uncaught`, `priority=E` |
| API calls | Custom OkHttp `EventListener.Factory` (not `LoggingEventListener`) | `event=http`, `method`, `host`, `path`, `status`, `duration_ms` |
| Lifecycle | `ProcessLifecycleOwner` + `ActivityLifecycleCallbacks` | `event=lifecycle`, `screen`, `state` |
| Navigation | Fragment/Compose route observer (app-specific) | `event=nav`, `route` |
| Repro correlation | App logs `event=repro_marker` when debug broadcast received OR host marker timestamp | matches `repro-marker.json` |
| Extensible categories | Single tag namespace `APP_TRACE` (configurable via `LOG_TAG`) | `event=<category>`, flat JSON key-values |

**Redaction rules (non-negotiable):** Never log auth headers, tokens, request/response bodies with PII, passwords. Document R8 `-assumenosideeffects` for debug `Log` in release builds.

### D. Cursor hook integration (MAS-08 compatible)

| Hook | Matcher / trigger | Action | Output |
|------|-------------------|--------|--------|
| `beforeSubmitPrompt` | Optional; handoff `LOG_CAPTURE: yes` + repro keywords | `capture-device-logs clear` | `{}` or warn stderr only |
| `stop` | `status=completed` + latest handoff `LOG_CAPTURE: yes` | `capture-device-logs dump`; read TASK_ID from handoff | `{"additional_context":"Device logs: .ai/context/device-logs/{TASK_ID}/capture-meta.json"}` |
| `afterShellExecution` | matcher `adb.*logcat` or script name | Parse stdout JSON `paths[]`; record in workflow session | path metadata only |
| `subagentStop` | unchanged | Chain reminder; bug-fix handoff may set `BRIEF_PATH` to capture-meta | existing mas-session-context |

**Invariants:** fail-open v1.6; stdout valid JSON only from hook scripts; Cloud Agent documents adb SKIP (platform-parity matrix).

### E. test-executor workflow extension

| Step | When | Command |
|------|------|---------|
| 0 | adb surface | `android-device-prep` (existing) |
| 0b | `LOG_CAPTURE: yes` | `capture-device-logs clear --marker` |
| 1..N | strategy commands | Gradle / adb / maestro |
| Post | `LOG_CAPTURE: yes` + repro occurred | `capture-device-logs dump` → populate test-run **Device Logs** |

### F. Agent ingestion contract

1. **bug-fix / general-dev:** At startup, if `BRIEF_PATH` or handoff points to `capture-meta.json`, read metadata (paths, filters, line_count, repro_started_at) — then read log files on disk (not injected via hook).
2. **Parse priority:** `logcat-crash.txt` → `APP_TRACE` JSON lines → unfiltered main buffer tail.
3. **Correlation:** Match `repro-marker.json` timestamp to first `event=repro_marker` or first app log after marker.

---

## Domain & Contracts

### Entities

| Entity | Location | Purpose |
|--------|----------|---------|
| `CaptureMeta` | `.ai/context/device-logs/{TASK_ID}/capture-meta.json` | Index: serial, package, tag, buffers, format, paths[], line_count, repro_started_at |
| `LogcatArtifact` | `logcat-main.jsonl`, `logcat-crash.txt` | Raw dump files |
| `ReproMarker` | `repro-marker.json` | ISO timestamp for repro window start |
| `DeviceLogsSlice` | test-run brief section | Summary table for reviewer |
| `WorkflowSessionLogCapture` | `.ai/context/workflow-sessions/{TASK_ID}.json` field `log_capture_path` | Telemetry |

### `capture-meta.json` schema (sketch)

```json
{
  "status": "PASS",
  "task_id": "MAS-09",
  "serial": "R58M90ABCDE",
  "package": "com.example.app",
  "tag_filter": "APP_TRACE",
  "buffers": ["main", "crash"],
  "format": "json",
  "api_level": 34,
  "paths": {
    "main": ".ai/context/device-logs/MAS-09/logcat-main.jsonl",
    "crash": ".ai/context/device-logs/MAS-09/logcat-crash.txt"
  },
  "line_count": { "main": 142, "crash": 3 },
  "repro_started_at": "2026-10-06T12:00:00.000Z",
  "dumped_at": "2026-10-06T12:05:00.000Z",
  "warnings": ["CAPTURE_EMPTY: crash buffer"]
}
```

### Script stdout JSON (last line — mirrors prep style)

```json
{
  "status": "PASS",
  "exit_code": "PASS",
  "message": "Dumped 142 lines to .ai/context/device-logs/MAS-09/",
  "capture_meta_path": ".ai/context/device-logs/MAS-09/capture-meta.json",
  "line_count": 142
}
```

### Exit codes (extend prep map)

| Code | Name | When |
|------|------|------|
| 0 | PASS | Success |
| 1 | ADB_NOT_FOUND | adb missing |
| 7 | INVALID_ARGS | Bad flags |
| 10–15 | (reuse prep) | NO_DEVICE, UNAUTHORIZED, etc. |
| 20 | CAPTURE_EMPTY | Dump succeeded but 0 lines — warn, exit 0 |
| 21 | DUMP_FAILED | adb logcat error |

### Handoff flags (proposed — Planner aligns with handoff-format.md)

| Flag | Values | Routing |
|------|--------|---------|
| `LOG_CAPTURE` | `yes` \| `no` (default no) | Enables Step 0b + dump + stop hook |
| `LOG_PACKAGE` | applicationId | PID filter for dump |
| `LOG_TAG` | default `APP_TRACE` | logcat tag filter |
| `LOG_BUFFERS` | default `main,crash` | `-b` list |
| `LOG_FORMAT` | `json` \| `threadtime` | API-aware default |
| `LOG_ESCALATION` | `full-bugreport` (P2) | Optional heavy capture |

Lite alias: `LOG:y` on handoff (MAS-08 lite extension process).

### test-run **Device Logs** section (proposed schema slice)

```markdown
## Device Logs

| Field | Value |
|-------|-------|
| Capture gate | PASS \| FAIL \| SKIPPED |
| Prep prerequisite | PASS (serial) |
| Clear executed | yes \| no |
| Dump path | .ai/context/device-logs/{TASK_ID}/capture-meta.json |
| Format | json \| threadtime |
| Line count | <n> |
| Tag filter | APP_TRACE \| — |
| Package | com.example.app \| — |
| Message | <from script JSON> |
```

**Conditional:** Required when `LOG_CAPTURE: yes` and capture attempted (including FAIL/SKIP). Omit when JVM-only with documented skip rationale.

### App-side types (convention doc — not shipped in MAS repo)

```kotlin
// Illustrative — target app implements
data class TraceEvent(
  val event: String,       // http | lifecycle | uncaught | nav | custom
  val timestamp: String,   // ISO-8601
  val fields: Map<String, String>
)

// OkHttp EventListener logs single-line JSON to Timber.tag("APP_TRACE")
// Timber.Tree planted in Application.onCreate (debug + structured release tree)
```

### Category extension mechanism

Apps register category handlers that emit `event=<name>` under `LOG_TAG`. MAS documents reserved events: `http`, `lifecycle`, `uncaught`, `repro_marker`, `nav`. Custom events (e.g. `db`, `analytics`) use same JSON line format — host filter uses tag only; category distinguished by `event` field.

---

## Edge Cases

| Case | Handling |
|------|----------|
| No device / unauthorized | Prep FAIL before clear/dump; test-run Device Logs `SKIPPED` with prep blocker message |
| Cloud Agent / no adb | `LOG_CAPTURE: yes` → SKIP with platform-parity rationale; do not FAIL workflow |
| Process restart mid-repro | PID filter stale — fall back to package `pidof` re-resolve at dump time; document in reference |
| API < 30 | Default `-v threadtime`; json format flag ignored with warning |
| R8 strips debug logs in release | Convention doc: use structured release tree for `APP_TRACE` or repro debug builds only |
| Empty crash buffer | `CAPTURE_EMPTY` warning; still write meta; bug-fix checks main buffer |
| Huge unfiltered dump | Enforce tag + PID filters; cap optional `--max-lines` (P1) with truncation warning |
| Multiple devices | Reuse MAS-07 selection policy; require prep PASS serial |
| Concurrent workflows | Artifact dir scoped by `TASK_ID`; no shared global log path |
| Hook fires without repro | `stop` dump still runs — may capture empty/minimal; meta records line_count |
| `beforeSubmitPrompt` auto-clear | **Opt-in only** via handoff — avoid clearing logs on non-bug sessions |
| ANR / system_server issues | Escalation: `LOG_ESCALATION: full-bugreport` (P2); document size/time cost |
| OkHttp bodies in logs | EventListener must redact; never use BODY-level `HttpLoggingInterceptor` for MAS |
| Wireless adb disconnect mid-dump | DUMP_FAILED; retry once; cite OFFLINE enrollment |
| Fixture testing | `ADB_DEVICES_FIXTURE` + dry-run mode mirroring MAS-07 fixtures pattern |

---

## Quality Bar

- **Idempotency:** `clear` and `dump` safe to re-run; marker overwrites with new timestamp.
- **Prep coupling:** Never run log ops without resolved `ANDROID_SERIAL` (same invariant as capture-connected-device).
- **Artifact-forward:** Hooks and `additional_context` expose paths only — max ~200 chars context string.
- **Fail-open hooks:** Log capture failure must not block agent `stop` or subagent chain.
- **Security:** No tokens/PII in logs or meta; convention doc lists redaction checklist.
- **Observability:** `capture-meta.json` includes `dumped_at`, `line_count`, `warnings[]` for reviewer audit.
- **Platform parity:** Document IDE+CLI local only; Cloud SKIP — extend `platform-parity.md`.
- **Test strategy (logic layer):**
  - Fixture dry-run tests for script JSON output (`.ai/fixtures/MAS-09-LOG-CAPTURE/`)
  - Contract test: prep FAIL → capture script does not call adb
  - Sample `APP_TRACE` JSON lines → parser unit test in convention doc examples
- **Similar code alignment:** `android-device-prep.ps1`, `capture-connected-device.ps1`, `hooks/mas-session-context.sh`, MAS-07 test-run **Device** section.

---

## Risks & Open Questions

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unfiltered dumps token-blow agent context | H | Mandatory tag/PID filters; path-only hook context |
| Low app adoption of structured logging | M | P0 host script works without app changes; convention is additive |
| Cursor hook payload drift across versions | M | fail-open; minimal JSON; document in platform-parity |
| `-v json` unavailable on older devices | L | threadtime fallback; record `format` in meta |
| `beforeSubmitPrompt` clear too aggressive | M | Opt-in via handoff only (OSINT recommends) |
| PID race on fast restarts | M | Re-resolve at dump; document in reference |

### Open Questions (for Planner / Architect)

1. **Brief type vs slice:** Start with test-run **Device Logs** slice (recommended); promote to standalone `device-logs` brief type if bug-fix-only workflows need logs without test execution.
2. **Inline prep vs require prior prep:** Should `capture-device-logs` call prep internally or require Step 0 PASS? (Recommend: **require prep PASS** for single serial source of truth.)
3. **Flag naming:** `LOG_CAPTURE` vs `DEVICE_LOGS` — align with MAS-08 handoff extension; lite `LOG:y`.
4. **Default format:** API 30+ → `json`; else `threadtime` — document detection in script.
5. **Max lines cap:** P0 unbounded vs P1 `--max-lines 5000` default?
6. **structlog-timber dependency:** Optional third-party vs lightweight custom Timber tree in convention doc?
7. **Workflow session field:** `log_capture_path` vs nested `device_logs: { meta, line_count }`?
8. **Version bump:** v1.7.0 additive (script + hooks) — confirm with release manifest policy.

### Suggested Next

**planner** — Break P0/P1 tasks: script authoring, hook template, handoff flags, test-run schema extension, fixtures, convention doc ownership (`mas-android-dev` vs new skill slice).

---

## References

- `.ai/context/osint/MAS-09.md`
- `skills/multi-agent-system/scripts/android-device-prep.ps1`
- `skills/multi-agent-system/scripts/capture-connected-device.ps1`
- `skills/multi-agent-system/references/device-prep-automation.md`
- `.ai/context/architecture/MAS-08.md` (ProjectHooks, artifact-forward)
- `.ai/context/brainstorms/MAS-07.md` (prep gate pattern)
- `hooks/mas-session-context.sh`
