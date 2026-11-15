<#
.SYNOPSIS
  Updates or validates GitHub repository metadata (description, homepage, topics, settings)
  from .github/repository-metadata.json using the GitHub CLI (gh) or GitHub REST API.

.DESCRIPTION
  Reads repository metadata from .github/repository-metadata.json, validates length constraints
  (description <= 350 characters, <= 20 lowercase kebab-case topics <= 50 characters each),
  and applies the configuration to the GitHub repository via 'gh' CLI or Invoke-RestMethod.

.PARAMETER MetadataPath
  Path to repository-metadata.json. Defaults to .github/repository-metadata.json in the repository root.

.PARAMETER Repo
  GitHub repository in 'owner/repo' format. If not provided, inferred from git remote or metadata.

.PARAMETER Token
  GitHub Personal Access Token (PAT). If not provided, checks $env:GITHUB_TOKEN or $env:GH_TOKEN.

.PARAMETER DescriptionKey
  Key for description to apply. Options: 'primary' (default), or any key from 'alternative_descriptions'
  (e.g., 'developer_centric', 'enterprise_governance', 'action_oriented').

.PARAMETER ValidateOnly
  Validates metadata schema and constraints without making API calls or modifications.

.PARAMETER DryRun
  Validates and previews API payloads without applying changes to GitHub.

.PARAMETER Method
  API execution method: 'Auto' (prefer gh if authenticated, fallback to RestApi), 'GhCli', or 'RestApi'.

.EXAMPLE
  # Validate metadata file only
  .\update-github-repository-metadata.ps1 -ValidateOnly

.EXAMPLE
  # Dry-run preview with GitHub REST API
  .\update-github-repository-metadata.ps1 -DryRun

.EXAMPLE
  # Apply metadata using an alternative description
  .\update-github-repository-metadata.ps1 -DescriptionKey developer_centric -Token $myPat
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$MetadataPath,

    [Parameter(Mandatory = $false)]
    [string]$Repo,

    [Parameter(Mandatory = $false)]
    [string]$Token,

    [Parameter(Mandatory = $false)]
    [string]$DescriptionKey = "primary",

    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "GhCli", "RestApi")]
    [string]$Method = "Auto"
)

