<#
.SYNOPSIS
    Portable Agentic SDLC Toolkit Installer for Windows PowerShell (Zero Dependencies).
.EXAMPLE
    irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.ps1 | iex
    install.ps1 --platform opencode --global --apply
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$LocalScriptDir = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "manifest.json"))) {
    $LocalScriptDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path -and (Test-Path (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "manifest.json"))) {
    $LocalScriptDir = Split-Path $MyInvocation.MyCommand.Path
}

$TempDir = $null
try {
    if ($LocalScriptDir) {
        $ToolkitDir = $LocalScriptDir
    } else {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Error: git is required for remote installation."
            exit 1
        }

        $TempParent = [System.IO.Path]::GetTempPath()
        $TempDir = Join-Path $TempParent "agent-toolkit-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

        Write-Host "Cloning agent-toolkit repository..." -ForegroundColor Cyan
        git clone --quiet --depth 1 https://github.com/coderbuzz/agent-toolkit.git (Join-Path $TempDir "agent-toolkit")
        $ToolkitDir = Join-Path $TempDir "agent-toolkit"
    }

    Set-Location $ToolkitDir

    $InstallWrapper = Join-Path $ToolkitDir "scripts\install.ps1"
    & $InstallWrapper @ToolkitArguments
    exit $LASTEXITCODE
} finally {
    if ($TempDir -and (Test-Path $TempDir)) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
