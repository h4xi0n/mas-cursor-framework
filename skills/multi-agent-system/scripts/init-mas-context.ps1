param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet("android", "general", "auto")]
    [string]$Stack = "auto",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ProjectPath = (Resolve-Path $ProjectPath).Path
$SkillsRoot = Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system"
$TemplatesDir = Join-Path $SkillsRoot "templates"

function Test-AndroidProject {
    param([string]$Root)
    $markers = @(
        (Join-Path $Root "build.gradle.kts"),
        (Join-Path $Root "build.gradle"),
        (Join-Path $Root "settings.gradle.kts"),
        (Join-Path $Root "settings.gradle")
    )
    foreach ($m in $markers) {
        if (Test-Path $m) { return $true }
    }
    Get-ChildItem -Path $Root -Filter "AndroidManifest.xml" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 | ForEach-Object { return $true }
    return $false
}

function Get-ProjectName {
    param([string]$Root)
    $settingsKts = Join-Path $Root "settings.gradle.kts"
    $settingsGradle = Join-Path $Root "settings.gradle"
    if (Test-Path $settingsKts) {
        $content = Get-Content $settingsKts -Raw
        if ($content -match 'rootProject\.name\s*=\s*"([^"]+)"') { return $Matches[1] }
    }
    if (Test-Path $settingsGradle) {
        $content = Get-Content $settingsGradle -Raw
        if ($content -match "rootProject\.name\s*=\s*'([^']+)'") { return $Matches[1] }
    }
    return (Split-Path $Root -Leaf)
}

function Get-AndroidModules {
    param([string]$Root)
    $settingsKts = Join-Path $Root "settings.gradle.kts"
    if (-not (Test-Path $settingsKts)) { return "*See settings.gradle*" }
    $includes = Select-String -Path $settingsKts -Pattern 'include\s*\(\s*"([^"]+)"\s*\)' -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object { $_.Groups[1].Value }
    if ($includes.Count -eq 0) { return ":app" }
    return ($includes -join ", ")
}

function Copy-TemplateFile {
    param(
        [string]$TemplateName,
        [string]$DestPath,
        [hashtable]$Replacements
    )
    if ((Test-Path $DestPath) -and -not $Force) {
        Write-Host "Skip (exists): $DestPath"
        return
    }
    $templatePath = Join-Path $TemplatesDir $TemplateName
    if (-not (Test-Path $templatePath)) {
        throw "Template not found: $templatePath"
    }
    $content = Get-Content $templatePath -Raw
    foreach ($key in $Replacements.Keys) {
        $content = $content.Replace("{{$key}}", $Replacements[$key])
    }
    $destDir = Split-Path $DestPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Set-Content -Path $DestPath -Value $content -Encoding UTF8
    Write-Host "Created: $DestPath"
}

# Detect stack
$resolvedStack = $Stack
if ($Stack -eq "auto") {
    $resolvedStack = if (Test-AndroidProject -Root $ProjectPath) { "android" } else { "general" }
    Write-Host "Auto-detected stack: $resolvedStack"
}

$projectName = Get-ProjectName -Root $ProjectPath

# Directories
$aiContext = Join-Path $ProjectPath ".ai\context"
$aiSpecs = Join-Path $aiContext "specs"
$aiBrainstorms = Join-Path $aiContext "brainstorms"
$aiImaginations = Join-Path $aiContext "imaginations"
$aiHandoffs = Join-Path $ProjectPath ".ai\handoffs"
New-Item -ItemType Directory -Path $aiContext -Force | Out-Null
New-Item -ItemType Directory -Path $aiSpecs -Force | Out-Null
New-Item -ItemType Directory -Path $aiBrainstorms -Force | Out-Null
New-Item -ItemType Directory -Path $aiImaginations -Force | Out-Null
New-Item -ItemType Directory -Path $aiHandoffs -Force | Out-Null
$workflowSessions = Join-Path $aiContext "workflow-sessions"
New-Item -ItemType Directory -Path $workflowSessions -Force | Out-Null

