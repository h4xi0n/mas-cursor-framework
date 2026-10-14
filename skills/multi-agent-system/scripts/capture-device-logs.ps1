<#
.SYNOPSIS
  MAS capture-device-logs gate - prep-gated logcat clear, marker, and dump.

.DESCRIPTION
  Downstream log capture consumer chained after android-device-prep (MAS-07).
  Emits a single JSON object on stdout (last line). Idempotent re-run safe.
  -DryRun prints planned adb ops without a device. Fixture env vars bypass real adb.

.EXIT CODES
  0  = PASS or CAPTURE_EMPTY (warn only)
  1  = ADB_NOT_FOUND
  7  = INVALID_ARGS
  10 = NO_SERIAL
  11 = UNAUTHORIZED
  12 = OFFLINE
  21 = DUMP_FAILED

.ENV
  ADB_DEVICES_FIXTURE   - mock adb devices -l for connectivity gate
  ADB_LOGCAT_FIXTURE    - mock main buffer dump content
  ADB_CRASH_LOGCAT_FIXTURE - mock crash buffer dump content
  ADB_API_LEVEL_FIXTURE - override ro.build.version.sdk
  ADB_PIDOF_FIXTURE     - override pidof output (empty = PID_NOT_FOUND)
  ANDROID_SERIAL        - required unless --serial set (from prep Step 0)
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet("clear", "marker", "dump", "clear-and-marker", "")]
    [string]$Subcommand = "",

    [string]$Serial,
    [string]$Package,
    [string]$Tag = "APP_TRACE",
    [string]$Buffers = "main,crash",
    [ValidateSet("json", "threadtime", "")]
    [string]$Format = "",
    [string]$OutputDir = "",
    [string]$TaskId,
    [int]$MaxLines = 0,
    [switch]$DryRun,
    [switch]$JsonOnly,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$ExitCodeMap = @{
    PASS          = 0
    CAPTURE_EMPTY = 0
    ADB_NOT_FOUND = 1
    INVALID_ARGS  = 7
    NO_SERIAL     = 10
    UNAUTHORIZED  = 11
    OFFLINE       = 12
    DUMP_FAILED   = 21
}

