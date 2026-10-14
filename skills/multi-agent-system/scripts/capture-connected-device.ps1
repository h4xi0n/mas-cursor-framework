<#
.SYNOPSIS
  MAS connected-device adb capture — gate, launch, screencap, optional crop.

.DESCRIPTION
  Orchestrates adb device capture for mas-visual-fidelity Priority 3 pipeline.
  Emits JSON summary to stdout on success. Never installs APK.

.EXIT CODES
  0 = Success (warnings allowed)
  1 = adb not found on PATH
  2 = Zero authorized devices
  3 = Multiple devices; serial not specified
  4 = Device unauthorized or offline
  5 = Launch failed (app not installed, activity not found, deeplink error)
  6 = Screencap or write failure
  7 = Invalid arguments / missing required flag
#>
[CmdletBinding()]
param(
    [string]$Serial,

    [Parameter(Mandatory = $false)]
    [string]$Package,

    [string]$Activity,
    [string]$Deeplink,
    [string]$Action = "android.intent.action.VIEW",
    [string]$Extras,
    [int]$WaitMs = 2000,
    [Parameter(Mandatory = $false)]
    [string]$Output,
    [switch]$ClearTask,
    [double]$FontScale,
    [ValidateSet("night", "day")]
    [string]$UiMode,
    [string]$Crop,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$warnings = @()

function Write-Err {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Get-AdbPath {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) { return $null }
    return $adb.Source
}

function Show-Usage {
    @"
Usage: capture-connected-device.ps1 -Package <id> -Output <path> [options]

Required:
  -Package          Application ID
  -Output           PNG output path

Optional:
  -Serial            Device serial (env: ANDROID_SERIAL or ADB_SERIAL)
  -Activity          Activity component
  -Deeplink          Deeplink URI
  -Action            Intent action (default: android.intent.action.VIEW)
  -Extras            JSON map of intent extras
  -WaitMs            Post-launch wait ms (default: 2000)
  -ClearTask         FLAG_ACTIVITY_CLEAR_TASK
  -FontScale         Pre-capture font_scale setting
  -UiMode            night | day
  -Crop              x,y,w,h crop rect (requires ImageMagick)
  -DryRun            Print adb commands without executing
  -Help              Show this help

Exit codes: 0=success, 1=adb missing, 2=no devices, 3=multi-device no serial,
            4=unauthorized/offline, 5=launch failed, 6=screencap failed, 7=invalid args
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

# Env fallbacks (ANDROID_SERIAL canonical post prep gate; ADB_SERIAL alias)
if (-not $Serial -and $env:ANDROID_SERIAL) { $Serial = $env:ANDROID_SERIAL }
if (-not $Serial -and $env:ADB_SERIAL) { $Serial = $env:ADB_SERIAL }
if (-not $Package -and $env:PACKAGE) { $Package = $env:PACKAGE }
if (-not $Activity -and $env:ACTIVITY) { $Activity = $env:ACTIVITY }
if (-not $Deeplink -and $env:DEEPLINK) { $Deeplink = $env:DEEPLINK }
if (-not $Action -and $env:ACTION) { $Action = $env:ACTION }
if (-not $Extras -and $env:INTENT_EXTRAS) { $Extras = $env:INTENT_EXTRAS }
if ($env:POST_LAUNCH_WAIT_MS) { $WaitMs = [int]$env:POST_LAUNCH_WAIT_MS }
if (-not $Output -and $env:OUTPUT) { $Output = $env:OUTPUT }
if (-not $Crop -and $env:CROP_RECT) { $Crop = $env:CROP_RECT }
if ($env:FONT_SCALE) { $FontScale = [double]$env:FONT_SCALE }
if (-not $UiMode -and $env:UI_MODE) { $UiMode = $env:UI_MODE }
if ($env:CLEAR_TASK -eq "true" -or $env:CLEAR_TASK -eq "1") { $ClearTask = $true }

if ([string]::IsNullOrWhiteSpace($Package) -or [string]::IsNullOrWhiteSpace($Output)) {
    Write-Err "Missing required -Package and/or -Output."
    Show-Usage
    exit 7
}

if ([string]::IsNullOrWhiteSpace($Deeplink) -and [string]::IsNullOrWhiteSpace($Activity)) {
    Write-Err "At least one of -Deeplink or -Activity is required."
    exit 7
}

$adbPath = Get-AdbPath
if (-not $adbPath -and -not $DryRun) {
    Write-Err "adb not found on PATH."
    exit 1
}

function Invoke-AdbArgs {
    param([string[]]$AdbArgs, [switch]$CaptureStdout)
    if ($DryRun) {
        $cmd = "adb"
        if ($Serial) { $cmd += " -s $Serial" }
        $cmd += " $($AdbArgs -join ' ')"
        Write-Host "[dry-run] $cmd"
        return $null
    }
    $allArgs = @()
    if ($Serial) { $allArgs += "-s", $Serial }
    $allArgs += $AdbArgs
    if ($CaptureStdout) {
        return & $adbPath $allArgs 2>&1
    }
    & $adbPath $allArgs 2>&1 | Out-Null
    return $LASTEXITCODE
}

function Get-ConnectedDevices {
    if ($DryRun) {
        if ($Serial) { return @(@{ Serial = $Serial; State = "device" }) }
        return @(@{ Serial = "emulator-5554"; State = "device" })
    }
    $lines = & $adbPath devices 2>&1
    $devices = @()
    foreach ($line in $lines) {
        if ($line -match "^\s*(\S+)\s+(\S+)\s*$" -and $matches[1] -ne "List") {
            $devices += @{ Serial = $matches[1]; State = $matches[2] }
        }
    }
    return $devices
}

# Device gate
$devices = Get-ConnectedDevices
$authorized = $devices | Where-Object { $_.State -eq "device" }
$badState = $devices | Where-Object { $_.State -in @("unauthorized", "offline") }

if (-not $DryRun) {
    if ($badState.Count -gt 0 -and $authorized.Count -eq 0) {
        Write-Err "Device unauthorized or offline: $($badState[0].Serial) ($($badState[0].State))"
        exit 4
    }
    if ($authorized.Count -eq 0) {
        Write-Err "No authorized devices connected."
        exit 2
    }
    if ($authorized.Count -gt 1 -and [string]::IsNullOrWhiteSpace($Serial)) {
        Write-Err "Multiple devices connected; specify -Serial, ANDROID_SERIAL, or ADB_SERIAL."
        exit 3
    }
    if ([string]::IsNullOrWhiteSpace($Serial) -and $authorized.Count -eq 1) {
        $Serial = $authorized[0].Serial
    }
    if ($Serial) {
        $match = $authorized | Where-Object { $_.Serial -eq $Serial }
        if (-not $match) {
            $offline = $devices | Where-Object { $_.Serial -eq $Serial -and $_.State -ne "device" }
            if ($offline) {
                Write-Err "Device $Serial is $($offline.State)."
                exit 4
            }
            Write-Err "Device $Serial not found among authorized devices."
            exit 2
        }
    }
}

# Pre-capture
if ($FontScale) {
    Invoke-AdbArgs @("shell", "settings", "put", "system", "font_scale", "$FontScale") | Out-Null
}
if ($UiMode) {
    $modeVal = if ($UiMode -eq "night") { "2" } else { "1" }
    Invoke-AdbArgs @("shell", "settings", "put", "secure", "ui_night_mode", $modeVal) | Out-Null
}

# Build launch command
$launchArgs = @("shell", "am", "start")
if ($Action) { $launchArgs += "-a", $Action }
if ($ClearTask) { $launchArgs += "-f", "0x08000000" }
if ($Deeplink) {
    $launchArgs += "-d", $Deeplink
}
if ($Activity) {
    $component = if ($Activity.StartsWith(".")) { "$Package/$Activity" } elseif ($Activity -match "/") { $Activity } else { "$Package/$Activity" }
    $launchArgs += "-n", $component
}
if ($Extras) {
    try {
        $extraMap = $Extras | ConvertFrom-Json
        foreach ($prop in $extraMap.PSObject.Properties) {
            $val = $prop.Value
            if ($val -is [bool]) {
                $launchArgs += "--ez", $prop.Name, $(if ($val) { "true" } else { "false" })
            } else {
                $launchArgs += "--es", $prop.Name, "$val"
            }
        }
    } catch {
        Write-Err "Invalid -Extras JSON: $_"
        exit 7
    }
}

if ($DryRun) {
    Invoke-AdbArgs -AdbArgs $launchArgs | Out-Null
    Write-Host "[dry-run] sleep $WaitMs ms"
    Invoke-AdbArgs -AdbArgs @("exec-out", "screencap", "-p") -CaptureStdout | Out-Null
    Write-Host "[dry-run] write output -> $Output"
    if ($Crop) { Write-Host "[dry-run] magick crop $Crop" }
    $summary = @{
        serial    = if ($Serial) { $Serial } else { "emulator-5554" }
        output    = $Output
        width     = 0
        height    = 0
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        warnings  = @("dry-run")
    } | ConvertTo-Json -Compress
    Write-Output $summary
    exit 0
}

$launchResult = & $adbPath $(if ($Serial) { @("-s", $Serial) }) $launchArgs 2>&1
if ($LASTEXITCODE -ne 0 -or ($launchResult -join "`n") -match "Error|Exception|does not exist|not found") {
    Write-Err "Launch failed: $($launchResult -join ' ')"
    exit 5
}

Start-Sleep -Milliseconds $WaitMs

$outputDir = Split-Path -Parent $Output
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$capArgs = @()
if ($Serial) { $capArgs += "-s", $Serial }
$capArgs += "exec-out", "screencap", "-p"
$capProc = Start-Process -FilePath $adbPath -ArgumentList $capArgs -RedirectStandardOutput $Output -Wait -PassThru -NoNewWindow
if ($capProc.ExitCode -ne 0 -or -not (Test-Path $Output) -or (Get-Item $Output).Length -eq 0) {
    Write-Err "Screencap failed."
    exit 6
}

# Optional crop via ImageMagick
if ($Crop) {
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    $convert = Get-Command convert -ErrorAction SilentlyContinue
    if ($magick -or $convert) {
        $parts = $Crop.Split(",")
        if ($parts.Count -eq 4) {
            $x, $y, $w, $h = $parts
            $tmp = "$Output.tmp.png"
            Move-Item -Force $Output $tmp
            if ($magick) {
                & magick $tmp -crop "${w}x${h}+${x}+${y}" $Output 2>&1 | Out-Null
            } else {
                & convert $tmp -crop "${w}x${h}+${x}+${y}" $Output 2>&1 | Out-Null
            }
            Remove-Item -Force $tmp -ErrorAction SilentlyContinue
        } else {
            $warnings += "Invalid crop rect format; expected x,y,w,h"
        }
    } else {
        $warnings += "ImageMagick not available; full-frame capture retained"
    }
}

# Image dimensions
$width = 0
$height = 0
try {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $Output).Path)
    $width = $img.Width
    $height = $img.Height
    $img.Dispose()
} catch {
    $warnings += "Could not read image dimensions: $_"
}

$timestamp = (Get-Date).ToUniversalTime().ToString("o")
$summary = @{
    serial    = $Serial
    output    = $Output
    width     = $width
    height    = $height
    timestamp = $timestamp
    warnings  = $warnings
} | ConvertTo-Json -Compress

# Optional mirror summary JSON alongside PNG
$summaryPath = [System.IO.Path]::ChangeExtension($Output, ".summary.json")
if ($summaryPath -eq $Output) {
    $summaryPath = "$Output.summary.json"
}
Set-Content -Path $summaryPath -Value ($summary | ConvertFrom-Json | ConvertTo-Json -Depth 5) -Encoding UTF8

Write-Output $summary
exit 0
