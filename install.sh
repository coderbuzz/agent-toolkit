#!/usr/bin/env bash
# Agent Toolkit Installer (POSIX Shell - Zero Dependencies)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash -s -- --platform opencode --global --apply
#   ./install.sh --platform opencode --global --apply

set -eu

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
elif [ -f "$0" ] && [ "$0" != "bash" ] && [ "$0" != "sh" ]; then
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fi

TMP_DIR=""
cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/manifest.json" ] && [ -f "$SCRIPT_DIR/scripts/install.sh" ]; then
    TOOLKIT_DIR="$SCRIPT_DIR"
else
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required for remote installation." >&2
        exit 1
    fi

    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'agent-toolkit')
    echo "Cloning agent-toolkit repository..." >&2
    git clone --quiet --depth 1 https://github.com/coderbuzz/agent-toolkit.git "$TMP_DIR/agent-toolkit"
    TOOLKIT_DIR="$TMP_DIR/agent-toolkit"
fi

cd "$TOOLKIT_DIR"

if [ $# -eq 0 ]; then
    if [ -t 0 ] || [ -c /dev/tty ]; then
        if [ ! -t 0 ] && [ -c /dev/tty ]; then
            exec ./scripts/setup.sh < /dev/tty
        else
            exec ./scripts/setup.sh
        fi
    else
        echo "Usage: install.sh --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]" >&2
        PLATFORMS="claude-code codex gemini github-copilot omp opencode"
        echo "Valid platforms: $PLATFORMS" >&2
        exit 2
    fi
else
    exec ./scripts/install.sh "$@"
fi
