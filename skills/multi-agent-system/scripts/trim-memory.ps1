param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = (Get-Location).Path,

    [int]$WarnAtLines = 280,
    [int]$MaxLines = 300
)

$ErrorActionPreference = "Stop"
$memoryPath = Join-Path $ProjectPath ".ai\context\memory.md"

if (-not (Test-Path $memoryPath)) {
    Write-Host "No memory.md found at: $memoryPath"
    exit 0
}

$lines = (Get-Content $memoryPath).Count
Write-Host "memory.md line count: $lines / $MaxLines"

if ($lines -ge $WarnAtLines) {
    Write-Warning "memory.md approaching cap ($lines lines). Review and prune obsolete entries."
}

if ($lines -gt $MaxLines) {
    Write-Error "memory.md exceeds $MaxLines line cap. Coordinator must prune before appending."
    exit 1
}

exit 0
