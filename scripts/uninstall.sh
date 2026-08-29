#!/bin/sh
# Interactive uninstaller for the Agent Toolkit (POSIX Shell - Zero Dependencies).
# Guides a user through previewing and removing installed toolkit files safely.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

VALID_PLATFORMS="claude-code codex gemini github-copilot omp opencode"

# Terminal styling (ANSI)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD='\033[1m'; DIM='\033[2m'; UND='\033[4m'
    RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'
    CYAN='\033[36m'; RESET='\033[0m'
else
    BOLD=''; DIM=''; UND=''
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; RESET=''
fi

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
    printf '%b%s%b' "$BOLD$BLUE" "$1" "$RESET" >&2
    if read -r REPLY; then
        printf '%s' "$REPLY"
    else
        printf '%s' "$2"
    fi
}

# If arguments are passed, pass directly to python3 toolkit.py uninstall
if [ $# -gt 0 ]; then
    exec python3 scripts/toolkit.py uninstall "$@"
fi

banner "Agent Toolkit - Uninstaller"
c_print "$DIM" "Interactive uninstaller — previews safe removals first, applies on confirmation."
echo

# Scope selection
scope_input=$(prompt "Scope - (r)epository or (g)lobal? [r]: " "r")
case "$scope_input" in
    g|G|global|Global) scope="global" ;;
    *) scope="repository" ;;
esac
c_print "$DIM" "  → scope: $BOLD$YELLOW$scope$RESET"

target_dir=""
platform=""

if [ "$scope" = "repository" ]; then
    target_dir=$(prompt "Target repository path [.]: " ".")
    c_print "$DIM" "  → target: $BOLD$YELLOW$target_dir$RESET"
    
    echo
    c_print "$BOLD$CYAN" "── Uninstall Preview (dry run) ───────────────────────────"
    python3 scripts/toolkit.py uninstall --scope repository --target "$target_dir" || true
    c_print "$BOLD$CYAN" "──────────────────────────────────────────────────────────"
    echo

    confirm=$(prompt "Apply this uninstallation now? [y/N]: " "N")
    case "$confirm" in
        y|Y|yes|Yes|YES)
            c_print "$GREEN" "Applying uninstallation…"
            python3 scripts/toolkit.py uninstall --scope repository --target "$target_dir" --apply
            c_print "$GREEN" "✓ Repository uninstallation complete."
            ;;
        *)
            c_print "$YELLOW" "No changes applied."
            ;;
    esac
else
    # Global Scope: prompt for platform
    c_print "$BOLD" "Select a platform to uninstall globally:"
    n=1
    for p in $VALID_PLATFORMS; do
        installed_tag=""
        if [ -f "$HOME/.agent-toolkit-install-$p.json" ] || [ -f "$HOME/.agent-toolkit-ledger-$p.json" ]; then
            installed_tag=" ${GREEN}(installed)$RESET"
        fi
        c_print "$GREEN" "  $n)$RESET  $BOLD$p$RESET$installed_tag"
        n=$((n + 1))
    done
    c_print "$GREEN" "  a)$RESET  ${BOLD}All installed platforms$RESET"

    answer=$(prompt "Platform number, name, or 'a' for all [1]: " "1")

    selected_platforms=""
    if [ "$answer" = "a" ] || [ "$answer" = "all" ] || [ "$answer" = "A" ]; then
        selected_platforms="$VALID_PLATFORMS"
    elif echo "$answer" | grep -qE '^[0-9]+$'; then
        i=1
        for p in $VALID_PLATFORMS; do
            if [ "$i" -eq "$answer" ]; then selected_platforms="$p"; fi
            i=$((i + 1))
        done
    else
        for p in $VALID_PLATFORMS; do
            if [ "$p" = "$answer" ]; then selected_platforms="$p"; fi
        done
    fi

    if [ -z "$selected_platforms" ]; then
        c_print "$RED" "Invalid platform selection: $answer" >&2
        exit 2
    fi

    c_print "$DIM" "  → selected platform(s): $BOLD$GREEN$selected_platforms$RESET"
    echo

    for p in $selected_platforms; do
        c_print "$BOLD$CYAN" "── Global Uninstall Preview for $p ────────────────────────"
        python3 scripts/toolkit.py uninstall --scope global --platform "$p" || true
        c_print "$BOLD$CYAN" "──────────────────────────────────────────────────────────"
        echo
    done

    confirm=$(prompt "Apply global uninstallation for selected platform(s)? [y/N]: " "N")
    case "$confirm" in
        y|Y|yes|Yes|YES)
            c_print "$GREEN" "Applying global uninstallation…"
            for p in $selected_platforms; do
                python3 scripts/toolkit.py uninstall --scope global --platform "$p" --apply
            done
            c_print "$GREEN" "✓ Global uninstallation complete."
            ;;
        *)
            c_print "$YELLOW" "No changes applied."
            ;;
    esac
fi