function Show-Usage {
    @"
Usage: capture-device-logs.ps1 <subcommand> [options]

Subcommands:
  clear              Clear logcat buffers (requires ANDROID_SERIAL)
  marker             Write repro-marker.json timestamp
  dump               Dump filtered logcat to artifact dir
  clear-and-marker   clear then marker atomically

Options:
  -Serial <id>           Device serial (default: `$env:ANDROID_SERIAL)
  -Package <id>          Application id for pidof PID filter
  -Tag <name>            Logcat tag filter (default: APP_TRACE)
  -Buffers <list>        Comma-separated buffers (default: main,crash)
  -Format json|threadtime Override format detection
  -OutputDir <path>      Artifact root (default: .ai/context/device-logs/{TASK_ID}/)
  -TaskId <id>           TASK_ID (required for marker/dump/clear-and-marker)
  -MaxLines <n>          Truncate tail per buffer (P1; 0 = unbounded)
  -DryRun                Print planned adb ops; no device required
  -JsonOnly              Suppress non-JSON stderr on success
  -Help                  Show this help

Exit codes: 0=PASS/CAPTURE_EMPTY, 1=ADB_NOT_FOUND, 7=INVALID_ARGS,
            10=NO_SERIAL, 11=UNAUTHORIZED, 12=OFFLINE, 21=DUMP_FAILED

Fixture env: ADB_DEVICES_FIXTURE, ADB_LOGCAT_FIXTURE, ADB_API_LEVEL_FIXTURE,
              ADB_PIDOF_FIXTURE, ADB_CRASH_LOGCAT_FIXTURE
See device-log-capture.md and .ai/fixtures/MAS-09-LOG-CAPTURE/
"@
}

function Write-Info {
    param([string]$Message)
    if (-not $JsonOnly) { Write-Host $Message }
}

# Last stdout line is always JSON; process exit mirrors exit_code field.
function Emit-CaptureResult {
    param(
        [string]$Status,
        [string]$ExitCode,
        [string]$Message,
        [AllowNull()][string]$CaptureMetaPath,
        [AllowNull()][int]$LineCount
    )

    $metaVal = if ([string]::IsNullOrWhiteSpace($CaptureMetaPath)) { $null } else { $CaptureMetaPath }
    $lineVal = if ($null -eq $LineCount) { $null } else { $LineCount }

    $result = [ordered]@{
        status            = $Status
        exit_code         = $ExitCode
        message           = $Message
        capture_meta_path = $metaVal
        line_count        = $lineVal
    }

    $json = $result | ConvertTo-Json -Compress -Depth 3
    Write-Output $json

    $procExit = $ExitCodeMap[$ExitCode]
    if ($null -eq $procExit) { $procExit = 1 }
    exit $procExit
}

function Get-AdbPath {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) { return $null }
    return $adb.Source
}

function Parse-DevicesOutput {
    param([string[]]$Lines)
    $devices = @()
    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed -match '^List of devices') { continue }
        if ($trimmed -match '^(\S+)\s+(\S+)(?:\s+(.+))?$') {
            $devices += @{ Serial = $matches[1]; State = $matches[2]; Details = $matches[3] }
        }
    }
    return $devices
}

function Get-DevicesList {
    param([string]$AdbPath, [bool]$UseFixture)

    if ($UseFixture) {
        $fixturePath = $env:ADB_DEVICES_FIXTURE
        if (-not (Test-Path $fixturePath)) {
            throw "ADB_DEVICES_FIXTURE not found: $fixturePath"
        }
        return Parse-DevicesOutput -Lines (Get-Content -Path $fixturePath)
    }

    if ($DryRun) {
        return @(@{ Serial = "dry-run-device"; State = "device"; Details = "" })
    }

    $output = & $AdbPath devices -l 2>&1
    return Parse-DevicesOutput -Lines @($output)
}

function Test-DeviceConnectivity {
    param(
        [string]$AdbPath,
        [string]$DeviceSerial,
        [bool]$UseFixture
    )

    if ($DryRun) { return @{ Ok = $true } }

    $devices = Get-DevicesList -AdbPath $AdbPath -UseFixture $UseFixture
    $row = $devices | Where-Object { $_.Serial -eq $DeviceSerial }

    if (-not $row) {
        $unauth = $devices | Where-Object { $_.Serial -eq $DeviceSerial -and $_.State -eq "unauthorized" }
        if ($unauth) {
            return @{ Ok = $false; ExitCode = "UNAUTHORIZED"; Message = "Device $DeviceSerial unauthorized - complete USB debugging enrollment." }
        }
        $offline = $devices | Where-Object { $_.Serial -eq $DeviceSerial -and $_.State -eq "offline" }
        if ($offline) {
            return @{ Ok = $false; ExitCode = "OFFLINE"; Message = "Device $DeviceSerial is offline." }
        }
        return @{ Ok = $false; ExitCode = "OFFLINE"; Message = "Device $DeviceSerial not found or not in device state." }
    }

    if ($row.State -eq "unauthorized") {
        return @{ Ok = $false; ExitCode = "UNAUTHORIZED"; Message = "Device $DeviceSerial unauthorized - complete USB debugging enrollment." }
    }
    if ($row.State -eq "offline") {
        return @{ Ok = $false; ExitCode = "OFFLINE"; Message = "Device $DeviceSerial is offline." }
    }
    if ($row.State -ne "device") {
        return @{ Ok = $false; ExitCode = "OFFLINE"; Message = "Device $DeviceSerial state: $($row.State)." }
    }

    return @{ Ok = $true }
}

function Invoke-CaptureAdb {
    param(
        [string]$AdbPath,
        [string]$DeviceSerial,
        [string[]]$AdbArguments,
        [bool]$UseFixture
    )

    $cmd = "adb"
    if ($DeviceSerial) { $cmd += " -s $DeviceSerial" }
    $cmd += " $($AdbArguments -join ' ')"

    if ($DryRun) {
        Write-Info "[dry-run] $cmd"
        return @{ Ok = $true; Output = "" }
    }

    if ($UseFixture) {
        $sub = $AdbArguments -join " "
        if ($sub -eq "logcat -c") {
            return @{ Ok = $true; Output = "" }
        }
        if ($sub -match '^shell getprop ro\.build\.version\.sdk$') {
            $val = if ($env:ADB_API_LEVEL_FIXTURE) { $env:ADB_API_LEVEL_FIXTURE } else { "34" }
            return @{ Ok = $true; Output = $val }
        }
        if ($sub -match '^shell pidof -s ') {
            if ($env:ADB_PIDOF_EMPTY -eq "1") {
                return @{ Ok = $true; Output = "" }
            }
            $pidofFixture = [Environment]::GetEnvironmentVariable('ADB_PIDOF_FIXTURE')
            if ($null -ne $pidofFixture) {
                return @{ Ok = $true; Output = $pidofFixture.Trim() }
            }
            return @{ Ok = $true; Output = "12345" }
        }
        if ($sub -match '^logcat -d -b crash') {
            $crashFixture = $env:ADB_CRASH_LOGCAT_FIXTURE
            if ($crashFixture -and (Test-Path $crashFixture)) {
                return @{ Ok = $true; Output = (Get-Content -Path $crashFixture -Raw) }
            }
            return @{ Ok = $true; Output = "" }
        }
        if ($sub -match '^logcat -d -b main') {
            $logFixture = $env:ADB_LOGCAT_FIXTURE
            if ($logFixture -and (Test-Path $logFixture)) {
                return @{ Ok = $true; Output = (Get-Content -Path $logFixture -Raw) }
            }
            return @{ Ok = $true; Output = "" }
        }
        if ($sub -eq "get-state") {
            return @{ Ok = $true; Output = "device" }
        }
        return @{ Ok = $true; Output = "" }
    }

    $allArgs = @()
    if ($DeviceSerial) { $allArgs += "-s", $DeviceSerial }
    $allArgs += $AdbArguments
    $output = & $AdbPath $allArgs 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    return @{ Ok = $ok; Output = ($output | Out-String).Trim() }
}

function Get-IsoTimestamp {
    return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

function Get-RelativePath {
    param([string]$FullPath, [string]$Root)
    $rootResolved = (Resolve-Path $Root).Path
    $fullResolved = (Resolve-Path $FullPath).Path
    $rel = $fullResolved.Substring($rootResolved.Length).TrimStart('\', '/')
    return $rel -replace '\\', '/'
}

function Write-ReproMarker {
    param(
        [string]$ArtifactDir,
        [string]$TaskIdValue,
        [string]$DeviceSerial,
        [string]$Root
    )

    $marker = [ordered]@{
        repro_started_at = Get-IsoTimestamp
        task_id          = $TaskIdValue
        serial           = $DeviceSerial
    }
    $markerPath = Join-Path $ArtifactDir "repro-marker.json"
    $marker | ConvertTo-Json -Depth 3 | Set-Content -Path $markerPath -Encoding UTF8
    return $markerPath
}

function Count-Lines {
    param([string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return 0 }
    $lines = $Content -split "`n"
    $count = 0
    foreach ($l in $lines) {
        if (-not [string]::IsNullOrWhiteSpace($l)) { $count++ }
    }
    return $count
}

function Truncate-Lines {
    param([string]$Content, [int]$Max)
    if ($Max -le 0 -or [string]::IsNullOrWhiteSpace($Content)) { return $Content }
    $lines = @($Content -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($lines.Count -le $Max) { return ($lines -join "`n") }
    return ($lines | Select-Object -Last $Max) -join "`n"
}

if ($Help) {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Subcommand)) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "INVALID_ARGS" `
        -Message "Subcommand required: clear, marker, dump, or clear-and-marker. Use -Help." `
        -CaptureMetaPath $null -LineCount $null
}

