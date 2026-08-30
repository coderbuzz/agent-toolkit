#!/bin/sh
# Shared helpers for the agent-toolkit shell installers (POSIX, zero deps).
#
# The installers must run on any Unix-like system without Python, jq, or
# other optional tools. Ledger JSON is therefore read and written with awk
# against the canonical serialization produced by scripts/toolkit.py
# (json.dumps(..., indent=2, sort_keys=True) + trailing newline). All three
# installers (POSIX sh, PowerShell, and the Python maintainer CLI) emit
# byte-identical ledger files so any uninstaller can read any install.

# Deterministic sorting and text processing everywhere.
LC_ALL=C
export LC_ALL

TK_CODEX_BLOCK_BEGIN='# >>> agent-toolkit agents (managed; do not edit) >>>'
TK_CODEX_BLOCK_END='# <<< agent-toolkit agents (managed) <<<'
TK_INSTR_BLOCK_BEGIN='# >>> agent-toolkit instructions (managed; do not edit) >>>'
TK_INSTR_BLOCK_END='# <<< agent-toolkit instructions (managed) <<<'
TK_TMP_SUFFIX='.agent-toolkit-tmp'

tk_die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Hashing and path safety
# ---------------------------------------------------------------------------

tk_hash_file() {
    # Print the SHA-256 hex digest of a file (first token of the digest line).
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | cut -d' ' -f1
    elif command -v sha256 >/dev/null 2>&1; then
        sha256 -q "$1"
    else
        tk_die "no sha256 tool found (need sha256sum, shasum, or sha256)"
    fi
}

tk_safe_rel() {
    # Reject values that could escape the target root when joined to it.
    case "$1" in
        ""|*'"'*|*'\'*|*'
'*) tk_die "Unsafe relative path: $1" ;;
        /*) tk_die "Unsafe relative path: $1" ;;
    esac
    oldifs=$IFS
    IFS=/
    for segment in $1; do
        case "$segment" in
            ""|"."|"..") IFS=$oldifs; tk_die "Unsafe relative path: $1" ;;
        esac
    done
    IFS=$oldifs
    printf '%s\n' "$1"
}

tk_abs_dir() {
    # Best-effort absolute physical path of a directory that may not exist.
    [ "$1" != "/" ] || tk_die "Refusing to use the filesystem root"
    if [ -d "$1" ]; then
        (cd -P "$1" && pwd) || tk_die "Cannot enter $1"
        return 0
    fi
    [ ! -e "$1" ] || tk_die "Not a directory: $1"
    parent=$(dirname -- "$1")
    base=$(basename -- "$1")
    parent_abs=$(cd -P "$parent" 2>/dev/null && pwd) || tk_die "Cannot resolve parent of $1"
    printf '%s/%s\n' "$parent_abs" "$base"
}

tk_check_dest() {
    # Verify a relative destination is reachable without symlinked parents.
    # $1 = target root (absolute), $2 = relative path. Returns 1 when a
    # symlinked ancestor is found; the caller composes the conflict message.
    rel=$(tk_safe_rel "$2") || exit 1
    cursor=$1
    rest=$rel
    while [ -n "$rest" ]; do
        segment=${rest%%/*}
        if [ "$segment" = "$rest" ]; then
            rest=""
        else
            rest=${rest#*/}
        fi
        cursor="$cursor/$segment"
        if [ -L "$cursor" ]; then
            return 1
        fi
    done
}

tk_prune_empty_parents() {
    # Remove now-empty directories between a removed file and its root.
    dir=$(dirname -- "$1")
    while [ "$dir" != "$2" ] && [ "$dir" != "/" ] && [ "$dir" != "." ]; do
        rmdir "$dir" 2>/dev/null || break
        dir=$(dirname -- "$dir")
    done
}

tk_atomic_write() {
    # Replace $1 with the contents of $2 via a same-directory temp file.
    dest=$1
    src=$2
    tmp="$dest$TK_TMP_SUFFIX"
    cat -- "$src" > "$tmp" || tk_die "cannot write $tmp"
    mv -f -- "$tmp" "$dest" || tk_die "cannot replace $dest"
}

tk_copy_atomic() {
    # Copy file $1 onto path $2 via a same-directory temp file.
    src=$1
    dest=$2
    tmp="$dest$TK_TMP_SUFFIX"
    cat -- "$src" > "$tmp" || tk_die "cannot write $tmp"
    mv -f -- "$tmp" "$dest" || tk_die "cannot replace $dest"
}

# ---------------------------------------------------------------------------
# Canonical ledger JSON readers (strict; fail closed on unknown shapes)
# ---------------------------------------------------------------------------

