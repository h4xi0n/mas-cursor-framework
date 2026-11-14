<#
.SYNOPSIS
  MAS host-wide build/install mutex — acquire, release, status, refresh, break-stale.

.DESCRIPTION
  Dual-lane FS locks (build | install) under MAS_LOCK_ROOT. JSON last line on stdout.
  See host-build-install-mutex.md and architecture MAS-10.

.EXIT CODES
  0  PASS (or skip passthrough)
  7  INVALID_ARGS
  20 LOCK_TIMEOUT
  21 LOCK_HELD
  22 LOCK_STALE_BREAK_FAILED

.ENV
  MAS_LOCK_ROOT      — override lock directory
  MAS_HOST_LOCK=skip — all subcommands no-op success (skipped: true)
  MAS_LOCK_VERBOSE=1 — human poll hints before final JSON line
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("acquire", "release", "status", "refresh", "break-stale", "")]
    [string]$Subcommand = "",
    [switch]$Help,
    [Alias("lane")][string]$LaneName,
    [Alias("task-id")][string]$TaskId,
    [Alias("workspace")][string]$RepoRoot,
    [Alias("lease-sec")][int]$LeaseSeconds = 7200,
    [Alias("wait-sec")][int]$WaitSeconds = 0,
    [Alias("command-hint")][string]$CommandHint,
    [Alias("agent-slug")][string]$AgentSlug
)

$ErrorActionPreference = "Stop"

$ExitCodeMap = @{
    PASS                   = 0
    INVALID_ARGS           = 7
    LOCK_TIMEOUT           = 20
    LOCK_HELD              = 21
    LOCK_STALE_BREAK_FAILED = 22
}

$StaleGraceSec = 600
$PollInitialSec = 2
$PollMaxSec = 30

function Show-Usage {
    @"
Usage: mas-host-lock.ps1 <subcommand> [options]

Subcommands:
  acquire     Exclusive lane lock (poll + stale auto-break)
  release     Release when task_id + holder PID match
  status      Describe lock holders (--json default)
  refresh     Extend lease (heartbeat)
  break-stale Remove lock only when stale predicates hold

Options (acquire / release / refresh / break-stale):
  --lane build|install
  --task-id <TASK_ID>
  --workspace <abs-path>
  --lease-sec <sec>       Default 7200
  --wait-sec <sec>      Default 0 (infinite wait)
  --command-hint <text> Truncated argv summary (acquire)
  --agent-slug <name>   Optional specialist id

Exit codes: 0=PASS, 7=INVALID_ARGS, 20=LOCK_TIMEOUT, 21=LOCK_HELD, 22=LOCK_STALE_BREAK_FAILED
Env: MAS_LOCK_ROOT, MAS_HOST_LOCK=skip, MAS_LOCK_VERBOSE=1
See host-build-install-mutex.md
"@
}

function Write-VerboseLine {
    param([string]$Message)
    if ($env:MAS_LOCK_VERBOSE -eq "1") {
        Write-Host $Message
    }
}

function Get-LockRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:MAS_LOCK_ROOT)) {
        return $env:MAS_LOCK_ROOT
    }
    $local = $env:LOCALAPPDATA
    if ([string]::IsNullOrWhiteSpace($local)) {
        $local = Join-Path $env:USERPROFILE "AppData\Local"
    }
    return Join-Path $local "MAS\locks"
}

function Test-SkipHostLock {
    return ($env:MAS_HOST_LOCK -eq "skip")
}

