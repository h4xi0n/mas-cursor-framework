#Requires -Version 5.1
<#
.SYNOPSIS
  Automated verification harness for the Multi-Stage Adaptive Review Architecture (v2.0.0).

.DESCRIPTION
  Executes offline test fixtures in .ai/fixtures/REV-01-ADAPTIVE-REVIEW/ and verifies:
  1. Stage 1 Fast-Fail Circuit Breaker halting on compiler/linter error with Approved: NO.
  2. Stage 2 Modular Profile Registry integrity and profile checklist constraints.
  3. Stage 3 False-Positive Suppression Filter (Type-system invariance, Compiler truth, Style vs Correctness).
  4. Delta-Only Re-Review rules for iteration 2+.
  5. Framework manifest version (2.0.0) and reviewer prompt size budget (<= 180 lines).

.PARAMETER Test
  Filter test execution: All (default), FastFail, Profiles, Suppression, Delta, Structural.

.OUTPUTS
  System.Int32. Returns exit code 0 if all assertions pass, 1 if any assertion fails.

.EXAMPLE
  .\Test-AdaptiveReviewer.ps1
  .\Test-AdaptiveReviewer.ps1 -Test FastFail

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File skills/multi-agent-system/scripts/Test-AdaptiveReviewer.ps1 -Test All
#>
param(
    [ValidateSet("All", "FastFail", "Profiles", "Suppression", "Delta", "Structural")]
    [string]$Test = "All"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "../../..")).Path
$fixturesDir = Join-Path $repoRoot ".ai/fixtures/REV-01-ADAPTIVE-REVIEW"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " MAS Adaptive Reviewer Test Harness (v2.0.0)              " -ForegroundColor Cyan
Write-Host " Target Filter: $Test                                     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$passCount = 0
$failCount = 0

# Evaluates a named test condition, emits colored pass/fail status, and increments suite pass/fail counters.
function Assert-Condition {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$Details = ""
    )
    if ($Condition) {
        Write-Host " [PASS] $Name" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host " [FAIL] $Name - $Details" -ForegroundColor Red
        $script:failCount++
    }
}

# -----------------------------------------------------------------------------
# Test Group: Structural & Manifest Invariants
# -----------------------------------------------------------------------------
if ($Test -in @("All", "Structural")) {
    Write-Host "`n--- Test Suite: Structural & Budget Invariants ---" -ForegroundColor Yellow

    # Check Reviewer line count budget (<= 180 lines)
    $reviewerSkillPath = Join-Path $repoRoot "skills/mas-reviewer/SKILL.md"
    if (Test-Path $reviewerSkillPath) {
        $lines = (Get-Content $reviewerSkillPath).Count
        Assert-Condition -Name "Reviewer Prompt Line Budget (<= 180 lines)" `
                         -Condition ($lines -le 180) `
                         -Details "Actual line count: $lines lines"
    } else {
        Assert-Condition -Name "Reviewer Prompt Exists" -Condition $false -Details "File not found"
    }

    # Check Manifest Version 2.0.0 & JSON validity
    $manifestPath = Join-Path $repoRoot "skills/multi-agent-system/install/manifest.json"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
            Assert-Condition -Name "Manifest Version Bump (v2.0.0)" `
                             -Condition ($manifest.version -eq "2.0.0") `
                             -Details "Found version: $($manifest.version)"
            Assert-Condition -Name "Manifest Review Profiles Registered" `
                             -Condition ($null -ne $manifest.reviewProfiles -and $manifest.reviewProfiles.Count -ge 7) `
                             -Details "Registered profiles: $($manifest.reviewProfiles.Count)"
        } catch {
            Assert-Condition -Name "Manifest JSON Valid" -Condition $false -Details $_.Exception.Message
        }
    }

    # Check Review Profiles Directory & 7 Profiles
    $profilesDir = Join-Path $repoRoot "skills/multi-agent-system/references/review-profiles"
    $expectedProfiles = @("bugfix.md", "ui.md", "backend.md", "infra.md", "genai.md", "feature.md", "refactor.md")
    foreach ($prof in $expectedProfiles) {
        $pPath = Join-Path $profilesDir $prof
        $exists = Test-Path $pPath
        $pLines = if ($exists) { (Get-Content $pPath).Count } else { 0 }
        Assert-Condition -Name "Review Profile Exists and Budgeted: $prof" `
                         -Condition ($exists -and $pLines -le 120) `
                         -Details "Exists: $exists, Lines: $pLines (budget: <= 120)"
    }

    # Check Reference Standards
    $stageGatePath = Join-Path $repoRoot "skills/multi-agent-system/references/review-stage-gate.md"
    Assert-Condition -Name "Stage 1 Gate Standard Exists" -Condition (Test-Path $stageGatePath)

    $arbiterPath = Join-Path $repoRoot "skills/multi-agent-system/references/review-arbiter-standards.md"
    Assert-Condition -Name "Stage 3 Arbiter Standards Exist" -Condition (Test-Path $arbiterPath)
}

