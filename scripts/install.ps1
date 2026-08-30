# Agent Toolkit Installer (PowerShell - Zero Dependencies)
#
# Installs pre-built packages from dist/ (or -Package DIR) without Python.
# Preview-first: without -Apply it only prints the plan. Never overwrites
# user-modified files; refuses conflicts and exits non-zero instead.
#
# Usage:
#   .\scripts\install.ps1 --platform opencode [--scope global|repository]
#                         [--bundle core|full|quality] [--target DIR]
#                         [--package DIR] [--apply]

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ErrorActionPreference = "Stop"

$Platforms = @("claude-code", "codex", "gemini", "github-copilot", "omp", "opencode")
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

$Platform = ""
$PackageDir = ""
$PackageExplicit = $false
$Scope = "global"
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
        '^(--repository|--scope=repository)$' { $Scope = "repository" }
        '^--scope$' { $Scope = $ToolkitArguments[++$i] }
        '^--scope=(.*)$' { $Scope = $Matches[1] }
        '^--target$' { $TargetDir = $ToolkitArguments[++$i] }
        '^--target=(.*)$' { $TargetDir = $Matches[1] }
        '^--bundle$' { $Bundle = $ToolkitArguments[++$i] }
        '^--bundle=(.*)$' { $Bundle = $Matches[1] }
        '^--apply$' { $Apply = $true }
        '^(-h|--help)$' {
            Write-Host "Usage: install.ps1 --platform <platform> [--scope global|repository] [--bundle core|full|quality] [--target DIR] [--package DIR] [--apply]"
            Write-Host "Valid platforms: $($Platforms -join ' ')"
            exit 0
        }
        default { Write-Error "Unknown argument: $Arg"; exit 2 }
    }
}

if ($Scope -ne "global" -and $Scope -ne "repository") {
    Fail "unknown scope '$Scope' (expected global or repository)"
}

if (-not $Platform -and -not $PackageExplicit) {
    Write-Error "Usage: install.ps1 --platform <platform> [--scope global|repository] [--bundle core|full|quality] [--target DIR] [--package DIR] [--apply]"
    Write-Error "Valid platforms: $($Platforms -join ' ')"
    exit 2
}

if ($Platform) {
    if ($Platforms -notcontains $Platform) {
        Fail "Unsupported platform '$Platform'. Valid platforms: $($Platforms -join ' ')"
    }
}

if (-not $PackageDir) {
    if ($Scope -eq "global") {
        $PackageDir = Join-Path $ToolkitDir "dist\global\$Platform"
    } else {
        $PackageDir = Join-Path $ToolkitDir "dist\$Platform"
    }
}

if (-not (Test-Path -LiteralPath $PackageDir -PathType Container)) {
    Write-Error "Error: Package directory '$PackageDir' does not exist."
    Write-Error "Maintainers regenerate packages with: python3 scripts/toolkit.py export --all --bundle $Bundle"
    exit 1
}

$MetaPath = Join-Path $PackageDir ".agent-toolkit-package.json"
if (-not (Test-Path -LiteralPath $MetaPath -PathType Leaf)) {
    Fail "Package metadata missing in $PackageDir"
}
$Meta = Get-Content -LiteralPath $MetaPath -Raw -Encoding UTF8 | ConvertFrom-Json

$MetaScope = if ($Meta.scope) { $Meta.scope } else { "repository" }
if ($Platform -and $Meta.platform -ne $Platform) {
    Fail "Package platform '$($Meta.platform)' does not match --platform '$Platform'"
}
if ($Meta.bundle -ne $Bundle) {
    Fail "Package bundle '$($Meta.bundle)' does not match --bundle '$Bundle'. Maintainers regenerate dist with: python3 scripts/toolkit.py export --all --bundle $Bundle"
}
if ($MetaScope -ne $Scope) {
    Fail "Package scope $MetaScope does not match --scope $Scope"
}
$Platform = $Meta.platform

