#!/bin/sh
# Agent Toolkit Installer (POSIX Shell - Zero Dependencies)
#
# Installs pre-built packages from dist/ (or --package DIR) without Python.
# Preview-first: without --apply it only prints the plan. Never overwrites
# user-modified files; refuses conflicts and exits non-zero instead.
#
# Usage:
#   ./scripts/install.sh --platform <platform> [--scope global|repository]
#                        [--bundle core|full|quality] [--target DIR]
#                        [--package DIR] [--apply]

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

. "$SCRIPT_DIR/toolkit-lib.sh"

VALID_PLATFORMS="claude-code codex gemini github-copilot omp opencode"
TAB=$(printf '\t')

usage() {
    echo "Usage: $0 --platform <platform> [--scope global|repository] [--bundle core|full|quality] [--target DIR] [--package DIR] [--apply]" >&2
    echo "Valid platforms: $VALID_PLATFORMS" >&2
    echo "Default scope is global (~). Use --scope repository for a project checkout." >&2
    echo "Use --package <dir> to install from a pre-generated package instead." >&2
}

platform=""
package_dir=""
package_explicit=0
scope="global"
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
        --bundle)
            bundle="$2"; shift 2 ;;
        --bundle=*)
            bundle="${1#*=}"; shift ;;
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

if [ -z "$platform" ] && [ -z "$package_dir" ]; then
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

if [ -z "$package_dir" ]; then
    if [ "$scope" = "global" ]; then
        package_dir="$TOOLKIT_DIR/dist/global/$platform"
    else
        package_dir="$TOOLKIT_DIR/dist/$platform"
    fi
fi

if [ ! -d "$package_dir" ]; then
    echo "Error: Package directory '$package_dir' does not exist." >&2
    echo "Maintainers regenerate packages with: python3 scripts/toolkit.py export --all --bundle $bundle" >&2
    exit 1
fi

meta="$package_dir/.agent-toolkit-package.json"
[ -f "$meta" ] || tk_die "Package metadata missing in $package_dir"

meta_platform=$(tk_pkg_scalar "$meta" platform)
meta_bundle=$(tk_pkg_scalar "$meta" bundle)
meta_scope=$(tk_pkg_scalar "$meta" scope)
[ -n "$meta_scope" ] || meta_scope="repository"

if [ -n "$platform" ] && [ "$meta_platform" != "$platform" ]; then
    tk_die "Package platform '$meta_platform' does not match --platform '$platform'"
fi
if [ "$meta_bundle" != "$bundle" ]; then
    tk_die "Package bundle '$meta_bundle' does not match --bundle '$bundle'. Maintainers regenerate dist with: python3 scripts/toolkit.py export --all --bundle $bundle"
fi
if [ "$meta_scope" != "$scope" ]; then
    tk_die "Package scope $meta_scope does not match --scope $scope"
fi
platform=$meta_platform

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
    tk_die "Refusing to use the filesystem root as install target"
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit-install.XXXXXX") || tk_die "cannot create work dir"
trap 'rm -rf "$WORK"' EXIT INT TERM

# --- Package inventory: hash every file once, LC_ALL=C sorted -------------

pkg_hashes="$WORK/pkg-hashes"
(cd "$package_dir" && find . -name '.agent-toolkit-package.json' -prune -o -type f -print) |
    sed 's|^\./||' | sort > "$WORK/pkg-files"

: > "$pkg_hashes"
while IFS= read -r rel || [ -n "$rel" ]; do
    [ -n "$rel" ] || continue
    tk_safe_rel "$rel" > /dev/null
    printf '%s\t%s\n' "$rel" "$(tk_hash_file "$package_dir/$rel")" >> "$pkg_hashes"
done < "$WORK/pkg-files"

pkg_hash_of() {
    awk -F'\t' -v p="$1" '$1 == p { print $2; exit }' "$pkg_hashes"
}

# --- Split global packages into regular / shared / merge / instruction ----

shared_list="$WORK/shared-list"
merge_list="$WORK/merge-list"
instruction_rel=""
exclude_list="$WORK/exclude-list"
: > "$exclude_list"

