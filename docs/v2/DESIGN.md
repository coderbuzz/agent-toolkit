# v2 Design — Best of Both

Snapshot sebelum refactor: branch `archive/main-20260829`, tag `archive-main-20260829`.

## Sources
- mattpocock/skills (principles): grilling, shared language (CONTEXT.md), TDD
  as core discipline, model-invoked skills, user-invoked vs model-invoked split.
- agent-toolkit v0.1 (process): lane routing, artifact gates, fail-closed
  installer, drift-check, vendor-neutral dist, bilingual docs.

## v2 Decisions
1. **AGENTS.md global = pointer only (<2KB).** Skills load on demand; the
   global file lists names + one-line triggers, never full procedures.
2. **Kill the 14-persona agent roster & session locking.** Each skill declares
   a compact `role:` in frontmatter. Fewer moving parts, same accountability.
3. **New skills from Matt:**
   - `grill` (user-invoked): two-way interview before any irreversible work.
     Merges and replaces `clarify` as the default ambiguity tool.
   - `context` (model-invoked): owns CONTEXT.md — shared language, domain
     terms, project invariants. Promoted from support skill to core technique.
4. **TDD folded into `implement`:** red-green-refactor steps are part of the
   build skill; `test` stays as a utility (scaffolding suites), not a gate phase.
5. **Lanes stay, gates stay.** Routing (start) and approval gates are the
   strongest idea in v0.1; unchanged in spirit, simplified in wording.
6. **Frontmatter adds `invocation: user|model|both`** per Matt's taxonomy.
7. **Installer/drift-check unchanged** (they were already good).

## Skill Roster v2 (draft)
Core: start, grill, context, discover, define, design, plan, implement,
review, verify, fix, release, document
Utility: guardrails, memory, glossary (alias of context), decide, test,
threat, audit-deps, orchestrate
Specialists (full bundle): design-ui, incident, observability, migrate

## v2 Naming & Scope (2026-08-29)
8. **No `sdlc-` prefix.** Skills live as `start`, `grill`, `implement`, etc.
   Directory name == frontmatter `name` == slash command name. Shorter to type,
   no namespace collision in practice (skills are loaded on demand, not all at
   once).
9. **`implement` supersedes the old v0.1 execution skill** (now kept only as
   `implement-execution` reference in git history; the v2 skill folds TDD into
   the build loop).
10. **Default install scope = global.** `toolkit.py install --platform <p>
    --apply` targets `~` and writes pointer files into each platform's global
    config (`~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md`, ...). Skills
    are shared cross-platform at `~/.agents/skills/`. Repository scope remains
    available via `--scope repository` for team-pinned/reproducible setups
    (CI, open-source repos).

## v2 Installer Architecture (2026-08-30)
11. **Pure-shell installers, zero runtime deps.** `scripts/install.sh`,
    `scripts/uninstall.sh` (POSIX sh + awk) and their PowerShell twins install
    straight from pre-built packages. Python is a maintainer-only build tool
    (validate/export/drift-check), never an install requirement. The former
    "delegate to toolkit.py" shortcut is gone.
12. **Pre-built global packages.** `toolkit.py export` now emits both
    `dist/<platform>` (repository layout) and `dist/global/<platform>`
    (home-relative layout: shared skills, agent files or the Codex TOML merge
    block, instruction pointer, OpenCode slash commands). Installers consume
    dist/ as-is; validate/check-drift cover both scopes.
13. **Canonical ledger format.** All three installers (POSIX, PowerShell,
    Python) write byte-identical ledger JSON (json.dumps indent=2 sort_keys
    convention), so any uninstaller can safely read any install. Tests assert
    the byte parity for both repository and global scope.
14. **Fail-closed parity.** The shell port mirrors toolkit.py semantics
    exactly: preview-first dry runs, never overwrite user-modified managed
    files, shared-skill reference counting across platforms, managed-block
    append/update/unmerge, stale-file cleanup, empty-parent pruning, exit 2
    on preserved-modified warnings. Known divergence: the shell apply phase
    has no full transactional rollback (per-file ops are atomic via
    temp+rename; the ledger is written only after all file ops succeed).
15. **AGENTS.md promoted to the v2 pointer file** (1.3 KB): routes to skills
    on demand instead of embedding full procedures. This is the content the
    global installer writes into each platform's instruction file.
16. **Legacy v0.1 awareness.** The global installer warns when it detects a
    `portable-sdlc` managed block it does not manage; the block is left for
    the user to remove.
