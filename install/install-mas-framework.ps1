#Requires -Version 5.1
<#
.SYNOPSIS
  Installs MAS Cursor framework from an exported bundle folder or zip.

.EXAMPLE
  .\install-mas-framework.ps1
  .\install-mas-framework.ps1 -BundleRoot "C:\Downloads\mas-cursor-framework"
  .\install-mas-framework.ps1 -ZipPath "C:\Downloads\mas-cursor-framework.zip" -Force
#>
param(
    [string]$BundleRoot = "",
    [string]$ZipPath = "",
    [string]$TargetCursorHome = "",
    [switch]$Force,
    [switch]$SkipHooks
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TargetCursorHome)) {
    $TargetCursorHome = Join-Path $env:USERPROFILE ".cursor"
}
New-Item -ItemType Directory -Path $TargetCursorHome -Force | Out-Null

$tempExtract = $null
if (-not [string]::IsNullOrWhiteSpace($ZipPath)) {
    $ZipPath = (Resolve-Path $ZipPath).Path
    $tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) ("mas-install-" + [guid]::NewGuid().ToString("n"))
    Expand-Archive -Path $ZipPath -DestinationPath $tempExtract -Force
    $BundleRoot = Join-Path $tempExtract "mas-cursor-framework"
    if (-not (Test-Path $BundleRoot)) {
        $candidates = Get-ChildItem -Path $tempExtract -Directory
        if ($candidates.Count -eq 1) {
            $BundleRoot = $candidates[0].FullName
        }
    }
}

if ([string]::IsNullOrWhiteSpace($BundleRoot)) {
    $parent = Split-Path $PSScriptRoot -Parent
    if (Test-Path (Join-Path $parent "skills")) {
        $BundleRoot = $parent
    } else {
        $BundleRoot = Split-Path $PSScriptRoot -Parent
        if (-not (Test-Path (Join-Path $BundleRoot "skills\multi-agent-system"))) {
            throw "BundleRoot not found. Use -ZipPath or -BundleRoot pointing to mas-cursor-framework folder."
        }
    }
}
$BundleRoot = (Resolve-Path $BundleRoot).Path

$ManifestPath = Join-Path $PSScriptRoot "manifest.json"
if (-not (Test-Path $ManifestPath)) {
    $ManifestPath = Join-Path $BundleRoot "install\manifest.json"
}
$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

function Install-Tree {
    param([string]$Src, [string]$Dest)
    if (-not (Test-Path $Src)) { return }
    if (Test-Path $Dest) {
        if (-not $Force) {
            Write-Host "Skip (exists, use -Force): $Dest"
            return
        }
        Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue
    }
    $destParent = Split-Path $Dest -Parent
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }
    Copy-Item -Path $Src -Destination $Dest -Recurse -Force
    Write-Host "Installed: $Dest"
}

Write-Host "Installing MAS to: $TargetCursorHome"
Write-Host "From bundle: $BundleRoot`n"

foreach ($skill in $manifest.skills) {
    $src = Join-Path $BundleRoot (Join-Path "skills" $skill)
    $dest = Join-Path $TargetCursorHome (Join-Path "skills" $skill)
    Install-Tree -Src $src -Dest $dest
}
foreach ($cmd in $manifest.commands) {
    $src = Join-Path $BundleRoot (Join-Path "commands" $cmd)
    $dest = Join-Path $TargetCursorHome (Join-Path "commands" $cmd)
    if (Test-Path $src) {
        $d = Split-Path $dest -Parent
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Copy-Item $src $dest -Force
        Write-Host "Installed: $dest"
    }
}
foreach ($rule in $manifest.rules) {
    $src = Join-Path $BundleRoot (Join-Path "rules" $rule)
    $dest = Join-Path $TargetCursorHome (Join-Path "rules" $rule)
    if (Test-Path $src) {
        New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
        Copy-Item $src $dest -Force
        Write-Host "Installed: $dest"
    }
}
$hooksDir = Join-Path $TargetCursorHome "hooks"
New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
foreach ($hook in $manifest.hooks) {
    $src = Join-Path $BundleRoot (Join-Path "hooks" $hook)
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $hooksDir (Split-Path $hook -Leaf)) -Force
        Write-Host "Installed: hooks/$(Split-Path $hook -Leaf)"
    }
}
foreach ($doc in $manifest.docs) {
    $src = Join-Path $BundleRoot $doc
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $TargetCursorHome $doc) -Force
        Write-Host "Installed: $doc"
    }
}

if (-not $SkipHooks) {
    $hookCmdSession = 'powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/mas-session-context.ps1 -Event sessionStart'
    $hookCmdSubagent = 'powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/mas-session-context.ps1 -Event subagentStop'

    $hooksJsonPath = Join-Path $TargetCursorHome "hooks.json"
    $existing = $null
    if (Test-Path $hooksJsonPath) {
        try {
            $existing = Get-Content $hooksJsonPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Could not parse hooks.json; backing up and creating new."
            Copy-Item $hooksJsonPath "$hooksJsonPath.bak.mas" -Force
        }
    }
    if (-not $existing) {
        $existing = @{ version = 1; hooks = @{} }
    }
    if (-not $existing.hooks) {
        $existing | Add-Member -NotePropertyName hooks -NotePropertyValue @{} -Force
    }
    $hooksObj = @{}
    if ($existing.hooks -is [pscustomobject]) {
        $existing.hooks.PSObject.Properties | ForEach-Object { $hooksObj[$_.Name] = @($_.Value) }
    } elseif ($existing.hooks) {
        $existing.hooks.GetEnumerator() | ForEach-Object { $hooksObj[$_.Key] = $_.Value }
    }

    function Add-HookIfMissing {
        param([string]$EventName, [string]$Command)
        $entry = @{ command = $Command }
        if (-not $hooksObj.ContainsKey($EventName)) {
            $hooksObj[$EventName] = @($entry)
            return
        }
        $list = [System.Collections.ArrayList]@($hooksObj[$EventName])
        $found = $false
        foreach ($item in $list) {
            if ($item.command -eq $Command) { $found = $true; break }
        }
        if (-not $found) {
            [void]$list.Add($entry)
            $hooksObj[$EventName] = $list.ToArray()
        }
    }

    Add-HookIfMissing -EventName "sessionStart" -Command $hookCmdSession
    Add-HookIfMissing -EventName "subagentStop" -Command $hookCmdSubagent

    $out = @{ version = 1; hooks = $hooksObj }
    $out | ConvertTo-Json -Depth 8 | Set-Content $hooksJsonPath -Encoding UTF8
    Write-Host "Updated: hooks.json"
}

if ($tempExtract -and (Test-Path $tempExtract)) {
    Remove-Item $tempExtract -Recurse -Force
}

Write-Host "`nMAS installed. Reload Cursor, then type /mas or /mas-lite."
Write-Host "Bootstrap a project:"
Write-Host "  $TargetCursorHome\skills\multi-agent-system\scripts\init-mas-context.ps1 -ProjectPath <path> -Stack auto"