if [ "$meta_scope" = "global" ]; then
    tk_pkg_string_list "$meta" shared_skill_files > "$shared_list"
    sort "$shared_list" -o "$shared_list"
    tk_pkg_merge_files "$meta" > "$merge_list"
    instruction_rel=$(tk_pkg_scalar "$meta" instruction_path)
    cut -f1 "$shared_list" > "$exclude_list"
    cut -f1 "$merge_list" >> "$exclude_list"
    if [ -n "$instruction_rel" ]; then
        printf '%s\n' "$instruction_rel" >> "$exclude_list"
    fi
    sort -u "$exclude_list" -o "$exclude_list"
    ledger_rel=".agent-toolkit-install-$platform.json"
else
    : > "$shared_list"
    : > "$merge_list"
    ledger_rel=".agent-toolkit-install.json"
fi

regular_files="$WORK/regular-files"
if [ -s "$exclude_list" ]; then
    cut -f1 "$pkg_hashes" | grep -Fxv -f "$exclude_list" > "$regular_files" || true
else
    cut -f1 "$pkg_hashes" > "$regular_files"
fi

# --- Ledger state ----------------------------------------------------------

ledger="$target/$ledger_rel"
managed="$WORK/managed"      # path<TAB>hash
: > "$managed"
if [ -f "$ledger" ]; then
    tk_read_install_ledger "$ledger" > "$managed"
fi

actions="$WORK/actions"        # action<TAB>path
conflicts="$WORK/conflicts"
new_ledger="$WORK/new-ledger"  # path<TAB>hash (LC_ALL=C sorted)
: > "$actions"
: > "$conflicts"
: > "$new_ledger"

add_action() {
    printf '%s\t%s\n' "$1" "$2" >> "$actions"
}

add_conflict() {
    printf '%s\n' "$1" >> "$conflicts"
}

managed_hash() {
    awk -F'\t' -v p="$1" '$1 == p { print $2; exit }' "$managed"
}

# --- Plan: regular files ---------------------------------------------------

while IFS= read -r rel || [ -n "$rel" ]; do
    [ -n "$rel" ] || continue
    if ! tk_check_dest "$target" "$rel"; then
        add_conflict "Refusing symlinked install path: $target/$rel"
        continue
    fi
    dest="$target/$rel"
    expected=$(pkg_hash_of "$rel")
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ] || [ ! -f "$dest" ]; then
            add_conflict "Destination is not a regular file: $rel"
            continue
        fi
        actual=$(tk_hash_file "$dest")
        recorded=$(managed_hash "$rel")
        if [ "$actual" = "$expected" ]; then
            if [ -n "$recorded" ]; then
                add_action "unchanged" "$rel"
                printf '%s\t%s\n' "$rel" "$expected" >> "$new_ledger"
            else
                add_action "preserve-identical-user-owned" "$rel"
            fi
        elif [ -n "$recorded" ] && [ "$actual" = "$recorded" ]; then
            add_action "update" "$rel"
            printf '%s\t%s\n' "$rel" "$expected" >> "$new_ledger"
        elif [ -n "$recorded" ]; then
            add_conflict "User-modified managed file: $rel"
        else
            add_conflict "Existing user-owned file differs: $rel"
        fi
    else
        add_action "create" "$rel"
        printf '%s\t%s\n' "$rel" "$expected" >> "$new_ledger"
    fi
done < "$regular_files"

# --- Plan: stale managed files (no longer in the package) ------------------

stale="$WORK/stale"
if [ -s "$regular_files" ]; then
    awk -F'\t' 'NR == FNR { keep[$1] = 1; next } !($1 in keep) { print }' \
        "$regular_files" "$managed" > "$stale"
else
    cp "$managed" "$stale"
fi

