# Agent Toolkit Uninstaller (PowerShell - Zero Dependencies)
#
# Previews and removes only files the installer recorded in its ledger.
# User-modified files are preserved and reported. Without -Apply it only
# prints the plan.
#
# Usage:
#   .\scripts\uninstall.ps1 --scope global --platform <platform> [--apply]
#   .\scripts\uninstall.ps1 --scope repository [--target DIR] [--apply]

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$Platforms = @("claude-code", "codex", "gemini", "github-copilot", "omp", "opencode", "zcode")
$ToolkitDir = Split-Path $PSScriptRoot -Parent

$CodexBlockBegin = "# >>> agent-toolkit agents (managed; do not edit) >>>"
$CodexBlockEnd = "# <<< agent-toolkit agents (managed) <<<"
$InstrBlockBegin = "# >>> agent-toolkit instructions (managed; do not edit) >>>"
$InstrBlockEnd = "# <<< agent-toolkit instructions (managed) <<<"

function Fail([string]$Message) {
    Write-Error "Error: $Message"
    exit 1
}

# --- Argument parsing -------------------------------------------------------

$Scope = "global"
$Platform = ""
$TargetDir = ""
$Apply = $false

for ($i = 0; $i -lt $ToolkitArguments.Count; $i++) {
    $Arg = $ToolkitArguments[$i]
    switch -Regex ($Arg) {
        '^--platform$' { $Platform = $ToolkitArguments[++$i] }
        '^--platform=(.*)$' { $Platform = $Matches[1] }
        '^(--global|--scope=global)$' { $Scope = "global" }
        '^(--repository|--scope=repository)$' { $Scope = "repository" }
        '^--scope$' { $Scope = $ToolkitArguments[++$i] }
        '^--scope=(.*)$' { $Scope = $Matches[1] }
        '^--target$' { $TargetDir = $ToolkitArguments[++$i] }
        '^--target=(.*)$' { $TargetDir = $Matches[1] }
        '^--apply$' { $Apply = $true }
        '^(-h|--help)$' {
            Write-Host "Usage: uninstall.ps1 [--scope global|repository] [--platform <platform>] [--target DIR] [--apply]"
            Write-Host "Default scope is global and requires --platform. Valid platforms: $($Platforms -join ' ')"
            exit 0
        }
        default { Write-Error "Unknown argument: $Arg"; exit 2 }
    }
}

if ($Scope -ne "global" -and $Scope -ne "repository") {
    Fail "unknown scope '$Scope' (expected global or repository)"
}

if ($Scope -eq "global" -and -not $Platform) {
    Write-Error "Usage: uninstall.ps1 [--scope global|repository] [--platform <platform>] [--target DIR] [--apply]"
    Write-Error "Default scope is global and requires --platform. Valid platforms: $($Platforms -join ' ')"
    exit 2
}

if ($Platform -and $Platforms -notcontains $Platform) {
    Fail "Unsupported platform '$Platform'. Valid platforms: $($Platforms -join ' ')"
}