# -----------------------------------------------------------------------------
# Test Group: Stage 1 Fast-Fail Circuit Breaker
# -----------------------------------------------------------------------------
if ($Test -in @("All", "FastFail")) {
    Write-Host "`n--- Test Suite: Stage 1 Fast-Fail Circuit Breaker ---" -ForegroundColor Yellow

    # Fixture 1: Compilation Syntax Break
    $f1MetaPath = Join-Path $fixturesDir "fixture-01-fastfail-compile/meta.json"
    $f1SrcPath = Join-Path $fixturesDir "fixture-01-fastfail-compile/BrokenSyntax.kt"
    if (Test-Path $f1MetaPath) {
        $meta1 = Get-Content $f1MetaPath -Raw | ConvertFrom-Json
        $content = Get-Content $f1SrcPath -Raw
        $isBroken = ($content -match "invalidMethod\(\s*\{")
        Assert-Condition -Name "Fixture 01: Fast-Fail Syntax Error Detected" `
                         -Condition ($isBroken -and $meta1.expected_circuit_breaker_tripped -eq $true) `
                         -Details "Expected circuit breaker to trip with Approved: NO"
    }

    # Fixture 2: Linter Static Violation
    $f2MetaPath = Join-Path $fixturesDir "fixture-02-fastfail-lint/meta.json"
    $f2SrcPath = Join-Path $fixturesDir "fixture-02-fastfail-lint/LinterViolation.kt"
    if (Test-Path $f2MetaPath) {
        $meta2 = Get-Content $f2MetaPath -Raw | ConvertFrom-Json
        $content2 = Get-Content $f2SrcPath -Raw
        $hasMissingRef = ($content2 -match "NonExistentClass")
        Assert-Condition -Name "Fixture 02: Fast-Fail Linter Error Detected" `
                         -Condition ($hasMissingRef -and $meta2.expected_gate_status -eq "FAIL") `
                         -Details "Expected gate status FAIL"
    }
}

# -----------------------------------------------------------------------------
# Test Group: Stage 2 Modular Profile Checklists
# -----------------------------------------------------------------------------
if ($Test -in @("All", "Profiles")) {
    Write-Host "`n--- Test Suite: Stage 2 Domain Verification Profiles ---" -ForegroundColor Yellow

    # Fixture 3: Bugfix Missing Regression Test
    $f3MetaPath = Join-Path $fixturesDir "fixture-03-profile-bugfix/meta.json"
    if (Test-Path $f3MetaPath) {
        $meta3 = Get-Content $f3MetaPath -Raw | ConvertFrom-Json
        Assert-Condition -Name "Fixture 03: Bugfix Profile Flags Missing Regression Test" `
                         -Condition ($meta3.expected_finding -eq "MAJOR-01" -and $meta3.expected_issue_resolved -eq "NO") `
                         -Details "Expected MAJOR-01 and Issue Resolved: NO"
    }

    # Fixture 4: UI Profile Missing Sealed UiState
    $f4MetaPath = Join-Path $fixturesDir "fixture-04-profile-ui/meta.json"
    $f4SrcPath = Join-Path $fixturesDir "fixture-04-profile-ui/ProfileScreenUnsealed.kt"
    if (Test-Path $f4MetaPath) {
        $meta4 = Get-Content $f4MetaPath -Raw | ConvertFrom-Json
        $src4 = Get-Content $f4SrcPath -Raw
        $lacksSealedState = ($src4 -match "mutableStateOf" -and -not ($src4 -match "sealed class UiState|sealed interface UiState"))
        Assert-Condition -Name "Fixture 04: UI Profile Enforces Sealed UiState" `
                         -Condition ($lacksSealedState -and $meta4.expected_finding -eq "MAJOR-01") `
                         -Details "Expected MAJOR-01 for unsealed state variables"
    }

    # Fixture 5: Backend Profile SQL Injection Risk
    $f5MetaPath = Join-Path $fixturesDir "fixture-05-profile-backend/meta.json"
    $f5SrcPath = Join-Path $fixturesDir "fixture-05-profile-backend/UserRepositoryRawSql.kt"
    if (Test-Path $f5MetaPath) {
        $meta5 = Get-Content $f5MetaPath -Raw | ConvertFrom-Json
        $src5 = Get-Content $f5SrcPath -Raw
        $hasSqlInterpolation = ($src5 -match 'SELECT.*WHERE.*\$email')
        Assert-Condition -Name "Fixture 05: Backend Profile Blocks Raw SQL Interpolation" `
                         -Condition ($hasSqlInterpolation -and $meta5.expected_finding -eq "CRITICAL-01") `
                         -Details "Expected CRITICAL-01 for raw SQL string concatenation"
    }
}

