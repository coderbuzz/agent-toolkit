param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$Platforms = @("claude-code", "codex", "gemini", "github-copilot", "omp", "opencode")
$ToolkitDir = Split-Path $PSScriptRoot -Parent

$Platform = ""
$PackageDir = ""
$PackageExplicit = $false
$Scope = "repository"
$TargetDir = ""
$Bundle = "core"
$Apply = $false

for ($i = 0; $i -lt $ToolkitArguments.Count; $i++) {
    $Arg = $ToolkitArguments[$i]
    switch -Regex ($Arg) {
        '^--platform$' { $Platform = $ToolkitArguments[++$i] }
        '^--platform=(.*)$' { $Platform = $Matches[1] }
        '^--package$' { $PackageDir = $ToolkitArguments[++$i]; $PackageExplicit = $true }
        '^--package=(.*)$' { $PackageDir = $Matches[1]; $PackageExplicit = $true }
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

if (-not $Platform -and -not $PackageExplicit) {
    Write-Error "Usage: install.ps1 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]"
    Write-Error "Valid platforms: $($Platforms -join ' ')"
    Write-Error "Use --package <dir> to install from a pre-generated package instead."
    exit 2
}

if ($PackageExplicit -and -not (Test-Path $PackageDir)) {
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

# Delegate to the authoritative toolkit installer so install and uninstall
# share one ledger format. scripts/uninstall.ps1 already delegates to
# toolkit.py uninstall; keeping both on toolkit.py prevents the two from
# drifting out of sync (e.g. global installs leaving empty ledgers).
$PythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $PythonCmd) { $PythonCmd = Get-Command python -ErrorAction SilentlyContinue }
if (-not $PythonCmd) {
    Write-Error "Error: Python 3 is required to run the installer."
    exit 1
}

$Args = @("install", "--scope", $Scope, "--target", $TargetDir, "--bundle", $Bundle)
if ($Platform) {
    $Args += @("--platform", $Platform)
}
if ($PackageExplicit) {
    $Args += @("--package", $PackageDir)
}
if ($Apply) {
    $Args += "--apply"
}

& $PythonCmd.Path (Join-Path $ToolkitDir "scripts\toolkit.py") @Args
exit $LASTEXITCODE
