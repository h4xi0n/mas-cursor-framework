<#
  MAS Coordinator: cap Workflow Usage entries and warn on section line count.
  Params: ProjectPath, MaxEntries (default 50), WarnAtLines (default 80).
  Stdout: TRIMMED | UNCHANGED, optional WARN line. Exit 0 on success.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [int]$MaxEntries = 50,
    [int]$WarnAtLines = 80
)

$ErrorActionPreference = "Stop"

$ProjectPath = (Resolve-Path $ProjectPath).Path
$MemoryPath = Join-Path $ProjectPath ".ai\context\memory.md"

if (-not (Test-Path $MemoryPath)) {
    Write-Output "UNCHANGED"
    exit 0
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.AddRange([string[]](Get-Content $MemoryPath))

$sectionIndex = -1
$entriesIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^### Workflow Usage \(MAS-02\)\s*$') {
        $sectionIndex = $i
    }
    if ($sectionIndex -ge 0 -and $lines[$i] -match '^## Entries\s*$' -and $i -gt $sectionIndex) {
        $entriesIndex = $i
        break
    }
}

if ($entriesIndex -lt 0) {
    Write-Output "UNCHANGED"
    exit 0
}

$sectionEnd = $lines.Count
for ($i = $entriesIndex + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#{1,3} ' -and $lines[$i] -notmatch '^- ') {
        $sectionEnd = $i
        break
    }
}

$entryIndices = [System.Collections.Generic.List[int]]::new()
for ($i = $entriesIndex + 1; $i -lt $sectionEnd; $i++) {
    if ($lines[$i] -match '^- \*\*') {
        [void]$entryIndices.Add($i)
    }
}

$trimmed = $false
while ($entryIndices.Count -gt $MaxEntries) {
    $lines.RemoveAt($entryIndices[0])
    $entryIndices.RemoveAt(0)
    for ($j = 0; $j -lt $entryIndices.Count; $j++) {
        $entryIndices[$j] = $entryIndices[$j] - 1
    }
    $sectionEnd--
    $trimmed = $true
}

$sectionLineCount = $sectionEnd - $sectionIndex
if ($sectionLineCount -ge $WarnAtLines) {
    Write-Warning "Workflow Usage section has $sectionLineCount lines (warn at $WarnAtLines). Consider manual review."
}

if ($trimmed) {
    Set-Content -Path $MemoryPath -Value ($lines -join "`n") -Encoding UTF8
    Write-Output "TRIMMED"
} else {
    Write-Output "UNCHANGED"
}
exit 0