while IFS="$TAB" read -r rel recorded || [ -n "$rel" ]; do
    [ -n "$rel" ] || continue
    if ! tk_check_dest "$target" "$rel"; then
        add_conflict "Refusing symlinked install path: $target/$rel"
        continue
    fi
    dest="$target/$rel"
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        add_action "already-removed" "$rel"
    elif [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(tk_hash_file "$dest")" = "$recorded" ]; then
        add_action "remove-stale" "$rel"
    else
        add_action "preserve-modified-stale" "$rel"
    fi
done < "$stale"

# --- Plan: shared skills (global only, reference-counted) ------------------

shared_actions="$WORK/shared-actions"
: > "$shared_actions"
shared_ledger="$target/.agent-toolkit-shared-skills.json"
shared_records="$WORK/shared-records"   # path<TAB>hash<TAB>owner,owner
: > "$shared_records"
if [ -f "$shared_ledger" ]; then
    tk_read_shared_ledger "$shared_ledger" > "$shared_records"
fi

shared_field() {
    # $1 = relative path, $2 = column (2 = hash, 3 = owners)
    awk -F'\t' -v p="$1" '$1 == p { print $'"$2"'; exit }' "$shared_records"
}

while IFS= read -r rel || [ -n "$rel" ]; do
    [ -n "$rel" ] || continue
    expected=$(pkg_hash_of "$rel")
    if [ -z "$expected" ]; then
        add_conflict "Shared skill file missing from package: $rel"
        continue
    fi
    if ! tk_check_dest "$target" "$rel"; then
        add_conflict "Refusing symlinked install path: $target/$rel"
        continue
    fi
    dest="$target/$rel"
    record_hash=$(shared_field "$rel" 2)
    record_owners=$(shared_field "$rel" 3)
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ] || [ ! -f "$dest" ]; then
            add_conflict "Shared skill destination is not a regular file: $rel"
            continue
        fi
        actual=$(tk_hash_file "$dest")
        case ",$record_owners," in
            *",$platform,"*) owned=1 ;;
            *) owned=0 ;;
        esac
        if [ "$actual" = "$expected" ]; then
            if [ -n "$record_hash" ] && [ "$owned" -eq 1 ]; then
                printf 'shared-unchanged\t%s\n' "$rel" >> "$shared_actions"
            else
                printf 'shared-adopt\t%s\n' "$rel" >> "$shared_actions"
            fi
        elif [ -n "$record_hash" ] && [ "$actual" = "$record_hash" ]; then
            printf 'shared-update\t%s\n' "$rel" >> "$shared_actions"
        elif [ -n "$record_hash" ]; then
            add_conflict "User-modified shared skill file: $rel"
        else
            add_conflict "Existing user-owned shared skill differs: $rel"
        fi
    else
        printf 'shared-create\t%s\n' "$rel" >> "$shared_actions"
    fi
done < "$shared_list"

# --- Plan: codex TOML merge + instruction block ----------------------------

merge_previews="$WORK/merge-previews"
instruction_preview="$WORK/instruction-preview"
: > "$merge_previews"
: > "$instruction_preview"
block_conflict=""

plan_block() {
    # Print the action for one managed-block destination: create, append,
    # update, or unchanged. Sets block_conflict and returns 1 on conflict.
    # $1 = dest, $2 = marker-wrapped block file, $3 = begin, $4 = end,
    # $5 = conflict label, $6 = relative path for messages.
    block_conflict=""
    if [ -L "$1" ] || { [ -e "$1" ] && [ ! -f "$1" ]; }; then
        block_conflict="$5 is not a regular file: $6"
        return 1
    fi
    if [ ! -e "$1" ]; then
        printf 'create'
        return 0
    fi
    status=0
    tk_block_split "$1" "$3" "$4" "$WORK/blk-before" "$WORK/blk-after" || status=$?
    if [ "$status" -eq 2 ]; then
        tk_die "Malformed managed block: missing end marker in $6"
    fi
    if [ "$status" -eq 0 ]; then
        tk_block_compose "$WORK/blk-compose" update "$WORK/blk-before" "$2" "$WORK/blk-after"
        if cmp -s "$WORK/blk-compose" "$1"; then
            printf 'unchanged'
        else
            printf 'update'
        fi
    else
        printf 'append'
    fi
}