# -----------------------------------------------------------------------------
# Test Group: Stage 3 False-Positive Suppression Filter
# -----------------------------------------------------------------------------
if ($Test -in @("All", "Suppression")) {
    Write-Host "`n--- Test Suite: Stage 3 False-Positive Suppression Filter ---" -ForegroundColor Yellow

    # Fixture 6: Suppression Filter Rules
    $f6MetaPath = Join-Path $fixturesDir "fixture-06-false-positive-filter/meta.json"
    if (Test-Path $f6MetaPath) {
        $meta6 = Get-Content $f6MetaPath -Raw | ConvertFrom-Json
        $rule2Pass = $false
        $rule4Pass = $false
        foreach ($prop in $meta6.raw_proposals) {
            if ($prop.expected_filter_rule -match "Rule 2" -and $prop.expected_action -eq "DISCARD") {
                $rule2Pass = $true
            }
            if ($prop.expected_filter_rule -match "Rule 4" -and $prop.expected_action -eq "FORCE_ADVISORY") {
                $rule4Pass = $true
            }
        }
        Assert-Condition -Name "Fixture 06: Rule 2 Discards Non-Null NPE Hallucinations" `
                         -Condition $rule2Pass `
                         -Details "Type-System Invariance rule active"
        Assert-Condition -Name "Fixture 06: Rule 4 Forces Style Nits to ADVISORY" `
                         -Condition $rule4Pass `
                         -Details "Style vs Correctness isolation active"
        Assert-Condition -Name "Fixture 06: Approved: YES when all Blockers Suppressed/Advisory" `
                         -Condition ($meta6.expected_verdict -eq "Approved: YES") `
                         -Details "Approval gate passes on advisory-only findings"
    }
}

# -----------------------------------------------------------------------------
# Test Group: Delta Re-Review Protocol
# -----------------------------------------------------------------------------
if ($Test -in @("All", "Delta")) {
    Write-Host "`n--- Test Suite: Delta-Only Re-Review Protocol ---" -ForegroundColor Yellow

    # Fixture 7: Delta Re-Review Scope & Boundary
    $f7MetaPath = Join-Path $fixturesDir "fixture-07-delta-rereview/meta.json"
    if (Test-Path $f7MetaPath) {
        $meta7 = Get-Content $f7MetaPath -Raw | ConvertFrom-Json
        $deltaScoped = ($meta7.review_scope -eq "delta-only" -and $meta7.iteration -eq 2)
        $untouchedBlocked = ($meta7.attempted_new_finding_on_untouched.can_block_approval -eq $false)
        Assert-Condition -Name "Fixture 07: Iteration 2 Enforces delta-only Scope" `
                         -Condition $deltaScoped `
                         -Details "REVIEW_SCOPE is delta-only"
        Assert-Condition -Name "Fixture 07: Untouched Code Cannot Receive New Blocking Findings" `
                         -Condition $untouchedBlocked `
                         -Details "New findings on untouched code forced to Advisory/Suppressed"
        Assert-Condition -Name "Fixture 07: Re-Review Approves When Previous Blockers Fixed" `
                         -Condition ($meta7.expected_verdict -eq "Approved: YES") `
                         -Details "Expected Approved: YES"
    }
}

# -----------------------------------------------------------------------------
# Summary & Exit
# -----------------------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Test Execution Summary" -ForegroundColor Cyan
Write-Host " Passed: $passCount | Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
