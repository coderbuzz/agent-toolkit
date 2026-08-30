#!/bin/sh
# Agent Toolkit Uninstaller (POSIX Shell - Zero Dependencies)
#
# Previews and removes only files the installer recorded in its ledger.
# User-modified files are preserved and reported. Without --apply it only
# prints the plan.
#
# Usage:
#   ./scripts/uninstall.sh --scope global --platform <platform> [--apply]
#   ./scripts/uninstall.sh --scope repository [--target DIR] [--apply]

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

. "$SCRIPT_DIR/toolkit-lib.sh"

VALID_PLATFORMS="claude-code codex gemini github-copilot omp opencode zcode"
TAB=$(printf '\t')

usage() {
    echo "Usage: $0 [--scope global|repository] [--platform <platform>] [--target DIR] [--apply]" >&2
    echo "Default scope is global and requires --platform. Valid platforms: $VALID_PLATFORMS" >&2
}

scope="global"
platform=""
target_dir=""
apply=0
arg_count=$#

while [ $# -gt 0 ]; do
    case "$1" in
        --platform)
            platform="$2"; shift 2 ;;
        --platform=*)
            platform="${1#*=}"; shift ;;
        --global|--scope=global)
            scope="global"; shift ;;
        --repository|--scope=repository)
            scope="repository"; shift ;;
        --scope)
            scope="$2"; shift 2 ;;
        --scope=*)
            scope="${1#*=}"; shift ;;
        --target)
            target_dir="$2"; shift 2 ;;
        --target=*)
            target_dir="${1#*=}"; shift ;;
        --apply)
            apply=1; shift ;;
        -h|--help)
            usage
            exit 0 ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2 ;;
    esac
done

case "$scope" in
    global|repository) ;;
    *)
        tk_die "unknown scope '$scope' (expected global or repository)" ;;
esac

# --- Interactive wizard (no arguments, terminal attached) -------------------

if [ "$arg_count" -eq 0 ] && [ -t 0 ]; then
    if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
        BOLD='\033[1m'; DIM='\033[2m'
        RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; CYAN='\033[36m'; RESET='\033[0m'
    else
        BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; RESET=''
    fi
    c_print() {
        color="$1"; shift
        printf '%b%b%b\n' "$color" "$*" "$RESET"
    }
    prompt() {
        printf '%b%s%b' "$BOLD$BLUE" "$1" "$RESET" >&2
        if read -r REPLY; then
            printf '%s' "$REPLY"
        else
            printf '%s' "$2"
        fi
    }

    c_print "$BOLD$CYAN" "Agent Toolkit - Uninstaller"
    c_print "$DIM" "Interactive uninstaller — previews safe removals first, applies on confirmation."
    echo

    scope_input=$(prompt "Scope - (g)lobal or (r)epository? [g]: " "g")
    case "$scope_input" in
        r|R|repository|Repository) wizard_scope="repository" ;;
        *) wizard_scope="global" ;;
    esac
    c_print "$DIM" "  → scope: $BOLD$YELLOW$wizard_scope$RESET"

    if [ "$wizard_scope" = "repository" ]; then
        wizard_target=$(prompt "Target repository path [.]: " ".")
        c_print "$DIM" "  → target: $BOLD$YELLOW$wizard_target$RESET"
        echo
        c_print "$BOLD$CYAN" "── Uninstall Preview (dry run) ───────────────────────────"
        "$0" --scope repository --target "$wizard_target" || true
        c_print "$BOLD$CYAN" "──────────────────────────────────────────────────────────"
        echo
        confirm=$(prompt "Apply this uninstallation now? [y/N]: " "N")
        case "$confirm" in
            y|Y|yes|Yes|YES)
                exec "$0" --scope repository --target "$wizard_target" --apply
                ;;
            *)
                c_print "$YELLOW" "No changes applied."
                ;;
        esac
        exit 0
    fi

    c_print "$BOLD" "Select a platform to uninstall globally:"
    n=1
    for p in $VALID_PLATFORMS; do
        installed_tag=""
        if [ -f "${HOME:-}/.agent-toolkit-install-$p.json" ]; then
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
        "$0" --scope global --platform "$p" || true
        c_print "$BOLD$CYAN" "──────────────────────────────────────────────────────────"
        echo
    done
    confirm=$(prompt "Apply global uninstallation for selected platform(s)? [y/N]: " "N")
    case "$confirm" in
        y|Y|yes|Yes|YES)
            status=0
            for p in $selected_platforms; do
                "$0" --scope global --platform "$p" --apply || status=$?
            done
            if [ "$status" -eq 0 ]; then
                c_print "$GREEN" "✓ Global uninstallation complete."
            else
                c_print "$YELLOW" "Completed with warnings (exit $status)."
            fi
            exit "$status"
            ;;
        *)
            c_print "$YELLOW" "No changes applied."
            ;;
    esac
    exit 0
fi

