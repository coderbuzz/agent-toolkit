#!/bin/sh
# Interactive quick-start for installing the toolkit.
# Guides a first-time user through platform + scope, previews the install,
# and applies only after explicit confirmation. Preview-first is preserved.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

# Platform list is sourced from manifest.json so new platforms (e.g. omp)
# appear automatically without editing this script.
PLATFORMS=$(python3 -c "import json,sys; print(' '.join(json.load(open('manifest.json'))['platforms']))" 2>/dev/null || echo "opencode codex claude-code github-copilot omp")

# --- Terminal styling (ANSI) ---------------------------------------------
# Only enable color when stdout is a terminal and NO_COLOR is unset.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD='\033[1m'; DIM='\033[2m'; UND='\033[4m'; UNDER='\033[4m'
    RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'
    CYAN='\033[36m'; PURPLE='\033[35m'; WHITE='\033[37m'
    RESET='\033[0m'
else
    BOLD=''; DIM=''; UND=''; UNDER=''
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; PURPLE=''; WHITE=''; RESET=''
fi

# Print helpers: c_print <color> <text>   (respects the reset)
# Both the color prefix and the message are rendered with %b so any color
# codes embedded in the message are also expanded.
c_print() {
    color="$1"; shift
    printf '%b%b%b\n' "$color" "$*" "$RESET"
}
banner() {
    printf '%b' "$BOLD$CYAN"
    printf '┌──────────────────────────────────────────────────────────┐\n'
    printf '│%b %-56s %b│\n' "$RESET$BOLD$CYAN" "$1" "$CYAN"
    printf '└──────────────────────────────────────────────────────────┘%b\n' "$RESET"
}

prompt() {
    # $1 = prompt text (printed to stderr), $2 = default. Echoes the reply on stdout.
    # Reads from stdin (pipe or terminal); falls back to default on no input.
    printf '%b%s%b' "$BOLD$BLUE" "$1" "$RESET" >&2
    if read -r REPLY; then
        printf '%s' "$REPLY"
    else
        printf '%s' "$2"
    fi
}

banner "Portable Agentic SDLC Toolkit"
c_print "$DIM" "Interactive setup — previews first, applies only on your confirmation."
echo

c_print "$BOLD" "Select a platform:"
n=1
for p in $PLATFORMS; do
    c_print "$GREEN" "  $n)$RESET  $BOLD$p$RESET"
    n=$((n + 1))
done
answer=$(prompt "Platform number or name [1]: " "1")

platform=""
if echo "$answer" | grep -qE '^[0-9]+$'; then
    i=1
    for p in $PLATFORMS; do
        if [ "$i" -eq "$answer" ]; then platform="$p"; fi
        i=$((i + 1))
    done
else
    for p in $PLATFORMS; do
        if [ "$p" = "$answer" ]; then platform="$p"; fi
    done
fi
if [ -z "$platform" ]; then
    c_print "$RED" "Invalid platform selection: $answer" >&2
    exit 2
fi
c_print "$DIM" "  → platform: $BOLD$GREEN$platform"

scope=$(prompt "Scope - (r)epository or (g)lobal? [r]: " "r")
case "$scope" in
    g|G|global|Global) scope_flag="--scope global" ;;
    *) scope_flag="" ;;
esac
c_print "$DIM" "  → scope:   $BOLD$YELLOW${scope_flag:-(repository)}"

target_flag=""
if [ -z "$scope_flag" ]; then
    target=$(prompt "Target repository path [..]: " ".")
    target_flag="--target $target"
    c_print "$DIM" "  → target:  $BOLD$YELLOW$target"
fi

cmd="python3 $SCRIPT_DIR/toolkit.py install --platform $platform $scope_flag $target_flag"
echo
c_print "$UND$BOLD" "Preview command:"
c_print "$DIM" "  $cmd"
echo

# Dry-run preview first.
c_print "$BOLD$CYAN" "── Preview (dry run) ──────────────────────────────────────"
# shellcheck disable=SC2086
python3 "$SCRIPT_DIR/toolkit.py" install --platform "$platform" $scope_flag $target_flag || exit $?
c_print "$BOLD$CYAN" "──────────────────────────────────────────────────────────"
echo

confirm=$(prompt "Apply this installation now? [y/N]: " "N")
case "$confirm" in
    y|Y|yes|Yes|YES)
        c_print "$GREEN" "Applying…"
        # shellcheck disable=SC2086
        python3 "$SCRIPT_DIR/toolkit.py" install --platform "$platform" $scope_flag $target_flag --apply
        c_print "$GREEN" "✓ Done."
        ;;
    *)
        c_print "$YELLOW" "No changes applied. Re-run with --apply or use setup.sh again."
        ;;
esac
