#!/bin/sh
# Portable Agentic SDLC Toolkit Installer (POSIX Shell - Zero Dependencies)
# Usage:
#   ./scripts/install.sh --platform <platform> [--global] [--bundle core|full|quality] [--target DIR] [--apply]

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$TOOLKIT_DIR"

VALID_PLATFORMS="claude-code codex gemini github-copilot omp opencode"

calc_sha256() {
    file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$file" | awk '{print $NF}'
    else
        ls -l "$file" | awk '{print $5 "_" $6 "_" $7 "_" $8}'
    fi
}

platform=""
package_dir=""
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
            package_dir="$2"; shift 2 ;;
        --package=*)
            package_dir="${1#*=}"; shift ;;
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

if [ -z "$package_dir" ]; then
    package_dir="$TOOLKIT_DIR/dist/$platform"
fi

if [ ! -d "$package_dir" ]; then
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

# Terminal colors
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; RESET='\033[0m'
else
    BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi

echo "${BOLD}${CYAN}Portable Agentic SDLC Installer${RESET}"
echo "${DIM}Platform:${RESET} ${BOLD}${platform:-custom}${RESET} | ${DIM}Scope:${RESET} ${BOLD}$scope${RESET} | ${DIM}Target:${RESET} ${BOLD}$target_dir${RESET}"
if [ "$apply" -eq 0 ]; then
    echo "${YELLOW}Mode: Preview (dry run). Pass --apply to commit changes.${RESET}"
else
    echo "${GREEN}Mode: Applying changes.${RESET}"
fi
echo ""

# LEDGER FILE
LEDGER_FILE="$target_dir/.portable-sdlc-install.json"
if [ "$scope" = "global" ]; then
    LEDGER_FILE="$target_dir/.portable-sdlc-install-${platform:-custom}.json"
fi

# Helper to check if file was previously installed by toolkit
is_managed_file() {
    dest_path="$1"
    rel_path="${dest_path#$target_dir/}"
    if [ -f "$LEDGER_FILE" ]; then
        grep -q "\"$rel_path\"" "$LEDGER_FILE" 2>/dev/null && return 0
    fi
    return 1
}

# --- REPOSITORY SCOPE INSTALLATION ---
if [ "$scope" = "repository" ]; then
    conflicts=0
    creates=0
    updates=0
    unchanged=0

    # Collect files to process
    file_list=$(cd "$package_dir" && find . -type f ! -name ".portable-sdlc-package.json" | sed 's|^\./||' | sort)

    echo "${BOLD}Plan Summary:${RESET}"
    for rel_path in $file_list; do
        src_file="$package_dir/$rel_path"
        dest_file="$target_dir/$rel_path"

        if [ ! -f "$dest_file" ]; then
            echo "  ${GREEN}[CREATE]${RESET} $rel_path"
            creates=$((creates + 1))
        else
            src_hash=$(calc_sha256 "$src_file")
            dest_hash=$(calc_sha256 "$dest_file")

            if [ "$src_hash" = "$dest_hash" ]; then
                echo "  ${DIM}[UNCHANGED]${RESET} $rel_path"
                unchanged=$((unchanged + 1))
            elif is_managed_file "$dest_file"; then
                echo "  ${YELLOW}[UPDATE]${RESET} $rel_path"
                updates=$((updates + 1))
            else
                echo "  ${RED}[CONFLICT]${RESET} $rel_path (User-owned file exists and differs)"
                conflicts=$((conflicts + 1))
            fi
        fi
    done

    echo ""
    echo "${BOLD}Action totals:${RESET} $creates to create, $updates to update, $unchanged unchanged, $conflicts conflicts."

    if [ "$conflicts" -gt 0 ]; then
        echo "${RED}Error: Cannot proceed due to file conflicts.${RESET}" >&2
        exit 1
    fi

    if [ "$apply" -eq 0 ]; then
        echo "${YELLOW}Dry run only. Re-run with --apply to perform installation.${RESET}"
        exit 0
    fi

    # Perform actual copy
    echo "${GREEN}Applying installation...${RESET}"
    installed_ledger_files=""
    for rel_path in $file_list; do
        src_file="$package_dir/$rel_path"
        dest_file="$target_dir/$rel_path"
        dest_dir=$(dirname "$dest_file")

        mkdir -p "$dest_dir"
        cp "$src_file" "$dest_file"

        file_hash=$(calc_sha256 "$dest_file")
        if [ -n "$installed_ledger_files" ]; then
            installed_ledger_files="$installed_ledger_files,"
        fi
        installed_ledger_files="$installed_ledger_files\n    \"$rel_path\": \"$file_hash\""
    done

    # Write Ledger JSON
    cat <<EOF > "$LEDGER_FILE"
{
  "schema_version": 1,
  "platform": "${platform:-custom}",
  "bundle": "$bundle",
  "scope": "repository",
  "files": {
$installed_ledger_files
  }
}
EOF

    echo "${BOLD}${GREEN}✓ Installation complete.${RESET}"
    exit 0
fi