if [ "$arg_count" -eq 0 ]; then
    usage
    exit 2
fi

if [ "$scope" = "global" ] && [ -z "$platform" ]; then
    usage
    exit 2
fi

if [ -n "$platform" ]; then
    valid=0
    for p in $VALID_PLATFORMS; do
        if [ "$p" = "$platform" ]; then valid=1; break; fi
    done
    if [ "$valid" -eq 0 ]; then
        tk_die "Unsupported platform '$platform'. Valid platforms: $VALID_PLATFORMS"
    fi
fi

if [ -z "$target_dir" ]; then
    if [ "$scope" = "global" ]; then
        [ -n "${HOME:-}" ] || tk_die "HOME is not set; pass --target explicitly"
        target_dir=$HOME
    else
        target_dir=.
    fi
fi

target=$(tk_abs_dir "$target_dir")
if [ "$target" = "/" ]; then
    tk_die "Refusing to use the filesystem root as uninstall target"
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit-uninstall.XXXXXX") || tk_die "cannot create work dir"
trap 'rm -rf "$WORK"' EXIT INT TERM

actions="$WORK/actions"
warnings="$WORK/warnings"
: > "$actions"
: > "$warnings"

add_action() {
    printf '%s\t%s\n' "$1" "$2" >> "$actions"
}

add_warning() {
    printf 'Warning: %s\n' "$1" >> "$warnings"
}

# --- Plan: ledger-managed files -------------------------------------------

if [ "$scope" = "global" ]; then
    ledger="$target/.agent-toolkit-install-$platform.json"
else
    ledger="$target/.agent-toolkit-install.json"
fi

managed="$WORK/managed"
: > "$managed"
if [ -f "$ledger" ]; then
    tk_read_install_ledger "$ledger" > "$managed"
fi