if (-not $TargetDir) {
    if ($Scope -eq "global") {
        $TargetDir = $HOME
    } else {
        $TargetDir = (Get-Location).Path
    }
}
$Target = [System.IO.Path]::GetFullPath($TargetDir).TrimEnd('\', '/')
if ($Target -eq [System.IO.Path]::GetPathRoot($Target).TrimEnd('\', '/')) {
    Fail "Refusing to use the filesystem root as uninstall target"
}

# --- Helpers ----------------------------------------------------------------

function Get-FileHash256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-RegularFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $Item = Get-Item -LiteralPath $Path -Force
    if ($Item.PSIsContainer) { return $false }
    if ($Item.LinkType) { return $false }
    return $true
}

function Write-Atomic([string]$Path, [string]$Content) {
    $Dir = Split-Path $Path -Parent
    if ($Dir -and -not (Test-Path -LiteralPath $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $Temporary = "$Path.agent-toolkit-tmp"
    [System.IO.File]::WriteAllText($Temporary, $Content, $Utf8NoBom)
    Move-Item -LiteralPath $Temporary -Destination $Path -Force
}

function Remove-EmptyParents([string]$Path, [string]$Root) {
    $Cursor = [System.IO.Path]::GetFullPath((Split-Path $Path -Parent))
    while ($Cursor.StartsWith($Root) -and $Cursor.Length -gt $Root.Length) {
        try {
            [System.IO.Directory]::Delete($Cursor, $false)
        } catch { break }
        $Cursor = [System.IO.Path]::GetFullPath((Split-Path $Cursor -Parent))
    }
}

function Read-InstallLedger([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $Ledger = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($Ledger.schema_version -ne 1) { Fail "Unsupported or invalid install ledger: $Path" }
    $Files = @{}
    foreach ($Property in $Ledger.files.PSObject.Properties) {
        $Files[$Property.Name] = [string]$Property.Value
    }
    return $Files
}

function Read-SharedLedger([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @{} }
    $Ledger = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($Ledger.schema_version -ne 1) { Fail "Unsupported or invalid shared skills ledger: $Path" }
    $Records = @{}
    foreach ($Property in $Ledger.files.PSObject.Properties) {
        $Records[$Property.Name] = @{
            hash = [string]$Property.Value.hash
            owners = @($Property.Value.owners)
        }
    }
    return $Records
}

function Format-SharedLedger([hashtable]$Records) {
    $Paths = @($Records.Keys)
    [Array]::Sort($Paths, [System.StringComparer]::Ordinal)
    $Sb = New-Object System.Text.StringBuilder
    [void]$Sb.Append("{`n")
    if ($Paths.Count -eq 0) {
        [void]$Sb.Append("  ""files"": {},`n")
    } else {
        [void]$Sb.Append("  ""files"": {`n")
        for ($i = 0; $i -lt $Paths.Count; $i++) {
            $Path = $Paths[$i]
            $Record = $Records[$Path]
            $Comma = ","
            if ($i -eq $Paths.Count - 1) { $Comma = "" }
            [void]$Sb.Append("    ""$Path"": {`n")
            [void]$Sb.Append("      ""hash"": ""$($Record.hash)"",`n")
            if (@($Record.owners).Count -eq 0) {
                [void]$Sb.Append("      ""owners"": []`n")
            } else {
                [void]$Sb.Append("      ""owners"": [`n")
                $Owners = @($Record.owners)
                [Array]::Sort($Owners, [System.StringComparer]::Ordinal)
                for ($j = 0; $j -lt $Owners.Count; $j++) {
                    $OwnerComma = ","
                    if ($j -eq $Owners.Count - 1) { $OwnerComma = "" }
                    [void]$Sb.Append("        ""$($Owners[$j])""$OwnerComma`n")
                }
                [void]$Sb.Append("      ]`n")
            }
            [void]$Sb.Append("    }$Comma`n")
        }
        [void]$Sb.Append("  },`n")
    }
    [void]$Sb.Append("  ""schema_version"": 1`n")
    [void]$Sb.Append("}`n")
    $Sb.ToString()
}

function Split-ManagedBlock([string]$Text, [string]$Begin, [string]$End) {
    $BeginIndex = $Text.IndexOf($Begin)
    if ($BeginIndex -lt 0) { return @{ before = $Text; after = $null; present = $false } }
    $EndIndex = $Text.IndexOf($End, $BeginIndex + $Begin.Length)
    if ($EndIndex -lt 0) { throw "Malformed managed block: missing end marker" }
    $EndIndex += $End.Length
    if ($EndIndex -lt $Text.Length -and $Text[$EndIndex] -eq "`n") { $EndIndex++ }
    return @{
        before = $Text.Substring(0, $BeginIndex)
        after = $Text.Substring($EndIndex)
        present = $true
    }
}

function Read-AdapterGlobal([string]$PlatformName, [string]$Key) {
    $AdapterPath = Join-Path $ToolkitDir "platforms\$PlatformName\adapter.json"
    if (-not (Test-Path -LiteralPath $AdapterPath -PathType Leaf)) {
        Fail "Missing adapter descriptor for $PlatformName"
    }
    $Adapter = Get-Content -LiteralPath $AdapterPath -Raw -Encoding UTF8 | ConvertFrom-Json
    [string]$Adapter.global.$Key
}

function Read-TextFile([string]$Path) {
    [System.IO.File]::ReadAllText($Path)
}

# --- Plan -------------------------------------------------------------------

if ($Scope -eq "global") {
    $LedgerPath = Join-Path $Target ".agent-toolkit-install-$Platform.json"
} else {
    $LedgerPath = Join-Path $Target ".agent-toolkit-install.json"
}

$Managed = Read-InstallLedger $LedgerPath
if ($null -eq $Managed) { $Managed = @{} }

$Actions = New-Object System.Collections.Generic.List[hashtable]
$Warnings = New-Object System.Collections.Generic.List[string]

foreach ($Rel in @($Managed.Keys)) {
    $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($Rel -replace '/', '\')))
    if (-not (Test-Path -LiteralPath $DestFull)) {
        $Actions.Add(@{ action = "already-removed"; path = $Rel })
    } elseif (Test-RegularFile $DestFull -and (Get-FileHash256 $DestFull) -eq $Managed[$Rel]) {
        $Actions.Add(@{ action = "remove"; path = $Rel })
    } else {
        $Actions.Add(@{ action = "preserve-modified"; path = $Rel })
        $Warnings.Add("Preserving modified or non-regular file: $Rel")
    }
}

$SharedKept = @{}
$InstructionRel = ""
$AgentStrategy = ""
$AgentConfig = ""

if ($Scope -eq "global") {
    $SharedLedgerPath = Join-Path $Target ".agent-toolkit-shared-skills.json"
    $SharedRecords = Read-SharedLedger $SharedLedgerPath

    foreach ($Rel in @($SharedRecords.Keys)) {
        $Record = $SharedRecords[$Rel]
        if (@($Record.owners) -notcontains $Platform) {
            $SharedKept[$Rel] = $Record
            continue
        }
        $Remaining = @($Record.owners | Where-Object { $_ -ne $Platform })
        if ($Remaining.Count -gt 0) {
            $Actions.Add(@{ action = "shared-release"; path = $Rel })
            $SharedKept[$Rel] = @{ hash = $Record.hash; owners = $Remaining }
            continue
        }
        $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($Rel -replace '/', '\')))
        if (-not (Test-Path -LiteralPath $DestFull)) {
            $Actions.Add(@{ action = "shared-already-removed"; path = $Rel })
        } elseif (Test-RegularFile $DestFull -and (Get-FileHash256 $DestFull) -eq $Record.hash) {
            $Actions.Add(@{ action = "shared-remove"; path = $Rel })
        } else {
            $Actions.Add(@{ action = "shared-preserve-modified"; path = $Rel })
            $Warnings.Add("Preserving modified shared skill file: $Rel")
        }
    }

    $InstructionRel = Read-AdapterGlobal $Platform "instruction_path"
    $AgentStrategy = Read-AdapterGlobal $Platform "agent_strategy"
    $AgentConfig = Read-AdapterGlobal $Platform "agent_config_path"

    if ($AgentStrategy -eq "toml-managed-block" -and $AgentConfig) {
        $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($AgentConfig -replace '/', '\')))
        $Present = $false
        if (Test-RegularFile $DestFull) {
            $Split = Split-ManagedBlock (Read-TextFile $DestFull) $CodexBlockBegin $CodexBlockEnd
            $Present = $Split.present
        }
        if ($Present) {
            $Actions.Add(@{ action = "codex-unmerge-remove"; path = $AgentConfig })
        } else {
            $Actions.Add(@{ action = "codex-unmerge-absent"; path = $AgentConfig })
        }
    }

    if ($InstructionRel) {
        $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($InstructionRel -replace '/', '\')))
        if (Test-RegularFile $DestFull) {
            $Split = Split-ManagedBlock (Read-TextFile $DestFull) $InstrBlockBegin $InstrBlockEnd
            if ($Split.present) {
                $Actions.Add(@{ action = "instruction-unblock-remove"; path = $InstructionRel })
            }
        }
    }
}

# --- Preview ----------------------------------------------------------------

if ($Scope -eq "global") {
    Write-Host "Global uninstall plan for $Platform from ${Target}:"
} else {
    Write-Host "Uninstall plan for ${Target}:"
}
if ($Actions.Count -gt 0) {
    foreach ($Item in $Actions) {
        Write-Host ("{0,-24} {1}" -f $Item.action, $Item.path)
    }
} else {
    Write-Host "No managed files found."
}

foreach ($Warning in $Warnings) {
    [Console]::Error.WriteLine("Warning: $Warning")
}

if (-not $Apply) {
    Write-Host "Dry run only. Re-run with --apply to uninstall."
    exit 0
}

# --- Apply ------------------------------------------------------------------

$Removed = 0
foreach ($Item in $Actions) {
    $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($Item.path -replace '/', '\')))
    switch ($Item.action) {
        "remove" {
            Remove-Item -LiteralPath $DestFull -Force
            Remove-EmptyParents $DestFull $Target
            $Removed++
        }
        "shared-remove" {
            if (Test-RegularFile $DestFull) {
                Remove-Item -LiteralPath $DestFull -Force
                Remove-EmptyParents $DestFull $Target
            }
        }
    }
}

if (Test-Path -LiteralPath $LedgerPath) {
    Remove-Item -LiteralPath $LedgerPath -Force
}

if ($Scope -eq "global") {
    if ($SharedKept.Count -gt 0) {
        Write-Atomic $SharedLedgerPath (Format-SharedLedger $SharedKept)
    } elseif (Test-Path -LiteralPath $SharedLedgerPath) {
        Remove-Item -LiteralPath $SharedLedgerPath -Force
    }

    if ($AgentStrategy -eq "toml-managed-block" -and $AgentConfig) {
        $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($AgentConfig -replace '/', '\')))
        if (Test-RegularFile $DestFull) {
            $Split = Split-ManagedBlock (Read-TextFile $DestFull) $CodexBlockBegin $CodexBlockEnd
            if ($Split.present) {
                $After = "$($Split.before)$($Split.after)"
                if ($After.Trim().Length -eq 0) {
                    Remove-Item -LiteralPath $DestFull -Force
                    Remove-EmptyParents $DestFull $Target
                } else {
                    Write-Atomic $DestFull $After
                }
            }
        }
    }

    if ($InstructionRel) {
        $DestFull = [System.IO.Path]::GetFullPath((Join-Path $Target ($InstructionRel -replace '/', '\')))
        if (Test-RegularFile $DestFull) {
            $Split = Split-ManagedBlock (Read-TextFile $DestFull) $InstrBlockBegin $InstrBlockEnd
            if ($Split.present) {
                $After = "$($Split.before)$($Split.after)"
                if ($After.Trim().Length -eq 0) {
                    Remove-Item -LiteralPath $DestFull -Force
                    Remove-EmptyParents $DestFull $Target
                } else {
                    Write-Atomic $DestFull $After
                }
            }
        }
    }

    Write-Host "Global uninstall completed for $Platform."
} else {
    Write-Host "Uninstall completed; removed $Removed unchanged managed file(s)."
}

if ($Warnings.Count -gt 0) { exit 2 }
exit 0