while IFS="$TAB" read -r merge_file merge_target || [ -n "$merge_file" ]; do
    [ -n "$merge_file" ] || continue
    if [ ! -f "$package_dir/$merge_file" ] || [ -L "$package_dir/$merge_file" ]; then
        add_conflict "Merge file missing from package: $merge_file"
        continue
    fi
    if action=$(plan_block "$target/$merge_target" "$package_dir/$merge_file" \
        "$TK_CODEX_BLOCK_BEGIN" "$TK_CODEX_BLOCK_END" "Codex config" "$merge_target"); then
        printf 'codex-merge-%s\t%s\n' "$action" "$merge_target" >> "$merge_previews"
    else
        add_conflict "$block_conflict"
    fi
done < "$merge_list"

if [ -n "$instruction_rel" ]; then
    tk_wrap_instruction_block "$package_dir/$instruction_rel" "$WORK/instr-block"
    if action=$(plan_block "$target/$instruction_rel" "$WORK/instr-block" \
        "$TK_INSTR_BLOCK_BEGIN" "$TK_INSTR_BLOCK_END" "Instruction file" "$instruction_rel"); then
        printf 'instruction-%s\t%s\n' "$action" "$instruction_rel" >> "$instruction_preview"
    else
        add_conflict "$block_conflict"
    fi
fi

# --- Preview ---------------------------------------------------------------

if [ "$meta_scope" = "global" ]; then
    printf 'Global install plan for %s into %s:\n' "$platform" "$target"
else
    printf 'Install plan for %s:\n' "$target"
fi

all_actions="$WORK/all-actions"
cat "$actions" "$shared_actions" "$merge_previews" "$instruction_preview" > "$all_actions"
if [ -s "$all_actions" ]; then
    awk -F'\t' '{ printf "%-24s %s\n", $1, $2 }' "$all_actions"
else
    printf 'No file actions.\n'
fi

if [ -s "$conflicts" ]; then
    printf 'Conflicts:\n' >&2
    while IFS= read -r conflict; do
        printf -- '- %s\n' "$conflict" >&2
    done < "$conflicts"
    exit 1
fi

if [ "$apply" -eq 0 ]; then
    printf 'Dry run only. Re-run with --apply to install.\n'
    exit 0
fi

# --- Apply -----------------------------------------------------------------

mkdir -p -- "$target" || tk_die "cannot create target $target"

while IFS="$TAB" read -r action rel || [ -n "$action" ]; do
    [ -n "$action" ] || continue
    dest="$target/$rel"
    case "$action" in
        create|update)
            mkdir -p -- "$(dirname -- "$dest")" || tk_die "cannot create $(dirname -- "$dest")"
            tk_copy_atomic "$package_dir/$rel" "$dest"
            ;;
        remove-stale)
            rm -f -- "$dest"
            tk_prune_empty_parents "$dest" "$target"
            ;;
    esac
done < "$actions"

# Ledger is written only after every regular file operation succeeded.
sort "$new_ledger" -o "$new_ledger"
tk_write_install_ledger "$WORK/ledger.json" "$new_ledger" \
    toolkit="$(tk_pkg_scalar "$meta" toolkit)" \
    version="$(tk_pkg_scalar "$meta" version)" \
    source_sha256="$(tk_pkg_scalar "$meta" source_sha256)" \
    platform="$platform" \
    bundle="$meta_bundle" \
    scope="$meta_scope"
tk_copy_atomic "$WORK/ledger.json" "$ledger"