while IFS="$TAB" read -r rel recorded || [ -n "$rel" ]; do
    [ -n "$rel" ] || continue
    if ! tk_check_dest "$target" "$rel"; then
        add_warning "Refusing symlinked uninstall path: $target/$rel"
        continue
    fi
    dest="$target/$rel"
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        add_action "already-removed" "$rel"
    elif [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(tk_hash_file "$dest")" = "$recorded" ]; then
        add_action "remove" "$rel"
    else
        add_action "preserve-modified" "$rel"
        add_warning "Preserving modified or non-regular file: $rel"
    fi
done < "$managed"

# --- Plan: shared skills, codex block, instruction block (global only) -----

shared_records="$WORK/shared-records"
: > "$shared_records"
shared_kept="$WORK/shared-kept"       # records that survive this uninstall
shared_released="$WORK/shared-released"  # path<TAB>hash<TAB>remaining-owners
: > "$shared_kept"
: > "$shared_released"

if [ "$scope" = "global" ]; then
    shared_ledger="$target/.agent-toolkit-shared-skills.json"
    if [ -f "$shared_ledger" ]; then
        tk_read_shared_ledger "$shared_ledger" > "$shared_records"
    fi

    while IFS="$TAB" read -r rel recorded owners || [ -n "$rel" ]; do
        [ -n "$rel" ] || continue
        case ",$owners," in
            *",$platform,"*) ;;
            *)
                printf '%s\t%s\t%s\n' "$rel" "$recorded" "$owners" >> "$shared_kept"
                continue
                ;;
        esac
        remaining=$(printf '%s\n' "$owners" | tr ',' '\n' | grep -vx "$platform" | paste -sd, -)
        if [ -n "$remaining" ]; then
            add_action "shared-release" "$rel"
            printf '%s\t%s\t%s\n' "$rel" "$recorded" "$remaining" >> "$shared_kept"
            printf '%s\t%s\t%s\n' "$rel" "$recorded" "$remaining" >> "$shared_released"
            continue
        fi
        if ! tk_check_dest "$target" "$rel"; then
            add_warning "Refusing symlinked uninstall path: $target/$rel"
            continue
        fi
        dest="$target/$rel"
        if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
            add_action "shared-already-removed" "$rel"
        elif [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(tk_hash_file "$dest")" = "$recorded" ]; then
            add_action "shared-remove" "$rel"
        else
            add_action "shared-preserve-modified" "$rel"
            add_warning "Preserving modified shared skill file: $rel"
        fi
    done < "$shared_records"

    # Codex TOML block and instruction block are adapter-driven.
    adapter="$TOOLKIT_DIR/platforms/$platform/adapter.json"
    [ -f "$adapter" ] || tk_die "Missing adapter descriptor for $platform"
    instruction_rel=$(tk_adapter_global_scalar "$adapter" instruction_path)
    agent_strategy=$(tk_adapter_global_scalar "$adapter" agent_strategy)
    agent_config=$(tk_adapter_global_scalar "$adapter" agent_config_path)

    if [ "$agent_strategy" = "toml-managed-block" ] && [ -n "$agent_config" ]; then
        dest="$target/$agent_config"
        status=0
        tk_block_split "$dest" "$TK_CODEX_BLOCK_BEGIN" "$TK_CODEX_BLOCK_END" \
            "$WORK/c-before" "$WORK/c-after" || status=$?
        [ "$status" -ne 2 ] || tk_die "Malformed managed block: missing end marker in $agent_config"
        if [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$status" -eq 0 ]; then
            add_action "codex-unmerge-remove" "$agent_config"
        else
            add_action "codex-unmerge-absent" "$agent_config"
        fi
    fi

    if [ -n "$instruction_rel" ]; then
        dest="$target/$instruction_rel"
        status=0
        tk_block_split "$dest" "$TK_INSTR_BLOCK_BEGIN" "$TK_INSTR_BLOCK_END" \
            "$WORK/i-before" "$WORK/i-after" || status=$?
        [ "$status" -ne 2 ] || tk_die "Malformed instruction block: missing end marker"
        if [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$status" -eq 0 ]; then
            add_action "instruction-unblock-remove" "$instruction_rel"
        fi
    fi
fi

# --- Preview ---------------------------------------------------------------

if [ "$scope" = "global" ]; then
    printf 'Global uninstall plan for %s from %s:\n' "$platform" "$target"
else
    printf 'Uninstall plan for %s:\n' "$target"
fi

if [ -s "$actions" ]; then
    awk -F'\t' '{ printf "%-24s %s\n", $1, $2 }' "$actions"
else
    printf 'No managed files found.\n'
fi

if [ -s "$warnings" ]; then
    cat "$warnings" >&2
fi

if [ "$apply" -eq 0 ]; then
    printf 'Dry run only. Re-run with --apply to uninstall.\n'
    exit 0
fi

# --- Apply -----------------------------------------------------------------

removed=0
while IFS="$TAB" read -r action rel || [ -n "$action" ]; do
    [ -n "$action" ] || continue
    dest="$target/$rel"
    case "$action" in
        remove)
            rm -f -- "$dest"
            tk_prune_empty_parents "$dest" "$target"
            removed=$((removed + 1))
            ;;
    esac
done < "$actions"

if [ -f "$ledger" ]; then
    rm -f -- "$ledger"
fi

if [ "$scope" = "global" ]; then
    # Shared skills: remove owned files, release ownership, rewrite ledger.
    while IFS="$TAB" read -r action rel || [ -n "$action" ]; do
        [ -n "$action" ] || continue
        case "$action" in
            shared-remove)
                dest="$target/$rel"
                if [ -f "$dest" ] && [ ! -L "$dest" ]; then
                    rm -f -- "$dest"
                    tk_prune_empty_parents "$dest" "$target"
                fi
                ;;
        esac
    done < "$actions"

    if [ -s "$shared_kept" ]; then
        sort "$shared_kept" -o "$shared_kept"
        tk_write_shared_ledger "$WORK/shared-ledger.json" "$shared_kept"
        tk_copy_atomic "$WORK/shared-ledger.json" "$shared_ledger"
    elif [ -f "$shared_ledger" ]; then
        rm -f -- "$shared_ledger"
    fi

    # Codex TOML unmerge.
    if [ "$agent_strategy" = "toml-managed-block" ] && [ -n "$agent_config" ]; then
        dest="$target/$agent_config"
        status=0
        tk_block_split "$dest" "$TK_CODEX_BLOCK_BEGIN" "$TK_CODEX_BLOCK_END" \
            "$WORK/c-before" "$WORK/c-after" || status=$?
        if [ "$status" -eq 0 ]; then
            if [ -s "$WORK/c-before" ] || [ -s "$WORK/c-after" ]; then
                cat "$WORK/c-before" "$WORK/c-after" > "$WORK/c-compose"
                tk_atomic_write "$dest" "$WORK/c-compose"
            else
                rm -f -- "$dest"
                tk_prune_empty_parents "$dest" "$target"
            fi
        fi
    fi

    # Instruction unblock: keep user content, drop only the managed block.
    if [ -n "$instruction_rel" ]; then
        dest="$target/$instruction_rel"
        status=0
        tk_block_split "$dest" "$TK_INSTR_BLOCK_BEGIN" "$TK_INSTR_BLOCK_END" \
            "$WORK/i-before" "$WORK/i-after" || status=$?
        if [ "$status" -eq 0 ]; then
            if [ -s "$WORK/i-before" ] || [ -s "$WORK/i-after" ]; then
                cat "$WORK/i-before" "$WORK/i-after" > "$WORK/i-compose"
                tk_atomic_write "$dest" "$WORK/i-compose"
            else
                rm -f -- "$dest"
                tk_prune_empty_parents "$dest" "$target"
            fi
        fi
    fi

    printf 'Global uninstall completed for %s.\n' "$platform"
else
    printf 'Uninstall completed; removed %s unchanged managed file(s).\n' "$removed"
fi

if [ -s "$warnings" ]; then
    exit 2
fi
exit 0
