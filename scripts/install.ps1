param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$Platforms = @("claude-code", "codex", "gemini", "github-copilot", "omp", "opencode")
$ToolkitDir = Split-Path $PSScriptRoot -Parent

$Platform = ""
$PackageDir = ""
$Scope = "repository"
$TargetDir = ""
$Bundle = "core"
$Apply = $false

for ($i = 0; $i -lt $ToolkitArguments.Count; $i++) {
    $Arg = $ToolkitArguments[$i]
    switch -Regex ($Arg) {
        '^--platform$' { $Platform = $ToolkitArguments[++$i] }
        '^--platform=(.*)$' { $Platform = $Matches[1] }
        '^--package$' { $PackageDir = $ToolkitArguments[++$i] }
        '^--package=(.*)$' { $PackageDir = $Matches[1] }
        '^(--global|--scope=global)$' { $Scope = "global" }
        '^--scope$' { $Scope = $ToolkitArguments[++$i] }
        '^--scope=(.*)$' { $Scope = $Matches[1] }
        '^--target$' { $TargetDir = $ToolkitArguments[++$i] }
        '^--target=(.*)$' { $TargetDir = $Matches[1] }
        '^--bundle$' { $Bundle = $ToolkitArguments[++$i] }
        '^--bundle=(.*)$' { $Bundle = $Matches[1] }
        '^--apply$' { $Apply = $true }
    }
}

if (-not $Platform -and -not $PackageDir) {
    Write-Error "Usage: install.ps1 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]"
    Write-Error "Valid platforms: $($Platforms -join ' ')"
    Write-Error "Use --package <dir> to install from a pre-generated package instead."
    exit 2
}

if (-not $PackageDir) {
    $PackageDir = Join-Path $ToolkitDir "dist\$Platform"
}

if (-not (Test-Path $PackageDir)) {
    Write-Error "Error: Package directory '$PackageDir' does not exist."
    exit 1
}

if (-not $TargetDir) {
    if ($Scope -eq "global") {
        $TargetDir = $HOME
    } else {
        $TargetDir = Get-Location
    }
}

Write-Host "Portable Agentic SDLC Installer (PowerShell)" -ForegroundColor Cyan
Write-Host "Platform: $Platform | Scope: $Scope | Target: $TargetDir" -ForegroundColor Gray
if ($Apply) {
    Write-Host "Mode: Applying changes." -ForegroundColor Green
} else {
    Write-Host "Mode: Preview (dry run). Pass --apply to commit changes." -ForegroundColor Yellow
}
Write-Host ""

$LedgerFile = Join-Path $TargetDir ".portable-sdlc-install.json"
if ($Scope -eq "global") {
    $LedgerFile = Join-Path $TargetDir ".portable-sdlc-install-$Platform.json"
}

if ($Scope -eq "repository") {
    $SourceFiles = Get-ChildItem -Path $PackageDir -Recurse -File | Where-Object { $_.Name -ne ".portable-sdlc-package.json" }
    $Creates = 0; $Updates = 0; $Unchanged = 0; $Conflicts = 0

    foreach ($File in $SourceFiles) {
        $RelPath = $File.FullName.Substring($PackageDir.Length + 1).Replace("\", "/")
        $DestPath = Join-Path $TargetDir $RelPath

        if (-not (Test-Path $DestPath)) {
            Write-Host "  [CREATE] $RelPath" -ForegroundColor Green
            $Creates++
        } else {
            $SrcHash = (Get-FileHash $File.FullName -Algorithm SHA256).Hash
            $DestHash = (Get-FileHash $DestPath -Algorithm SHA256).Hash

            if ($SrcHash -eq $DestHash) {
                Write-Host "  [UNCHANGED] $RelPath" -ForegroundColor DarkGray
                $Unchanged++
            } else {
                Write-Host "  [UPDATE] $RelPath" -ForegroundColor Yellow
                $Updates++
            }
        }
    }

    Write-Host ""
    Write-Host "Action totals: $Creates to create, $Updates to update, $Unchanged unchanged." -ForegroundColor White

    if (-not $Apply) {
        Write-Host "Preview complete. Re-run with --apply to perform installation." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Applying installation..." -ForegroundColor Green
    foreach ($File in $SourceFiles) {
        $RelPath = $File.FullName.Substring($PackageDir.Length + 1).Replace("\", "/")
        $DestPath = Join-Path $TargetDir $RelPath
        $Parent = Split-Path $DestPath -Parent
        if (-not (Test-Path $Parent)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }
        Copy-Item -Path $File.FullName -Destination $DestPath -Force
    }

    Write-Host "✓ Installation complete." -ForegroundColor Green
    exit 0
}

if ($Scope -eq "global") {
    if (-not $Apply) {
        Write-Host "Preview complete. Re-run with --apply to perform global installation." -ForegroundColor Yellow
        exit 0
    }

    $SkillsDest = Join-Path $TargetDir ".agents\skills"
    if (Test-Path (Join-Path $PackageDir ".agents\skills")) {
        Copy-Item -Path (Join-Path $PackageDir ".agents\skills\*") -Destination $SkillsDest -Recurse -Force
    }

    Write-Host "✓ Global installation complete." -ForegroundColor Green
    exit 0
}
