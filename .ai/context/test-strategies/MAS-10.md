# Test Strategy — MAS-10

## Feature

MAS-10 (v1.8.0) — **Dual-lane host mutex** for parallel Cursor chats on one machine: `mas-host-lock` (acquire / release / status / refresh / break-stale) and `mas-host-exec` (lane classify → ordered acquire → child exec → trap release). Framework repo delivers cross-platform scripts, reference SOT, specialist skill obligations, and a **fixture acceptance harness** — **no consumer Android Gradle project** and **no live adb** required for workflow approval (`UI_SCOPE: logic-only`).

**Upstream coupling:** MAS-07 `android-device-prep` is orthogonal (serial export only; no install lane). Ordering for device workflows: **host lock (when gated) → prep → gradlew/adb**. MAS-08 P1 `preToolUse` warn hook is P1 — fail-open; not a P0 acceptance gate.

## Scope

| Layer | Paths |
|-------|-------|
| Lock CLI (P0) | `skills/multi-agent-system/scripts/mas-host-lock.ps1`, `mas-host-lock.sh` |
| Exec wrapper (P0) | `skills/multi-agent-system/scripts/mas-host-exec.ps1`, `mas-host-exec.sh` |
| Reference SOT (P0) | `skills/multi-agent-system/references/host-build-install-mutex.md` |
| Fixture driver (P0) | `skills/multi-agent-system/scripts/Test-MasHostLock.ps1` |
| Fixture docs (P0) | `.ai/fixtures/MAS-10-HOST-LOCK/README.md` |
| Context | `.ai/context/architecture/MAS-10.md` |
| Dogfood outputs | `.ai/context/test-strategies/MAS-10.md` (this brief), `.ai/context/test-runs/MAS-10.md` (test-executor) |

**Out of scope for P0 approval:** Consumer-repo `gradlew` runs, live two-chat blocking soak, Firebase/CI matrix on physical devices, P1 hook `mas-host-lock-warn.*` enforcement tests, `bundletool install` lane (P2 doc), blocking hook deny (v1.9).

## Test Surfaces

`fixture` (isolated `MAS_LOCK_ROOT`, mocked lock files, dry-run classifier) · `integration` (subprocess `mas-host-lock` / `mas-host-exec` with temp lock root) · `schema` (JSON last-line stdout, exit codes 0/7/20–22) · `manual` (optional live gradlew/adb on developer machine — HITL only)

No JVM/Android test pyramid in MAS framework repo.

---

## Device Prerequisites

| Field | Value |
|-------|-------|
| Enrollment | — |
| Target | none |
| Prep gate | skip |
| DEVICE_SERIAL | — |
| DEVICE_POLICY | auto |
| Package | — |
| Permissions to pre-grant | — |
| adb reverse | — |
| Skip rationale | P0 acceptance is fixture-only (`Test-MasHostLock.ps1`); no `adb`, `connectedDebugAndroidTest`, or Maestro in recommended commands. Optional HITL rows document live device policy separately. |

---

## Tests to Write

