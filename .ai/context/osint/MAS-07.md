# OSINT Brief — MAS-07

## Research Mode

FEATURE

## Topic

How do CI systems, Android test frameworks, and agent workflows automate instrumentation/UI tests on physical ADB devices with zero manual prompts?

## Scope

MAS framework `mas-test-executor` integration — device discovery, USB/wireless debugging authorization, `ANDROID_SERIAL` selection, Gradle `connectedDebugAndroidTest`, app install/launch, `adb screencap`, UI Automator / uiautomator dump, and common blockers (unauthorized device, multiple devices, emulator vs physical). Stack: mas-cursor-framework (skills + scripts orchestrating target Android projects), not an app repo itself.

## Research Summary

Industry practice separates **one-time device enrollment** (human unlock + RSA accept or wireless pairing — unavoidable on consumer hardware per official ADB docs) from **repeatable automated prep** (discovery, state gates, serial pinning, boot/animation stabilization, permission pre-grant, then test execution). CI farms and agent pipelines that claim "zero intervention" rely on pre-authorized dedicated devices or cloud-managed devices (Firebase Test Lab, Gradle Managed Devices) rather than bypassing Android's RSA trust model. For local physical devices — the MAS user scenario — the highest-confidence pattern is a **device prep gate** executed immediately before `test-executor` shell commands: parse `adb devices -l`, fail fast on `unauthorized`/`offline`/ambiguous multi-device, export `ANDROID_SERIAL`, wait for `sys.boot_completed`, optionally disable animations, pre-grant runtime permissions via `pm grant`, then run Gradle `connected*AndroidTest` or layered adb tools (`exec-out screencap`, `uiautomator dump`, `input tap`). Maestro and Appium add higher-level orchestration atop the same adb + accessibility primitives; Gradle connected tests remain the standard for existing instrumentation suites. MAS currently documents `connectedDebugAndroidTest` and `adb exec-out screencap` but lacks any device-prep contract — this is the integration gap.

## Sources Consulted

