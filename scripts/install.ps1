param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ToolkitArguments
)

$ToolkitScript = Join-Path $PSScriptRoot "toolkit.py"
python $ToolkitScript install @ToolkitArguments
exit $LASTEXITCODE