if [ "$meta_scope" = "global" ]; then
    # Shared skills: copy, then rewrite the reference-counted ledger.
    while IFS="$TAB" read -r action rel || [ -n "$action" ]; do
        [ -n "$action" ] || continue
        case "$action" in
            shared-create|shared-update)
                dest="$target/$rel"
                mkdir -p -- "$(dirname -- "$dest")" || tk_die "cannot create $(dirname -- "$dest")"
                tk_copy_atomic "$package_dir/$rel" "$dest"
                ;;
        esac
    done < "$shared_actions"

    new_shared="$WORK/new-shared"
    : > "$new_shared"
    while IFS= read -r rel || [ -n "$rel" ]; do
        [ -n "$rel" ] || continue
        expected=$(pkg_hash_of "$rel")
        owners=$(shared_field "$rel" 3)
        case ",$owners," in
            *",$platform,"*) ;;
            *) owners=$(printf '%s%s\n' "$platform" "${owners:+,$owners}" | tr ',' '\n' | sort -u | paste -sd, -) ;;
        esac
        printf '%s\t%s\t%s\n' "$rel" "$expected" "$owners" >> "$new_shared"
    done < "$shared_list"
    # Keep records for shared files that are not part of this package.
    if [ -s "$shared_list" ]; then
        awk -F'\t' 'NR == FNR { planned[$1] = 1; next } !($1 in planned) { print }' \
            "$shared_list" "$shared_records" >> "$new_shared"
    else
        cat "$shared_records" >> "$new_shared"
    fi
    sort "$new_shared" -o "$new_shared"
    if [ -s "$new_shared" ]; then
        tk_write_shared_ledger "$WORK/shared-ledger.json" "$new_shared"
        tk_copy_atomic "$WORK/shared-ledger.json" "$shared_ledger"
    else
        rm -f -- "$shared_ledger"
    fi

    # Codex TOML merges (block file already carries the managed markers).
    while IFS="$TAB" read -r merge_file merge_target || [ -n "$merge_file" ]; do
        [ -n "$merge_file" ] || continue
        dest="$target/$merge_target"
        status=0
        tk_block_split "$dest" "$TK_CODEX_BLOCK_BEGIN" "$TK_CODEX_BLOCK_END" \
            "$WORK/m-before" "$WORK/m-after" || status=$?
        [ "$status" -ne 2 ] || tk_die "Malformed managed block: missing end marker in $merge_target"
        if [ ! -e "$dest" ]; then
            mkdir -p -- "$(dirname -- "$dest")" || tk_die "cannot create $(dirname -- "$dest")"
            tk_copy_atomic "$package_dir/$merge_file" "$dest"
        elif [ "$status" -eq 1 ]; then
            tk_block_compose "$WORK/m-compose" append "$WORK/m-before" "$package_dir/$merge_file" "$WORK/m-after"
            tk_atomic_write "$dest" "$WORK/m-compose"
        else
            tk_block_compose "$WORK/m-compose" update "$WORK/m-before" "$package_dir/$merge_file" "$WORK/m-after"
            if ! cmp -s "$WORK/m-compose" "$dest"; then
                tk_atomic_write "$dest" "$WORK/m-compose"
            fi
        fi
    done < "$merge_list"

    # Global instruction block (append preserves user content).
    if [ -n "$instruction_rel" ]; then
        dest="$target/$instruction_rel"
        status=0
        tk_block_split "$dest" "$TK_INSTR_BLOCK_BEGIN" "$TK_INSTR_BLOCK_END" \
            "$WORK/i-before" "$WORK/i-after" || status=$?
        [ "$status" -ne 2 ] || tk_die "Malformed instruction block: missing end marker"
        if [ ! -e "$dest" ]; then
            mode=create
        elif [ "$status" -eq 1 ]; then
            mode=append
        else
            mode=update
        fi
        tk_block_compose "$WORK/i-compose" "$mode" "$WORK/i-before" "$WORK/instr-block" "$WORK/i-after"
        mkdir -p -- "$(dirname -- "$dest")" || tk_die "cannot create $(dirname -- "$dest")"
        if ! cmp -s "$WORK/i-compose" "$dest"; then
            tk_atomic_write "$dest" "$WORK/i-compose"
        fi

        # Surface legacy v0.1 blocks this installer will not manage.
        if grep -q 'portable-sdlc instructions (managed' "$dest" 2>/dev/null; then
            printf 'Note: a legacy portable-sdlc managed block was detected in %s.\n' "$dest" >&2
            printf 'This installer does not manage it; remove it manually if it is no longer wanted.\n' >&2
        fi
    fi

    printf 'Global install completed for %s.\n' "$platform"
else
    changed=$(awk -F'\t' '$1 == "create" || $1 == "update" || $1 == "remove-stale" { n++ } END { print n + 0 }' "$actions")
    printf 'Install completed; %s file action(s) changed the target.\n' "$changed"
fi
