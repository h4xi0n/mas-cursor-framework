# MAS-10 P1: preToolUse warn when Shell bypasses mas-host-exec (fail-open).
$ErrorActionPreference = "SilentlyContinue"

$inputRaw = ""
if ($null -ne $Input -and $Input.Count -gt 0) {
    $inputRaw = ($Input | Out-String).Trim()
}
if ([string]::IsNullOrWhiteSpace($inputRaw) -and [Console]::IsInputRedirected) {
    try { $inputRaw = [Console]::In.ReadToEnd() } catch { $inputRaw = "" }
}

function Get-ShellCommandFromHook {
    param($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj.command) { return [string]$Obj.command }
    if ($Obj.tool_input -and $Obj.tool_input.command) { return [string]$Obj.tool_input.command }
    if ($Obj.args -and $Obj.args.command) { return [string]$Obj.args.command }
    return $null
}

function Test-GatedShellCommand {
    param([string]$Cmd)
    if ([string]::IsNullOrWhiteSpace($Cmd)) { return $false }
    if ($Cmd -match 'mas-host-exec') { return $false }
    $norm = $Cmd -replace '\\', '/'
    if ($norm -match '(^|[\s/])(\./)?gradlew(\.bat)?(\s|$)') { return $true }
    if ($norm -match '\badb\s+install-multiple\b') { return $true }
    if ($norm -match '\badb\s+install\b') { return $true }
    return $false
}

try {
    $parsed = $inputRaw | ConvertFrom-Json
} catch {
    Write-Output "{}"
    exit 0
}

$cmd = Get-ShellCommandFromHook -Obj $parsed
if (Test-GatedShellCommand -Cmd $cmd) {
    $msg = "Gradle/adb install should use mas-host-exec (see host-build-install-mutex.md)"
    Write-Output (@{ warning = $msg } | ConvertTo-Json -Compress)
    exit 0
}

Write-Output "{}"
exit 0
