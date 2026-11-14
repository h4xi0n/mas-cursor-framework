# MAS-10 Host Lock Fixtures

No Gradle or adb required. Uses isolated `MAS_LOCK_ROOT` under `%TEMP%`.

## Primary driver

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-MasHostLock.ps1
```

## Scenarios covered

| ID | Scenario |
|----|----------|
| a | Second `acquire --lane build` hits `LOCK_TIMEOUT` until first `release` |
| b | Dead `holder_pid` → auto-break on acquire |
| c | Expired lease → `break-stale` |
| d | `mas-host-exec --dry-run` lane classifier samples |
| e | `MAS_HOST_LOCK=skip` passthrough |

## Manual snippets

```powershell
$env:MAS_LOCK_ROOT = "$env:TEMP\mas-lock-manual"
New-Item -ItemType Directory -Force -Path $env:MAS_LOCK_ROOT | Out-Null
powershell -File skills/multi-agent-system/scripts/mas-host-lock.ps1 status --json
```

Reference: [host-build-install-mutex.md](../../../skills/multi-agent-system/references/host-build-install-mutex.md)
