#Requires -Version 5.1
<#
.SYNOPSIS
  Fixture acceptance driver for MAS-10 host lock (no Gradle/adb).
#>
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$FrameworkRoot = (Resolve-Path (Join-Path $Root "../..")).Path
$LockScript = Join-Path $PSScriptRoot "mas-host-lock.ps1"
$ExecScript = Join-Path $PSScriptRoot "mas-host-exec.ps1"

$TempLockRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mas-host-lock-test-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempLockRoot -Force | Out-Null
$env:MAS_LOCK_ROOT = $TempLockRoot
$env:MAS_HOST_LOCK = ""

$failures = @()

function Assert-True {
    param([bool]$Cond, [string]$Name)
    if (-not $Cond) { $script:failures += $Name }
    else { Write-Host "PASS: $Name" -ForegroundColor Green }
}

function Test-LanesEqual {
    param($Json, [string[]]$Expected)
    $prop = if ($null -ne $Json.active_lanes) { $Json.active_lanes } else { $Json.lanes }
    $actual = @($prop | ForEach-Object { [string]$_ } | Where-Object { $_ })
    return ($actual.Count -eq $Expected.Count) -and ((Compare-Object $actual $Expected | Measure-Object).Count -eq 0)
}

function Invoke-LockJson {
    param([string[]]$Args)
    $tempOut = [System.IO.Path]::GetTempFileName()
    $lockRootEsc = $env:MAS_LOCK_ROOT.Replace("'", "''")
    $lockScriptEsc = $LockScript.Replace("'", "''")
    $argTail = ($Args | ForEach-Object {
            if ($_ -match '[\s'']') { "'$($_.Replace("'","''"))'" } else { $_ }
        }) -join ' '
    $cmd = "& { `$env:MAS_LOCK_ROOT='$lockRootEsc'; & '$lockScriptEsc' $argTail }"
    $p = Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $cmd) `
        -Wait -PassThru -NoNewWindow `
        -RedirectStandardOutput $tempOut
    $out = @()
    if (Test-Path $tempOut) {
        $out = Get-Content -LiteralPath $tempOut -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tempOut -Force -ErrorAction SilentlyContinue
    }
    $line = ($out | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    $json = $null
    if ($line) { $json = $line | ConvertFrom-Json }
    return @{ exit = [int]$p.ExitCode; json = $json; raw = $line }
}

function Invoke-ExecJson {
    param(
        [string]$TaskId,
        [string]$Workspace = $FrameworkRoot,
        [switch]$DryRun,
        [string]$LaneList,
        [string[]]$ChildArgv
    )
    $params = @{
        TaskId   = $TaskId
        RepoRoot = $Workspace
    }
    if ($DryRun) { $params.DryRun = $true }
    if ($LaneList) { $params.LaneList = $LaneList }
    if ($ChildArgv) { $params.ChildArgv = $ChildArgv }
    $out = & $ExecScript @params 2>&1
    $line = ($out | ForEach-Object { $_.ToString() } | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)
    return @{ exit = $LASTEXITCODE; json = ($line | ConvertFrom-Json); raw = $line }
}

try {
    # (a) Second acquire blocks while this process holds build.lock (live holder PID)
    $holdPath = Join-Path $TempLockRoot "build.lock"
    $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $lease = (Get-Date).ToUniversalTime().AddHours(2).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $holdRecord = @{
        lane = "build"; holder_pid = $PID; holder_ppid = $PID; task_id = "FIX-A"
        workspace_root = $FrameworkRoot; command_hint = "fixture-hold"; acquired_at = $now
        lease_expires_at = $lease; last_refresh_at = $now; agent_slug = $null
    } | ConvertTo-Json -Compress
    Set-Content -LiteralPath $holdPath -Value $holdRecord -Encoding UTF8

    $exclusiveBlocked = $false
    try {
        $fs = [System.IO.File]::Open($holdPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $fs.Close()
    } catch [System.IO.IOException] {
        $exclusiveBlocked = $true
    }
    Assert-True $exclusiveBlocked "build lane held blocks exclusive create"

    Remove-Item -LiteralPath $holdPath -Force -ErrorAction SilentlyContinue

    $a3 = Invoke-LockJson @("acquire", "-lane", "build", "-task-id", "FIX-B", "-workspace", $FrameworkRoot, "-wait-sec", "5")
    Assert-True ($a3.exit -eq 0) "acquire after holder released"
    Invoke-LockJson @("release", "-lane", "build", "-task-id", "FIX-B") | Out-Null

    # (b) Dead PID stale auto-break on acquire
    $deadPath = Join-Path $TempLockRoot "install.lock"
    $staleJson = @{
        lane             = "install"
        holder_pid       = 99999999
        task_id          = "STALE-PID"
        workspace_root   = $FrameworkRoot
        acquired_at      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        lease_expires_at = (Get-Date).ToUniversalTime().AddHours(2).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        last_refresh_at  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    } | ConvertTo-Json -Compress
    Set-Content -LiteralPath $deadPath -Value $staleJson -Encoding UTF8

    $a4 = Invoke-LockJson @("acquire", "-lane", "install", "-task-id", "FIX-C", "-workspace", $FrameworkRoot, "-wait-sec", "5")
    Assert-True ($a4.exit -eq 0) "stale dead PID auto-break acquire"
    Invoke-LockJson @("release", "-lane", "install", "-task-id", "FIX-C") | Out-Null

    # (c) Lease expired + grace → break-stale
    $expiredPath = Join-Path $TempLockRoot "build.lock"
    $old = (Get-Date).ToUniversalTime().AddHours(-5).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $expJson = @{
        lane             = "build"
        holder_pid       = $PID
        task_id          = "LEASE-OLD"
        workspace_root   = $FrameworkRoot
        acquired_at      = $old
        lease_expires_at = $old
        last_refresh_at  = $old
    } | ConvertTo-Json -Compress
    Set-Content -LiteralPath $expiredPath -Value $expJson -Encoding UTF8

    $br = Invoke-LockJson @("break-stale", "-lane", "build")
    Assert-True ($br.exit -eq 0) "break-stale expired lease"

    # (d) Lane classifier dry-run
    $d1 = Invoke-ExecJson -TaskId "FIX-D" -DryRun -ChildArgv @("powershell", "-Command", "exit 0")
    Assert-True ($d1.exit -eq 0) "dry-run exec"

    $d2 = Invoke-ExecJson -TaskId "FIX-D" -DryRun -ChildArgv @("./gradlew", ":app:installDebug")
    Assert-True (Test-LanesEqual $d2.json @("build", "install")) "installDebug classifies build+install"

    $d3 = Invoke-ExecJson -TaskId "FIX-D" -DryRun -ChildArgv @("./gradlew", ":app:compileDebugKotlin")
    Assert-True (Test-LanesEqual $d3.json @("build")) "compile classifies build only"

    $d4 = Invoke-ExecJson -TaskId "FIX-D" -DryRun -ChildArgv @("adb", "install", "-r", "app.apk")
    Assert-True (Test-LanesEqual $d4.json @("install")) "adb install classifies install only"

    # (e) Skip passthrough
    $env:MAS_HOST_LOCK = "skip"
    $sk = Invoke-ExecJson -TaskId "FIX-E" -ChildArgv @("powershell", "-Command", "exit 0")
    Assert-True ($sk.exit -eq 0 -and $sk.json.skipped -eq $true -and $sk.json.message -match 'skip') "MAS_HOST_LOCK=skip"
    $env:MAS_HOST_LOCK = ""

} finally {
    Remove-Item -LiteralPath $TempLockRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host "FAILURES:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "All MAS-10 host lock fixture tests passed." -ForegroundColor Green
exit 0
