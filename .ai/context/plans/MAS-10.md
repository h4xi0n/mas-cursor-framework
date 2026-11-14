# Plan Brief — MAS-10

## Plan

Goal:
Add **machine-wide host mutex** so only **one Gradle build** and **one device install** run at a time across all Cursor chats/agents on the host. Waiting workflows **block** (poll + backoff) until the holder releases or a **stale lock** is recovered. Ship **`mas-host-lock` / `mas-host-exec` CLI** (`.ps1` + `.sh`), reference doc, skill + protocol updates, optional MAS-08 **hook telemetry** (fail-open), fixture acceptance tests, and **Cloud Agent SKIP** documentation. **Logic-only** — no Android app or Gradle daemon tuning in consumer projects.

**Upstream context:** `.ai/handoffs/MAS-10.md`; See `memory.md` — Architecture Decisions (MAS-07 prep gate, MAS-08 project hooks / fail-open).

**Complements:** MAS-07 `android-device-prep` (serial SOT, does not install APK); MAS-08 bootstrap (`hooks/` → `.cursor/hooks/`); specialist Gradle/adb surfaces in `build-test-visual-qa.md`, `mas-reviewer`, `mas-test-executor`, `mas-android-dev`, `mas-test-strategy`.

**Version target:** `1.8.0` — additive scripts + protocol; architect confirms semver and hook phase (P0 skill-only vs P1 `preToolUse` warn).

**Proposed approach (planner default — architect confirms):**

