$ErrorActionPreference = "Stop"
$ToolkitDir = Split-Path -Parent $PSScriptRoot
Push-Location $ToolkitDir

try {
    python scripts/toolkit.py validate
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    python -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    python scripts/toolkit.py export --all --bundle core
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    python scripts/toolkit.py validate --dist dist --bundle core
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    python scripts/toolkit.py check-drift --all --bundle core
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
