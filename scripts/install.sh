#!/bin/sh
# Convenience wrapper around `toolkit.py install`.
# Adds a --global shorthand and a friendlier missing-platform message,
# then forwards everything else to the Python CLI (preview-first preserved).
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

PLATFORMS="opencode codex claude-code github-copilot"

# Normalize arguments: --global -> --scope global
normalized=""
has_selector=0
for arg in "$@"; do
    case "$arg" in
        --global)
            normalized="$normalized --scope global"
            ;;
        --platform|--package)
            has_selector=1
            normalized="$normalized $arg"
            ;;
        --platform=*|--package=*)
            has_selector=1
            normalized="$normalized $arg"
            ;;
        *)
            normalized="$normalized $arg"
            ;;
    esac
done

if [ "$has_selector" -eq 0 ]; then
    echo "Usage: $0 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]" >&2
    echo "Valid platforms: $PLATFORMS" >&2
    echo "Use --package <dir> to install from a pre-generated package instead." >&2
    exit 2
fi

# shellcheck disable=SC2086
exec python3 "$SCRIPT_DIR/toolkit.py" install $normalized