| # | Source | Tier | Date | Version | Notes |
|---|--------|------|------|---------|-------|
| 1 | [Android Developers — ADB](https://developer.android.com/tools/adb) | official | 2026-03 | Platform Tools | Device states, RSA dialog requirement, `ANDROID_SERIAL`, `-d`/`-e`, wireless pairing |
| 2 | [Android Developers — Instrumented tests](https://developer.android.com/training/testing/instrumented-tests) | official | 2026-03 | AndroidX Test | Espresso, UI Automator, Compose test, `AndroidJUnitRunner` |
| 3 | [Android Developers — UI Automator](https://developer.android.com/training/testing/other-components/ui-automator) | official | 2026-03 | UI Automator 2.4+ | DSL, `waitForStable`, screenshot + `ResultsReporter` |
| 4 | [Android Developers — Gradle Managed Devices](https://developer.android.com/studio/test/gradle-managed-devices) | official | 2026-03 | AGP | Virtual/FTL managed devices; `grantedPermissions = "all"`; avoids local USB auth |
| 5 | [Firebase Test Lab — Get started](https://firebase.google.com/docs/test-lab/android/get-started) | official | 2026-03 | — | Remote physical/virtual devices; Espresso/UI Automator; no local adb RSA |
| 6 | [Maestro — What is Maestro](https://docs.maestro.dev/get-started/what-is-maestro.md) | maintained OSS | 2026 | Maestro CLI | Accessibility-first black-box automation; YAML flows; Compose supported |
| 7 | [Maestro — Android Driver Architecture (DeepWiki summary)](https://deepwiki.com/mobile-dev-inc/Maestro/4.2-android-driver-architecture) | community | 2026 | — | Hybrid gRPC UI Automator + adb shell routing |
| 8 | [Autosana — Espresso vs UiAutomator](https://autosana.ai/blogs/android-test-automation) | community | 2026 | — | System dialogs, permission grants, mixed Espresso+UiDevice pattern |
| 9 | Medium — ADB/UIAutomator agent deep-dive (Node Developer, 2026) | community | 2026 | — | `exec-out screencap`, serial adb queue, Compose via accessibility |
| 10 | MAS local: `skills/mas-test-executor/SKILL.md`, `build-test-visual-qa.md`, `visual-fidelity-standards.md` | local seed | 2026-09 | MAS v1.4 | Run-only executor; screencap capture tier 3; no device prep |

## Findings

| # | Source | Context | Pattern/Fix | Tradeoffs | Applicability | Recommendation | Confidence |
|---|--------|---------|-------------|-----------|---------------|----------------|------------|
| 1 | 1 | First USB connect shows RSA "Allow USB debugging?" — blocks unattended runs | **One-time enrollment + persistent trust:** enable Developer Options + USB debugging; on first connect user taps "Always allow from this computer"; host stores `~/.android/adbkey` pair; wireless uses `adb pair` once then auto-reconnects on trusted network (Android 11+). Revoke via Settings resets trust. **No supported bypass on locked retail devices.** | Cannot eliminate initial human step; key rotation requires re-enrollment; CI uses dedicated farm devices enrolled once | MAS must document enrollment as **prerequisite** outside agent loop; test-executor fails with actionable message on `unauthorized` | **adapt** | HIGH |
| 2 | 1,10 | Agent runs adb/Gradle blindly; flaky or cryptic failures | **Device prep gate (preflight script):** (a) `adb start-server`; (b) `adb devices -l` parse serial + state; (c) reject `unauthorized`, `offline`, zero devices, ambiguous multi-device unless policy picks one; (d) export `ANDROID_SERIAL` (or `-s` per command); (e) wait `adb shell getprop sys.boot_completed == 1`; (f) optional `settings put global animator_duration_scale 0` etc.; (g) emit structured JSON/status for test-run brief **Device** section | Adds ~5–30s per run; policy needed for emulator+physical coexistence | Core MAS integration: run gate before test-strategy commands in test-executor workflow; framework script in `skills/multi-agent-system/scripts/` or reference doc | **adopt** | HIGH |
| 3 | 1,4 | Multiple emulators + one phone → `adb: more than one device/emulator` | **Serial pinning policy:** prefer physical when `DEVICE_POLICY=physical` (visual fidelity / real rendering); else single connected device; use `-d` (one hardware), `-e` (one emulator), or explicit serial from gate; Gradle inherits `ANDROID_SERIAL` env var; `-s` overrides env | Wrong policy selects emulator when physical required (MAS-06 tier-3 screencap on wrong target) | test-strategy **Recommended Commands** prefix with `ANDROID_SERIAL=<serial>`; document filter rules (e.g. exclude `emulator-*`) | **adopt** | HIGH |
| 4 | 2,4,10 | Run existing androidTest instrumentation on device | **Gradle `connected{Variant}AndroidTest`:** AGP installs app + test APK, runs `AndroidJUnitRunner`, collects results. Example: `./gradlew :app:connectedDebugAndroidTest --tests "…"`. Requires exactly one target device or pinned serial. Animations off improves stability. | Slow vs unit tests; needs device; flaky on unstable USB | Primary path for P0 instrumentation in test-executor when test-strategy lists connected tests; aligns with `build-test-visual-qa.md` | **adopt** | HIGH |
| 5 | 1,8,9 | Runtime permission dialogs block unattended UI flows | **Pre-grant permissions before launch:** `adb shell pm grant <package> android.permission.<NAME>` for each required permission; instrumentation alternative: `GrantPermissionRule` / `UiAutomation` grant in test `@Before`; Firebase Test Lab `fixture.grantedPermissions = "all"` for managed runs. UiAutomator fallback for system sheets Espresso cannot touch | Package-specific; Android 13+ notification permission; some permissions not grantable via adb | test-strategy lists grants in **Device Prerequisites**; test-executor runs grant commands in prep gate before `am start` or connected tests | **adapt** | HIGH |
| 6 | 1,9,10 | Visual evidence / agent navigation without Java tests | **Layered adb capture stack:** screenshot via `adb exec-out screencap -p > capture.png` (binary-safe, especially Windows); hierarchy via `adb shell uiautomator dump /sdcard/view.xml` + pull + parse bounds/text/content-desc; interaction via `adb shell input tap|swipe|text|keyevent`; launch via `adb shell am start -n pkg/activity` or `monkey -p pkg -c LAUNCHER 1`. **Serialize adb calls** — parallel adb races corrupt state | Raw adb brittle vs Compose recomposition timing; file-path screencap can corrupt on Windows without `exec-out` | MAS-06 tier-3 capture + test-executor Option 6 fallback; agent evidence in test-run brief | **adapt** | HIGH |
| 7 | 3,8 | Cross-app/system UI during tests | **UI Automator instrumentation vs shell dump:** in-app tests use androidx UI Automator 2.4 DSL (`onElement`, `waitForStable`, built-in screenshots); system boundaries (notifications, settings) need `UiDevice` / shell uiautomator. Compose surfaces expose accessibility nodes — black-box viable | Slower than Espresso; shell dump is point-in-time not synchronized | test-strategy classifies: Espresso/Compose test for in-app; adb uiautomator for agent-driven smoke when no androidTest exists | **adapt** | MEDIUM |
| 8 | 6,7 | Agent-friendly YAML flows without writing instrumentation | **Maestro CLI as orchestration layer:** declarative flows; built-in wait/settle; Android driver combines adb shell (lifecycle, keys) + on-device gRPC UI Automator service; runs against any connected serial. Maestro Cloud for CI scale | Extra binary install; another tool chain; not run-only if executor must invoke `maestro test` | Optional P1 command in test-strategy when project has `*.yaml` flows; test-executor runs after prep gate | **adapt** | MEDIUM |
| 9 | 4,5 | Local USB auth / device scarcity in CI | **Managed/cloud devices when local physical blocked:** Gradle Managed Devices (local emulator ATD or Firebase Test Lab plugin) or `gcloud firebase test android run` — Google-hosted physical/virtual devices, pre-authorized, `grantedPermissions`, artifact pull. Not the user's "USB phone on desk" scenario but standard CI escape hatch | Cost; network; not local font/GPU fidelity | Document as **Skip with rationale** when no enrolled local device; do not pretend local adb works in cloud agents without USB passthrough | **adapt** | HIGH |
| 10 | 1 | Agent needs localhost API during device test | **`adb reverse` for dev backends:** `adb reverse tcp:<hostPort> tcp:<devicePort>` exposes workstation localhost to app; pair with prep gate serial. Complements instrumentation tests hitting local mock server | Reverse cleared on disconnect; API 21+ | test-strategy notes when integration tests hit local server; prep gate sets reverse before launch | **adapt** | MEDIUM |

## Recommended Approach

Integrate **device prep automation** as a framework-level contract consumed by `mas-test-strategy` (prerequisites + command prefixes) and `mas-test-executor` (preflight execution + evidence), without patching target app source.

### Architectural split (enrollment vs automation)

```
[Human once]  USB debugging ON → RSA "Always allow" OR wireless adb pair
       ↓
[Automated]   Device Prep Gate → test-executor commands → test-run brief
       │              │
       │              ├─ adb devices -l / state machine
       │              ├─ ANDROID_SERIAL export
       │              ├─ boot + animation + pm grant
       │              └─ optional adb reverse
       ↓
[Execute]     Gradle connected*AndroidTest | adb screencap/uiautomator | maestro test
```

**Critical honesty for MAS users:** "Zero user intervention" applies to **repeatable agent runs after enrollment**, not the first RSA trust establishment on a new host/device pair. Agent workflows that skip this distinction fail in production.

### Device state machine (prep gate)

| `adb devices` state | Action |
|-------------------|--------|
| (empty) | FAIL — `NO_DEVICE`; suggest USB cable / wireless reconnect |
| `unauthorized` | FAIL — `UNAUTHORIZED`; user must unlock device and accept RSA (link to enrollment doc) |
| `offline` | FAIL — retry `adb kill-server && adb start-server`; check cable/driver |
| `device` (one) | PASS — capture serial |
| `device` (multiple) | Apply **selection policy** (below) or FAIL — `AMBIGUOUS_DEVICE` |
| `emulator-*` + physical | Default MAS policy: **prefer physical serial** for visual fidelity / real-device tests; unit-only jobs may prefer emulator |

### Selection policy (recommended defaults)

1. If handoff/test-strategy specifies `DEVICE_SERIAL:` → use exactly that.
2. Else if exactly one `device` → use it.
3. Else if one hardware + emulators → pick hardware (`-d` semantics).
4. Else if multiple hardware → FAIL unless `DEVICE_SERIAL` set (never guess wrong phone).

### Command integration patterns

**Gradle (instrumentation):**

```bash
# After prep gate exports ANDROID_SERIAL
./gradlew :<module>:connectedDebugAndroidTest --tests "com.example.UiTest"
```

**Agent capture / smoke (no androidTest):**

```bash
adb exec-out screencap -p > .ai/artifacts/<TASK_ID>/capture.png
adb shell uiautomator dump /sdcard/view.xml && adb pull /sdcard/view.xml ...
adb shell am start -n <package>/<activity>
```

**Optional Maestro:**

```bash
maestro test flows/smoke.yaml
```

### test-executor skill boundary (MAS v1)

- test-executor remains **run-only** — does not author tests.
- Add **preflight**: invoke prep gate script; record Device section in `.ai/context/test-runs/{TASK_ID}.md`.
- On prep FAIL → Overall PARTIAL/FAIL; Gaps cite blocker; do not run connected tests (avoid misleading Gradle errors).
- test-strategy owns **Device Prerequisites** table (enrollment status, required grants, serial policy, skip cloud vs local).

### Cursor agent shell considerations

- Agent shell must reach host `adb` on PATH (Platform Tools) with USB permissions on the workstation OS.
- Long `connectedAndroidTest` runs need generous command timeout in executor.
- Cloud Cursor agents without USB passthrough **cannot** drive a physical desk phone — document `BLOCKED: no adb device visible to agent host`.
- Serialize adb invocations in prep + capture scripts.

### Relationship to MAS-06 visual fidelity

| Capture tier | Device requirement |
|--------------|-------------------|
| Paparazzi / Compose Preview Screenshot | JVM — no adb prep |
| `adb exec-out screencap` (tier 3) | **Requires prep gate PASS** + pinned serial + app in target state (launch command in strategy) |

## Recommended Fix Strategy

N/A — FEATURE mode.

## Priority Order

1. **Finding #2 — Device prep gate** — unblocks all adb/Gradle commands; converts cryptic failures into agent-actionable blockers.
2. **Finding #1 — Enrollment prerequisite doc** — sets correct user expectation; only fix for `unauthorized`.
3. **Finding #3 — ANDROID_SERIAL pinning policy** — prevents multi-device Gradle/adb race failures in dev machines with emulators open.
4. **Finding #5 — Permission pre-grant** — eliminates system-dialog stalls during unattended UI runs.
5. **Finding #4 — connectedDebugAndroidTest with prep** — standard instrumentation path already referenced in MAS docs; needs serial + stable device.

## Anti-Patterns Avoided

- **Assuming adb works without preflight** — `unauthorized` and multi-device errors waste agent turns on Gradle stack traces.
- **Promising RSA bypass on retail devices** — contradicts official Android security model; leads to false "zero intervention" marketing.
- **Parallel adb from multiple agent tools** — race conditions corrupt installs and screencaps.
- **File-based `screencap` + pull on Windows without `exec-out`** — PNG corruption risk (community agent reports).
- **Letting Gradle auto-pick device when emulator + phone connected** — wrong target for physical-device fidelity work.
- **Using cloud Test Lab patterns for local USB scenario without disclosure** — different trust, network, and rendering profile.

## Implementation Guidance

For **brainstorm / planner / architect** (framework repo only — no target app patches):

1. **New reference doc** `skills/multi-agent-system/references/device-prep-automation.md`:
   - Enrollment checklist (USB + wireless)
   - Prep gate state machine + exit codes (`NO_DEVICE`, `UNAUTHORIZED`, `AMBIGUOUS_DEVICE`, `BOOT_TIMEOUT`)
   - `ANDROID_SERIAL` / `-d` / `-e` selection rules
   - Permission grant template
   - Blocker → user message mapping

2. **Extend `test-strategy-standards.md` schema** with **Device Prerequisites** section:
   - `Enrollment: required | enrolled`
   - `Target: physical | emulator | managed-ftl`
   - `DEVICE_SERIAL: optional explicit`
   - `Permissions to pre-grant: list`
   - `Prep gate: required | skip (JVM-only tests)`

3. **Extend `mas-test-executor` workflow** (skill text only in this phase):
   - Step 0: run prep gate when any Recommended Command contains `adb`, `connected`, or `maestro`
   - test-run brief sections: **Device** (serial, state, prep PASS/FAIL), existing Commands/Pass-fail

4. **Optional shell script** `skills/multi-agent-system/scripts/android-device-prep.sh` (+ `.ps1` for Windows host parity):
   - Idempotent; stdout JSON for agent parsing
   - Called by test-executor, not duplicated in every strategy command

5. **test-strategy command template:**

   ```bash
   # Prep gate sets ANDROID_SERIAL
   ./gradlew :app:connectedDebugAndroidTest
   adb exec-out screencap -p > .ai/artifacts/<TASK_ID>/screen.png
   ```

6. **Skip path:** when only `testDebugUnitTest` / Paparazzi / Compose Preview Screenshot — prep gate **skip** with documented rationale in Gaps.

7. **Maestro optional tier:** test-strategy flags `MAESTRO_FLOW: path` for projects with YAML; prep gate still required.

## License / Copy Guardrails

- Maestro — Apache-2.0; describe CLI integration only.
- Maestro/Android driver architecture summaries — pattern description only.
- Medium/community agent posts — behavioral patterns only (exec-out, serial queue).
- No paste of prep script from third-party repos — MAS-owned minimal gate.

## Regression Notes

N/A — FEATURE mode. Related: MAS-06 tier-3 `adb screencap` assumes device available but defines no prep; MAS-04 test-executor v1 has no device section in test-run schema.

## Local Files Referenced

- `skills/mas-test-executor/SKILL.md`
- `skills/mas-test-strategy/SKILL.md`
- `skills/multi-agent-system/references/build-test-visual-qa.md`
- `skills/multi-agent-system/references/visual-fidelity-standards.md`
- `skills/multi-agent-system/references/test-strategy-standards.md`

## Open Questions

- **D1:** Windows-first prep script (`.ps1`) vs bash-only — user host is win32; both needed?
- **D2:** Should prep gate live in test-executor skill inline vs shared script invoked by visual-fidelity too?
- **D3:** Default physical-over-emulator policy — always on, or flag `DEVICE_POLICY: emulator|physical|auto` on handoff?
- **D4:** Maestro in v1 test-executor scope or defer to v2 optional integration?
- **D5:** Cursor Cloud Agent USB limitation — document as hard BLOCKED or support user-run local executor hook?
- **D6:** Wireless-only devices (no USB) — extend prep gate with `adb connect ip:port` health check?

## Overall Confidence

**HIGH** for prep gate, serial pinning, Gradle connected tests, permission pre-grant, and adb capture layering — multiple official Android sources agree. **MEDIUM** for Maestro-as-MAS-integration (maintained OSS, less official than AGP). **HIGH** that true first-connect RSA bypass is impossible on retail devices without prior enrollment — official ADB documentation is explicit.
