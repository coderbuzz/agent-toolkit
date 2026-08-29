#!/bin/sh
# Agent Toolkit Installer (POSIX Shell - Zero Dependencies)
# Usage:
#   ./scripts/install.sh --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

VALID_PLATFORMS="claude-code codex gemini github-copilot omp opencode"

platform=""
package_dir=""
package_explicit=0
scope="repository"
target_dir=""
bundle="core"
apply=0

while [ $# -gt 0 ]; do
    case "$1" in
        --platform)
            platform="$2"; shift 2 ;;
        --platform=*)
            platform="${1#*=}"; shift ;;
        --package)
            package_dir="$2"; package_explicit=1; shift 2 ;;
        --package=*)
            package_dir="${1#*=}"; package_explicit=1; shift ;;
        --global|--scope=global)
            scope="global"; shift ;;
        --scope)
            scope="$2"; shift 2 ;;
        --scope=*)
            scope="${1#*=}"; shift ;;
        --target)
            target_dir="$2"; shift 2 ;;
        --target=*)
            target_dir="${1#*=}"; shift ;;
        --bundle)
            bundle="$2"; shift 2 ;;
        --bundle=*)
            bundle="${1#*=}"; shift ;;
        --apply)
            apply=1; shift ;;
        -h|--help)
            echo "Usage: $0 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]" >&2
            echo "Valid platforms: $VALID_PLATFORMS" >&2
            exit 0 ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2 ;;
    esac
done

if [ -z "$platform" ] && [ -z "$package_dir" ]; then
    echo "Usage: $0 --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]" >&2
    echo "Valid platforms: $VALID_PLATFORMS" >&2
    echo "Use --package <dir> to install from a pre-generated package instead." >&2
    exit 2
fi

if [ -n "$platform" ]; then
    valid=0
    for p in $VALID_PLATFORMS; do
        if [ "$p" = "$platform" ]; then valid=1; break; fi
    done
    if [ "$valid" -eq 0 ]; then
        echo "Error: Unsupported platform '$platform'." >&2
        echo "Valid platforms: $VALID_PLATFORMS" >&2
        exit 2
    fi
fi

if [ -z "$package_dir" ] && [ -n "$platform" ]; then
    package_dir="$TOOLKIT_DIR/dist/$platform"
fi

if [ "$package_explicit" -eq 1 ] && [ ! -d "$package_dir" ]; then
    echo "Error: Package directory '$package_dir' does not exist." >&2
    exit 1
fi

if [ -z "$target_dir" ]; then
    if [ "$scope" = "global" ]; then
        target_dir="$HOME"
    else
        target_dir="."
    fi
fi

# Delegate to the authoritative toolkit installer so install and uninstall
# share one ledger format. scripts/uninstall.sh already delegates to
# toolkit.py uninstall; keeping both on toolkit.py prevents the two from
# drifting out of sync (e.g. global installs leaving empty ledgers).
scope_arg="--scope $scope"
if [ -n "$platform" ]; then
    platform_arg="--platform $platform"
else
    platform_arg=""
fi
if [ "$package_explicit" -eq 1 ]; then
    package_arg="--package $package_dir"
else
    package_arg=""
fi
if [ "$apply" -eq 1 ]; then
    apply_arg="--apply"
else
    apply_arg=""
fi

# shellcheck disable=SC2086
exec python3 scripts/toolkit.py install $platform_arg $package_arg $scope_arg --target "$target_dir" --bundle "$bundle" $apply_arg
