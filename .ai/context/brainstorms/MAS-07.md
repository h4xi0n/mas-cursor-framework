# Brainstorm Brief — MAS-07

## Problem & User Outcome

**Problem:** MAS v1.4 documents `connectedDebugAndroidTest` and `adb exec-out screencap` in `build-test-visual-qa.md` and `visual-fidelity-standards.md` (tier-3 capture), but `mas-test-executor` runs shell commands blindly with no device-prep contract. Repeat agent runs on a developer's physical phone fail unpredictably: `unauthorized` RSA state, ambiguous multi-device (`adb: more than one device/emulator`), boot-incomplete targets, animation-induced flakiness, and runtime permission dialogs stall unattended UI flows. Gradle stack traces waste agent turns; test-run briefs lack a **Device** section for reviewer evidence.

**User outcome:** After one-time USB/wireless enrollment, every `/mas` workflow that needs adb or connected instrumentation tests runs a **deterministic device prep gate** before test-executor commands — pinning `ANDROID_SERIAL`, stabilizing device state, pre-granting declared permissions — so repeat runs are fully automated with actionable blockers when prep fails.

**UI scope:** `logic-only` (per handoff). Designs MAS protocol contracts (prep gate, selection policy, brief schema extensions, executor workflow step 0). No Compose layouts, screens, or styling.

**OSINT delta:** OSINT (`.ai/context/osint/MAS-07.md`) converges on prep gate as core integration (HIGH), enrollment honesty (HIGH), serial pinning (HIGH), permission pre-grant (HIGH), Gradle connected tests as primary instrumentation path (HIGH). Maestro and cloud managed devices are optional escape hatches (MEDIUM). This brief evaluates implementation placement (script vs inline) and wires OSINT into test-strategy ↔ test-executor chain. Does **not** re-research externally.

**Prior-art delta:** MAS-04 shipped run-only `mas-test-executor` with no device section in test-run schema. MAS-06 tier-3 `adb screencap` assumes a device is available but defines no prep. Framework already has PowerShell scripts under `skills/multi-agent-system/scripts/` (session/changelog) — device prep follows same pattern with cross-platform parity.

---

## Options

| # | Option | Pros | Cons | Risk | Effort | Fits memory? |
|---|--------|------|------|------|--------|--------------|
| 1 | **Inline adb in `mas-test-executor` skill** — embed discovery, boot wait, animation off, `pm grant` as numbered shell steps in skill Workflow; agent runs raw adb each session | No new files; fastest to document; agent sees each step in chat | Duplicated logic if `mas-visual-fidelity` Option 6 fallback also needs prep; agent may skip/reorder steps; Windows `exec-out` and JSON parsing inconsistent across models; hard to unit-test; violates DRY with future Maestro path | M | S | N |
| 2 | **Shared prep gate script only** — `android-device-prep.ps1` + `.sh`; test-executor invokes script; stdout JSON; test-strategy lists prerequisites; no skill workflow change beyond "run script" | Idempotent, testable, single source of truth; both `.ps1` and `.sh` for win32 + CI; exit codes map to blockers; reusable by visual-fidelity tier-3 and Maestro | Requires script maintenance; agent must parse JSON; still needs skill text for *when* to skip prep | L | M | Y |
| 3 | **Composite: prep script + skill orchestration + schema extensions** (recommended) — script owns device ops; `device-prep-automation.md` reference owns state machine; test-strategy **Device Prerequisites** section declares enrollment/grants/policy; test-executor Step 0 invokes prep when commands match adb/connected/maestro; test-run brief gains **Device** section; skip path for JVM-only tests | Clean separation (strategy plans, script stabilizes, executor runs); aligns MAS-04 mutual exclusion; actionable failures before Gradle; serial exported once per session; matches existing `scripts/` pattern | +3 reference/skill touchpoints; D1 win32-first vs dual-script; coordinator must pass `DEVICE_POLICY` on handoff when ambiguous | L | M | Y |
| 4 | **Cloud/managed devices as default** — Gradle Managed Devices or Firebase Test Lab instead of local adb prep | No RSA on agent host; `grantedPermissions = "all"` in managed config; standard CI pattern | Not user's desk-phone scenario; cost/network; different rendering (fonts/GPU); Cursor cloud agents without USB cannot use local path anyway — must be **skip with rationale**, not default | M | L | Partial |

**Fits existing patterns?** Option 3: Y — extends MAS-04 advisory evidence model + `scripts/` convention. Option 1: N — duplicates orchestration across specialists. Option 4: N as default — document as skip path only.

