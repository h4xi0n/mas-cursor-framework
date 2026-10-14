<#
.SYNOPSIS
  MAS android-device-prep gate — device discovery, selection, boot wait, grants, reverse.

.DESCRIPTION
  Upstream prep gate for test-executor Step 0, Gradle connected tests, and tier-3 capture.
  Emits a single JSON object on stdout (last line). Idempotent re-run safe.
  -DryRun prints planned adb ops without a device. ADB_DEVICES_FIXTURE bypasses real adb.

.EXIT CODES
  0  = PASS
  1  = ADB_NOT_FOUND
  7  = INVALID_ARGS
  10 = NO_DEVICE
  11 = UNAUTHORIZED
  12 = OFFLINE
  13 = AMBIGUOUS_DEVICE
  14 = SERIAL_NOT_FOUND
  15 = BOOT_TIMEOUT

.ENV
  ADB_DEVICES_FIXTURE  - path to mock `adb devices -l` output; adb not required when set
                         (fixtures: .ai/fixtures/MAS-07-ADB-PREP/)
  ADB_BOOT_COMPLETED   - when "0", mock boot incomplete (fixture testing only)
  ANDROID_SERIAL       - set on PASS for child processes
#>
[CmdletBinding()]
param(
    [string]$Policy = "auto",
    [string]$Serial,
    [string]$Package,
    [string]$Grants,
    [int]$BootTimeout = 120,
    [string[]]$Reverse,
    [switch]$NoAnimationOff,
    [switch]$DryRun,
    [switch]$JsonOnly,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$ExitCodeMap = @{
    PASS              = 0
    ADB_NOT_FOUND     = 1
    INVALID_ARGS      = 7
    NO_DEVICE         = 10
    UNAUTHORIZED      = 11
    OFFLINE           = 12
    AMBIGUOUS_DEVICE  = 13
    SERIAL_NOT_FOUND  = 14
    BOOT_TIMEOUT      = 15
}

function Show-Usage {
    @"
Usage: android-device-prep.ps1 [options]

Options:
  -Policy physical|emulator|auto   Selection when multiple devices (default: auto)
  -Serial <id>                     Explicit device serial override
  -Package <id>                    Application id for pm grant loop
  -Grants <p1,p2,...>              Comma-separated permission names
  -BootTimeout <sec>               Max boot wait (default: 120)
  -Reverse <tcp:host:device>       Repeatable adb reverse pairs
  -NoAnimationOff                  Skip animator scale disable
  -DryRun                          Print planned ops; no device required
  -JsonOnly                        Suppress non-JSON stderr on success
  -Help                            Show this help

Exit codes: 0=PASS, 1=ADB_NOT_FOUND, 7=INVALID_ARGS, 10=NO_DEVICE,
            11=UNAUTHORIZED, 12=OFFLINE, 13=AMBIGUOUS_DEVICE,
            14=SERIAL_NOT_FOUND, 15=BOOT_TIMEOUT

Fixture testing: set ADB_DEVICES_FIXTURE to mock adb devices -l output.
See device-prep-automation.md and .ai/fixtures/MAS-07-ADB-PREP/
"@
}

function Write-Info {
    param([string]$Message)
    if (-not $JsonOnly) {
        Write-Host $Message
    }
}

function Emit-PrepResult {
    param(
        [string]$Status,
        [AllowNull()][string]$Serial,
        [string]$ExitCode,
        [string]$Message,
        [string]$PolicyApplied,
        [AllowNull()][int]$BootWaitMs = $null,
        [string[]]$GrantsApplied = @(),
        [string[]]$GrantsSkipped = @(),
        [string[]]$ReverseApplied = @(),
        [bool]$AnimationsDisabled = $false,
        [string[]]$Warnings = @()
    )

    $serialValue = if ([string]::IsNullOrWhiteSpace($Serial)) { $null } else { $Serial }
    $result = [ordered]@{
        status              = $Status
        serial              = $serialValue
        exit_code           = $ExitCode
        message             = $Message
        policy_applied      = $PolicyApplied
        boot_wait_ms        = $BootWaitMs
        grants_applied      = @($GrantsApplied)
        grants_skipped      = @($GrantsSkipped)
        reverse_applied     = @($ReverseApplied)
        animations_disabled = $AnimationsDisabled
        warnings            = @($Warnings)
    }

    $json = $result | ConvertTo-Json -Compress -Depth 5
    Write-Output $json

    $procExit = $ExitCodeMap[$ExitCode]
    if ($null -eq $procExit) { $procExit = 1 }
    exit $procExit
}

function Test-IsEmulator {
    param([string]$DeviceSerial)
    return $DeviceSerial -match '^emulator-'
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
            $devices += @{
                Serial  = $matches[1]
                State   = $matches[2]
                Details = $matches[3]
            }
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

function Select-DeviceSerial {
    param(
        [array]$Devices,
        [string]$Policy,
        [string]$SerialOverride
    )

    $authorized = @($Devices | Where-Object { $_.State -eq "device" })
    $unauthorized = @($Devices | Where-Object { $_.State -eq "unauthorized" })
    $offline = @($Devices | Where-Object { $_.State -eq "offline" })

    if ($authorized.Count -eq 0 -and $unauthorized.Count -gt 0) {
        return @{ Ok = $false; ExitCode = "UNAUTHORIZED"; Serial = $null; Message = "Device unauthorized - unlock phone and tap Always allow on USB debugging prompt. See device-prep-automation.md enrollment checklist." }
    }

    if ($authorized.Count -eq 0) {
        if ($offline.Count -gt 0 -and $SerialOverride) {
            $off = $offline | Where-Object { $_.Serial -eq $SerialOverride }
            if ($off) {
                return @{ Ok = $false; ExitCode = "OFFLINE"; Serial = $null; Message = "Device $SerialOverride is offline after adb server retry. Reconnect USB or restart adb." }
            }
        }
        return @{ Ok = $false; ExitCode = "NO_DEVICE"; Serial = $null; Message = "No devices in device state. Connect a phone or start an emulator, then retry." }
    }

    if ($SerialOverride) {
        $match = $authorized | Where-Object { $_.Serial -eq $SerialOverride }
        if (-not $match) {
            $bad = $Devices | Where-Object { $_.Serial -eq $SerialOverride -and $_.State -ne "device" }
            if ($bad) {
                if ($bad.State -eq "offline") {
                    return @{ Ok = $false; ExitCode = "OFFLINE"; Serial = $null; Message = "Device $SerialOverride is offline after adb server retry." }
                }
                if ($bad.State -eq "unauthorized") {
                    return @{ Ok = $false; ExitCode = "SERIAL_NOT_FOUND"; Serial = $null; Message = "Serial $SerialOverride is unauthorized. Complete USB debugging enrollment first." }
                }
            }
            return @{ Ok = $false; ExitCode = "SERIAL_NOT_FOUND"; Serial = $null; Message = "Serial $SerialOverride not found among authorized devices." }
        }
        return @{ Ok = $true; Serial = $SerialOverride; Message = "Device ready; ANDROID_SERIAL=$SerialOverride" }
    }

    if ($authorized.Count -eq 1) {
        $s = $authorized[0].Serial
        return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
    }

    $hardware = @($authorized | Where-Object { -not (Test-IsEmulator $_.Serial) })
    $emulators = @($authorized | Where-Object { Test-IsEmulator $_.Serial })

    switch ($Policy) {
        "physical" {
            if ($hardware.Count -eq 1) {
                $s = $hardware[0].Serial
                return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
            }
            if ($hardware.Count -eq 0) {
                return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "DEVICE_POLICY physical requires a hardware device; only emulators connected." }
            }
            return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "Multiple hardware devices; set DEVICE_SERIAL or --serial to disambiguate." }
        }
        "emulator" {
            if ($emulators.Count -eq 1) {
                $s = $emulators[0].Serial
                return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
            }
            if ($emulators.Count -eq 0) {
                return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "DEVICE_POLICY emulator requires an emulator; only hardware connected." }
            }
            return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "Multiple emulators; set DEVICE_SERIAL or --serial to disambiguate." }
        }
        default {
            if ($hardware.Count -eq 1 -and $emulators.Count -ge 1) {
                $s = $hardware[0].Serial
                return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
            }
            if ($hardware.Count -eq 1 -and $emulators.Count -eq 0) {
                $s = $hardware[0].Serial
                return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
            }
            if ($hardware.Count -eq 0 -and $emulators.Count -eq 1) {
                $s = $emulators[0].Serial
                return @{ Ok = $true; Serial = $s; Message = "Device ready; ANDROID_SERIAL=$s" }
            }
            if ($hardware.Count -gt 1) {
                return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "Multiple hardware devices; set DEVICE_SERIAL or --serial to disambiguate." }
            }
            return @{ Ok = $false; ExitCode = "AMBIGUOUS_DEVICE"; Serial = $null; Message = "Multiple devices; policy auto could not resolve a single target." }
        }
    }
}

