param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$Platforms = @("claude-code", "codex", "gemini", "github-copilot", "omp", "opencode")
$ToolkitDir = Split-Path $PSScriptRoot -Parent

if ($ToolkitArguments.Count -gt 0) {
    $PythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $PythonCmd) { $PythonCmd = Get-Command python -ErrorAction SilentlyContinue }
    if ($PythonCmd) {
        & $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") uninstall @ToolkitArguments
        exit $LASTEXITCODE
    } else {
        Write-Error "Error: Python 3 is required to run uninstallation with flags."
        exit 1
    }
}

Write-Host "┌──────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ Agent Toolkit - Uninstaller              │" -ForegroundColor Cyan
Write-Host "└──────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host "Interactive uninstaller — previews safe removals first, applies on confirmation." -ForegroundColor Gray
Write-Host ""

$ScopeInput = Read-Host "Scope - (r)epository or (g)lobal? [r]"
if ($ScopeInput -match '^(g|global)$') {
    $Scope = "global"
} else {
    $Scope = "repository"
}
Write-Host "  → scope: $Scope" -ForegroundColor Yellow

$PythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $PythonCmd) { $PythonCmd = Get-Command python -ErrorAction SilentlyContinue }
if (-not $PythonCmd) {
    Write-Error "Error: Python 3 is required to run the uninstaller."
    exit 1
}

if ($Scope -eq "repository") {
    $TargetDir = Read-Host "Target repository path [.]"
    if (-not $TargetDir) { $TargetDir = "." }
    Write-Host "  → target: $TargetDir" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "── Uninstall Preview (dry run) ───────────────────────────" -ForegroundColor Cyan
    & $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") uninstall --scope repository --target $TargetDir
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""

    $Confirm = Read-Host "Apply this uninstallation now? [y/N]"
    if ($Confirm -match '^(y|yes)$') {
        Write-Host "Applying uninstallation..." -ForegroundColor Green
        & $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") uninstall --scope repository --target $TargetDir --apply
        Write-Host "✓ Repository uninstallation complete." -ForegroundColor Green
    } else {
        Write-Host "No changes applied." -ForegroundColor Yellow
    }
} else {
    Write-Host "Select a platform to uninstall globally:" -ForegroundColor White
    for ($i = 0; $i -lt $Platforms.Count; $i++) {
        $p = $Platforms[$i]
        $tag = ""
        $GlobalLedger = Join-Path $HOME ".portable-install-$p.json"
        if (Test-Path $GlobalLedger) { $tag = " (installed)" }
        Write-Host "  $($i + 1)) $p$tag" -ForegroundColor Green
    }
    Write-Host "  a) All installed platforms" -ForegroundColor Green

    $Answer = Read-Host "Platform number, name, or 'a' for all [1]"
    if (-not $Answer) { $Answer = "1" }

    $SelectedPlatforms = @()
    if ($Answer -match '^(a|all)$') {
        $SelectedPlatforms = $Platforms
    } elseif ($Answer -match '^\d+$') {
        $idx = [int]$Answer - 1
        if ($idx -ge 0 -and $idx -lt $Platforms.Count) {
            $SelectedPlatforms = @($Platforms[$idx])
        }
    } else {
        if ($Platforms -contains $Answer) {
            $SelectedPlatforms = @($Answer)
        }
    }

    if ($SelectedPlatforms.Count -eq 0) {
        Write-Error "Invalid platform selection: $Answer"
        exit 2
    }

    Write-Host "  → selected platform(s): $($SelectedPlatforms -join ', ')" -ForegroundColor Yellow
    Write-Host ""

    foreach ($p in $SelectedPlatforms) {
        Write-Host "── Global Uninstall Preview for $p ────────────────────────" -ForegroundColor Cyan
        & $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") uninstall --scope global --platform $p
        Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host ""
    }

    $Confirm = Read-Host "Apply global uninstallation for selected platform(s)? [y/N]"
    if ($Confirm -match '^(y|yes)$') {
        Write-Host "Applying global uninstallation..." -ForegroundColor Green
        foreach ($p in $SelectedPlatforms) {
            & $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") uninstall --scope global --platform $p --apply
        }
        Write-Host "✓ Global uninstallation complete." -ForegroundColor Green
    } else {
        Write-Host "No changes applied." -ForegroundColor Yellow
    }
}
