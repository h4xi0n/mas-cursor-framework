<#
.SYNOPSIS
  MAS capture-device-logs Cursor hook — opt-in logcat clear and stop dump.

.DESCRIPTION
  Fail-open hook: always emits valid JSON; never blocks agent stop.
  Opt-in via latest handoff with LOG_CAPTURE: yes (or legacy LOG: y).
  Reads LOG_PACKAGE, LOG_TAG, LOG_BUFFERS, LOG_FORMAT from that handoff.

  Events:
    beforeSubmitPrompt — keyword-gated clear (repro|bug|logcat); D8 opt-in only
    stop               — dump on completed status; returns additional_context path
    afterShellExecution — record log_capture_path when capture script runs in shell
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Event = "unknown",
    [Parameter(ValueFromPipeline = $true)]
    [AllowNull()]
    [string]$PipelineStdin
)

$ErrorActionPreference = "SilentlyContinue"

# Read hook input from pipeline (redirected stdin) or Console.In fallback
$inputRaw = ""
if (-not [string]::IsNullOrWhiteSpace($PipelineStdin)) {
    $inputRaw = $PipelineStdin.Trim()
}
if ([string]::IsNullOrWhiteSpace($inputRaw) -and [Console]::IsInputRedirected) {
    try { $inputRaw = [Console]::In.ReadToEnd().Trim() } catch { $inputRaw = "" }
}
$hookInput = $null
try { $hookInput = $inputRaw | ConvertFrom-Json } catch { $hookInput = $null }

function Emit-Empty {
    @{ } | ConvertTo-Json -Compress
    exit 0
}

function Get-WorkspaceRoot {
    param($InputObj)
    if ($InputObj -and $InputObj.workspace_roots -and $InputObj.workspace_roots.Count -gt 0) {
        return $InputObj.workspace_roots[0]
    }
    if ($InputObj -and $InputObj.root) { return $InputObj.root }
    if ($InputObj -and $InputObj.cwd) { return $InputObj.cwd }
    return $null
}

function Get-LatestLogCaptureHandoff {
    param([string]$Root)
    $handoffDir = Join-Path $Root ".ai\handoffs"
    if (-not (Test-Path $handoffDir)) { return $null }
    Get-ChildItem -Path $handoffDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object {
            $c = Get-Content $_.FullName -Raw
            $c -match '(?m)^LOG_CAPTURE:\s*yes\s*$' -or $c -match '(?m)^LOG:\s*y\s*$'
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Parse-HandoffField {
    param([string]$Content, [string]$Field, [string]$Default = "")
    if ($Content -match "(?m)^${Field}:\s*(.+)$") {
        return $Matches[1].Trim()
    }
    return $Default
}

function Get-ScriptPath {
    param([string]$Root)
    $candidates = @(
        (Join-Path $Root "skills\multi-agent-system\scripts\capture-device-logs.ps1"),
        (Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system\scripts\capture-device-logs.ps1")
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# Resolve workspace and latest LOG_CAPTURE handoff (newest matching file wins)
$workspaceRoot = Get-WorkspaceRoot -InputObj $hookInput
if (-not $workspaceRoot) { Emit-Empty }

$resolvedEvent = $Event
if ($hookInput -and $hookInput.hook_event) { $resolvedEvent = $hookInput.hook_event }

$handoff = Get-LatestLogCaptureHandoff -Root $workspaceRoot
if (-not $handoff) { Emit-Empty }

$content = Get-Content $handoff.FullName -Raw
$taskId = Parse-HandoffField -Content $content -Field "TASK_ID"
$logPackage = Parse-HandoffField -Content $content -Field "LOG_PACKAGE"
$logTag = Parse-HandoffField -Content $content -Field "LOG_TAG" -Default "APP_TRACE"
$logBuffers = Parse-HandoffField -Content $content -Field "LOG_BUFFERS" -Default "main,crash"
$logFormat = Parse-HandoffField -Content $content -Field "LOG_FORMAT"

if ([string]::IsNullOrWhiteSpace($taskId)) { Emit-Empty }

$scriptPath = Get-ScriptPath -Root $workspaceRoot
if (-not $scriptPath) { Emit-Empty }

# beforeSubmitPrompt: opt-in clear only (D8)
if ($resolvedEvent -eq "beforeSubmitPrompt") {
    try {
        $prompt = ""
        if ($hookInput -and $hookInput.prompt) { $prompt = $hookInput.prompt }
        if ($prompt -notmatch '(?i)repro|bug|logcat') { Emit-Empty }
        & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
            clear -TaskId $taskId -JsonOnly 2>$null | Out-Null
    } catch { }
    Emit-Empty
}

# stop: dump logcat when agent completed; surface capture-meta path to follow-up turn
if ($resolvedEvent -eq "stop") {
    $status = ""
    if ($hookInput -and $hookInput.status) { $status = $hookInput.status }
    if ($status -ne "completed") { Emit-Empty }

    try {
        $args = @("dump", "-TaskId", $taskId, "-Tag", $logTag, "-JsonOnly")
        if ($logPackage) { $args += @("-Package", $logPackage) }
        if ($logBuffers) { $args += @("-Buffers", $logBuffers) }
        if ($logFormat) { $args += @("-Format", $logFormat) }

        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath $args 2>$null
        $lastLine = ($output | Select-Object -Last 1)
        if ($lastLine) {
            try {
                $parsed = $lastLine | ConvertFrom-Json
                if ($parsed.status -eq "PASS" -and $parsed.capture_meta_path) {
                    $context = "Device logs: $($parsed.capture_meta_path)"
                    if ($context.Length -gt 200) { $context = $context.Substring(0, 200) }
                    @{ additional_context = $context } | ConvertTo-Json -Compress
                    exit 0
                }
            } catch { }
        }
        Emit-Empty
    } catch {
        Emit-Empty
    }
}

# afterShellExecution: record log_capture_path when capture script runs
if ($resolvedEvent -eq "afterShellExecution") {
    try {
        $cmd = ""
        if ($hookInput -and $hookInput.command) { $cmd = $hookInput.command }
        if ($cmd -notmatch 'capture-device-logs|adb.*logcat') { Emit-Empty }

        $stdout = ""
        if ($hookInput -and $hookInput.output) { $stdout = $hookInput.output }
        $lastLine = ($stdout -split "`n" | Where-Object { $_ } | Select-Object -Last 1)
        if (-not $lastLine) { Emit-Empty }

        $parsed = $lastLine | ConvertFrom-Json
        if (-not $parsed.capture_meta_path) { Emit-Empty }

        $recordScript = Join-Path $workspaceRoot "skills\multi-agent-system\scripts\record-workflow-step.ps1"
        if (-not (Test-Path $recordScript)) {
            $recordScript = Join-Path $env:USERPROFILE ".cursor\skills\multi-agent-system\scripts\record-workflow-step.ps1"
        }
        if (Test-Path $recordScript) {
            $lineCount = if ($parsed.line_count) { [int]$parsed.line_count } else { -1 }
            & powershell -NoProfile -ExecutionPolicy Bypass -File $recordScript `
                -ProjectPath $workspaceRoot -TaskId $taskId -Agent "hook" `
                -LogCapturePath $parsed.capture_meta_path -LineCount $lineCount 2>$null | Out-Null
        }
    } catch { }
    Emit-Empty
}

Emit-Empty
