<#
  MAS Coordinator: delete ephemeral workflow session without writing memory.
  Params: ProjectPath, TaskId. Stdout: CANCELLED | NOT_FOUND. Exit 0 on success.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId
)

$ErrorActionPreference = "Stop"

$ProjectPath = (Resolve-Path $ProjectPath).Path
$TaskId = $TaskId.Trim()
$SessionPath = Join-Path $ProjectPath ".ai\context\workflow-sessions\$TaskId.json"

if (-not (Test-Path $SessionPath)) {
    Write-Output "NOT_FOUND"
    exit 0
}

Remove-Item -Path $SessionPath -Force
Write-Output "CANCELLED"
exit 0