| Piece | Decision |
|-------|----------|
| Mutex lanes | **Two independent lanes:** `build` (any `gradlew` / `gradlew.bat`) and `install` (`gradlew` tasks matching `install`, `adb install*`, optional `bundletool install*` P2) |
| Lock scope | **Host-wide** (not per-repo) — same machine, multiple workspaces |
| Lock root | `%LOCALAPPDATA%\MAS\locks\` (Windows); `${XDG_STATE_HOME:-$HOME/.local/state}/mas/locks/` (POSIX); override **`MAS_LOCK_ROOT`** |
| Enforcement | **Primary:** specialists invoke **`mas-host-exec`** for gated commands; **secondary (P1):** optional hook warns on unwrapped Shell patterns — **fail-open** per MAS-08 D6 |
| Skip | **`MAS_HOST_LOCK=skip`** (fixtures, framework CI, explicit opt-out); **Cloud Agent** → document `SKIPPED` in `platform-parity.md` |
| Stale recovery | Dead **holder PID** OR **lease expired** without refresh; `mas-host-lock break-stale` for operator recovery |

**Open questions (architect Phase 0):**

| ID | Question | Planner lean |
|----|----------|--------------|
| Q1 | `connected*AndroidTest` — build lane only, or also install lane? | **Build lane only** (APK push is Gradle-owned; install lane for explicit `install*` / `adb install`) |
| Q2 | Nested lock order for `installDebug` | **Acquire `build` then `install`**; release reverse; `mas-host-exec` auto-detects lanes from argv |
| Q3 | `preToolUse` block vs warn in v1.8 | **Warn-only P1**; blocking deferred to v1.9 opt-in `hooks.json` flag |
| Q4 | Lease default / max wait | **Lease 7200s**, refresh every 300s on long runs; **default wait 0** (infinite poll) with **`--wait-sec`** cap for hooks |
| Q5 | User-visible wait UX | JSON stdout + optional **`MAS_LOCK_VERBOSE=1`** human lines; agents read JSON `message` |

**NEXT_AGENT:** architect

Tasks:

### Phase 0 — Architect gate (pre-implementation)

1. **Architect confirms host-lock topology and contracts** — Validate dual-lane semantics, lock file schema, CLI subcommands, stale rules, skill/hook integration, skip matrix, and Q1–Q5.
   - **Files:** `.ai/context/architecture/MAS-10.md` (new)
   - **Decisions required:**
     - Lock file names: `build.lock`, `install.lock` under `MAS_LOCK_ROOT`
     - Lock JSON schema: `holder_pid`, `holder_ppid`, `task_id`, `workspace_root`, `command_hint`, `acquired_at`, `lease_expires_at`, `last_refresh_at`, `agent_slug` (optional)
     - Acquire algorithm: create lock dir if missing; open with exclusive create; on conflict → read holder → stale check → sleep backoff (e.g. 2s → 5s cap 30s) until released or `--wait-sec` exceeded
     - Stale predicates: PID not alive (platform-specific probe); OR `now > lease_expires_at` AND `now - last_refresh_at > grace` (e.g. 600s)
     - `mas-host-exec` lane detection regex table (gradlew path variants, `adb install`, `adb install-multiple`, `gradlew` task token `install`)
     - Exit code map aligned with MAS-07 style (0 success, 7 invalid args, 20 `LOCK_TIMEOUT`, 21 `LOCK_BUSY`/`LOCK_HELD`, 22 `LOCK_STALE_BREAK_FAILED`)
     - Interaction with MAS-07: prep runs **outside** install lane unless prep script later adds install (currently none)
     - Semver `1.8.0`; `install/manifest.json` scripts array + README
     - Hook P1: `preToolUse` matcher `Shell` — detect gated patterns; stdout `{ "warning": "..." }` only
   - **Acceptance:** Architecture brief documents acquire → exec → release, stale recovery, and multi-chat wait behavior without re-litigating dual-lane vs single-queue.

### Phase P0 — Host lock CLI + reference (v1.8.0 core)

2. **Create `host-build-install-mutex.md`** — SOT for lanes, lock root, stale policy, skip env vars, agent obligations, operator runbook (`break-stale`), Cloud SKIP.
   - **Files:** `skills/multi-agent-system/references/host-build-install-mutex.md` (new)
   - **Acceptance:** Cross-linked from `build-test-visual-qa.md`, `device-prep-automation.md`, `platform-parity.md`; documents timeout/stale-lock behavior per handoff.

3. **Create `mas-host-lock.ps1`** — Acquire, release, status, break-stale, refresh (heartbeat); JSON last line on stdout; `-Help`.
   - **Files:** `skills/multi-agent-system/scripts/mas-host-lock.ps1` (new)
   - **Env:** `MAS_LOCK_ROOT`, `MAS_HOST_LOCK=skip` (no-op PASS), `MAS_LOCK_VERBOSE`
   - **Acceptance:** Idempotent release by matching `task_id` + PID; fixture mode uses temp `MAS_LOCK_ROOT`.

4. **Create `mas-host-lock.sh`** — POSIX twin; same exit codes and JSON schema.
   - **Files:** `skills/multi-agent-system/scripts/mas-host-lock.sh` (new)

5. **Create `mas-host-exec.ps1` / `mas-host-exec.sh`** — Parse argv → lanes → `mas-host-lock acquire` (ordered) → run child via `&` / `exec` → trap/release on exit; propagate child exit code.
   - **Files:** `skills/multi-agent-system/scripts/mas-host-exec.ps1`, `mas-host-exec.sh` (new)
   - **Flags:** `--task-id`, `--workspace`, `--lease-sec`, `--wait-sec`, `--lanes` override, `--dry-run` (print plan only)
   - **Acceptance:** `./gradlew :app:installDebug` acquires both lanes; `./gradlew :app:compileDebugKotlin` acquires `build` only; `adb install -r foo.apk` acquires `install` only.

6. **Extend `scripts/README.md`** — Section for host lock quick start, env table, exit codes, fixture path.
   - **Files:** `skills/multi-agent-system/scripts/README.md`

7. **Update `build-test-visual-qa.md`** — All documented Gradle/adb install examples wrap with `mas-host-exec`; note mutex wait in Reviewer evidence table.
   - **Files:** `skills/multi-agent-system/references/build-test-visual-qa.md`

8. **Update specialist skills (Gradle / install surfaces)** — Mandatory `mas-host-exec` for gated commands; cite reference doc.
   - **Files:** `skills/mas-reviewer/SKILL.md`, `skills/mas-test-executor/SKILL.md`, `skills/mas-android-dev/SKILL.md`, `skills/mas-test-strategy/SKILL.md`
   - **Acceptance:** Build/test/install command blocks show wrapper invocation with `TASK_ID` from handoff.

9. **Update `platform-parity.md`** — Row: host mutex **N/A / SKIPPED** on Cloud Agent (no shared host FS with local IDE chats).
   - **Files:** `skills/multi-agent-system/protocol/platform-parity.md`

10. **Fixture acceptance harness** — No live Gradle/adb; scripts under `.ai/fixtures/MAS-10-HOST-LOCK/` + small test driver (PowerShell; optional shell).
    - **Files:** `.ai/fixtures/MAS-10-HOST-LOCK/*` (new), optional `skills/multi-agent-system/scripts/Test-MasHostLock.ps1`
    - **Scenarios:** (a) second acquire blocks until first releases; (b) dead PID → stale auto-break on acquire; (c) lease expired → break-stale; (d) lane classifier samples; (e) `MAS_HOST_LOCK=skip` passthrough
    - **Acceptance:** Documented commands in plan **Build & Test Plan**; reviewer runs fixture driver in dogfood.

### Phase P1 — Hooks + bootstrap (optional v1.8.0 or v1.8.1)

11. **Hook script `mas-host-lock-warn.ps1` / `.sh`** — `preToolUse` input: if Shell command matches gated pattern and does not invoke `mas-host-exec`, emit warning JSON (fail-open).
    - **Files:** `hooks/mas-host-lock-warn.ps1`, `hooks/mas-host-lock-warn.sh` (new); bootstrap copies to `.cursor/hooks/`
    - **Template:** extend install `hooks.mas.template.json` / MAS-08 project hooks template (when present) with commented P1 entry
    - **Acceptance:** Non-MAS commands unaffected; no `deny` in default template.

12. **Extend `init-mas-project` / export templates** — Copy warn hook; document opt-in merge for existing projects.
    - **Files:** `skills/multi-agent-system/install/export-mas-framework.ps1` (or `init-mas-project.ps1` when landed from MAS-08)

### Phase P2 — Documenter + review

13. **Documenter** — Script header comments, reference doc polish, install README slice, changelog/memory entry pointer for Coordinator.
14. **test-strategy** — Acceptance matrix artifact `.ai/context/test-strategies/MAS-10.md` (fixture commands, expected exit codes, skip paths).
15. **test-executor** — Run fixture harness; brief `.ai/context/test-runs/MAS-10.md` with Commands + Pass/fail.
16. **Reviewer** — Verify skill compliance, schema cross-refs, fixture PASS, no secrets in lock files.

## Dependencies

| Dependency | Notes |
|------------|-------|
| MAS-07 | Prep gate unchanged; install mutex is orthogonal — document ordering: lock → prep → gradle/adb |
| MAS-08 | Project hooks layout; fail-open invariant; bootstrap copy pattern from `hooks/` |
| Cursor hook `preToolUse` | P1 warn-only; schema per Cursor docs — architect validates payload fields |
| Consumer Android repos | Specialists use wrapper when running Gradle/adb; no Gradle plugin required |
| Parallel local chats | Requires shared `MAS_LOCK_ROOT` default (user state dir) |

## Acceptance criteria

1. **Single build:** With lock A held for `build`, a second `mas-host-lock acquire --lane build` blocks until A releases (fixture test proves wait/release).
2. **Single install:** Same for `install` lane with `adb install` or `gradlew install*` command via `mas-host-exec`.
3. **Dual lane:** `installDebug` acquires both lanes; concurrent `compileDebugKotlin` + `adb install` can proceed only if lanes differ and policy allows (install waits on build when Gradle install task needs daemon).
4. **Stale lock:** Dead PID or expired lease documented and recoverable via auto-break on acquire or `break-stale` without manual file delete in normal cases.
5. **Timeout:** `--wait-sec` returns exit `LOCK_TIMEOUT` with JSON message when wait cap exceeded.
6. **Skip:** `MAS_HOST_LOCK=skip` and Cloud parity doc state agents must not deadlock waiting on a lock that does not exist on host.
7. **Skills:** Reviewer, test-executor, android-dev, test-strategy reference `host-build-install-mutex.md` and show wrapped command examples.
8. **No regression:** Framework fixture tests run without physical device or consumer `./gradlew`.

## Risks

| Risk | Mitigation |
|------|------------|
| Agents bypass wrapper and run raw `gradlew` | P1 hook warning; reviewer checks evidence; future opt-in deny |
| Stale lock after IDE crash | PID + lease + `break-stale` runbook |
| Infinite wait burns agent turn | Document `--wait-sec` for hooks; agents poll `status --json` in long waits |
| WSL vs Windows dual Gradle on same machine | Document: separate lock roots per OS session unless shared `MAS_LOCK_ROOT` mounted |
| Install lane too narrow/broad | Architect Q1; regex table in reference doc with examples |
| Hook JSON contract drift | Fail-open empty `{}` on parse errors |

## Build & Test Plan

| Surface | Command / action | Owner |
|---------|------------------|--------|
| Fixture harness (primary) | `powershell -File skills/multi-agent-system/scripts/Test-MasHostLock.ps1` (or fixture README commands) | test-executor |
| Lock CLI help | `mas-host-lock.ps1 -Help`; `mas-host-exec.ps1 -Help` | reviewer |
| Skip mode | `$env:MAS_HOST_LOCK='skip'; mas-host-exec ... -- echo ok` | fixture |
| Framework repo | **No** consumer `./gradlew` required for MAS-10 approval | reviewer |
| Optional manual dogfood | Two local chats: chat A holds lock via long `mas-host-exec -- sleep`; chat B waits — human checklist in test-strategy | user |

High-level test surfaces for **test-strategy** brief: lane classifier table, acquire/release state machine, stale PID simulation, wait timeout, skip env.

## Visual QA Scenarios

N/A — `UI_SCOPE: logic-only`; no Compose or IDE UI.

## Required Agents

| Agent | Phase | Responsibility |
|-------|-------|----------------|
| **architect** | 0 | Contracts, exit codes, hook phase, Q1–Q5 |
| **general-dev** | P0–P1 | Scripts, fixtures, reference, skill/protocol edits |
| **test-strategy** | P0 | Acceptance matrix + device/JVM-only rationale |
| **test-executor** | P2 | Run fixture harness; test-run brief |
| **documenter** | P2 | Headers, install README, cross-refs |
| **reviewer** | P2 | Fixture PASS, skill compliance, `Approved:` gate |

**Not required:** android-dev (no app code), ux-intelligence, security-auditor (unless Coordinator flags supply-chain review of new scripts), mas-figma, visual-fidelity.