| # | Type | Target | Scenario | Rationale | Priority | Flaky risk | Mitigation | Command hint |
|---|------|--------|----------|-----------|----------|------------|------------|--------------|
| 1 | fixture | `Test-MasHostLock.ps1` | Full driver exits 0; all `PASS:` assertions green | Single P0 gate for MAS-10 approval; maps to plan criterion 8 (no consumer gradlew) | P0 | LOW | Fresh temp `MAS_LOCK_ROOT` per run; `finally` cleanup | `powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-MasHostLock.ps1` |
| 2 | integration | `mas-host-lock` acquire/release | After manual `build.lock` removed, `acquire -lane build` returns exit 0 + JSON; `release` clears lane | Proves happy-path FS mutex on build lane | P0 | LOW | Isolated `MAS_LOCK_ROOT` | Same driver (FIX-B row) or manual with `$env:MAS_LOCK_ROOT` |
| 3 | integration | FS exclusive create | While valid `build.lock` present, `CreateNew` on same path throws → treated as held | Guards concurrent writers without live second chat | P0 | LOW | Deterministic pre-seeded lock file | Driver row `build lane held blocks exclusive create` |
| 4 | integration | Stale dead PID | `install.lock` with `holder_pid=99999999` → `acquire -lane install` succeeds (auto-break) | Acceptance criterion 4 (D5a) | P0 | LOW | Use non-existent PID constant in fixture | Driver row `stale dead PID auto-break acquire` |
| 5 | integration | Stale lease | Expired `lease_expires_at` + old `last_refresh_at` → `break-stale -lane build` exit 0 | Acceptance criterion 4 (D5b) + operator path | P0 | LOW | Seed times 5h in past | Driver row `break-stale expired lease` |
| 6 | integration | `mas-host-exec --dry-run` | `./gradlew :app:installDebug` → lanes `build`,`install` | Dual-lane classifier (Q2, criterion 3) | P0 | LOW | Dry-run only; no child exec | Driver `installDebug classifies build+install` |
| 7 | integration | `mas-host-exec --dry-run` | `./gradlew :app:compileDebugKotlin` → lane `build` only | Build-only Gradle tasks (Q1) | P0 | LOW | Dry-run | Driver `compile classifies build only` |
| 8 | integration | `mas-host-exec --dry-run` | `adb install -r app.apk` → lane `install` only | Install lane without gradlew | P0 | LOW | Dry-run | Driver `adb install classifies install only` |
| 9 | integration | Skip matrix | `MAS_HOST_LOCK=skip` → child runs; JSON `skipped: true` + message mentions skip | Acceptance criterion 6 (D4) | P0 | LOW | Reset env after test | Driver `MAS_HOST_LOCK=skip` |
| 10 | integration | `mas-host-lock` timeout | Second acquire with `--wait-sec 1` while peer holds lock → process exit **20**, JSON `LOCK_TIMEOUT` | Acceptance criterion 5; **not in current driver** — add harness row or document manual proof | P1 | MED | Use background job to hold lock; cap wait | Extend `Test-MasHostLock.ps1` or manual two-shell script |
| 11 | integration | `mas-host-exec` child exit propagation | Child `exit 1` → process exit 1; locks still released | Wrapper must not swallow child failures | P1 | LOW | `powershell -Command exit 1` child | Manual or extend driver |
| 12 | integration | `release` idempotency | `release` when not holder or already released → exit 0 | Operator safety (D6) | P2 | LOW | — | Manual snippet in fixture README |
| 13 | schema | JSON stdout | Last line parseable JSON on lock/exec invocations; dry-run includes `active_lanes` or `lanes` | Agent contract (Q5) | P1 | LOW | Driver already parses last `{` line | Grep fixture driver helpers |
| 14 | manual | Live two-chat wait | Chat A holds `mas-host-exec` on long sleep child; Chat B blocks until A exits | Criterion 1–2 real-world proof | P3 | HIGH | Short lease + verbose; optional | HITL only — not required for test-executor PASS |
| 15 | manual | POSIX parity | Run equivalent scenarios on `mas-host-lock.sh` / `mas-host-exec.sh` on Linux/macOS | Cross-platform ship claim | P2 | MED | CI or developer Unix host | `./skills/multi-agent-system/scripts/mas-host-lock.sh status --json` |

---

## Tests to Skip

| # | Target | Reason | Covered by |
| 1 | Consumer Android `:app:testDebugUnitTest` | No Android modules in MAS framework repo; handoff explicitly excludes consumer Gradle | Fixture harness only (criterion 8) |
| 2 | Live `gradlew assembleDebug` in CI | Requires AGP, JDK, and long builds; out of framework approval scope | Dry-run classifier rows + specialist docs |
| 3 | Live `adb install` serialization | No adb in fixture; install lane logic covered by classifier dry-run | P1 manual optional |
| 4 | `connectedDebugAndroidTest` on device | MAS-07 device prep + Gradle; not required for MAS-10 mutex proof | Classifier: `connected*AndroidTest` → build-only (Q1) via dry-run |
| 5 | P1 `mas-host-lock-warn` hook | P1 phase; fail-open; no deny in v1.8 | Document in `host-build-install-mutex.md`; defer hook integration test |
| 6 | Cloud Agent host lock | No shared FS (D4); parity SKIPPED | `platform-parity.md` row — schema review only |
| 7 | WSL vs Windows shared `MAS_LOCK_ROOT` | Environment-specific (D10); operator doc | Reference runbook — manual when needed |
| 8 | Heartbeat refresh every 300s during long child | Timing-dependent; long-running soak | Architecture contract + code review; optional long HITL |
| 9 | Paparazzi / Compose screenshot / Maestro | `UI_SCOPE: logic-only`; no UI | N/A |
| 10 | Duplicate full mutex matrix in JUnit | Scripts are PowerShell/shell — harness is the test suite | `Test-MasHostLock.ps1` |

---

## Edge Cases

