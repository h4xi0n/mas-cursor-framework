param(
    [string]$Event = "unknown"
)

$ErrorActionPreference = "SilentlyContinue"

# Read hook input from stdin (supports pipeline and Console.In)
$inputRaw = ""
if ($null -ne $Input -and $Input.Count -gt 0) {
    $inputRaw = ($Input | Out-String).Trim()
}
if ([string]::IsNullOrWhiteSpace($inputRaw) -and [Console]::IsInputRedirected) {
    try {
        $inputRaw = [Console]::In.ReadToEnd()
    } catch {
        $inputRaw = ""
    }
}
$input = $null
try {
    $input = $inputRaw | ConvertFrom-Json
} catch {
    $input = $null
}

# Resolve workspace root from hook input
$workspaceRoot = $null
if ($input -and $input.workspace_roots -and $input.workspace_roots.Count -gt 0) {
    $workspaceRoot = $input.workspace_roots[0]
} elseif ($input -and $input.root) {
    $workspaceRoot = $input.root
} elseif ($input -and $input.cwd) {
    $workspaceRoot = $input.cwd
}

function Get-LatestHandoff {
    param([string]$Root)
    $handoffDir = Join-Path $Root ".ai\handoffs"
    if (-not (Test-Path $handoffDir)) { return $null }
    Get-ChildItem -Path $handoffDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-NextAgentFromHandoff {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $content = Get-Content $FilePath -Raw
    if ($content -match '(?m)^NEXT_AGENT:\s*(\S+)') {
        $next = $Matches[1].Trim()
        if ($next -and $next -ne "none" -and $next -ne "NONE") {
            return $next
        }
    }
    return $null
}

function Get-PendingChainHandoff {
    param([string]$Root)
    $handoffDir = Join-Path $Root ".ai\handoffs"
    if (-not (Test-Path $handoffDir)) { return $null }
    Get-ChildItem -Path $handoffDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object {
            $c = Get-Content $_.FullName -Raw
            $next = $null
            if ($c -match '(?m)^NEXT_AGENT:\s*(\S+)') { $next = $Matches[1].Trim() }
            $hasNext = $next -and $next -notmatch '^(?i)none$'
            $spawned = $c -match '(?m)^SPAWN_STATUS:\s*spawned\s*$'
            $notComplete = $c -notmatch '(?m)^SPAWN_STATUS:\s*complete'
            $hasNext -and ($spawned -or $notComplete)
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# sessionStart: inject context hint when .ai/context exists
if ($Event -eq "sessionStart" -or ($input -and $input.hook_event -eq "sessionStart")) {
    if ($workspaceRoot) {
        $contextDir = Join-Path $workspaceRoot ".ai\context"
        if (Test-Path $contextDir) {
            $msg = "Multi-agent context at .ai/context/. Use /mas-lite for low-token orchestration (memory.md only) or /mas for full pipeline (project + standards + memory)."
            @{ additional_context = $msg } | ConvertTo-Json -Compress
            exit 0
        }
    }
    @{ } | ConvertTo-Json -Compress
    exit 0
}

# subagentStop: remind Coordinator to chain via Task if handoff has pending NEXT_AGENT
if ($Event -eq "subagentStop" -or ($input -and $input.hook_event -eq "subagentStop")) {
    if ($workspaceRoot) {
        $pending = Get-PendingChainHandoff -Root $workspaceRoot
        if (-not $pending) {
            $pending = Get-LatestHandoff -Root $workspaceRoot
        }
        if ($pending) {
            $nextAgent = Get-NextAgentFromHandoff -FilePath $pending.FullName
            if ($nextAgent) {
                $taskId = ""
                $content = Get-Content $pending.FullName -Raw
                if ($content -match '(?m)^TASK_ID:\s*(\S+)') { $taskId = $Matches[1].Trim() }
                $followup = "Coordinator: Task subagent finished. Handoff $($pending.Name) (TASK_ID: $taskId) has NEXT_AGENT: $nextAgent. Set SPAWN_STATUS: complete on current handoff, write new handoff for $nextAgent, spawn Task (generalPurpose, run_in_background: false). Do not implement inline."
                @{ followup_message = $followup } | ConvertTo-Json -Compress
                exit 0
            }
        }
    }
    @{ } | ConvertTo-Json -Compress
    exit 0
}

# Default: no-op
@{ } | ConvertTo-Json -Compress
exit 0