function Get-IsoUtcNow {
    return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

function Parse-IsoUtc {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    return [datetime]::Parse($Value, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
}

function Test-PidAlive {
    param([int]$ProcessId)
    if ($ProcessId -le 0) { return $false }
    try {
        $null = Get-Process -Id $ProcessId -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-LockPath {
    param([string]$Lane, [string]$Root)
    return Join-Path $Root "$Lane.lock"
}

function Read-LockRecord {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Test-LockStale {
    param($Record)
    if ($null -eq $Record) { return $true }
    $pidVal = [int]$Record.holder_pid
    if (-not (Test-PidAlive -ProcessId $pidVal)) {
        return $true
    }
    $lease = Parse-IsoUtc -Value ([string]$Record.lease_expires_at)
    $lastRefresh = Parse-IsoUtc -Value ([string]$Record.last_refresh_at)
    if ($null -eq $lease -or $null -eq $lastRefresh) {
        return $false
    }
    $now = (Get-Date).ToUniversalTime()
    if ($now -gt $lease) {
        $sinceRefresh = ($now - $lastRefresh).TotalSeconds
        if ($sinceRefresh -gt $StaleGraceSec) {
            return $true
        }
    }
    return $false
}

function Write-LockAtomic {
    param([string]$Path, [hashtable]$Record)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = ($Record | ConvertTo-Json -Compress -Depth 4)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            $sw = New-Object System.IO.StreamWriter($fs, $utf8)
            $sw.Write($json)
            $sw.Flush()
            $sw.Close()
        } finally {
            $fs.Close()
        }
        return $true
    } catch [System.IO.IOException] {
        return $false
    }
}

function Update-LockAtomic {
    param([string]$Path, [hashtable]$Record)
    $json = ($Record | ConvertTo-Json -Compress -Depth 4)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $tmp = "$Path.tmp.$PID"
    [System.IO.File]::WriteAllText($tmp, $json, $utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Remove-LockFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    }
}

function Emit-LockResult {
    param(
        [string]$Status,
        [string]$ExitCode,
        [string]$Message,
        [hashtable]$Extra = @{}
    )
    $result = [ordered]@{
        status    = $Status
        exit_code = $ExitCode
        message   = $Message
    }
    foreach ($k in $Extra.Keys) {
        $result[$k] = $Extra[$k]
    }
    if (Test-SkipHostLock) {
        $result["skipped"] = $true
    }
    $json = $result | ConvertTo-Json -Compress -Depth 6
    Write-Output $json
    $code = $ExitCodeMap[$ExitCode]
    if ($null -eq $code) { $code = 0 }
    exit $code
}

function Invoke-BreakStaleInternal {
    param([string]$Lane, [string]$Root)
    $path = Get-LockPath -Lane $Lane -Root $Root
    $rec = Read-LockRecord -Path $path
    if ($null -eq $rec) {
        return @{ ok = $true; message = "No lock file" }
    }
    if (-not (Test-LockStale -Record $rec)) {
        return @{ ok = $false; message = "Lock not stale"; holder = $rec }
    }
    Remove-LockFile -Path $path
    return @{ ok = $true; message = "Stale lock removed"; holder = $rec }
}

function Invoke-AcquireLane {
    param(
        [string]$Lane,
        [string]$TaskId,
        [string]$Workspace,
        [int]$LeaseSec,
        [int]$WaitSec,
        [string]$CommandHint,
        [string]$AgentSlug,
        [string]$Root
    )
    $path = Get-LockPath -Lane $Lane -Root $Root
    $backoff = $PollInitialSec
    $waitStart = Get-Date

    while ($true) {
        $br = Invoke-BreakStaleInternal -Lane $Lane -Root $Root
        if (-not $br.ok -and (Test-Path -LiteralPath $path)) {
            $holder = Read-LockRecord -Path $path
            if ($WaitSec -gt 0) {
                $elapsed = ((Get-Date) - $waitStart).TotalSeconds
                if ($elapsed -ge $WaitSec) {
                    Emit-LockResult -Status "FAIL" -ExitCode "LOCK_TIMEOUT" -Message "Wait exceeded for lane $Lane" -Extra @{
                        lane   = $Lane
                        holder = $holder
                    }
                }
            }
            Write-VerboseLine "Lane $Lane held by task_id=$($holder.task_id) pid=$($holder.holder_pid); retry in ${backoff}s"
            Start-Sleep -Seconds $backoff
            $backoff = [Math]::Min($backoff * 2, $PollMaxSec)
            continue
        }

        $now = Get-IsoUtcNow
        $leaseEnd = (Get-Date).ToUniversalTime().AddSeconds($LeaseSec).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $hint = $CommandHint
        if ($null -ne $hint -and $hint.Length -gt 500) {
            $hint = $hint.Substring(0, 500)
        }
        $record = @{
            lane              = $Lane
            holder_pid        = $PID
            holder_ppid       = $PID
            task_id           = $TaskId
            workspace_root    = $Workspace
            command_hint      = $hint
            acquired_at       = $now
            lease_expires_at  = $leaseEnd
            last_refresh_at   = $now
            agent_slug        = $AgentSlug
        }
        if (Write-LockAtomic -Path $path -Record $record) {
            Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Acquired lane $Lane" -Extra @{
                lane   = $Lane
                path   = $path
                holder = $record
            }
        }

        if ($WaitSec -eq 0) {
            Start-Sleep -Seconds $backoff
            $backoff = [Math]::Min($backoff * 2, $PollMaxSec)
            continue
        }
        $elapsed = ((Get-Date) - $waitStart).TotalSeconds
        if ($elapsed -ge $WaitSec) {
            $holder = Read-LockRecord -Path $path
            Emit-LockResult -Status "FAIL" -ExitCode "LOCK_TIMEOUT" -Message "Wait exceeded for lane $Lane" -Extra @{
                lane   = $Lane
                holder = $holder
            }
        }
        Start-Sleep -Seconds $backoff
        $backoff = [Math]::Min($backoff * 2, $PollMaxSec)
    }
}

function Invoke-ReleaseLane {
    param([string]$Lane, [string]$TaskId, [string]$Root)
    $path = Get-LockPath -Lane $Lane -Root $Root
    $rec = Read-LockRecord -Path $path
    if ($null -eq $rec) {
        Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Already released (no lock)" -Extra @{ lane = $Lane }
    }
    $holderPid = [int]$rec.holder_pid
    $recTask = [string]$rec.task_id
    if ($recTask -eq $TaskId -and $holderPid -eq $PID) {
        Remove-LockFile -Path $path
        Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Released lane $Lane" -Extra @{ lane = $Lane }
    }
    if ($recTask -eq $TaskId -and (Test-LockStale -Record $rec)) {
        Remove-LockFile -Path $path
        Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Released stale lane $Lane" -Extra @{ lane = $Lane }
    }
    Emit-LockResult -Status "FAIL" -ExitCode "LOCK_HELD" -Message "Release refused: task_id/PID mismatch" -Extra @{
        lane   = $Lane
        holder = $rec
    }
}

function Invoke-RefreshLane {
    param([string]$Lane, [string]$TaskId, [int]$LeaseSec, [string]$Root)
    $path = Get-LockPath -Lane $Lane -Root $Root
    $rec = Read-LockRecord -Path $path
    if ($null -eq $rec) {
        Emit-LockResult -Status "FAIL" -ExitCode "LOCK_HELD" -Message "No lock to refresh" -Extra @{ lane = $Lane }
    }
    if ([string]$rec.task_id -ne $TaskId -or [int]$rec.holder_pid -ne $PID) {
        Emit-LockResult -Status "FAIL" -ExitCode "LOCK_HELD" -Message "Refresh refused: not holder" -Extra @{ lane = $Lane; holder = $rec }
    }
    $now = Get-IsoUtcNow
    $leaseEnd = (Get-Date).ToUniversalTime().AddSeconds($LeaseSec).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $record = @{
        lane              = [string]$rec.lane
        holder_pid        = [int]$rec.holder_pid
        holder_ppid       = if ($rec.holder_ppid) { [int]$rec.holder_ppid } else { $PID }
        task_id           = [string]$rec.task_id
        workspace_root    = [string]$rec.workspace_root
        command_hint      = $rec.command_hint
        acquired_at       = [string]$rec.acquired_at
        lease_expires_at  = $leaseEnd
        last_refresh_at   = $now
        agent_slug        = $rec.agent_slug
    }
    Update-LockAtomic -Path $path -Record $record
    Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Refreshed lane $Lane" -Extra @{ lane = $Lane; holder = $record }
}

function Invoke-Status {
    param([string]$LaneFilter, [string]$Root)
    $lanes = @("build", "install")
    if (-not [string]::IsNullOrWhiteSpace($LaneFilter)) {
        $lanes = @($LaneFilter)
    }
    $holders = @()
    foreach ($lane in $lanes) {
        $path = Get-LockPath -Lane $lane -Root $Root
        $rec = Read-LockRecord -Path $path
        if ($null -ne $rec) {
            $holders += @{
                lane   = $lane
                stale  = (Test-LockStale -Record $rec)
                holder = $rec
                path   = $path
            }
        }
    }
    Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "Status ok" -Extra @{
        lock_root = $Root
        lanes     = $holders
    }
}

function Invoke-BreakStaleCmd {
    param([string]$Lane, [string]$Root)
    $br = Invoke-BreakStaleInternal -Lane $Lane -Root $Root
    if (-not $br.ok) {
        Emit-LockResult -Status "FAIL" -ExitCode "LOCK_STALE_BREAK_FAILED" -Message $br.message -Extra @{
            lane   = $Lane
            holder = $br.holder
        }
    }
    Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message $br.message -Extra @{
        lane   = $Lane
        holder = $br.holder
    }
}

if ($Help -or [string]::IsNullOrWhiteSpace($Subcommand)) {
    Show-Usage
    exit 0
}

if (Test-SkipHostLock) {
    Emit-LockResult -Status "PASS" -ExitCode "PASS" -Message "MAS_HOST_LOCK=skip" -Extra @{ subcommand = $Subcommand; skipped = $true }
}

$lockRoot = Get-LockRoot

switch ($Subcommand) {
    "acquire" {
        if ([string]::IsNullOrWhiteSpace($LaneName) -or [string]::IsNullOrWhiteSpace($TaskId) -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
            Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "acquire requires --lane, --task-id, --workspace"
        }
        if ($LaneName -notin @("build", "install")) {
            Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "Invalid lane"
        }
        Invoke-AcquireLane -Lane $LaneName -TaskId $TaskId -Workspace $RepoRoot `
            -LeaseSec $LeaseSeconds -WaitSec $WaitSeconds -CommandHint $CommandHint `
            -AgentSlug $AgentSlug -Root $lockRoot
    }
    "release" {
        if ([string]::IsNullOrWhiteSpace($LaneName) -or [string]::IsNullOrWhiteSpace($TaskId)) {
            Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "release requires --lane, --task-id"
        }
        Invoke-ReleaseLane -Lane $LaneName -TaskId $TaskId -Root $lockRoot
    }
    "refresh" {
        if ([string]::IsNullOrWhiteSpace($LaneName) -or [string]::IsNullOrWhiteSpace($TaskId)) {
            Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "refresh requires --lane, --task-id"
        }
        Invoke-RefreshLane -Lane $LaneName -TaskId $TaskId -LeaseSec $LeaseSeconds -Root $lockRoot
    }
    "status" {
        Invoke-Status -LaneFilter $LaneName -Root $lockRoot
    }
    "break-stale" {
        if ([string]::IsNullOrWhiteSpace($LaneName)) {
            Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "break-stale requires --lane"
        }
        Invoke-BreakStaleCmd -Lane $LaneName -Root $lockRoot
    }
    default {
        Emit-LockResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "Unknown subcommand"
    }
}