---

## Recommended

**Option 3 — Composite: shared prep gate script + skill orchestration + test-strategy Device Prerequisites + test-run Device section.**

**Rationale vs alternatives:**

- **vs Option 1 (inline adb):** MAS-06 already routes tier-3 capture through test-executor fallback and visual-fidelity standards. Inline adb in one skill forces copy-paste or drift when a second consumer appears. A script with structured JSON output is the same pattern as `init-workflow-session.ps1` — framework-owned, agent-invoked.
- **vs Option 2 (script only):** Script without schema/skill contracts leaves test-strategy unable to declare grants or serial policy; executor would run prep unconditionally or never. Option 3 wires the full chain.
- **vs Option 4 (cloud default):** Valid **Skip with rationale** when `Prep gate: skip (no local adb)` — e.g. Cursor Cloud Agent without USB, or strategy is Paparazzi/JVM-only. Must not replace local physical-device path OSINT targets.

**Enrollment honesty (non-negotiable):** "Zero user intervention" applies to **repeat runs after RSA trust**. First connect requires human unlock + "Always allow" (or wireless `adb pair`). Prep gate FAIL `UNAUTHORIZED` must cite enrollment doc — no promise of RSA bypass.

---

## Logic Flow

### A. Architectural split

```
[Human once]  Developer Options ON → USB debugging → RSA "Always allow" OR adb pair
       ↓
[test-strategy]  Device Prerequisites table (enrollment, target, serial, grants, prep flag)
       ↓
[test-executor Step 0]  Prep gate (if required) → export ANDROID_SERIAL → test-run Device section
       ↓
[test-executor Step 1+]  Recommended Commands (Gradle connected* | adb capture | maestro)
       ↓
[test-run brief]  Device + Commands + Pass/fail → reviewer 0d
```

### B. Prep gate state machine (`adb devices -l` parse)

| State | Exit code | Action |
|-------|-----------|--------|
| (empty list) | `NO_DEVICE` | FAIL — suggest cable, `adb kill-server`, wireless reconnect |
| `unauthorized` | `UNAUTHORIZED` | FAIL — user must unlock + accept RSA; link enrollment checklist |
| `offline` | `OFFLINE` | FAIL — retry server restart once; check driver/cable |
| `device` (exactly one) | `PASS` | Capture serial → export `ANDROID_SERIAL` |
| `device` (multiple) | — | Apply **selection policy** (§C); FAIL `AMBIGUOUS_DEVICE` if policy cannot resolve |
| boot `sys.boot_completed != 1` | `BOOT_TIMEOUT` | FAIL after bounded wait (default 120s) |
| post-select stabilization | — | Optional: animator scales → 0; `wm dismiss-keyguard` if strategy allows (document risk) |

### C. ANDROID_SERIAL selection policy (recommended defaults)

Priority order — first match wins:

| Priority | Condition | Selected serial |
|----------|-----------|-----------------|
| 1 | test-strategy or handoff `DEVICE_SERIAL: <id>` | Exact match; FAIL if not in `device` state |
| 2 | Exactly one `device` row | That serial |
| 3 | `DEVICE_POLICY: physical` (default for visual fidelity / connected UI) | Sole hardware device (`-d` semantics); exclude `emulator-*` |
| 4 | `DEVICE_POLICY: emulator` | Sole emulator (`-e` semantics) |
| 5 | `DEVICE_POLICY: auto` | Prefer hardware over emulator when one of each |
| 6 | Multiple hardware serials | FAIL `AMBIGUOUS_DEVICE` — never guess wrong phone |
| 7 | Gradle / adb execution | Inherit `ANDROID_SERIAL` env; per-command `-s` only when strategy overrides |

**MAS-06 coupling:** Tier-3 `adb exec-out screencap` and connected UI tests default `DEVICE_POLICY: physical` when handoff has `VISUAL_FIDELITY` or design-spec exists.

### D. Gradle `connectedAndroidTest` integration

After prep PASS:

```bash
# ANDROID_SERIAL set by prep gate
./gradlew :<module>:connectedDebugAndroidTest --tests "com.example.FooUiTest"
```

| Concern | Handling |
|---------|----------|
| Variant | Strategy names full task (`connectedDebugAndroidTest`, `connectedReleaseAndroidTest`) |
| Single device | AGP uses `ANDROID_SERIAL` when exactly one target needed |
| Animations | Prep gate disables global animator scales (idempotent restore optional v1.1) |
| Timeout | Executor uses generous `block_until_ms` for connected suites (suggest ≥ 10 min P0) |
| No androidTest APK | Gradle FAIL — document in test-run Failures; route bug-fix |
| Prep FAIL | **Do not run** connected tasks — Overall PARTIAL/FAIL; Gaps cite prep blocker |