# Serial resolution (ANDROID_SERIAL from prep Step 0; ADB_SERIAL alias)
if (-not $Serial -and $env:ANDROID_SERIAL) { $Serial = $env:ANDROID_SERIAL }
if (-not $Serial -and $env:ADB_SERIAL) { $Serial = $env:ADB_SERIAL }

$useFixture = -not [string]::IsNullOrWhiteSpace($env:ADB_DEVICES_FIXTURE) `
    -or -not [string]::IsNullOrWhiteSpace($env:ADB_LOGCAT_FIXTURE) `
    -or -not [string]::IsNullOrWhiteSpace($env:ADB_API_LEVEL_FIXTURE)

$adbPath = Get-AdbPath
if (-not $adbPath -and -not $useFixture -and -not $DryRun) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "ADB_NOT_FOUND" `
        -Message "adb not found on PATH. Install Android Platform Tools." `
        -CaptureMetaPath $null -LineCount $null
}

if ([string]::IsNullOrWhiteSpace($Serial)) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "NO_SERIAL" `
        -Message "ANDROID_SERIAL unset - run android-device-prep (Step 0) first" `
        -CaptureMetaPath $null -LineCount $null
}

if ($Subcommand -in @("marker", "dump", "clear-and-marker") -and [string]::IsNullOrWhiteSpace($TaskId)) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "INVALID_ARGS" `
        -Message "--task-id is required for $Subcommand subcommand." `
        -CaptureMetaPath $null -LineCount $null
}