if (-not $TargetDir) {
    if ($Scope -eq "global") {
        $TargetDir = $HOME
    } else {
        $TargetDir = (Get-Location).Path
    }
}
$Target = [System.IO.Path]::GetFullPath($TargetDir).TrimEnd('\', '/')
if ($Target -eq [System.IO.Path]::GetPathRoot($Target).TrimEnd('\', '/')) {
    Fail "Refusing to use the filesystem root as install target"
}

# --- Helpers ----------------------------------------------------------------

function Get-FileHash256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-RegularFile([string]$Path) {
    # A regular file: exists, is not a directory, and is not a link.
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $Item = Get-Item -LiteralPath $Path -Force
    if ($Item.PSIsContainer) { return $false }
    if ($Item.LinkType) { return $false }
    return $true
}

function Get-PackageFiles([string]$Root) {
    # Returns a hashtable of forward-slash relative path -> sha256.
    $Map = @{}
    # -Force: dot-directories (.agents, .opencode) are "hidden" on Unix.
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force | ForEach-Object {
        $Relative = $_.FullName.Substring($Root.Length + 1).Replace('\', '/')
        if ($Relative -eq ".agent-toolkit-package.json") { return }
        $Map[$Relative] = Get-FileHash256 $_.FullName
    }
    return $Map
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

function Format-InstallLedger([string]$Toolkit, [string]$Version, [string]$SourceSha,
                               [string]$PlatformName, [string]$BundleName, [string]$ScopeName,
                               [hashtable]$Files) {
    # Byte-identical to the canonical JSON produced by the other installers.
    $Paths = @($Files.Keys)
    [Array]::Sort($Paths, [System.StringComparer]::Ordinal)
    $Sb = New-Object System.Text.StringBuilder
    [void]$Sb.Append("{`n")
    [void]$Sb.Append("  ""bundle"": ""$BundleName"",`n")
    if ($Paths.Count -eq 0) {
        [void]$Sb.Append("  ""files"": {},`n")
    } else {
        [void]$Sb.Append("  ""files"": {`n")
        for ($i = 0; $i -lt $Paths.Count; $i++) {
            $Comma = ","
            if ($i -eq $Paths.Count - 1) { $Comma = "" }
            [void]$Sb.Append("    ""$($Paths[$i])"": ""$($Files[$Paths[$i]])""$Comma`n")
        }
        [void]$Sb.Append("  },`n")
    }
    [void]$Sb.Append("  ""platform"": ""$PlatformName"",`n")
    [void]$Sb.Append("  ""schema_version"": 1,`n")
    [void]$Sb.Append("  ""scope"": ""$ScopeName"",`n")
    [void]$Sb.Append("  ""source_sha256"": ""$SourceSha"",`n")
    [void]$Sb.Append("  ""toolkit"": ""$Toolkit"",`n")
    [void]$Sb.Append("  ""version"": ""$Version""`n")
    [void]$Sb.Append("}`n")
    $Sb.ToString()
}

function Format-SharedLedger([hashtable]$Records) {
    # Records: path -> @{ hash = "..."; owners = @(...) }
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

function Compose-ManagedBlock([string]$Mode, [string]$Before, [string]$Block, [string]$After) {
    if ($Mode -eq "create") { return $Block }
    if ($Mode -eq "update") { return "$Before$Block$After" }
    if ($Mode -eq "append") {
        $Base = $Before
        if ($Base) {
            if (-not $Base.EndsWith("`n")) { $Base += "`n" }
            if (-not $Base.EndsWith("`n`n")) { $Base += "`n" }
        }
        return "$Base$Block"
    }
    throw "unknown block mode: $Mode"
}

function Read-TextFile([string]$Path) {
    [System.IO.File]::ReadAllText($Path)
}

function Join-TargetPath([string]$Base, [string]$Rel) {
    [System.IO.Path]::GetFullPath((Join-Path $Base ($Rel -replace '/', '\')))
}

# --- Package inventory ------------------------------------------------------

$PackageRoot = (Get-Item -LiteralPath $PackageDir).FullName.TrimEnd('\', '/')
$PackageHashes = Get-PackageFiles $PackageRoot

$SharedList = @()
$MergeList = @()
$InstructionRel = ""
$LedgerRel = ".agent-toolkit-install.json"
if ($MetaScope -eq "global") {
    $SharedList = @($Meta.shared_skill_files)
    [Array]::Sort($SharedList, [System.StringComparer]::Ordinal)
    $MergeList = @($Meta.merge_files | ForEach-Object { @{ merge_file = $_.merge_file; target = $_.target } })
    $InstructionRel = [string]$Meta.instruction_path
    $LedgerRel = ".agent-toolkit-install-$Platform.json"
}

$Exclude = @{}
foreach ($Item in $SharedList) { $Exclude[$Item] = $true }
foreach ($Item in $MergeList) { $Exclude[$Item.merge_file] = $true }
if ($InstructionRel) { $Exclude[$InstructionRel] = $true }

$RegularFiles = @($PackageHashes.Keys | Where-Object { -not $Exclude.ContainsKey($_) })
[Array]::Sort($RegularFiles, [System.StringComparer]::Ordinal)

# --- Plan: regular files ----------------------------------------------------

$LedgerPath = Join-TargetPath $Target $LedgerRel
$Managed = Read-InstallLedger $LedgerPath
if ($null -eq $Managed) { $Managed = @{} }

$Actions = New-Object System.Collections.Generic.List[hashtable]
$Conflicts = New-Object System.Collections.Generic.List[string]
$NewLedgerFiles = @{}

foreach ($Rel in $RegularFiles) {
    $Expected = $PackageHashes[$Rel]
    $DestFull = Join-TargetPath $Target $Rel
    if (-not $DestFull.StartsWith($Target, [System.StringComparison]::OrdinalIgnoreCase)) {
        $Conflicts.Add("Unsafe relative path: $Rel"); continue
    }
    if (Test-Path -LiteralPath $DestFull) {
        if (-not (Test-RegularFile $DestFull)) {
            $Conflicts.Add("Destination is not a regular file: $Rel"); continue
        }
        $Actual = Get-FileHash256 $DestFull
        $Recorded = $Managed[$Rel]
        if ($Actual -eq $Expected) {
            if ($Recorded) {
                $Actions.Add(@{ action = "unchanged"; path = $Rel })
                $NewLedgerFiles[$Rel] = $Expected
            } else {
                $Actions.Add(@{ action = "preserve-identical-user-owned"; path = $Rel })
            }
        } elseif ($Recorded -and $Actual -eq $Recorded) {
            $Actions.Add(@{ action = "update"; path = $Rel })
            $NewLedgerFiles[$Rel] = $Expected
        } elseif ($Recorded) {
            $Conflicts.Add("User-modified managed file: $Rel")
        } else {
            $Conflicts.Add("Existing user-owned file differs: $Rel")
        }
    } else {
        $Actions.Add(@{ action = "create"; path = $Rel })
        $NewLedgerFiles[$Rel] = $Expected
    }
}

# --- Plan: stale managed files ----------------------------------------------

$Stale = @($Managed.Keys | Where-Object { $RegularFiles -notcontains $_ })
foreach ($Rel in $Stale) {
    $DestFull = Join-TargetPath $Target $Rel
    if (-not (Test-Path -LiteralPath $DestFull)) {
        $Actions.Add(@{ action = "already-removed"; path = $Rel })
    } elseif (Test-RegularFile $DestFull -and (Get-FileHash256 $DestFull) -eq $Managed[$Rel]) {
        $Actions.Add(@{ action = "remove-stale"; path = $Rel })
    } else {
        $Actions.Add(@{ action = "preserve-modified-stale"; path = $Rel })
    }
}

# --- Plan: shared skills ----------------------------------------------------

$SharedLedgerPath = Join-TargetPath $Target ".agent-toolkit-shared-skills.json"
$SharedRecords = Read-SharedLedger $SharedLedgerPath

foreach ($Rel in $SharedList) {
    if (-not $PackageHashes.ContainsKey($Rel)) {
        $Conflicts.Add("Shared skill file missing from package: $Rel"); continue
    }
    $Expected = $PackageHashes[$Rel]
    $DestFull = Join-TargetPath $Target $Rel
    if (Test-Path -LiteralPath $DestFull) {
        if (-not (Test-RegularFile $DestFull)) {
            $Conflicts.Add("Shared skill destination is not a regular file: $Rel"); continue
        }
        $Actual = Get-FileHash256 $DestFull
        $Record = $SharedRecords[$Rel]
        if ($Actual -eq $Expected) {
            if ($Record -and @($Record.owners) -contains $Platform) {
                $Actions.Add(@{ action = "shared-unchanged"; path = $Rel })
            } else {
                $Actions.Add(@{ action = "shared-adopt"; path = $Rel })
            }
        } elseif ($Record -and $Actual -eq $Record.hash) {
            $Actions.Add(@{ action = "shared-update"; path = $Rel })
        } elseif ($Record) {
            $Conflicts.Add("User-modified shared skill file: $Rel")
        } else {
            $Conflicts.Add("Existing user-owned shared skill differs: $Rel")
        }
    } else {
        $Actions.Add(@{ action = "shared-create"; path = $Rel })
    }
}

# --- Plan: codex merge + instruction block ----------------------------------

foreach ($Entry in $MergeList) {
    $MergeSource = Join-TargetPath $PackageRoot $Entry.merge_file
    if (-not (Test-RegularFile $MergeSource)) {
        $Conflicts.Add("Merge file missing from package: $($Entry.merge_file)"); continue
    }
    $DestFull = Join-TargetPath $Target $Entry.target
    $Action = $null
    if (Test-Path -LiteralPath $DestFull) {
        if (-not (Test-RegularFile $DestFull)) {
            $Conflicts.Add("Codex config is not a regular file: $($Entry.target)"); continue
        }
        $Text = Read-TextFile $DestFull
        $Split = Split-ManagedBlock $Text $CodexBlockBegin $CodexBlockEnd
        if ($Split.present) {
            $Block = Read-TextFile $MergeSource
            $Composed = Compose-ManagedBlock "update" $Split.before $Block $Split.after
            if ($Composed -eq $Text) { $Action = "unchanged" } else { $Action = "update" }
        } else {
            $Action = "append"
        }
    } else {
        $Action = "create"
    }
    $Actions.Add(@{ action = "codex-merge-$Action"; path = $Entry.target })
}

if ($InstructionRel) {
    $BodyPath = Join-TargetPath $PackageRoot $InstructionRel
    $Block = "$InstrBlockBegin`n$(Read-TextFile $BodyPath)$InstrBlockEnd`n"
    $DestFull = Join-TargetPath $Target $InstructionRel
    $Action = $null
    if (Test-Path -LiteralPath $DestFull) {
        if (-not (Test-RegularFile $DestFull)) {
            $Conflicts.Add("Instruction file is not a regular file: $InstructionRel")
        } else {
            $Text = Read-TextFile $DestFull
            $Split = Split-ManagedBlock $Text $InstrBlockBegin $InstrBlockEnd
            if ($Split.present) {
                $Composed = Compose-ManagedBlock "update" $Split.before $Block $Split.after
                if ($Composed -eq $Text) { $Action = "unchanged" } else { $Action = "update" }
            } else {
                $Action = "append"
            }
        }
    } else {
        $Action = "create"
    }
    if ($Action) { $Actions.Add(@{ action = "instruction-$Action"; path = $InstructionRel }) }
}

# --- Preview ----------------------------------------------------------------

if ($MetaScope -eq "global") {
    Write-Host "Global install plan for $Platform into ${Target}:"
} else {
    Write-Host "Install plan for ${Target}:"
}
if ($Actions.Count -gt 0) {
    foreach ($Item in $Actions) {
        Write-Host ("{0,-24} {1}" -f $Item.action, $Item.path)
    }
} else {
    Write-Host "No file actions."
}

if ($Conflicts.Count -gt 0) {
    [Console]::Error.WriteLine("Conflicts:")
    foreach ($Conflict in $Conflicts) { [Console]::Error.WriteLine("- $Conflict") }
    exit 1
}

if (-not $Apply) {
    Write-Host "Dry run only. Re-run with --apply to install."
    exit 0
}

# --- Apply ------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

function Ensure-ParentDir([string]$Path) {
    $Dir = Split-Path $Path -Parent
    if ($Dir -and -not (Test-Path -LiteralPath $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
}

foreach ($Item in $Actions) {
    $Source = Join-TargetPath $PackageRoot $Item.path
    $DestFull = Join-TargetPath $Target $Item.path
    switch ($Item.action) {
        "create" { Ensure-ParentDir $DestFull; Copy-Item -LiteralPath $Source -Destination $DestFull -Force }
        "update" { Ensure-ParentDir $DestFull; Copy-Item -LiteralPath $Source -Destination $DestFull -Force }
        "remove-stale" {
            Remove-Item -LiteralPath $DestFull -Force
            Remove-EmptyParents $DestFull $Target
        }
    }
}

$LedgerContent = Format-InstallLedger $Meta.toolkit $Meta.version $Meta.source_sha256 `
    $Platform $Meta.bundle $MetaScope $NewLedgerFiles
Write-Atomic $LedgerPath $LedgerContent

if ($MetaScope -eq "global") {
    foreach ($Item in $Actions) {
        if ($Item.action -in @("shared-create", "shared-update")) {
            $Source = Join-TargetPath $PackageRoot $Item.path
            $DestFull = Join-TargetPath $Target $Item.path
            Ensure-ParentDir $DestFull
            Copy-Item -LiteralPath $Source -Destination $DestFull -Force
        }
    }

    foreach ($Rel in $SharedList) {
        $Record = $SharedRecords[$Rel]
        $Owners = @()
        if ($Record) { $Owners = @($Record.owners) }
        if ($Owners -notcontains $Platform) { $Owners += $Platform }
        $SharedRecords[$Rel] = @{ hash = $PackageHashes[$Rel]; owners = $Owners }
    }
    if ($SharedRecords.Count -gt 0) {
        Write-Atomic $SharedLedgerPath (Format-SharedLedger $SharedRecords)
    } elseif (Test-Path -LiteralPath $SharedLedgerPath) {
        Remove-Item -LiteralPath $SharedLedgerPath -Force
    }

    foreach ($Entry in $MergeList) {
        $Block = Read-TextFile (Join-TargetPath $PackageRoot $Entry.merge_file)
        $DestFull = Join-TargetPath $Target $Entry.target
        if (-not (Test-Path -LiteralPath $DestFull)) {
            Write-Atomic $DestFull $Block
            continue
        }
        $Text = Read-TextFile $DestFull
        $Split = Split-ManagedBlock $Text $CodexBlockBegin $CodexBlockEnd
        if ($Split.present) {
            Write-Atomic $DestFull (Compose-ManagedBlock "update" $Split.before $Block $Split.after)
        } else {
            Write-Atomic $DestFull (Compose-ManagedBlock "append" $Text $Block $null)
        }
    }

    if ($InstructionRel) {
        $BodyPath = Join-TargetPath $PackageRoot $InstructionRel
        $Block = "$InstrBlockBegin`n$(Read-TextFile $BodyPath)$InstrBlockEnd`n"
        $DestFull = Join-TargetPath $Target $InstructionRel
        if (-not (Test-Path -LiteralPath $DestFull)) {
            Write-Atomic $DestFull $Block
        } else {
            $Text = Read-TextFile $DestFull
            $Split = Split-ManagedBlock $Text $InstrBlockBegin $InstrBlockEnd
            if ($Split.present) {
                Write-Atomic $DestFull (Compose-ManagedBlock "update" $Split.before $Block $Split.after)
            } else {
                Write-Atomic $DestFull (Compose-ManagedBlock "append" $Text $Block $null)
            }
        }
        if ((Test-Path -LiteralPath $DestFull) -and (Select-String -LiteralPath $DestFull -Pattern "portable-sdlc instructions" -Quiet)) {
            Write-Warning "Note: a legacy portable-sdlc managed block was detected in $DestFull."
            Write-Warning "This installer does not manage it; remove it manually if it is no longer wanted."
        }
    }

    Write-Host "Global install completed for $Platform."
} else {
    $Changed = @($Actions | Where-Object { $_.action -in @("create", "update", "remove-stale") }).Count
    Write-Host "Install completed; $Changed file action(s) changed the target."
}
