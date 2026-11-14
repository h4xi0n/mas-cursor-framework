# Host Build / Install Mutex (MAS-10 v1.8.0)

Machine-wide mutex so only **one Gradle build** and **one device install** run at a time across all Cursor chats on the host.

## Lanes

| Lane | Gates |
|------|--------|
| **build** | Any `gradlew` / `gradlew.bat` invocation |
| **install** | `gradlew … install*`, `adb install`, `adb install-multiple` |

**Dual acquire:** Gradle `installDebug` / `installRelease` tasks acquire **build then install**; release **install then build**.

**Not gated:** `adb devices`, `adb shell`, `adb logcat`, `android-device-prep`, screencap, Maestro-only flows without gradlew install.

**Q1:** `connected*AndroidTest` → **build lane only** (Gradle owns APK push).

## Lock root

| Platform | Default |
|----------|---------|
| Windows | `%LOCALAPPDATA%\MAS\locks\` |
| POSIX | `${XDG_STATE_HOME:-$HOME/.local/state}/mas/locks/` |

Override: **`MAS_LOCK_ROOT`**. Files: `build.lock`, `install.lock` (UTF-8 JSON).

## Lock JSON schema

| Field | Description |
|-------|-------------|
| `lane` | `build` \| `install` |
| `holder_pid` | Holding process |
| `task_id` | Handoff `TASK_ID` |
| `workspace_root` | Repo root |
| `command_hint` | Truncated argv (≤500 chars) |
| `acquired_at`, `lease_expires_at`, `last_refresh_at` | ISO-8601 UTC |
| `agent_slug` | Optional specialist |

**Stale (D5):** holder PID dead **or** (`now > lease_expires_at` **and** `now - last_refresh_at > 600s`).

**Defaults:** lease **7200s**; heartbeat refresh every **300s** in `mas-host-exec`; wait **infinite** unless `--wait-sec N`.

## Skip matrix

| Context | Behavior |
|---------|----------|
| `MAS_HOST_LOCK=skip` | Passthrough; JSON `skipped: true` |
| Framework fixtures | Temp `MAS_LOCK_ROOT` + real mutex tests |
| Cursor Cloud Agent | **SKIPPED** — see [platform-parity.md](../protocol/platform-parity.md) |
| Consumer Android repo | Specialists wrap gated commands by default |

## Agent obligations

1. Wrap gated Shell commands with **`mas-host-exec`** and handoff **`TASK_ID`**.
2. Order with MAS-07: **lock (when gated) → android-device-prep → Gradle/adb**.
3. Long waits: optional `--wait-sec`; poll `mas-host-lock status --json`.
4. Operator recovery: `mas-host-lock break-stale --lane build|install`.

## Lane classifier (argv → lanes)

| Pattern | Lane(s) |
|---------|---------|
| `(^|[\s/\\])(\./)?gradlew(\.bat)?(\s\|$)` | build |
| `gradlew(\.bat)?\s+[^\s]*install` | build + install |
| `gradlew(\.bat)?\s+[^\s]*connected[^\s]*AndroidTest` | build |
| `gradlew(\.bat)?\s+` (other tasks) | build |
| `\badb\s+install-multiple\b` | install |
| `\badb\s+install\b` | install |

Override: `mas-host-exec --lanes build,install`.

## CLI

### mas-host-lock

Subcommands: `acquire`, `release`, `status`, `refresh`, `break-stale`.

```powershell
powershell -File skills/multi-agent-system/scripts/mas-host-lock.ps1 acquire `
  --lane build --task-id MAS-XX --workspace $PWD --wait-sec 0
```

```bash
./skills/multi-agent-system/scripts/mas-host-lock.sh acquire \
  --lane build --task-id MAS-XX --workspace "$(pwd)"
```

### mas-host-exec

```powershell
powershell -File skills/multi-agent-system/scripts/mas-host-exec.ps1 `
  -TaskId MAS-XX -RepoRoot $PWD -WaitSec 0 `
  -ChildArgv @('./gradlew', ':app:installDebug')
```

PowerShell binds `-TaskId`, `-RepoRoot`, `-WaitSec`, `-LaneList`, `-DryRun`, and `-ChildArgv` (remaining argv). Bash uses `--flag` form with `--` before child argv.

```bash
./skills/multi-agent-system/scripts/mas-host-exec.sh \
  --task-id MAS-XX --workspace "$(pwd)" \
  -- ./gradlew :app:connectedDebugAndroidTest
```

## Exit codes

| Code | `exit_code` | Meaning |
|------|-------------|---------|
| 0 | PASS | Success / child exit (exec propagates child non-zero) |
| 7 | INVALID_ARGS | Bad flags |
| 20 | LOCK_TIMEOUT | `--wait-sec` exceeded |
| 21 | LOCK_HELD | Release/refresh refused |
| 22 | LOCK_STALE_BREAK_FAILED | break-stale on live lock |

Stdout: **valid JSON last line**; `MAS_LOCK_VERBOSE=1` for human poll lines.

## WSL / dual OS

Default lock roots differ per OS session unless **`MAS_LOCK_ROOT`** points at a shared mounted path.

## P1 hook (warn-only)

Optional `preToolUse` on Shell: if command matches gated pattern and omits `mas-host-exec`, emit `{ "warning": "..." }`. **Fail-open `{}`** on errors — never deny in v1.8. See `hooks/mas-host-lock-warn.ps1`.

## Related

- [build-test-visual-qa.md](build-test-visual-qa.md) — wrapped Gradle examples
- [device-prep-automation.md](device-prep-automation.md) — prep before device Gradle/adb
- Fixtures: `.ai/fixtures/MAS-10-HOST-LOCK/`