### E. Permission pre-grant patterns

**Declarative (test-strategy):** Device Prerequisites lists package + permissions:

```markdown
| Package | Permission | Grant method |
|---------|------------|--------------|
| com.example.app | android.permission.CAMERA | adb pm grant |
| com.example.app | android.permission.POST_NOTIFICATIONS | adb pm grant |
```

**Executor (prep gate extension):** After serial pin, run `adb shell pm grant <package> <permission>` for each row. Idempotent — already-granted is success.

| Pattern | When | Owner |
|---------|------|-------|
| **adb pm grant** (pre-test) | Unattended agent runs; permissions known upfront | prep gate + test-strategy |
| **GrantPermissionRule** / **UiAutomation.grant** | In-test `@Before`; Espresso-accessible | Dev per test-strategy hint (not executor v1) |
| **Firebase `grantedPermissions = "all"`** | Managed/FTL runs | Document as cloud skip path |
| **UiAutomator for system sheets** | Permissions not grantable via adb | test-strategy marks manual or in-test; not prep gate |

**Non-grantable via adb:** `MANAGE_EXTERNAL_STORAGE`, some special permissions — strategy must skip or use in-test grant; prep gate logs `GRANT_SKIPPED` warning, does not FAIL.

### F. test-strategy: Device Prerequisites section (new schema slice)

Add to `test-strategy-standards.md` brief template:

```markdown
## Device Prerequisites

| Field | Value |
|-------|-------|
| Enrollment | required \| enrolled (assumed) |
| Target | physical \| emulator \| managed-ftl \| none |
| Prep gate | required \| skip |
| DEVICE_SERIAL | optional explicit |
| DEVICE_POLICY | physical \| emulator \| auto (default physical when ui/connected) |
| Package | applicationId for grants |
| Permissions to pre-grant | list or — |
| adb reverse | optional `tcp:host:device` pairs or — |
| Skip rationale | when Prep gate = skip |
```

**Prep gate = skip** when ALL Recommended Commands are JVM-local:

- `testDebugUnitTest`, `compileDebugKotlin`, Paparazzi, Compose Preview Screenshot validate
- No `adb`, `connected`, `maestro`, `am start`, `uiautomator`

**Prep gate = required** when any command touches device shell, connected instrumentation, screencap, or Maestro.

### G. test-executor: prep invocation

**Step 0 — Device prep (before Step 1 load commands):**

1. Read test-strategy **Device Prerequisites**.
2. If `Prep gate: skip` → record Device section `SKIPPED — <rationale>`; proceed.
3. If `Prep gate: required`:
   - Run `skills/multi-agent-system/scripts/android-device-prep.ps1` (win32) or `android-device-prep.sh` (bash) with args: `--policy`, `--serial`, `--package`, `--grants`, `--boot-timeout`, `--reverse`.
   - Parse stdout JSON: `{ "status": "PASS"|"FAIL", "serial": "...", "exit_code": "...", "message": "..." }`.
   - On FAIL → write test-run Device section; set Overall PARTIAL/FAIL; copy blocker to Gaps; **skip** device commands (mark SKIP with prep reason).
   - On PASS → export `ANDROID_SERIAL` in agent shell for subsequent commands.
4. Serialize adb — no parallel adb from prep + capture in same turn.

**test-run brief — new Device section:**

```markdown
## Device

| Field | Value |
|-------|-------|
| Prep gate | PASS \| FAIL \| SKIPPED |
| Serial | <serial or —> |
| Policy | physical \| emulator \| auto |
| Exit code | NO_DEVICE \| UNAUTHORIZED \| … \| — |
| Grants applied | list or — |
| Message | actionable user text |
```

Register **Device** in `brief-schemas.md` test-run required sections (Planner/Architect touch).

### H. Failure modes & skip rationale matrix