| Case | Layer | Test approach | Priority |
|------|-------|---------------|----------|
| Empty lock root | Lock service | First acquire creates `build.lock` / `install.lock` | P0 (via acquire after clean temp dir) |
| Held lock (live PID) | Lock service | Exclusive create blocked; acquire waits or times out | P0 (exclusive create assertion; P1 timeout row) |
| Stale dead PID | Lock service | Auto-break on acquire | P0 |
| Stale lease + grace | Lock service | `break-stale` when predicates true; refuse when fresh | P0 break; P2 refuse path |
| Invalid args | CLI | Exit 7 `INVALID_ARGS` | P2 — manual or extend driver |
| `break-stale` on fresh lock | Lock service | Exit 22 `LOCK_STALE_BREAK_FAILED` | P2 |
| Skip env | Policy | Passthrough, `skipped: true` | P0 |
| Dual lane order | Exec wrapper | Acquire build→install; release install→build | P1 — extend dry-run or short live exec with `--lanes build,install` |
| Classifier: `connected*AndroidTest` | Exec wrapper | Build lane only | P1 — add dry-run argv sample to driver |
| Classifier: non-gated `adb devices` | Policy | No lanes; direct child (or empty lanes in dry-run) | P2 |
| Wrong `task_id` on release | Lock service | No-op success if no match (idempotent) | P2 |
| `MAS_LOCK_VERBOSE=1` | Observability | Human lines before JSON | P3 manual |
| Wrapper fault before child | Exec wrapper | Release held lanes; wrapper error exit | P2 — inject failing acquire mock |

---

## Regression Risks

N/A — `.ai/context/daily-changelog.md` has no module-specific entries for 2026-10-25. Related prior work (MAS-07 prep ordering, MAS-08 fail-open hooks) is **contractual** only; regression focus is **do not break** `android-device-prep` or existing test-executor Step 0 when adding wrapper examples to skills.

---

## Flaky Test Risks

| Risk | Surface | Mitigation |
|------|---------|------------|
| Race between two real PowerShell acquire polls | Live two-chat manual | Default to fixture driver; cap `--wait-sec` in tests |
| Temp dir cleanup on Windows | Fixture driver | `finally` block; unique GUID subfolder |
| Subprocess env not inheriting `MAS_LOCK_ROOT` | `Invoke-LockJson` | Driver already wraps child with explicit env |
| Clock skew on lease/stale tests | Stale lease row | Use UTC timestamps far in past (driver uses -5h) |
| Parsing JSON when verbose lines precede JSON | Schema | Always take **last** line matching `^\s*\{` (driver pattern) |

---

## Recommended Commands

**test-executor (P0 — must run and record in `.ai/context/test-runs/MAS-10.md`):**

- `powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-MasHostLock.ps1`

**Reviewer / optional schema spot-check:**

- `powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $env:MAS_LOCK_ROOT = Join-Path $env:TEMP ('mas-lock-review-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $env:MAS_LOCK_ROOT -Force | Out-Null; & 'skills/multi-agent-system/scripts/mas-host-lock.ps1' status --json }"`

**Do not require for MAS-10 PASS:**

- `./gradlew` (any task)
- `adb install` / `connectedDebugAndroidTest`
- `npm test` / `pytest`

**Post-dev extension (P1 — general-dev may add harness row before test-executor re-run):**

- Same primary command after adding timeout / child-exit cases to `Test-MasHostLock.ps1`

---

## Synthetic Fixture TASK_ID

| Fixture ID | Purpose | Expected outcome |
|------------|---------|------------------|
| `MAS-10-HOST-LOCK` | Primary dogfood — script driver | Exit 0; message `All MAS-10 host lock fixture tests passed.` |

**Harness ↔ architecture acceptance map:**

| Criterion | Harness coverage |
|-----------|------------------|
| 1 Single build | Partial — exclusive create + acquire after release; not full blocking acquire wait |
| 2 Single install | Classifier only (adb install dry-run) |
| 3 Dual lane | `installDebug` dry-run |
| 4 Stale | Dead PID + `break-stale` lease |
| 5 Timeout | **Gap** — recommend P1 harness row |
| 6 Skip | `MAS_HOST_LOCK=skip` |
| 7 Skills | Out of test-strategy scope — reviewer checks SKILL.md + reference |
| 8 No consumer gradlew | Driver is sole P0 gate |

**Note:** `.ai/fixtures/MAS-10-HOST-LOCK/README.md` scenario (a) describes `LOCK_TIMEOUT` on second acquire; current driver implements exclusive-create blocking and post-release acquire. test-executor should record **actual** assertions from script output; coordinator may track README/harness alignment as follow-up.

---

## Overall Confidence

**HIGH** for P0 fixture path — scope files read, harness scenarios enumerated, clear skip matrix for Gradle/adb. **MEDIUM** on timeout and live dual-chat until harness row 10 lands or manual evidence attached in test-run.

---

## Files Reviewed

- `.ai/handoffs/MAS-10-test-strategy.md`
- `.ai/context/architecture/MAS-10.md`
- `skills/multi-agent-system/scripts/Test-MasHostLock.ps1`
- `.ai/fixtures/MAS-10-HOST-LOCK/README.md`
- `.ai/context/memory.md`
- `.ai/context/daily-changelog.md`

## Open Questions

- Should P1 `LOCK_TIMEOUT` harness row be **mandatory** before reviewer `Approved:` or acceptable as documented gap with P1 follow-up task?
- Is POSIX shell parity validated in CI, or Windows-only `Test-MasHostLock.ps1` sufficient for v1.8.0 ship?