$ErrorActionPreference = "Stop"

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-WarnMessage([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage([string]$Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Resolve repository root and metadata path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path

if ([string]::IsNullOrWhiteSpace($MetadataPath)) {
    $MetadataPath = Join-Path $RepoRoot ".github\repository-metadata.json"
}

if (-not (Test-Path $MetadataPath)) {
    Write-ErrorMessage "Metadata file not found at: $MetadataPath"
    exit 1
}

Write-Info "Loading repository metadata from: $MetadataPath"

try {
    $RawJson = Get-Content -Path $MetadataPath -Raw -Encoding UTF8
    $Metadata = $RawJson | ConvertFrom-Json
} catch {
    Write-ErrorMessage "Failed to parse JSON in metadata file: $_"
    exit 1
}

# -------------------------------------------------------------
# Validation Phase
# -------------------------------------------------------------
$ValidationErrors = @()

# 1. Validate primary description
$PrimaryDesc = $Metadata.description
if ([string]::IsNullOrWhiteSpace($PrimaryDesc)) {
    $ValidationErrors += "Field 'description' must not be empty."
} else {
    $PrimaryLen = $PrimaryDesc.Length
    if ($PrimaryLen -gt 350) {
        $ValidationErrors += "Primary description exceeds GitHub 350-character limit ($PrimaryLen chars)."
    } else {
        Write-Info "Primary description length: $PrimaryLen / 350 characters (OK)."
    }
}

# 2. Validate alternative descriptions if present
if ($null -ne $Metadata.alternative_descriptions) {
    $AltDescs = $Metadata.alternative_descriptions
    foreach ($Prop in $AltDescs.PSObject.Properties) {
        $AltKey = $Prop.Name
        $AltVal = $Prop.Value
        if (-not [string]::IsNullOrWhiteSpace($AltVal)) {
            $AltLen = $AltVal.Length
            if ($AltLen -gt 350) {
                $ValidationErrors += "Alternative description '$AltKey' exceeds 350 characters ($AltLen chars)."
            } else {
                Write-Info "Alternative description '$AltKey' length: $AltLen / 350 characters (OK)."
            }
        }
    }
}

# 3. Validate chosen description key
$SelectedDescription = $PrimaryDesc
if ($DescriptionKey -ne "primary" -and $DescriptionKey -ne "default") {
    if ($null -eq $Metadata.alternative_descriptions -or -not ($Metadata.alternative_descriptions.PSObject.Properties.Name -contains $DescriptionKey)) {
        $ValidationErrors += "DescriptionKey '$DescriptionKey' not found in 'alternative_descriptions'."
    } else {
        $SelectedDescription = $Metadata.alternative_descriptions.$DescriptionKey
        Write-Info "Selected alternative description '$DescriptionKey' ($($SelectedDescription.Length) chars)."
    }
}

# 4. Validate homepage URL
if (-not [string]::IsNullOrWhiteSpace($Metadata.homepage)) {
    $IsValidUri = [System.Uri]::IsWellFormedUriString($Metadata.homepage, [System.UriKind]::Absolute)
    if (-not $IsValidUri) {
        $ValidationErrors += "Field 'homepage' ('$($Metadata.homepage)') is not a well-formed absolute URL."
    }
}

# 5. Validate topics array
$Topics = @($Metadata.topics)
if ($Topics.Count -gt 20) {
    $ValidationErrors += "Topics count ($($Topics.Count)) exceeds GitHub maximum of 20 topics."
} else {
    Write-Info "Topics count: $($Topics.Count) / 20 topics."
}

$TopicRegex = '^[a-z0-9]+(-[a-z0-9]+)*$'
foreach ($Topic in $Topics) {
    if ($Topic.Length -gt 50) {
        $ValidationErrors += "Topic '$Topic' exceeds 50-character limit ($($Topic.Length) chars)."
    }
    if ($Topic -notmatch $TopicRegex) {
        $ValidationErrors += "Topic '$Topic' is invalid. Topics must be lowercase alphanumeric and single hyphens (kebab-case)."
    }
}

if ($ValidationErrors.Count -gt 0) {
    Write-ErrorMessage "Metadata validation failed with $($ValidationErrors.Count) error(s):"
    foreach ($Err in $ValidationErrors) {
        Write-Host "  - $Err" -ForegroundColor Red
    }
    exit 1
}

Write-Success "Metadata validation passed successfully."

if ($ValidateOnly) {
    Write-Success "Validation-only mode requested. Exiting."
    exit 0
}

# -------------------------------------------------------------
# Resolve Target Repository
# -------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Repo)) {
    # Try git remote origin
    try {
        $RemoteUrl = git config --get remote.origin.url 2>$null
        if ($RemoteUrl -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/\.]+)(\.git)?') {
            $Repo = "$($Matches['owner'])/$($Matches['repo'])"
            Write-Info "Inferred repository from git remote: $Repo"
        }
    } catch {
        # ignore git error
    }
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    if (-not [string]::IsNullOrWhiteSpace($Metadata.owner) -and -not [string]::IsNullOrWhiteSpace($Metadata.name)) {
        $Repo = "$($Metadata.owner)/$($Metadata.name)"
        Write-Info "Inferred repository from metadata file: $Repo"
    }
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-ErrorMessage "Could not determine target repository. Please specify -Repo 'owner/repo'."
    exit 1
}

# -------------------------------------------------------------
# Prepare Payloads
# -------------------------------------------------------------
$RepoPayload = [ordered]@{
    description = $SelectedDescription
    homepage    = $Metadata.homepage
}

if ($null -ne $Metadata.private) { $RepoPayload["private"] = [bool]$Metadata.private }
if ($null -ne $Metadata.has_issues) { $RepoPayload["has_issues"] = [bool]$Metadata.has_issues }
if ($null -ne $Metadata.has_projects) { $RepoPayload["has_projects"] = [bool]$Metadata.has_projects }
if ($null -ne $Metadata.has_wiki) { $RepoPayload["has_wiki"] = [bool]$Metadata.has_wiki }
if ($null -ne $Metadata.allow_squash_merge) { $RepoPayload["allow_squash_merge"] = [bool]$Metadata.allow_squash_merge }
if ($null -ne $Metadata.allow_merge_commit) { $RepoPayload["allow_merge_commit"] = [bool]$Metadata.allow_merge_commit }
if ($null -ne $Metadata.allow_rebase_merge) { $RepoPayload["allow_rebase_merge"] = [bool]$Metadata.allow_rebase_merge }
if ($null -ne $Metadata.delete_branch_on_merge) { $RepoPayload["delete_branch_on_merge"] = [bool]$Metadata.delete_branch_on_merge }

$TopicsPayload = [ordered]@{
    names = $Topics
}

$RepoJson = $RepoPayload | ConvertTo-Json -Depth 5
$TopicsJson = $TopicsPayload | ConvertTo-Json -Depth 5

