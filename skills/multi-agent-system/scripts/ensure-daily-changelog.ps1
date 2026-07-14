<#
  MAS Coordinator startup: ensure .ai/context/daily-changelog.md exists for today's local date.
  Rollovers from template when file is missing or header date differs; writes ROLLOVER or UNCHANGED.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"

$ProjectPath = (Resolve-Path $ProjectPath).Path
$SkillsRoot = Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system"
$TemplatePath = Join-Path $SkillsRoot "templates\daily-changelog.md.tpl"
$ContextDir = Join-Path $ProjectPath ".ai\context"
$ChangelogPath = Join-Path $ContextDir "daily-changelog.md"
$Today = Get-Date -Format "yyyy-MM-dd"

function Get-ChangelogHeaderDate {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $firstLine = Get-Content $Path -TotalCount 1 -ErrorAction SilentlyContinue
    if ($firstLine -match '^# Daily Changelog — (.+)$') {
        return $Matches[1].Trim()
    }
    return $null
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
    Write-Output "ROLLOVER"
    exit 0
}

$headerDate = Get-ChangelogHeaderDate -Path $ChangelogPath
if ($null -eq $headerDate -or $headerDate -ne $Today) {
    Write-ChangelogFromTemplate
    Write-Output "ROLLOVER"
    exit 0
}

Write-Output "UNCHANGED"
exit 0
