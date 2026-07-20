param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ToolkitScript = Join-Path $PSScriptRoot "toolkit.py"
$Platforms = @("opencode", "codex", "claude-code", "github-copilot")

# Normalize: --global -> --scope global
$Normalized = @()
$HasSelector = $false
foreach ($Arg in $ToolkitArguments) {
    switch -Regex ($Arg) {
        '^--global$' {
            $Normalized += "--scope", "global"
        }
        '^--(platform|package)$' {
            $HasSelector = $true
            $Normalized += $Arg
        }
        '^--(platform|package)=' {
            $HasSelector = $true
            $Normalized += $Arg
        }
        default {
            $Normalized += $Arg
        }
    }
}

if (-not $HasSelector) {
    Write-Error "Usage: install.ps1 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]"
    Write-Error "Valid platforms: $($Platforms -join ' ')"
    Write-Error "Use --package <dir> to install from a pre-generated package instead."
    exit 2
}

python $ToolkitScript install @Normalized
exit $LASTEXITCODE
