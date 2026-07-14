<#
  MAS Coordinator: start ephemeral workflow session JSON for telemetry tracking.
  Params: ProjectPath, TaskId, Mode (FULL|LITE), Tier (S|M|L|L+|none), Type (feature|bugfix).
  Idempotent if session exists. Stdout: CREATED | EXISTS. Exit 0 on success.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("FULL", "LITE")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [ValidateSet("S", "M", "L", "L+", "none")]
    [string]$Tier,

    [ValidateSet("feature", "bugfix")]
    [string]$Type = "feature"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Write-Error "TaskId is required."
    exit 1
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
$TaskId = $TaskId.Trim()
$Type = $Type.ToLower()

$SessionsDir = Join-Path $ProjectPath ".ai\context\workflow-sessions"
$SessionPath = Join-Path $SessionsDir "$TaskId.json"

if (-not (Test-Path $SessionsDir)) {
    New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
}

if (Test-Path $SessionPath) {
    Write-Output "EXISTS"
    exit 0
}

$startedAt = (Get-Date).ToString("o")

$session = [ordered]@{
    task_id    = $TaskId
    mode       = $Mode
    tier       = $Tier
    type       = $Type
    started_at = $startedAt
    steps      = @()
}

$json = $session | ConvertTo-Json -Depth 10 -Compress:$false
Set-Content -Path $SessionPath -Value $json.TrimEnd() -Encoding UTF8
Write-Output "CREATED"
exit 0
