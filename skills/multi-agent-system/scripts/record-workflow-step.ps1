<#
  MAS Coordinator: append or upsert an agent step in workflow session JSON.
  Same agent re-spawn replaces last step for that agent. Stdout: RECORDED. Exit 0 on success.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [string]$Agent,

    [string]$Model = "default",

    [ValidateSet("normal", "fast", "thinking", "")]
    [string]$ModelClass = "",

    [int]$TokensIn = -1,
    [int]$TokensOut = -1,

    [ValidateSet("task_metadata", "usage_report", "unknown", "estimate", "")]
    [string]$TokensSource = "",

    [double]$DurationSec = -1
)

$ErrorActionPreference = "Stop"

function Get-ModelClassFromSlug {
    param([string]$Slug)
    $s = $Slug.ToLower()
    if ($s -match 'thinking') { return "thinking" }
    if ($s -match 'fast') { return "fast" }
    return "normal"
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
$TaskId = $TaskId.Trim()
$Agent = $Agent.Trim().ToLower()
$Model = if ([string]::IsNullOrWhiteSpace($Model)) { "default" } else { $Model.Trim() }

$SessionPath = Join-Path $ProjectPath ".ai\context\workflow-sessions\$TaskId.json"
if (-not (Test-Path $SessionPath)) {
    Write-Error "Session not found: $SessionPath"
    exit 1
}

$session = Get-Content $SessionPath -Raw | ConvertFrom-Json
$steps = [System.Collections.Generic.List[object]]::new()
foreach ($s in $session.steps) {
    [void]$steps.Add($s)
}

$resolvedClass = if ([string]::IsNullOrWhiteSpace($ModelClass)) {
    Get-ModelClassFromSlug -Slug $Model
} else {
    $ModelClass
}

$tokensInVal = if ($TokensIn -ge 0) { $TokensIn } else { $null }
$tokensOutVal = if ($TokensOut -ge 0) { $TokensOut } else { $null }

$resolvedSource = if ([string]::IsNullOrWhiteSpace($TokensSource)) {
    "unknown"
} else {
    $TokensSource
}

$replaceIndex = -1
for ($i = $steps.Count - 1; $i -ge 0; $i--) {
    if ($steps[$i].agent -eq $Agent) {
        $replaceIndex = $i
        break
    }
}

$spawnIndex = if ($replaceIndex -ge 0) { $steps[$replaceIndex].spawn_index } else { $steps.Count + 1 }

$step = [ordered]@{
    agent         = $Agent
    model         = $Model
    model_class   = $resolvedClass
    tokens_in     = $tokensInVal
    tokens_out    = $tokensOutVal
    tokens_source = $resolvedSource
    spawn_index   = $spawnIndex
}

if ($DurationSec -ge 0) {
    $step.duration_sec = $DurationSec
}

if ($replaceIndex -ge 0) {
    $steps[$replaceIndex] = [pscustomobject]$step
} else {
    [void]$steps.Add([pscustomobject]$step)
}

$session.steps = $steps.ToArray()
$json = $session | ConvertTo-Json -Depth 10 -Compress:$false
Set-Content -Path $SessionPath -Value $json.TrimEnd() -Encoding UTF8
Write-Output "RECORDED"
exit 0