# .gitkeep for specs, brainstorms, and handoffs
$specsKeep = Join-Path $aiSpecs ".gitkeep"
if (-not (Test-Path $specsKeep)) {
    Set-Content -Path $specsKeep -Value "" -Encoding UTF8
    Write-Host "Created: $specsKeep"
}
$brainstormsKeep = Join-Path $aiBrainstorms ".gitkeep"
if (-not (Test-Path $brainstormsKeep)) {
    Set-Content -Path $brainstormsKeep -Value "" -Encoding UTF8
    Write-Host "Created: $brainstormsKeep"
}
$imaginationsKeep = Join-Path $aiImaginations ".gitkeep"
if (-not (Test-Path $imaginationsKeep)) {
    Set-Content -Path $imaginationsKeep -Value "" -Encoding UTF8
    Write-Host "Created: $imaginationsKeep"
}
$gitkeep = Join-Path $aiHandoffs ".gitkeep"
if (-not (Test-Path $gitkeep)) {
    Set-Content -Path $gitkeep -Value "" -Encoding UTF8
    Write-Host "Created: $gitkeep"
}

# Stack-specific defaults
if ($resolvedStack -eq "android") {
    $modules = Get-AndroidModules -Root $ProjectPath
    $stackDesc = "Kotlin, Jetpack Compose, Hilt, KSP, Gradle (Android)"
    $codingTemplate = "coding_standards_android.md.tpl"
    $buildInfo = '- Android project: see app/build.gradle.kts for SDK versions'
} else {
    $modules = "N/A"
    $stackDesc = "See project files for stack (React, Next.js, Python, Node, etc.)"
    $codingTemplate = "coding_standards.md.tpl"
    $architecture = @"
* Follow patterns established in existing codebase
* Read package.json, pyproject.toml, or equivalent for dependencies
"@
    $buildInfo = '- See project build files for commands'
}

# Context files
Copy-TemplateFile -TemplateName "project.md.tpl" -DestPath (Join-Path $aiContext "project.md") -Replacements @{
    PROJECT_NAME = $projectName
    STACK        = $stackDesc
    MODULES      = $modules
    ENTRY_POINTS = '- Main application entry: inspect project structure'
    BUILD_INFO   = $buildInfo
}

if ($resolvedStack -eq "android") {
    Copy-TemplateFile -TemplateName $codingTemplate -DestPath (Join-Path $aiContext "coding_standards.md") -Replacements @{}
} else {
    Copy-TemplateFile -TemplateName $codingTemplate -DestPath (Join-Path $aiContext "coding_standards.md") -Replacements @{
        ARCHITECTURE = $architecture
    }
}

Copy-TemplateFile -TemplateName "memory.md.tpl" -DestPath (Join-Path $aiContext "memory.md") -Replacements @{}

$today = Get-Date -Format "yyyy-MM-dd"
Copy-TemplateFile -TemplateName "daily-changelog.md.tpl" -DestPath (Join-Path $aiContext "daily-changelog.md") -Replacements @{
    DATE = $today
}

# AGENTS.md
$agentsMd = Join-Path $ProjectPath "AGENTS.md"
if (-not (Test-Path $agentsMd) -or $Force) {
    @"
# Agent Instructions

Read `.ai/context/` in order: project.md -> coding_standards.md -> memory.md.
For orchestration: ``/mas-lite`` (low token) or ``/mas`` (full pipeline). Brainstorm logic/options: ``/mas brainstorm <feature>`` (logic-only unless you ask for UI).
Do not repeat content from memory.md in responses.
"@ | Set-Content -Path $agentsMd -Encoding UTF8
    Write-Host "Created: $agentsMd"
} else {
    Write-Host "Skip (exists): $agentsMd"
}

# .gitignore entry
$gitignore = Join-Path $ProjectPath ".gitignore"
$aiIgnoreBlock = @"
# Multi-agent local context (not in VCS)
.ai/
"@
if (Test-Path $gitignore) {
    $giContent = Get-Content $gitignore -Raw
    # Remove legacy partial handoff-only rules
    $giContent = $giContent -replace '(?ms)\r?\n# Multi-agent handoffs[^\r\n]*\r?\n\.ai/handoffs/\*\.md\r?\n!\.ai/handoffs/\.gitkeep\r?\n?', "`n"
    if ($giContent -notmatch '(?m)^\.ai/\s*$') {
        Set-Content -Path $gitignore -Value ($giContent.TrimEnd() + "`n`n" + $aiIgnoreBlock + "`n") -Encoding UTF8
        Write-Host "Updated: $gitignore"
    } else {
        Write-Host "Skip: .gitignore already excludes .ai/"
    }
} else {
    Set-Content -Path $gitignore -Value $aiIgnoreBlock -Encoding UTF8
    Write-Host "Created: $gitignore"
}

Write-Host "`nMAS context initialized for: $ProjectPath ($resolvedStack)"
Write-Host "Use /mas in Cursor Agent chat for orchestrated workflows."
