#Requires -Version 5.1
<#
.SYNOPSIS
  Packages the MAS Cursor framework into a portable folder and/or zip.

.PARAMETER OutputDir
  Folder export destination. Accepts a parent directory or a path that already
  ends with mas-cursor-framework; otherwise mas-cursor-framework is appended.
  When set alone, writes the bundle folder only (no zip). Add -OutputPath to
  also create a zip from the same staged bundle.

.EXAMPLE
  .\export-mas-framework.ps1
  Creates zip on Desktop (default).

.EXAMPLE
  .\export-mas-framework.ps1 -OutputPath "D:\backups\mas-cursor-framework.zip"
  Zip only to the specified path.

.EXAMPLE
  .\export-mas-framework.ps1 -OutputDir "C:\Users\arunk\AndroidStudioProjects\mas-cursor-framework"
  Folder export only (no zip).

.EXAMPLE
  .\export-mas-framework.ps1 -OutputDir "C:\dev\out" -OutputPath "C:\dev\mas.zip"
  Folder export and zip.

.EXAMPLE
  .\export-mas-framework.ps1 -SourceCursorHome "$env:USERPROFILE\.cursor" -OutputDir "<workspace>\mas-cursor-framework"
  Export from live ~/.cursor into a workspace folder.
#>
param(
    [string]$SourceCursorHome = "",
    [string]$OutputPath = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Test-InstallParity {
    param([string]$CanonicalInstallDir)
    $frameworkRoot = (Resolve-Path (Join-Path $CanonicalInstallDir "../../..")).Path
    $rootInstall = Join-Path $frameworkRoot "install"
    if (-not (Test-Path $rootInstall)) { return }

    $compareFiles = @(
        "install-mas-framework.ps1",
        "install-mas-framework.sh",
        "install.bat",
        "manifest.json",
        "export-mas-framework.ps1"
    )

    foreach ($file in $compareFiles) {
        $canonical = Join-Path $CanonicalInstallDir $file
        $root = Join-Path $rootInstall $file
        if (Test-Path $root) {
            if (-not (Test-Path $canonical)) {
                throw "Test-InstallParity FAIL: repo install/$file exists but missing in canonical skills/multi-agent-system/install/. Remove root copy or edit canonical only."
            }
            $hCanonical = (Get-FileHash -Path $canonical -Algorithm SHA256).Hash
            $hRoot = (Get-FileHash -Path $root -Algorithm SHA256).Hash
            if ($hCanonical -ne $hRoot) {
                throw "Test-InstallParity FAIL: install/$file differs from skills/multi-agent-system/install/$file. Edit canonical path only; root install/ is export-generated or pointer-only."
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($SourceCursorHome)) {
    $SourceCursorHome = Join-Path $env:USERPROFILE ".cursor"
}
$SourceCursorHome = (Resolve-Path $SourceCursorHome).Path

$InstallDir = $PSScriptRoot
Test-InstallParity -CanonicalInstallDir $InstallDir
$ManifestPath = Join-Path $InstallDir "manifest.json"
if (-not (Test-Path $ManifestPath)) {
    throw "manifest.json not found beside this script."
}
$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mas-export-" + [guid]::NewGuid().ToString("n"))
$bundleRoot = Join-Path $stagingRoot "mas-cursor-framework"
New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null

function Copy-Rel {
    param([string]$RelativePath, [string]$DestSubdir)
    $src = Join-Path $SourceCursorHome $RelativePath
    if (-not (Test-Path $src)) {
        Write-Warning "Skip (missing): $RelativePath"
        return $false
    }
    $dest = Join-Path $bundleRoot $DestSubdir
    $destParent = Split-Path $dest -Parent
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }
    if (Test-Path $src -PathType Container) {
        Copy-Item -Path $src -Destination $dest -Recurse -Force
    } else {
        Copy-Item -Path $src -Destination $dest -Force
    }
    Write-Host "  + $RelativePath"
    return $true
}

function Resolve-BundleOutputDir {
    param([string]$Dir)
    $resolved = [System.IO.Path]::GetFullPath($Dir)
    if ($resolved -match '[\\/]mas-cursor-framework$') {
        return $resolved
    }
    return Join-Path $resolved "mas-cursor-framework"
}

function Export-BundleFolder {
    param(
        [string]$SourceBundleRoot,
        [string]$DestinationBundleRoot
    )
    if (Test-Path $DestinationBundleRoot) {
        Remove-Item $DestinationBundleRoot -Recurse -Force
    }
    $destParent = Split-Path $DestinationBundleRoot -Parent
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }
    Copy-Item -Path $SourceBundleRoot -Destination $DestinationBundleRoot -Recurse -Force
}

Write-Host "Exporting MAS from: $SourceCursorHome"
Write-Host "Staging: $bundleRoot`n"

foreach ($skill in $manifest.skills) {
    Copy-Rel -RelativePath (Join-Path "skills" $skill) -DestSubdir (Join-Path "skills" $skill) | Out-Null
}
foreach ($cmd in $manifest.commands) {
    Copy-Rel -RelativePath (Join-Path "commands" $cmd) -DestSubdir (Join-Path "commands" $cmd) | Out-Null
}
foreach ($rule in $manifest.rules) {
    Copy-Rel -RelativePath (Join-Path "rules" $rule) -DestSubdir (Join-Path "rules" $rule) | Out-Null
}
foreach ($hook in $manifest.hooks) {
    Copy-Rel -RelativePath (Join-Path "hooks" $hook) -DestSubdir (Join-Path "hooks" $hook) | Out-Null
}
foreach ($doc in $manifest.docs) {
    Copy-Rel -RelativePath $doc -DestSubdir $doc | Out-Null
}

# Always include install scripts in bundle
$installDest = Join-Path $bundleRoot "install"
New-Item -ItemType Directory -Path $installDest -Force | Out-Null
Get-ChildItem -Path $InstallDir -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $installDest $_.Name) -Force
    Write-Host "  + install/$($_.Name)"
}

# hooks.json template for installer
$hooksTemplate = @{
    version = 1
    hooks     = @{
        sessionStart  = @(
            @{ command = "MAS_HOOK_SESSION" }
        )
        subagentStop  = @(
            @{ command = "MAS_HOOK_SUBAGENT" }
        )
    }
}
$hooksTemplate | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $bundleRoot "hooks.mas.template.json") -Encoding UTF8

$wantFolderExport = -not [string]::IsNullOrWhiteSpace($OutputDir)
$wantZipExport = [string]::IsNullOrWhiteSpace($OutputDir) -or -not [string]::IsNullOrWhiteSpace($OutputPath)

if ($wantFolderExport) {
    $folderDest = Resolve-BundleOutputDir -Dir $OutputDir
    Export-BundleFolder -SourceBundleRoot $bundleRoot -DestinationBundleRoot $folderDest
    Write-Host "Exported folder: $folderDest"
}

if ($wantZipExport) {
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "mas-cursor-framework.zip"
    }
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $zipParent = Split-Path $OutputPath -Parent
    if (-not (Test-Path $zipParent)) {
        New-Item -ItemType Directory -Path $zipParent -Force | Out-Null
    }
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($bundleRoot, $OutputPath)
    Write-Host "Exported zip: $OutputPath"
}

Remove-Item $stagingRoot -Recurse -Force

Write-Host "`nDone."
if ($wantZipExport -and -not $wantFolderExport) {
    Write-Host "Copy this zip to the other machine and run install-mas-framework.ps1 or install-mas-framework.sh"
}