if ($DryRun) {
    Write-Host "`n--- [DRY RUN PREVIEW] ---" -ForegroundColor Yellow
    Write-Host "Target Repository: $Repo" -ForegroundColor Yellow
    Write-Host "`nPATCH /repos/$Repo Payload:" -ForegroundColor Yellow
    Write-Host $RepoJson
    Write-Host "`nPUT /repos/$Repo/topics Payload:" -ForegroundColor Yellow
    Write-Host $TopicsJson
    Write-Host "--------------------------`n" -ForegroundColor Yellow
    Write-Success "Dry-run preview completed. No changes were applied."
    exit 0
}

# -------------------------------------------------------------
# Determine Execution Method & Auth
# -------------------------------------------------------------
$GhAvailable = $false
try {
    $null = Get-Command gh -ErrorAction SilentlyContinue
    if ($?) { $GhAvailable = $true }
} catch {
    $GhAvailable = $false
}

if ([string]::IsNullOrWhiteSpace($Token)) {
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $Token = $env:GITHUB_TOKEN
    } elseif (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
        $Token = $env:GH_TOKEN
    }
}

$ExecuteViaGh = $false
if ($Method -eq "GhCli") {
    if (-not $GhAvailable) {
        Write-ErrorMessage "Method 'GhCli' was explicitly requested, but 'gh' executable was not found on PATH."
        exit 1
    }
    $ExecuteViaGh = $true
} elseif ($Method -eq "RestApi") {
    $ExecuteViaGh = $false
} else { # Auto
    if ($GhAvailable) {
        # Check if authenticated
        $AuthCheck = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ExecuteViaGh = $true
            Write-Info "Using GitHub CLI ('gh') authenticated session."
        } else {
            Write-WarnMessage "'gh' CLI found but not authenticated. Falling back to REST API with token."
        }
    }
}

# -------------------------------------------------------------
# Apply Updates
# -------------------------------------------------------------
if ($ExecuteViaGh) {
    Write-Info "Updating repository settings via gh api..."
    $TempRepoFile = [System.IO.Path]::GetTempFileName()
    $TempTopicsFile = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($TempRepoFile, $RepoJson, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($TempTopicsFile, $TopicsJson, [System.Text.Encoding]::UTF8)

        # 1. Update repo settings
        gh api -X PATCH "repos/$Repo" --input $TempRepoFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update repository settings via gh api."
        }
        Write-Success "Repository settings updated successfully."

        # 2. Update topics
        gh api -X PUT "repos/$Repo/topics" -H "Accept: application/vnd.github+json" --input $TempTopicsFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update topics via gh api."
        }
        Write-Success "Repository topics updated successfully."
    } finally {
        if (Test-Path $TempRepoFile) { Remove-Item -Force $TempRepoFile }
        if (Test-Path $TempTopicsFile) { Remove-Item -Force $TempTopicsFile }
    }
} else {
    # Execute via Invoke-RestMethod
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-ErrorMessage "GitHub authentication token is required for REST API calls."
        Write-Host "Set `$env:GITHUB_TOKEN or pass -Token <PAT> with repo permissions." -ForegroundColor Yellow
        exit 1
    }

    $Headers = @{
        "Accept"               = "application/vnd.github+json"
        "Authorization"        = "Bearer $Token"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent"           = "MAS-Framework-Repository-Updater"
    }

    Write-Info "Updating repository settings via GitHub REST API (PATCH /repos/$Repo)..."
    try {
        $PatchUri = "https://api.github.com/repos/$Repo"
        $null = Invoke-RestMethod -Uri $PatchUri -Method Patch -Headers $Headers -Body $RepoJson -ContentType "application/json; charset=utf-8"
        Write-Success "Repository settings updated successfully."
    } catch {
        Write-ErrorMessage "Failed to update repository settings: $_"
        if ($_.Exception.Response) {
            $Stream = $_.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($Stream)
            Write-Host "Response: $($Reader.ReadToEnd())" -ForegroundColor Red
        }
        exit 1
    }

    Write-Info "Updating repository topics via GitHub REST API (PUT /repos/$Repo/topics)..."
    try {
        $TopicsUri = "https://api.github.com/repos/$Repo/topics"
        $null = Invoke-RestMethod -Uri $TopicsUri -Method Put -Headers $Headers -Body $TopicsJson -ContentType "application/json; charset=utf-8"
        Write-Success "Repository topics updated successfully."
    } catch {
        Write-ErrorMessage "Failed to update repository topics: $_"
        if ($_.Exception.Response) {
            $Stream = $_.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($Stream)
            Write-Host "Response: $($Reader.ReadToEnd())" -ForegroundColor Red
        }
        exit 1
    }
}

Write-Success "GitHub repository metadata synchronization completed for $Repo."