tk_read_install_ledger() {
    # $1 = ledger file. Prints "path<TAB>sha256" lines. Fails on invalid
    # content. Empty/absent handled by the caller. All structural matching is
    # string equality so no awk regex escapes are involved.
    file=$1
    [ -f "$file" ] || tk_die "Install ledger is not a regular file: $file"
    [ ! -L "$file" ] || tk_die "Install ledger is not a regular file: $file"
    awk '
        function fail(msg) { printf "Invalid install ledger (%s): %s\n", FILENAME, msg > "/dev/stderr"; exit 2 }
        BEGIN { state = "top"; schema_ok = 0 }
        {
            line = $0
            if (state == "top") {
                if (line == "{") next
                if (line == "}") { if (!schema_ok) fail("missing schema_version"); next }
                if (line == "  \"files\": {") { state = "files"; next }
                if (line == "  \"files\": {}" || line == "  \"files\": {},") next
                if (line == "  \"schema_version\": 1" || line == "  \"schema_version\": 1,") { schema_ok = 1; next }
                if (line ~ /^  "(bundle|platform|scope|source_sha256|toolkit|version)": ".*",?$/) next
                fail("unexpected line: " line)
            } else if (state == "files") {
                if (line == "  }" || line == "  },") { state = "top"; next }
                if (line ~ /^    "[^"]*": "[0-9a-f]*",?$/) {
                    entry = line
                    sub(/,$/, "", entry)
                    sub(/^    "/, "", entry)
                    sep = index(entry, "\": \"")
                    if (sep < 1) fail("bad entry: " line)
                    key = substr(entry, 1, sep - 1)
                    val = substr(entry, sep + 4)
                    sub(/"$/, "", val)
                    if (val !~ /^[0-9a-f]+$/ || length(val) != 64) fail("bad hash for " key)
                    print key "\t" val
                    next
                }
                fail("unexpected files entry: " line)
            }
        }
        END { if (state != "top") fail("truncated") }
    ' "$file" || tk_die "Unsupported or invalid install ledger: $file"
}

tk_read_shared_ledger() {
    # $1 = shared-skills ledger file. Prints "path<TAB>hash<TAB>owner,owner"
    # lines (owners comma-separated, no spaces inside owners).
    file=$1
    [ -f "$file" ] || tk_die "Shared skills ledger is not a regular file: $file"
    [ ! -L "$file" ] || tk_die "Shared skills ledger is not a regular file: $file"
    awk '
        function fail(msg) { printf "Invalid shared skills ledger (%s): %s\n", FILENAME, msg > "/dev/stderr"; exit 2 }
        function flushrecord() {
            if (path != "") {
                if (hash !~ /^[0-9a-f]+$/ || length(hash) != 64) fail("bad hash for " path)
                print path "\t" hash "\t" owners
            }
            path = ""; hash = ""; owners = ""
        }
        BEGIN { state = "top"; schema_ok = 0 }
        {
            line = $0
            if (state == "top") {
                if (line == "{") next
                if (line == "}") { if (!schema_ok) fail("missing schema_version"); next }
                if (line == "  \"files\": {") { state = "files"; next }
                if (line == "  \"files\": {}" || line == "  \"files\": {},") next
                if (line == "  \"schema_version\": 1" || line == "  \"schema_version\": 1,") { schema_ok = 1; next }
                fail("unexpected line: " line)
            } else if (state == "files") {
                if (line == "  }" || line == "  },") { flushrecord(); state = "top"; next }
                if (length(line) > 8 && substr(line, 1, 5) == "    \"" && substr(line, length(line) - 2) == ": {") {
                    flushrecord()
                    path = substr(line, 6)
                    path = substr(path, 1, length(path) - 4)
                    sub(/^"/, "", path)
                    state = "entry"
                    next
                }
                fail("unexpected files entry: " line)
            } else if (state == "entry") {
                hp = "      \"hash\": \""
                if (index(line, hp) == 1) {
                    hash = substr(line, length(hp) + 1)
                    sub(/",?$/, "", hash)
                    next
                }
                if (line == "      \"owners\": [") { state = "owners"; next }
                if (line == "      \"owners\": []" || line == "      \"owners\": [],") next
                if (line == "    }" || line == "    },") { flushrecord(); state = "files"; next }
                fail("unexpected record line: " line)
            } else if (state == "owners") {
                if (line == "      ]" || line == "      ],") { state = "entry"; next }
                if (length(line) > 10 && substr(line, 1, 9) == "        \"") {
                    owner = substr(line, 10)
                    sub(/",?$/, "", owner)
                    owners = (owners == "" ? owner : owners "," owner)
                    next
                }
                fail("unexpected owners line: " line)
            }
        }
        END {
            flushrecord()
            if (state != "top" && state != "files" && state != "entry") fail("truncated")
        }
    ' "$file" || tk_die "Unsupported or invalid shared skills ledger: $file"
}

# ---------------------------------------------------------------------------
# Canonical ledger JSON writers (byte-identical to Python json.dumps)
# ---------------------------------------------------------------------------

tk_write_install_ledger() {
    # $1 = output path, $2 = entries file ("path<TAB>hash", LC_ALL=C sorted),
    # then keyword pairs: toolkit= version= source_sha256= platform= bundle=
    # scope=
    out=$1
    entries=$2
    shift 2
    toolkit=""; version=""; sha=""; platform=""; bundle=""; scope=""
    while [ $# -gt 0 ]; do
        case "$1" in
            toolkit=*) toolkit=${1#toolkit=} ;;
            version=*) version=${1#version=} ;;
            source_sha256=*) sha=${1#source_sha256=} ;;
            platform=*) platform=${1#platform=} ;;
            bundle=*) bundle=${1#bundle=} ;;
            scope=*) scope=${1#scope=} ;;
        esac
        shift
    done
    count=$(wc -l < "$entries" | tr -d ' ')
    [ "$count" -gt 0 ] || count=0
    awk -v toolkit="$toolkit" -v version="$version" -v sha="$sha" \
        -v platform="$platform" -v bundle="$bundle" -v scope="$scope" \
        -v count="$count" '
        BEGIN {
            printf "{\n"
            printf "  \"bundle\": \"%s\",\n", bundle
            if (count == 0) {
                printf "  \"files\": {},\n"
            } else {
                printf "  \"files\": {\n"
            }
            entry_index = 0
        }
        NR <= count {
            split($0, pair, "\t")
            entry_index++
            comma = (entry_index < count) ? "," : ""
            printf "    \"%s\": \"%s\"%s\n", pair[1], pair[2], comma
        }
        END {
            if (count > 0) printf "  },\n"
            printf "  \"platform\": \"%s\",\n", platform
            printf "  \"schema_version\": 1,\n"
            printf "  \"scope\": \"%s\",\n", scope
            printf "  \"source_sha256\": \"%s\",\n", sha
            printf "  \"toolkit\": \"%s\",\n", toolkit
            printf "  \"version\": \"%s\"\n", version
            printf "}\n"
        }
    ' "$entries" > "$out"
}

tk_write_shared_ledger() {
    # $1 = output path, $2 = entries file ("path<TAB>hash<TAB>owner,owner",
    # LC_ALL=C sorted by path).
    out=$1
    entries=$2
    count=$(wc -l < "$entries" | tr -d ' ')
    [ "$count" -gt 0 ] || count=0
    awk -v count="$count" '
        BEGIN {
            printf "{\n"
            if (count == 0) printf "  \"files\": {},\n"
            else printf "  \"files\": {\n"
            entry_index = 0
        }
        NR <= count {
            split($0, cols, "\t")
            owners_n = split(cols[3], owners, ",")
            entry_index++
            printf "    \"%s\": {\n", cols[1]
            printf "      \"hash\": \"%s\",\n", cols[2]
            printf "      \"owners\": ["
            if (owners_n > 0) printf "\n"
            for (i = 1; i <= owners_n; i++) {
                printf "        \"%s\"%s\n", owners[i], (i < owners_n) ? "," : ""
            }
            printf "      ]\n"
            printf "    }%s\n", (entry_index < count) ? "," : ""
        }
        END {
            if (count > 0) printf "  },\n"
            printf "  \"schema_version\": 1\n"
            printf "}\n"
        }
    ' "$entries" > "$out"
}

# ---------------------------------------------------------------------------
# Package metadata (.agent-toolkit-package.json) readers
# ---------------------------------------------------------------------------

tk_pkg_scalar() {
    # $1 = metadata file, $2 = key. Prints the string value or nothing.
    awk -v key="$2" '
        BEGIN { prefix = "  \"" key "\": \"" }
        index($0, prefix) == 1 {
            line = substr($0, length(prefix) + 1)
            sub(/",?$/, "", line)
            print line
            exit
        }
    ' "$1"
}

tk_pkg_string_list() {
    # $1 = metadata file, $2 = top-level array key of strings.
    awk -v key="$2" '
        BEGIN { state = "outside"; prefix = "  \"" key "\": [" }
        {
            line = $0
            if (state == "outside") {
                if (index(line, prefix) == 1) {
                    tail = substr(line, length(prefix) + 1)
                    if (tail == "]" || tail == "],") exit
                    state = "inside"
                }
            } else {
                if (line == "  ]" || line == "  ],") exit
                if (index(line, "    \"") == 1) {
                    item = substr(line, 6)
                    sub(/",?$/, "", item)
                    print item
                }
            }
        }
    ' "$1"
}

tk_pkg_merge_files() {
    # $1 = metadata file. Prints "merge_file<TAB>target" lines in order.
    awk '
        BEGIN { state = "outside"; prefix = "  \"merge_files\": [" }
        {
            line = $0
            if (state == "outside") {
                if (index(line, prefix) == 1) {
                    tail = substr(line, length(prefix) + 1)
                    if (tail == "]" || tail == "],") exit
                    state = "list"
                }
            } else if (state == "list") {
                if (line == "  ]" || line == "  ],") exit
                if (line == "    {" || line == "    },") {
                    if (line == "    },") {
                        if (merge_file != "" && target != "") print merge_file "\t" target
                        merge_file = ""; target = ""
                    }
                    next
                }
                if (line == "    }") {
                    if (merge_file != "" && target != "") print merge_file "\t" target
                    merge_file = ""; target = ""
                    next
                }
                mp = "      \"merge_file\": \""
                tp = "      \"target\": \""
                if (index(line, mp) == 1) {
                    merge_file = substr(line, length(mp) + 1)
                    sub(/",?$/, "", merge_file)
                } else if (index(line, tp) == 1) {
                    target = substr(line, length(tp) + 1)
                    sub(/",?$/, "", target)
                }
            }
        }
    ' "$1"
}

tk_adapter_global_scalar() {
    # $1 = adapter.json, $2 = key inside the "global" block.
    awk -v key="$2" '
        BEGIN { in_global = 0 }
        {
            if (index($0, "\"global\": {") > 0) { in_global = 1; next }
            if (in_global && ($0 == "  }," || $0 == "  }")) in_global = 0
            if (in_global) {
                prefix = "    \"" key "\": \""
                if (index($0, prefix) == 1) {
                    line = substr($0, length(prefix) + 1)
                    sub(/",?$/, "", line)
                    print line
                    exit
                }
            }
        }
    ' "$1"
}

# ---------------------------------------------------------------------------
# Managed blocks (codex TOML + global instruction files)
# ---------------------------------------------------------------------------

tk_block_split() {
    # Split $1 around the managed block markers $2 (begin) and $3 (end).
    # Writes the exact "before" bytes to $4 and "after" bytes to $5.
    # Exit: 0 block present, 1 absent, 2 malformed (begin without end).
    file=$1; begin=$2; end=$3; before_out=$4; after_out=$5
    if [ ! -f "$file" ]; then
        : > "$before_out"
        : > "$after_out"
        return 1
    fi
    if [ -L "$file" ]; then
        printf '%s\n' "Instruction/config file is not a regular file: $file" >&2
        return 3
    fi
    if [ -n "$(tail -c 1 "$file" 2>/dev/null)" ]; then
        trailing_newline=0
    else
        trailing_newline=1
    fi
    awk -v begin_marker="$begin" -v end_marker="$end" \
        -v before_out="$before_out" -v after_out="$after_out" \
        -v trailing_newline="$trailing_newline" '
        BEGIN { printf "" > before_out; printf "" > after_out }
        { buf = buf $0 "\n" }
        END {
            if (!trailing_newline && length(buf) > 0) buf = substr(buf, 1, length(buf) - 1)
            b = index(buf, begin_marker)
            if (b == 0) {
                printf "%s", buf > before_out
                exit 1
            }
            if (b > 1) printf "%s", substr(buf, 1, b - 1) > before_out
            rest = substr(buf, b + length(begin_marker))
            e = index(rest, end_marker)
            if (e == 0) exit 2
            after = substr(rest, e + length(end_marker))
            # Python eats the single newline that terminates the end-marker
            # line; mirror that so before/after match byte-for-byte.
            if (substr(after, 1, 1) == "\n") after = substr(after, 2)
            printf "%s", after > after_out
            exit 0
        }
    ' "$file"
}

tk_block_compose() {
    # Write to $1 the file content for one managed-block operation.
    # $2 = mode (create|append|update), $3 = before file, $4 = block file,
    # $5 = after file. Mirrors the Python installer byte-for-byte.
    out=$1; mode=$2; before=$3; block=$4; after=$5
    case "$mode" in
        create)
            cat -- "$block" > "$out"
            ;;
        append)
            # Python: ensure base ends with "\n", then with "\n\n".
            if [ -s "$before" ]; then
                cat -- "$before" > "$out"
                last2=$(tail -c 2 "$before" | od -An -tx1 | tr -d ' \n')
                case "$last2" in
                    0a0a) ;;
                    *0a) printf '\n' >> "$out" ;;
                    *) printf '\n\n' >> "$out" ;;
                esac
            fi
            cat -- "$block" >> "$out"
            ;;
        update)
            cat -- "$before" "$block" "$after" > "$out"
            ;;
        *)
            tk_die "unknown block mode: $mode"
            ;;
    esac
}

tk_wrap_instruction_block() {
    # Wrap the body file $1 with instruction managed-block markers into $2.
    {
        printf '%s\n' "$TK_INSTR_BLOCK_BEGIN"
        cat -- "$1"
        printf '%s\n' "$TK_INSTR_BLOCK_END"
    } > "$2"
}