# --- GLOBAL SCOPE INSTALLATION ---
if [ "$scope" = "global" ]; then
    echo "${GREEN}Installing global configuration for platform '${platform}'...${RESET}"

    # Determine platform target mapping
    case "$platform" in
        codex)
            inst_dest="$target_dir/.codex/AGENTS.md"
            agent_dir="$target_dir/.codex"
            ;;
        opencode)
            inst_dest="$target_dir/.config/opencode/AGENTS.md"
            agent_dir="$target_dir/.config/opencode/agents"
            ;;
        claude-code)
            inst_dest="$target_dir/.claude/CLAUDE.md"
            agent_dir="$target_dir/.claude/agents"
            ;;
        github-copilot)
            inst_dest="$target_dir/.copilot/copilot-instructions.md"
            agent_dir="$target_dir/.copilot/agents"
            ;;
        omp)
            inst_dest="$target_dir/.omp/agent/AGENTS.md"
            agent_dir="$target_dir/.omp/agent/agents"
            ;;
        gemini)
            inst_dest="$target_dir/.gemini/antigravity/AGENTS.md"
            agent_dir="$target_dir/.gemini/antigravity/agents"
            ;;
        *)
            echo "Error: Scope global not supported for '$platform'." >&2
            exit 1
            ;;
    esac

    # Shared skills destination
    skills_dest="$target_dir/.agents/skills"

    echo "  [TARGET] Instructions: $inst_dest"
    echo "  [TARGET] Agents:       $agent_dir"
    echo "  [TARGET] Skills:       $skills_dest"

    if [ "$apply" -eq 0 ]; then
        echo ""
        echo "${YELLOW}Preview complete. Re-run with --apply to perform global installation.${RESET}"
        exit 0
    fi

    # 1. Copy Shared Skills
    mkdir -p "$skills_dest"
    if [ -d "$package_dir/.agents/skills" ]; then
        cp -R "$package_dir/.agents/skills/"* "$skills_dest/"
    fi

    # 2. Copy Agents / Handle Codex Merge
    mkdir -p "$agent_dir"
    if [ "$platform" = "codex" ]; then
        # Codex uses managed block in config.toml
        config_toml="$target_dir/.codex/config.toml"
        mkdir -p "$target_dir/.codex"
        block_begin="# >>> portable-sdlc agents (managed by agent-toolkit) >>>"
        block_end="# <<< portable-sdlc agents <<<"
        
        # Build block body from agents in package
        block_content=""
        if [ -d "$package_dir/.codex/agents" ]; then
            for f in "$package_dir/.codex/agents/"*.toml; do
                if [ -f "$f" ]; then
                    block_content="$block_content$(cat "$f")\n\n"
                fi
            done
        fi

        if [ ! -f "$config_toml" ]; then
            printf "%s\n%b%s\n" "$block_begin" "$block_content" "$block_end" > "$config_toml"
        elif grep -qF "$block_begin" "$config_toml"; then
            BLOCK_BODY=$(printf "%b" "$block_content") export BLOCK_BODY
            awk -v b="$block_begin" -v e="$block_end" '
                BEGIN { in_block = 0 }
                $0 ~ b { print b; print ENVIRON["BLOCK_BODY"]; in_block = 1; next }
                $0 ~ e { print e; in_block = 0; next }
                !in_block { print }
            ' "$config_toml" > "$config_toml.tmp" && mv "$config_toml.tmp" "$config_toml"
            unset BLOCK_BODY
        else
            printf "\n%s\n%b%s\n" "$block_begin" "$block_content" "$block_end" >> "$config_toml"
        fi
    else
        # Copy agent definition files directly
        pkg_agent_dir=""
        case "$platform" in
            opencode) pkg_agent_dir="$package_dir/.opencode/agents" ;;
            claude-code) pkg_agent_dir="$package_dir/.claude/agents" ;;
            github-copilot) pkg_agent_dir="$package_dir/.copilot/agents" ;;
            omp)
                if [ -d "$package_dir/.omp/agents" ]; then
                    pkg_agent_dir="$package_dir/.omp/agents"
                else
                    pkg_agent_dir="$package_dir/.omp/agent/agents"
                fi
                ;;
            gemini)
                if [ -d "$package_dir/.gemini/agents" ]; then
                    pkg_agent_dir="$package_dir/.gemini/agents"
                else
                    pkg_agent_dir="$package_dir/.gemini/antigravity/agents"
                fi
                ;;
        esac
        if [ -d "$pkg_agent_dir" ]; then
            cp -R "$pkg_agent_dir/"* "$agent_dir/"
        fi
    fi

    # 3. Copy/Append Global Instructions
    mkdir -p "$(dirname "$inst_dest")"
    src_inst="$package_dir/AGENTS.md"
    if [ "$platform" = "claude-code" ] && [ -f "$package_dir/CLAUDE.md" ]; then
        src_inst="$package_dir/CLAUDE.md"
    fi

    block_begin="# >>> portable-sdlc instructions (managed by agent-toolkit) >>>"
    block_end="# <<< portable-sdlc instructions <<<"
    inst_body=$(cat "$src_inst")

    if [ ! -f "$inst_dest" ]; then
        printf "%s\n%s\n%s\n" "$block_begin" "$inst_body" "$block_end" > "$inst_dest"
    elif grep -qF "$block_begin" "$inst_dest"; then
        INST_BODY="$inst_body" export INST_BODY
        awk -v b="$block_begin" -v e="$block_end" '
            BEGIN { in_block = 0 }
            $0 ~ b { print b; print ENVIRON["INST_BODY"]; in_block = 1; next }
            $0 ~ e { print e; in_block = 0; next }
            !in_block { print }
        ' "$inst_dest" > "$inst_dest.tmp" && mv "$inst_dest.tmp" "$inst_dest"
        unset INST_BODY
    else
        printf "\n%s\n%s\n%s\n" "$block_begin" "$inst_body" "$block_end" >> "$inst_dest"
    fi

    # Write global ledger
    cat <<EOF > "$LEDGER_FILE"
{
  "schema_version": 1,
  "platform": "$platform",
  "bundle": "$bundle",
  "scope": "global",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2026-07-27")"
}
EOF

    echo "${BOLD}${GREEN}✓ Global installation complete.${RESET}"
    exit 0
fi
