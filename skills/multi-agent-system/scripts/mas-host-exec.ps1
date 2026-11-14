<#
.SYNOPSIS
  MAS host mutex wrapper — classify lanes, acquire, run child, release.

.DESCRIPTION
  Wraps Gradle build and adb install commands with mas-host-lock acquire/release.
  Propagates child exit code. JSON plan/result on stdout (last line).

.EXIT CODES
  Child exit code on success path; 7 INVALID_ARGS; 20 LOCK_TIMEOUT; 22 lock wrapper fault

.ENV
  MAS_HOST_LOCK=skip — run child without locks
  MAS_LOCK_ROOT, MAS_LOCK_VERBOSE
#>
[CmdletBinding()]
param(
    [switch]$Help,
    [Alias("task-id")][string]$TaskId,
    [Alias("workspace")][string]$RepoRoot = (Get-Location).Path,
    [Alias("lease-sec")][int]$LeaseSec = 7200,
    [Alias("wait-sec")][int]$WaitSec = 0,
    [Alias("lanes", "lane-list")][string]$LaneList,
    [Alias("dry-run")][switch]$DryRun,
    [Alias("agent-slug")][string]$AgentSlug,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ChildArgv = @()
)

$ErrorActionPreference = "Stop"

$LockScript = Join-Path $PSScriptRoot "mas-host-lock.ps1"
$DefaultLeaseSec = 7200
$RefreshIntervalSec = 300

function Show-Usage {
    @"
Usage: mas-host-exec.ps1 --task-id <ID> --workspace <path> [options] -- <child argv...>

Options:
  --task-id <ID>       Handoff TASK_ID (required unless MAS_HOST_LOCK=skip)
  --workspace <path>   Repo root (default: current directory)
  --lease-sec <n>      Lock lease (default: 7200)
  --wait-sec <n>       Max wait per lane (default: 0 = infinite)
  --lanes build|install|build,install   Override auto classifier
  --dry-run            Print plan JSON only
  --agent-slug <name>  Optional specialist id
  --help               Show help

Examples:
  mas-host-exec.ps1 --task-id MAS-XX --workspace `$PWD -- ./gradlew :app:installDebug
  mas-host-exec.ps1 --task-id MAS-XX -- -- adb install -r app.apk

See host-build-install-mutex.md
"@
}

function Write-VerboseLine {
    param([string]$Message)
    if ($env:MAS_LOCK_VERBOSE -eq "1") { Write-Host $Message }
}

function Test-SkipHostLock {
    return ($env:MAS_HOST_LOCK -eq "skip" -or $env:MAS_HOST_LOCK -eq "SKIP")
}

function Emit-ExecResult {
    param(
        [string]$Status,
        [string]$ExitCode,
        [string]$Message,
        [hashtable]$Extra = @{},
        [int]$ProcessExit = 0
    )
    $result = [ordered]@{
        status    = $Status
        exit_code = $ExitCode
        message   = $Message
    }
    foreach ($k in $Extra.Keys) { $result[$k] = $Extra[$k] }
    Write-Output ($result | ConvertTo-Json -Compress -Depth 8)
    exit $ProcessExit
}

function Get-MasHostLanesFromArgv {
    param([string[]]$ChildTokens)
    $joined = ($ChildTokens -join " ") -replace '\\', '/'
    $wantBuild = $false
    $wantInstall = $false

    if ($joined -match '(^|[\s/])(\./)?gradlew(\.bat)?(\s|$)') {
        $wantBuild = $true
    }
    if ($joined -match 'gradlew(\.bat)?\s+[^\s]*install') {
        $wantInstall = $true
        $wantBuild = $true
    } elseif ($joined -match 'gradlew(\.bat)?\s+[^\s]*connected[^\s]*AndroidTest') {
        $wantBuild = $true
    } elseif ($joined -match 'gradlew(\.bat)?\s+') {
        $wantBuild = $true
    }
    if ($joined -match '\badb\s+install-multiple\b') {
        $wantInstall = $true
    }
    if ($joined -match '\badb\s+install\b') {
        $wantInstall = $true
    }

    $ordered = @()
    if ($wantBuild) { $ordered += "build" }
    if ($wantInstall) { $ordered += "install" }
    return $ordered
}

function Invoke-LockCli {
    param([string[]]$LockArgs)
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LockScript @LockArgs 2>&1
    $line = ($output | Select-Object -Last 1)
    if ($null -eq $line) { throw "mas-host-lock produced no output" }
    $parsed = $line | ConvertFrom-Json
    $exit = $LASTEXITCODE
    return @{ json = $parsed; exit = $exit; raw = $line }
}

function Start-RefreshJob {
    param(
        [string[]]$Lanes,
        [string]$TaskId,
        [int]$LeaseSec,
        [string]$LockRoot
    )
    $scriptBlock = {
        param($LockScriptPath, $LaneList, $Tid, $Lease, $Root)
        $env:MAS_LOCK_ROOT = $Root
        while ($true) {
            Start-Sleep -Seconds 300
            foreach ($ln in $LaneList) {
                & powershell -NoProfile -ExecutionPolicy Bypass -File $LockScriptPath refresh `
                    -lane $ln -task-id $Tid -lease-sec $Lease | Out-Null
            }
        }
    }
    return Start-Job -ScriptBlock $scriptBlock -ArgumentList @($LockScript, $Lanes, $TaskId, $LeaseSec, $LockRoot)
}

