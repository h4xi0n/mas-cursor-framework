# Test Run — MAS-10

TASK_ID: MAS-10
EXECUTOR: test-executor
STRATEGY: .ai/context/test-strategies/MAS-10.md
DATE: 2026-10-25
HOST: win32 (PowerShell 5.1)
FIXTURE: MAS-10-HOST-LOCK

## Device

| Field | Value |
|-------|-------|
| Prep gate | SKIPPED |
| Serial | — |
| Policy | auto |
| Exit code | — |
| Grants applied | — |
| Message | P0 acceptance is fixture-only (`Test-MasHostLock.ps1`); no adb or connected instrumentation per test-strategy Device Prerequisites (`Prep gate: skip`). |

## Commands

| # | Command | Source | Result |
|---|---------|--------|--------|
| 1 | `powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-MasHostLock.ps1` | test-strategy Recommended (P0 #1) | PASS |

**Harness assertions (exit 0):**

| Assertion | Maps to strategy |
|-----------|------------------|
| build lane held blocks exclusive create | #3 |
| acquire after holder released | #2 |
| stale dead PID auto-break acquire | #4 |
| break-stale expired lease | #5 |
| dry-run exec | schema |
| installDebug classifies build+install | #6 |
| compile classifies build only | #7 |
| adb install classifies install only | #8 |
| MAS_HOST_LOCK=skip | #9 |

**Driver stdout tail:** `All MAS-10 host lock fixture tests passed.`  
**Process exit code:** 0  
**Wall time:** ~8s

## Pass/fail

Overall: PASS  
P0 commands: PASS

## Failures

| # | Command | Error summary | Flaky | Route |
|---|---------|---------------|-------|-------|
| — | — | — | — | — |

## Gaps

| Item | Reason | Covered by |
|------|--------|------------|
| Consumer `:app:testDebugUnitTest` | No Android modules in framework repo | Fixture harness (strategy skip #1) |
| Live `gradlew assembleDebug` | Out of framework approval scope | Dry-run classifier rows (skip #2) |
| Live `adb install` serialization | No adb in fixture | Classifier dry-run (skip #3) |
| `connectedDebugAndroidTest` | Not required for mutex proof | Dry-run policy (skip #4) |
| P1 `mas-host-lock-warn` hook | P1 fail-open; v1.8 | Reference doc (skip #5) |
| Cloud Agent shared FS lock | No shared FS | platform-parity (skip #6) |
| WSL vs Windows `MAS_LOCK_ROOT` | Environment-specific | Manual runbook (skip #7) |
| Heartbeat refresh 300s soak | Timing-dependent | Architecture contract (skip #8) |
| Paparazzi / Compose / Maestro | `UI_SCOPE: logic-only` | N/A (skip #9) |
| `LOCK_TIMEOUT` (exit 20) while peer holds lock | P1 — not in current driver | strategy #10; README scenario (a) vs harness alignment |
| `mas-host-exec` child exit propagation | P1 — not in driver | strategy #11; manual follow-up |
| POSIX `mas-host-lock.sh` / `mas-host-exec.sh` parity | P2 — not run on this host | strategy #15 |
| Reviewer schema spot-check (`status --json`) | Optional per strategy | Not executed in P0 gate |

## Regression note

MAS-07 `android-device-prep` ordering unchanged; this run did not invoke prep or Gradle/adb wrappers on a consumer repo.