# Connectivity gate — prep-first invariant; no adb when NO_SERIAL/UNAUTHORIZED/OFFLINE
$conn = Test-DeviceConnectivity -AdbPath $adbPath -DeviceSerial $Serial -UseFixture ($useFixture -or $DryRun)
if (-not $conn.Ok) {
    Emit-CaptureResult -Status "FAIL" -ExitCode $conn.ExitCode -Message $conn.Message `
        -CaptureMetaPath $null -LineCount $null
}

$workspaceRoot = Get-Location
if ($OutputDir) {
    $artifactDir = $OutputDir
} elseif ($TaskId) {
    $artifactDir = Join-Path $workspaceRoot ".ai\context\device-logs\$TaskId"
} else {
    $artifactDir = Join-Path $workspaceRoot ".ai\context\device-logs"
}

if ($Subcommand -eq "clear") {
    $clearResult = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
        -AdbArguments @("logcat", "-c") -UseFixture ($useFixture -or $DryRun)
    if (-not $clearResult.Ok) {
        Emit-CaptureResult -Status "FAIL" -ExitCode "DUMP_FAILED" `
            -Message "adb logcat -c failed." -CaptureMetaPath $null -LineCount $null
    }
    Emit-CaptureResult -Status "PASS" -ExitCode "PASS" `
        -Message "Logcat buffers cleared for $Serial." `
        -CaptureMetaPath $null -LineCount $null
}

if ($Subcommand -eq "marker") {
    if (-not (Test-Path $artifactDir)) {
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    }
    Write-ReproMarker -ArtifactDir $artifactDir -TaskIdValue $TaskId -DeviceSerial $Serial -Root $workspaceRoot | Out-Null
    $relDir = ".ai/context/device-logs/$TaskId"
    Emit-CaptureResult -Status "PASS" -ExitCode "PASS" `
        -Message "Repro marker written to $relDir/repro-marker.json." `
        -CaptureMetaPath $null -LineCount $null
}

if ($Subcommand -eq "clear-and-marker") {
    $clearResult = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
        -AdbArguments @("logcat", "-c") -UseFixture ($useFixture -or $DryRun)
    if (-not $clearResult.Ok) {
        Emit-CaptureResult -Status "FAIL" -ExitCode "DUMP_FAILED" `
            -Message "adb logcat -c failed during clear-and-marker." `
            -CaptureMetaPath $null -LineCount $null
    }
    if (-not (Test-Path $artifactDir)) {
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    }
    Write-ReproMarker -ArtifactDir $artifactDir -TaskIdValue $TaskId -DeviceSerial $Serial -Root $workspaceRoot | Out-Null
    $relDir = ".ai/context/device-logs/$TaskId"
    Emit-CaptureResult -Status "PASS" -ExitCode "PASS" `
        -Message "Cleared logcat and wrote repro marker to $relDir/." `
        -CaptureMetaPath $null -LineCount $null
}

# dump subcommand (clear/marker/clear-and-marker exit above via Emit-CaptureResult)
$warnings = @()
$bufferList = @($Buffers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })

# Format fallback: API 30+ prefers json (-v json); older devices use threadtime (D4)
$apiResult = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
    -AdbArguments @("shell", "getprop", "ro.build.version.sdk") -UseFixture ($useFixture -or $DryRun)
$apiLevel = 34
if ($apiResult.Output -match '^\d+$') { $apiLevel = [int]$apiResult.Output }

$resolvedFormat = $Format
if ([string]::IsNullOrWhiteSpace($resolvedFormat)) {
    if ($apiLevel -ge 30) {
        $resolvedFormat = "json"
    } else {
        $resolvedFormat = "threadtime"
        $warnings += "FORMAT_FALLBACK: threadtime"
    }
} elseif ($resolvedFormat -eq "json" -and $apiLevel -lt 30) {
    $resolvedFormat = "threadtime"
    $warnings += "FORMAT_FALLBACK: threadtime"
}

# PID resolve at dump time only; empty pidof → tag-only filter + PID_NOT_FOUND warning (D13)
$appPid = $null
if ($Package) {
    $pidResult = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
        -AdbArguments @("shell", "pidof", "-s", $Package) -UseFixture ($useFixture -or $DryRun)
    if (-not [string]::IsNullOrWhiteSpace($pidResult.Output) -and $pidResult.Output -match '^\d+$') {
        $appPid = [int]$pidResult.Output
    } else {
        $warnings += "PID_NOT_FOUND"
    }
}