| Failure | test-run outcome | Gaps / reviewer note | User action |
|---------|------------------|----------------------|-------------|
| `NO_DEVICE` | PARTIAL/FAIL; device cmds SKIP | "No adb device — enroll or connect" | USB/wireless connect |
| `UNAUTHORIZED` | PARTIAL/FAIL | "Accept RSA on device" | Unlock + Always allow |
| `AMBIGUOUS_DEVICE` | PARTIAL/FAIL | "Set DEVICE_SERIAL on handoff" | Disconnect extra devices or set serial |
| `BOOT_TIMEOUT` | PARTIAL/FAIL | "Device boot incomplete" | Reboot device |
| `OFFLINE` | PARTIAL/FAIL | "adb offline — cable/driver" | Reconnect |
| Prep PASS, Gradle FAIL | FAIL per command | bug-fix route | Fix test/app |
| JVM-only strategy | Device SKIPPED | Strategy skip rationale | N/A |
| Cloud agent, no USB | Device SKIPPED | `BLOCKED: no adb on agent host` | User runs locally or managed device |
| Maestro without binary | FAIL that command | "Install Maestro CLI" | Optional P1 |
| Grant partial | PASS with warning | List `GRANT_SKIPPED` | Manual/in-test grant |

**Skip honesty:** When connected tests are P0 but prep FAILs, Overall cannot be PASS — reviewer 0d must see Device FAIL or SKIP with explicit blocker.

### I. Optional paths (defer v1.1 unless planner promotes)

| Path | Trigger | Notes |
|------|---------|-------|
| **Maestro** | test-strategy `MAESTRO_FLOW: path` | Prep gate still required; `maestro test` after PASS |
| **Wireless-only** | `adb connect ip:port` in prep if serial absent but strategy lists endpoint | OSINT D6 |
| **adb reverse** | Integration tests hit localhost mock | Prep sets reverse before `am start` |
| **Managed FTL** | `Target: managed-ftl` | Skip local prep; document cloud command in strategy |

### J. Chain position (unchanged)

```
test-strategy (plans Device Prerequisites + commands)
  → dev
  → mas-visual-fidelity (optional)
  → … specialists …
  → test-executor (Step 0 prep → execute)
  → documenter → reviewer (0d consumes test-run Device + Commands)
```

---

## Domain & Contracts

### 1. Prep gate script contract

**Paths:**

- `skills/multi-agent-system/scripts/android-device-prep.ps1`
- `skills/multi-agent-system/scripts/android-device-prep.sh`

**Inputs (flags):**

| Flag | Purpose |
|------|---------|
| `--policy physical\|emulator\|auto` | Selection when multiple devices |
| `--serial <id>` | Explicit override |
| `--package <id>` | Application id for grants |
| `--grants <perm1,perm2>` | Pre-grant list |
| `--boot-timeout <sec>` | Default 120 |
| `--reverse <tcp:h:d>` | Repeatable |
| `--no-animation-off` | Opt out of animator disable |

**Outputs:** JSON on stdout; exit 0 = PASS, non-zero = FAIL code.

**Idempotency:** Safe to re-run; grants and animation settings are no-ops if already applied.

### 2. Reference doc contract

**Path:** `skills/multi-agent-system/references/device-prep-automation.md`

Contents: enrollment checklist, state machine, exit codes, selection policy, grant template, blocker messages, relationship to MAS-06 tier-3, cloud skip path.

### 3. test-strategy schema delta

New section **Device Prerequisites** (see §F). Planner adds handoff fields: `DEVICE_POLICY`, `DEVICE_SERIAL` when known.

### 4. test-run schema delta

New required section **Device** when any Recommended Command required prep (or prep was attempted). Fields in §G.

### 5. test-executor skill delta

- Startup: read `device-prep-automation.md` when strategy Device Prerequisites present.
- Workflow Step 0: prep invocation rules in §G.
- Output template: optional **Device** row in chat summary for full `/mas`.

### 6. Handoff fields (Coordinator)

| Field | When |
|-------|------|
| `DEVICE_SERIAL` | User has one phone among many |
| `DEVICE_POLICY` | Override default physical preference |
| `RUN_TESTS: yes` | Unchanged — executor still needs strategy or explicit commands |

---

## Edge Cases

| Case | Layer | Handling | Priority |
|------|-------|----------|----------|
| Empty device list | prep gate | FAIL `NO_DEVICE` | P0 |
| unauthorized RSA | prep gate | FAIL `UNAUTHORIZED` | P0 |
| emulator + phone connected | selection | Default physical for UI/fidelity | P0 |
| two phones connected | selection | FAIL `AMBIGUOUS_DEVICE` | P0 |
| boot in progress | prep gate | Wait then `BOOT_TIMEOUT` | P0 |
| Permission not grantable | prep gate | Warn `GRANT_SKIPPED`; strategy owns fallback | P1 |
| Android 13+ POST_NOTIFICATIONS | grants | Must be in strategy list | P1 |
| Windows PNG capture | adb | `exec-out screencap -p` only (not pull) | P0 |
| Parallel adb calls | executor | Serialize prep then commands | P0 |
| Gradle without device | executor | Skip if prep FAIL; never run connected blind | P0 |
| Paparazzi-only strategy | strategy | Prep skip with rationale | P1 |
| Cursor Cloud no USB | environment | SKIP `BLOCKED: no adb` | P1 |
| USB disconnect mid-test | executor | Document FAIL; no unbounded retry | P1 |
| `adb reverse` cleared on disconnect | prep | Re-apply each run | P2 |
| Wireless adb drop | prep | FAIL `OFFLINE`; suggest `adb connect` | P2 |