if ($Help) { Show-Usage; exit 0 }

if (Test-SkipHostLock) {
    $skipChild = @($ChildArgv)
    if ($skipChild.Count -eq 0) {
        Emit-ExecResult -Status "PASS" -ExitCode "PASS" -Message "MAS_HOST_LOCK=skip (no child)" -Extra @{ skipped = $true } -ProcessExit 0
    }
    & $skipChild[0] @($skipChild[1..($skipChild.Count - 1)])
    $skipExit = $LASTEXITCODE
    Emit-ExecResult -Status "PASS" -ExitCode "PASS" -Message "Skipped host lock" -Extra @{
        skipped    = $true
        child_exit = $skipExit
    } -ProcessExit $skipExit
}

$cfg = @{
    task_id    = $TaskId
    workspace  = $RepoRoot
    lease_sec  = $LeaseSec
    wait_sec   = $WaitSec
    dry_run    = [bool]$DryRun
    agent_slug = $AgentSlug
}

$child = @($ChildArgv)
if ($child.Count -eq 0) {
    Emit-ExecResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "Missing child argv after --" -ProcessExit 7
}

$hint = ($child -join " ")
if ($hint.Length -gt 500) { $hint = $hint.Substring(0, 500) }

if ([string]::IsNullOrWhiteSpace($cfg.task_id)) {
    Emit-ExecResult -Status "FAIL" -ExitCode "INVALID_ARGS" -Message "--task-id required" -ProcessExit 7
}

if ($LaneList) {
    $selectedLanes = @($LaneList -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
} else {
    $selectedLanes = @(Get-MasHostLanesFromArgv -ChildTokens @($child))
}
if ($selectedLanes.Count -eq 0) {
    Write-VerboseLine "No gated lanes detected - running child directly"
    & $child[0] @($child[1..($child.Count - 1)])
    $childExit = $LASTEXITCODE
    Emit-ExecResult -Status "PASS" -ExitCode "PASS" -Message "Ungated command" -Extra @{
        lanes      = @()
        child_exit = $childExit
    } -ProcessExit $childExit
}

if ($cfg.dry_run) {
    Emit-ExecResult -Status "PASS" -ExitCode "PASS" -Message "Dry run plan" -Extra @{
        active_lanes = @($selectedLanes)
        task_id      = $cfg.task_id
        workspace    = $cfg.workspace
        child        = @($child)
        dry_run      = $true
    } -ProcessExit 0
}

$lockRoot = if ($env:MAS_LOCK_ROOT) { $env:MAS_LOCK_ROOT } else { $null }
$held = @()
$refreshJob = $null
$childExit = 0
$wrapperError = $null

try {
    foreach ($lane in $selectedLanes) {
        $acqArgs = @(
            "acquire",
            "-lane", $lane,
            "-task-id", $cfg.task_id,
            "-workspace", $cfg.workspace,
            "-lease-sec", $cfg.lease_sec,
            "-wait-sec", $cfg.wait_sec,
            "-command-hint", $hint
        )
        if ($cfg.agent_slug) { $acqArgs += @("-agent-slug", $cfg.agent_slug) }
        $res = Invoke-LockCli -LockArgs $acqArgs
        if ($res.exit -ne 0) {
            throw "Acquire failed for lane $lane (exit $($res.exit)): $($res.raw)"
        }
        $held += $lane
    }

    if ($held.Count -gt 0) {
        $rootForJob = if ($lockRoot) { $lockRoot } else { $env:LOCALAPPDATA + "\MAS\locks" }
        if ($env:MAS_LOCK_ROOT) { $rootForJob = $env:MAS_LOCK_ROOT }
        $refreshJob = Start-RefreshJob -Lanes $held -TaskId $cfg.task_id -LeaseSec $cfg.lease_sec -LockRoot $rootForJob
    }

    & $child[0] @($child[1..($child.Count - 1)])
    $childExit = $LASTEXITCODE
} catch {
    $wrapperError = $_.Exception.Message
} finally {
    if ($refreshJob) {
        Stop-Job -Job $refreshJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job -Job $refreshJob -Force -ErrorAction SilentlyContinue | Out-Null
    }
    for ($i = $held.Count - 1; $i -ge 0; $i--) {
        $lane = $held[$i]
        $relArgs = @("release", "-lane", $lane, "-task-id", $cfg.task_id)
        $null = Invoke-LockCli -LockArgs $relArgs
    }
}

if ($wrapperError) {
    Emit-ExecResult -Status "FAIL" -ExitCode "LOCK_STALE_BREAK_FAILED" -Message $wrapperError -Extra @{ lanes = $held } -ProcessExit 22
}

Emit-ExecResult -Status "PASS" -ExitCode "PASS" -Message "Child completed" -Extra @{
    active_lanes = @($selectedLanes)
    child_exit   = $childExit
} -ProcessExit $childExit