if (-not (Test-Path $artifactDir)) {
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
}

$mainExt = if ($resolvedFormat -eq "json") { "jsonl" } else { "txt" }
$mainFileName = "logcat-main.$mainExt"
$mainPath = Join-Path $artifactDir $mainFileName
$crashPath = Join-Path $artifactDir "logcat-crash.txt"
$markerPath = Join-Path $artifactDir "repro-marker.json"
$metaPath = Join-Path $artifactDir "capture-meta.json"

$reproStartedAt = $null
if (Test-Path $markerPath) {
    try {
        $markerObj = Get-Content $markerPath -Raw | ConvertFrom-Json
        $reproStartedAt = $markerObj.repro_started_at
    } catch { }
}

# Main buffer: tag filter $Tag:D *:S (default APP_TRACE); optional --pid when package resolved
$mainArgs = @("logcat", "-d", "-b", "main", "-v", $resolvedFormat)
if ($appPid) { $mainArgs += "--pid=$appPid" }
$mainArgs += "$Tag`:D", "*:S"

$mainDump = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
    -AdbArguments $mainArgs -UseFixture ($useFixture -or $DryRun)
if (-not $mainDump.Ok) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "DUMP_FAILED" `
        -Message "adb logcat main buffer dump failed." `
        -CaptureMetaPath $null -LineCount $null
}

$mainContent = $mainDump.Output
if ($MaxLines -gt 0) {
    $beforeCount = Count-Lines -Content $mainContent
    $mainContent = Truncate-Lines -Content $mainContent -Max $MaxLines
    $afterCount = Count-Lines -Content $mainContent
    if ($beforeCount -gt $afterCount) { $warnings += "TRUNCATED: main" }
}
Set-Content -Path $mainPath -Value $mainContent -Encoding UTF8 -NoNewline
$mainLineCount = Count-Lines -Content $mainContent

# Crash buffer: full dump, no tag filter (captures FATAL EXCEPTION / tombstone lines)
$crashDump = Invoke-CaptureAdb -AdbPath $adbPath -DeviceSerial $Serial `
    -AdbArguments @("logcat", "-d", "-b", "crash") -UseFixture ($useFixture -or $DryRun)
if (-not $crashDump.Ok) {
    Emit-CaptureResult -Status "FAIL" -ExitCode "DUMP_FAILED" `
        -Message "adb logcat crash buffer dump failed." `
        -CaptureMetaPath $null -LineCount $null
}
$crashContent = $crashDump.Output
Set-Content -Path $crashPath -Value $crashContent -Encoding UTF8 -NoNewline
$crashLineCount = Count-Lines -Content $crashContent

$totalLines = $mainLineCount + $crashLineCount
$relBase = ".ai/context/device-logs/$TaskId"
$relMain = "$relBase/$mainFileName"
$relCrash = "$relBase/logcat-crash.txt"
$relMarker = if (Test-Path $markerPath) { "$relBase/repro-marker.json" } else { $null }

$dumpedAt = Get-IsoTimestamp
$metaStatus = "PASS"
$exitCode = "PASS"
$message = "Dumped $totalLines lines to $relBase/"

if ($totalLines -eq 0) {
    $warnings += "CAPTURE_EMPTY"
    $exitCode = "CAPTURE_EMPTY"
    $message = "Dump succeeded but 0 lines captured - check tag filter or repro window"
}

$meta = [ordered]@{
    status           = $metaStatus
    task_id          = $TaskId
    serial           = $Serial
    package          = if ($Package) { $Package } else { $null }
    tag_filter       = $Tag
    buffers          = $bufferList
    format           = $resolvedFormat
    api_level        = $apiLevel
    pid              = $appPid
    paths            = [ordered]@{
        main   = $relMain
        crash  = $relCrash
        marker = $relMarker
    }
    line_count       = [ordered]@{
        main  = $mainLineCount
        crash = $crashLineCount
        total = $totalLines
    }
    repro_started_at = $reproStartedAt
    dumped_at        = $dumpedAt
    warnings         = @($warnings)
}

$meta | ConvertTo-Json -Depth 6 | Set-Content -Path $metaPath -Encoding UTF8

Emit-CaptureResult -Status "PASS" -ExitCode $exitCode -Message $message `
    -CaptureMetaPath "$relBase/capture-meta.json" -LineCount $totalLines