function Invoke-Adb {
    param(
        [string]$AdbPath,
        [string]$DeviceSerial,
        [string[]]$AdbArguments,
        [bool]$UseFixture,
        [bool]$IsDryRun
    )

    $cmd = "adb"
    if ($DeviceSerial) { $cmd += " -s $DeviceSerial" }
    $cmd += " $($AdbArguments -join ' ')"

    if ($IsDryRun) {
        Write-Info "[dry-run] $cmd"
        return @{ Ok = $true; Output = "" }
    }

    if ($UseFixture) {
        $sub = $AdbArguments -join " "
        if ($sub -match '^shell getprop sys\.boot_completed$') {
            $val = if ($env:ADB_BOOT_COMPLETED -eq "0") { "0" } else { "1" }
            return @{ Ok = $true; Output = $val }
        }
        if ($sub -match '^shell (settings put|pm grant)' -or $sub -match '^reverse ') {
            return @{ Ok = $true; Output = "" }
        }
        if ($sub -eq "start-server" -or $sub -match '^kill-server$') {
            return @{ Ok = $true; Output = "" }
        }
        return @{ Ok = $true; Output = "" }
    }

    $allArgs = @()
    if ($DeviceSerial) { $allArgs += "-s", $DeviceSerial }
    $allArgs += $AdbArguments
    $output = & $AdbPath $allArgs 2>&1
    return @{ Ok = ($LASTEXITCODE -eq 0); Output = ($output | Out-String).Trim() }
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($Policy -notin @("physical", "emulator", "auto")) {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode "INVALID_ARGS" `
        -Message "Invalid policy: $Policy. Use physical, emulator, or auto." -PolicyApplied "auto"
}

if ($BootTimeout -lt 1) {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode "INVALID_ARGS" `
        -Message "BootTimeout must be >= 1." -PolicyApplied $Policy
}

if ($Grants -and [string]::IsNullOrWhiteSpace($Package)) {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode "INVALID_ARGS" `
        -Message "--package is required when --grants is set." -PolicyApplied $Policy
}

$useFixture = -not [string]::IsNullOrWhiteSpace($env:ADB_DEVICES_FIXTURE)
$adbPath = Get-AdbPath

if (-not $adbPath -and -not $useFixture -and -not $DryRun) {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode "ADB_NOT_FOUND" `
        -Message "adb not found on PATH. Install Android Platform Tools." -PolicyApplied $Policy
}

$warnings = @()
$grantsApplied = @()
$grantsSkipped = @()
$reverseApplied = @()
$animationsDisabled = $false

if ($DryRun) {
    Write-Info "[dry-run] adb start-server"
    Write-Info "[dry-run] adb devices -l"
    $selSerial = if ($Serial) { $Serial } else { "dry-run-device" }
    if (-not $NoAnimationOff) {
        Write-Info "[dry-run] adb -s $selSerial shell settings put global animator_duration_scale 0"
        $animationsDisabled = $true
    }
    if ($Package -and $Grants) {
        foreach ($perm in ($Grants -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            Write-Info "[dry-run] adb -s $selSerial shell pm grant $Package $perm"
            $grantsApplied += $perm
        }
    }
    foreach ($rev in $Reverse) {
        if ($rev) {
            Write-Info "[dry-run] adb -s $selSerial reverse $rev"
            $reverseApplied += $rev
        }
    }
    Emit-PrepResult -Status "PASS" -Serial $selSerial -ExitCode "PASS" `
        -Message "Dry-run complete; planned ops printed." -PolicyApplied $Policy `
        -BootWaitMs 0 -GrantsApplied $grantsApplied -GrantsSkipped $grantsSkipped `
        -ReverseApplied $reverseApplied -AnimationsDisabled $animationsDisabled -Warnings @("dry-run")
}

# start-server
Invoke-Adb -AdbPath $adbPath -DeviceSerial $null -AdbArguments @("start-server") -UseFixture $useFixture -IsDryRun $false | Out-Null

$devices = Get-DevicesList -AdbPath $adbPath -UseFixture $useFixture

# Offline retry: kill-server + start-server once when offline rows present and no authorized yet
$offlineOnly = @($devices | Where-Object { $_.State -eq "offline" })
$authorizedPre = @($devices | Where-Object { $_.State -eq "device" })
if ($offlineOnly.Count -gt 0 -and $authorizedPre.Count -eq 0 -and -not $useFixture) {
    Invoke-Adb -AdbPath $adbPath -DeviceSerial $null -AdbArguments @("kill-server") -UseFixture $false -IsDryRun $false | Out-Null
    Invoke-Adb -AdbPath $adbPath -DeviceSerial $null -AdbArguments @("start-server") -UseFixture $false -IsDryRun $false | Out-Null
    $devices = Get-DevicesList -AdbPath $adbPath -UseFixture $false
}

$selection = Select-DeviceSerial -Devices $devices -Policy $Policy -SerialOverride $Serial

if (-not $selection.Ok) {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode $selection.ExitCode `
        -Message $selection.Message -PolicyApplied $Policy
}

$selectedSerial = $selection.Serial

# Check selected device not offline
$selRow = $devices | Where-Object { $_.Serial -eq $selectedSerial }
if ($selRow -and $selRow.State -eq "offline") {
    Emit-PrepResult -Status "FAIL" -Serial $null -ExitCode "OFFLINE" `
        -Message "Device $selectedSerial is offline after adb server retry." -PolicyApplied $Policy
}

# Boot wait
$bootStart = [DateTime]::UtcNow
$bootComplete = $false
$pollMs = 500

while (-not $bootComplete) {
    $prop = Invoke-Adb -AdbPath $adbPath -DeviceSerial $selectedSerial `
        -AdbArguments @("shell", "getprop", "sys.boot_completed") -UseFixture $useFixture -IsDryRun $false
    if ($prop.Output -eq "1") {
        $bootComplete = $true
        break
    }
    $elapsed = ([DateTime]::UtcNow - $bootStart).TotalSeconds
    if ($elapsed -ge $BootTimeout) {
        Emit-PrepResult -Status "FAIL" -Serial $selectedSerial -ExitCode "BOOT_TIMEOUT" `
            -Message "sys.boot_completed did not become 1 within $BootTimeout seconds." `
            -PolicyApplied $Policy -BootWaitMs ([int](([DateTime]::UtcNow - $bootStart).TotalMilliseconds))
    }
    Start-Sleep -Milliseconds $pollMs
}

$bootWaitMs = [int](([DateTime]::UtcNow - $bootStart).TotalMilliseconds)

# Animation off
if (-not $NoAnimationOff) {
    foreach ($setting in @(
        @("global", "animator_duration_scale", "0"),
        @("global", "transition_animation_scale", "0"),
        @("global", "window_animation_scale", "0")
    )) {
        Invoke-Adb -AdbPath $adbPath -DeviceSerial $selectedSerial `
            -AdbArguments @("shell", "settings", "put") + $setting -UseFixture $useFixture -IsDryRun $false | Out-Null
    }
    $animationsDisabled = $true
}

# Grants
if ($Package -and $Grants) {
    foreach ($perm in ($Grants -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $grant = Invoke-Adb -AdbPath $adbPath -DeviceSerial $selectedSerial `
            -AdbArguments @("shell", "pm", "grant", $Package, $perm) -UseFixture $useFixture -IsDryRun $false
        if ($grant.Ok) {
            $grantsApplied += $perm
        } else {
            $grantsSkipped += $perm
            $warnings += "GRANT_SKIPPED: $perm"
        }
    }
}

# Reverse
foreach ($rev in $Reverse) {
    if ([string]::IsNullOrWhiteSpace($rev)) { continue }
    Invoke-Adb -AdbPath $adbPath -DeviceSerial $selectedSerial `
        -AdbArguments @("reverse", $rev) -UseFixture $useFixture -IsDryRun $false | Out-Null
    $reverseApplied += $rev
}

$env:ANDROID_SERIAL = $selectedSerial

Emit-PrepResult -Status "PASS" -Serial $selectedSerial -ExitCode "PASS" `
    -Message $selection.Message -PolicyApplied $Policy -BootWaitMs $bootWaitMs `
    -GrantsApplied $grantsApplied -GrantsSkipped $grantsSkipped `
    -ReverseApplied $reverseApplied -AnimationsDisabled $animationsDisabled -Warnings $warnings
