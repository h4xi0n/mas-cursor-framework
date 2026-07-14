<#
  MAS Coordinator post-reviewer: upsert a task entry under ## Entries by TaskId.
  Truncates summary to 120 chars, retains max 30 entries; writes APPENDED or UPDATED.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("feature", "bugfix")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Summary
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TaskId) -or [string]::IsNullOrWhiteSpace($Summary)) {
    Write-Error "TaskId and Summary are required."
    exit 1
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
$SkillsRoot = Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system"
$TemplatePath = Join-Path $SkillsRoot "templates\daily-changelog.md.tpl"
$ContextDir = Join-Path $ProjectPath ".ai\context"
$ChangelogPath = Join-Path $ContextDir "daily-changelog.md"
$Today = Get-Date -Format "yyyy-MM-dd"
$MaxEntries = 30
$MaxSummaryLen = 120

$Type = $Type.ToLower()
$TaskId = $TaskId.Trim()
$Summary = $Summary.Trim() -replace '[\r\n]+', ' '
if ($Summary.Length -gt $MaxSummaryLen) {
    $Summary = $Summary.Substring(0, $MaxSummaryLen - 1) + [char]0x2026
}

function Write-ChangelogFromTemplate {
    if (-not (Test-Path $TemplatePath)) {
        Write-Error "Template not found: $TemplatePath"
        exit 1
    }
    $content = Get-Content $TemplatePath -Raw
    $content = $content.Replace("{{DATE}}", $Today)
    if (-not (Test-Path $ContextDir)) {
        New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null
    }
    Set-Content -Path $ChangelogPath -Value $content.TrimEnd() -Encoding UTF8
}

if (-not (Test-Path $ChangelogPath)) {
    Write-ChangelogFromTemplate
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.AddRange([string[]](Get-Content $ChangelogPath))

$entriesHeaderIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## Entries\s*$') {
        $entriesHeaderIndex = $i
        break
    }
}

if ($entriesHeaderIndex -lt 0) {
    Write-ChangelogFromTemplate
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]](Get-Content $ChangelogPath))
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Entries\s*$') {
            $entriesHeaderIndex = $i
            break
        }
    }
}

$bullet = "- **$TaskId** ($Type): $Summary"
$taskPattern = "\*\*$([regex]::Escape($TaskId))\*\*"
$updated = $false
$result = "APPENDED"

for ($i = $entriesHeaderIndex + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^- \*\*' -and $lines[$i] -match $taskPattern) {
        $lines[$i] = $bullet
        $updated = $true
        $result = "UPDATED"
        break
    }
}

if (-not $updated) {
    $insertAt = $entriesHeaderIndex + 1
    while ($insertAt -lt $lines.Count -and $lines[$insertAt] -match '^- \*\*') {
        $insertAt++
    }
    if ($insertAt -ge $lines.Count) {
        $lines.Add($bullet)
    } else {
        $lines.Insert($insertAt, $bullet)
    }
}

$entryIndices = [System.Collections.Generic.List[int]]::new()
for ($i = $entriesHeaderIndex + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^- \*\*') {
        [void]$entryIndices.Add($i)
    }
}

while ($entryIndices.Count -gt $MaxEntries) {
    $lines.RemoveAt($entryIndices[0])
    $entryIndices.RemoveAt(0)
    for ($j = 0; $j -lt $entryIndices.Count; $j++) {
        $entryIndices[$j] = $entryIndices[$j] - 1
    }
}

Set-Content -Path $ChangelogPath -Value ($lines -join "`n") -Encoding UTF8
Write-Output $result
exit 0