---

## Quality Bar

- **Idempotency:** Prep gate safe on every test-executor spawn; no cumulative device harm.
- **Fail-fast:** Prep FAIL before Gradle — no misleading AGP "no devices" stack traces.
- **Evidence:** test-run **Device** section gives reviewer auditable serial + prep status.
- **Honesty:** Enrollment documented outside agent loop; `UNAUTHORIZED` message is actionable.
- **Mutual exclusion:** test-strategy plans prerequisites; test-executor runs prep + commands; no strategy shell execution.
- **Cross-platform:** `.ps1` primary for win32 user host; `.sh` for bash CI.
- **Serialization:** Single adb queue per executor session.
- **Timeout discipline:** Bounded boot wait; connectedAndroidTest long timeout; no unbounded flaky retry.
- **Security:** No adb bypass of lock screen; no storing RSA keys in repo.
- **Tests (framework dogfood):** P0 validates script exit codes with mocked `adb devices` output fixtures — no physical device required in mas-cursor-framework CI.

---

## Risks & Open Questions

| ID | Question | Brainstorm recommendation |
|----|----------|---------------------------|
| D1 | Windows-first `.ps1` vs bash-only? | **Both** — user host is win32; bash for Linux CI. Shared JSON schema. |
| D2 | Prep in executor only vs shared with visual-fidelity? | **Shared script**; visual-fidelity tier-3 and test-executor both invoke; fidelity skill text references same reference doc. |
| D3 | Default physical-over-emulator always on? | **Default `physical`** when `TEST_SURFACE` includes `ui` or VISUAL_FIDELITY; else `auto`. Handoff `DEVICE_POLICY` overrides. |
| D4 | Maestro in v1 scope? | **Defer P1** — document optional command template; prep gate still runs if maestro in Recommended Commands. |
| D5 | Cursor Cloud USB limitation? | **Hard SKIP** with `BLOCKED: no adb on agent host` in Gaps; user runs workflow locally or uses managed device strategy. |
| D6 | Wireless-only devices? | **v1.1** — optional `--connect host:port` in prep gate when strategy lists wireless endpoint. |

**Risks:**

| Risk | Severity | Mitigation |
|------|----------|------------|
| Script drift from skill text | M | Single reference doc + script as SOT |
| Wrong device selected | H | FAIL on ambiguous hardware; explicit serial on handoff |
| Animator disable left on device | L | Document restore optional; dev machine side effect acceptable |
| Grant gives excessive permissions | M | Strategy lists minimum set only |
| Long connected tests timeout agent | M | Document timeout guidance in executor skill |

---

## Priority Order (implementation)

1. **Prep gate script + reference doc** — unblocks all adb/Gradle paths; structured exit codes.
2. **test-executor Step 0 + test-run Device section** — executor integration + reviewer evidence.
3. **test-strategy Device Prerequisites schema** — declarative grants, policy, skip rationale.
4. **ANDROID_SERIAL selection policy** — multi-device failure prevention.
5. **Permission pre-grant in prep** — unattended UI stability.
6. **Enrollment prerequisite doc** (README or reference §) — sets user expectation for first run.
7. **Maestro / wireless / FTL** — optional P1 extensions.

---

## Suggested Next

**planner** — Break into skill/reference/script file touches, brief-schema updates, dogfood TASK_ID with fixture adb output, and handoff field additions (`DEVICE_POLICY`, `DEVICE_SERIAL`). Architect follows for script module layout and test-run schema registration.

---

## Files Referenced

- `skills/mas-test-executor/SKILL.md`
- `skills/mas-test-strategy/SKILL.md`
- `skills/multi-agent-system/references/build-test-visual-qa.md`
- `skills/multi-agent-system/references/visual-fidelity-standards.md`
- `skills/multi-agent-system/references/test-strategy-standards.md`
- `skills/multi-agent-system/scripts/*.ps1` (pattern reference)
- `.ai/context/osint/MAS-07.md`
