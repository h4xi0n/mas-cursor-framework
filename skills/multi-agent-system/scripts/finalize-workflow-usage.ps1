<#
  MAS Coordinator post-reviewer: write workflow telemetry bullet to memory.md.
  Reads session JSON, upserts under Workflow Usage (MAS-02), trims, deletes session.
  Params: ProjectPath, TaskId, Summary (optional, <=80 chars). Stdout: FINALIZED | UPDATED.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [string]$Summary = ""
)

$ErrorActionPreference = "Stop"

$SkillsRoot = Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system"
$TrimScript = Join-Path $SkillsRoot "scripts\trim-workflow-usage.ps1"

function Ensure-WorkflowUsageSection {
    param(
        [System.Collections.Generic.List[string]]$Lines
    )
    $sectionIndex = -1
    $entriesIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^### Workflow Usage \(MAS-02\)\s*$') {
            $sectionIndex = $i
        }
        if ($sectionIndex -ge 0 -and $Lines[$i] -match '^## Entries\s*$' -and $i -gt $sectionIndex) {
            $entriesIndex = $i
            break
        }
    }
    if ($entriesIndex -ge 0) { return $entriesIndex }

    if ($sectionIndex -ge 0) {
        $insertAt = $sectionIndex + 1
        while ($insertAt -lt $Lines.Count) {
            $line = $Lines[$insertAt]
            if ($line -match '^### ' -or ($line -match '^## ' -and $line -notmatch '^## Entries')) {
                break
            }
            $insertAt++
        }
        if ($insertAt -lt $Lines.Count -and -not [string]::IsNullOrWhiteSpace($Lines[$insertAt - 1])) {
            $Lines.Insert($insertAt, "")
            $insertAt++
        }
        $Lines.Insert($insertAt, "## Entries")
        return $insertAt
    }

    $masIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^## MAS Framework\s*$') {
            $masIndex = $i
            break
        }
    }

    $stub = @(
        "### Workflow Usage (MAS-02)",
        "",
        "> Durable per-workflow telemetry (mode, tier, agent chain, models, tokens). One line per approved workflow. Policy: workflow-usage-policy.md",
        "",
        "## Entries"
    )

    if ($masIndex -ge 0) {
        $insertAt = $masIndex + 1
        while ($insertAt -lt $Lines.Count -and $Lines[$insertAt] -notmatch '^## ') {
            $insertAt++
        }
        foreach ($line in $stub) {
            $Lines.Insert($insertAt, $line)
            $insertAt++
        }
    } else {
        if ($Lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Lines[$Lines.Count - 1])) {
            $Lines.Add("")
        }
        $Lines.Add("## MAS Framework")
        foreach ($line in $stub) {
            $Lines.Add($line)
        }
    }

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^## Entries\s*$') {
            for ($j = $i - 1; $j -ge 0; $j--) {
                if ($Lines[$j] -match 'Workflow Usage') { return $i }
                if ($Lines[$j] -match '^### ' -and $Lines[$j] -notmatch 'Workflow Usage') { break }
            }
        }
    }
    return -1
}

function Get-TokensLabel {
    param($Session)
    $steps = @($Session.steps)
    if ($steps.Count -eq 0) { return "unknown" }

    $allKnown = $true
    $total = 0
    foreach ($step in $steps) {
        if ($null -eq $step.tokens_in -or $null -eq $step.tokens_out) {
            $allKnown = $false
            break
        }
        $total += [int]$step.tokens_in + [int]$step.tokens_out
    }
    if ($allKnown) { return "$total" }

    $mode = $Session.mode
    $tier = $Session.tier
    if ($mode -eq "LITE" -and $tier -and $tier -ne "none") {
        return "est~$tier"
    }
    return "unknown"
}

$ProjectPath = (Resolve-Path $ProjectPath).Path
$TaskId = $TaskId.Trim()
$SessionPath = Join-Path $ProjectPath ".ai\context\workflow-sessions\$TaskId.json"
$MemoryPath = Join-Path $ProjectPath ".ai\context\memory.md"
$ContextDir = Join-Path $ProjectPath ".ai\context"
$Today = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $SessionPath)) {
    Write-Error "Session not found: $SessionPath"
    exit 1
}

if (-not (Test-Path $ContextDir)) {
    New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null
}

if (-not (Test-Path $MemoryPath)) {
    $SkillsTpl = Join-Path $SkillsRoot "templates\memory.md.tpl"
    if (Test-Path $SkillsTpl) {
        Copy-Item $SkillsTpl $MemoryPath
    } else {
        Set-Content -Path $MemoryPath -Value "# Project Memory`n`n## MAS Framework`n" -Encoding UTF8
    }
}

$session = Get-Content $SessionPath -Raw | ConvertFrom-Json
$steps = @($session.steps) | Sort-Object { $_.spawn_index }

$chain = ($steps | ForEach-Object { $_.agent }) -join [char]0x2192
$models = ($steps | ForEach-Object { $_.model }) -join ","
$classes = ($steps | ForEach-Object { $_.model_class }) -join ","
$tokens = Get-TokensLabel -Session $session
$type = $session.type
$mode = $session.mode
$tier = $session.tier

$bullet = "- **$TaskId** ($Today, $type, ${mode}/${tier}): chain=$chain; models=$models; classes=$classes; tokens=$tokens"
$taskPattern = "\*\*$([regex]::Escape($TaskId))\*\*"

$lines = [System.Collections.Generic.List[string]]::new()
$lines.AddRange([string[]](Get-Content $MemoryPath))

$entriesIndex = Ensure-WorkflowUsageSection -Lines $lines
if ($entriesIndex -lt 0) {
    Write-Error "Could not locate or create Workflow Usage ## Entries section."
    exit 1
}

$updated = $false
$result = "FINALIZED"
for ($i = $entriesIndex + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#{1,3} ' -and $lines[$i] -notmatch '^- ') { break }
    if ($lines[$i] -match '^- \*\*' -and $lines[$i] -match $taskPattern) {
        $lines[$i] = $bullet
        $updated = $true
        $result = "UPDATED"
        break
    }
}

if (-not $updated) {
    $insertAt = $entriesIndex + 1
    while ($insertAt -lt $lines.Count -and $lines[$insertAt] -match '^- \*\*') {
        $insertAt++
    }
    if ($insertAt -ge $lines.Count) {
        $lines.Add($bullet)
    } else {
        $lines.Insert($insertAt, $bullet)
    }
}

Set-Content -Path $MemoryPath -Value ($lines -join "`n") -Encoding UTF8

& $TrimScript -ProjectPath $ProjectPath | Out-Null

Remove-Item -Path $SessionPath -Force
Write-Output $result
exit 0
