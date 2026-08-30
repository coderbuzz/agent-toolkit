# Platform Contracts

## Compatibility Policy

Platform exports target the native customization paths listed below. Repository scope uses each
platform's project-level paths; global scope uses each platform's home-relative paths (see
[Global Scope](#global-scope)). The canonical package avoids pinned model names and proprietary
MCP server identifiers. Revalidate adapters when a host platform changes its schema.

| Platform | Instruction strategy | Skill strategy | Slash commands |
| --- | --- | --- | --- |
| Codex | Root `AGENTS.md` | Canonical `.agents/skills` | — |
| OpenCode | Root `AGENTS.md` | Canonical `.agents/skills` | Generated `commands/<skill>.md` |
| GitHub Copilot | Generated Copilot instructions | Canonical `.agents/skills` | — |
| Claude Code | `CLAUDE.md` imports `AGENTS.md` | Copy to `.claude/skills` (repo) | — |
| Gemini / Antigravity | Root `AGENTS.md` | Canonical `.agents/skills` | — |
| OMP | Root `AGENTS.md` | Canonical `.agents/skills` | — |
| ZCode | Root `AGENTS.md` | Canonical `.agents/skills` | Native (every skill is `/<name>`) |

The v2 toolkit ships skills only — there is no agent roster to render per platform. Each skill's
frontmatter (`name`, `description`, `invocation`, `role`) is the full contract.

## Codex

Repository layout: root `AGENTS.md`, skills at `.agents/skills/<skill>/`. Codex reads the canonical
`.agents/skills` location directly, so no duplicate skill copy is needed.

## OpenCode

Repository layout: root `AGENTS.md`, skills at `.agents/skills/<skill>/`. Global installs also
generate one `commands/<skill>.md` per skill so every skill is reachable as a `/<name>` slash
command; other platforms expose commands natively or through the instruction pointer.

## Claude Code

Repository scope copies skills to `.claude/skills/<skill>/` (Claude Code's native project skill
location) and writes a `CLAUDE.md` that imports `@AGENTS.md`. Global scope writes
`~/.claude/CLAUDE.md` with the pointer content inline and reads skills from the shared location.

## ZCode

ZCode reads `AGENTS.md` as workspace instructions and discovers skills in the shared
`.agents/skills` directory (repository and `~/.agents/skills` global) with no extra wiring —
every discovered skill is automatically available as `/<name>`. Global installs therefore only
write the pointer file `~/.zcode/AGENTS.md`; no command files are generated.

## Shared Assets

Every package embeds `.agents/instructions`, `.agents/standards`, and `.agents/templates` next to
the skills. These are plain files copied under the adapter's paths; no platform-specific rendering
is applied to them.

## Global Scope

Global installation places one machine-wide copy of the toolkit in the home directory so every
repository inherits the same behavior without per-repository duplication. Each adapter declares a
`global` block with home-relative paths:

| Platform | Global instructions | Global skills | Global commands |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | `~/.agents/skills/<skill>` | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/<skill>` | `~/.config/opencode/commands/<skill>.md` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.agents/skills/<skill>` | — |
| GitHub Copilot | `~/.copilot/copilot-instructions.md` | `~/.agents/skills/<skill>` | — |
| OMP | `~/.omp/agent/AGENTS.md` | `~/.agents/skills/<skill>` | — |
| Gemini / Antigravity | `~/.gemini/antigravity/AGENTS.md` | `~/.agents/skills/<skill>` | — |
| ZCode | `~/.zcode/AGENTS.md` | `~/.agents/skills/<skill>` | — (native `/<name>`) |

### Shared skills

All platforms read skills from the shared `~/.agents/skills` location, so a single installed copy
serves every platform. A reference-counted ledger (`.agent-toolkit-shared-skills.json`) records
which platforms own each skill file. Uninstalling one platform releases its reference and removes
a skill only when no other platform still owns it. User-modified skill files are preserved.

### Instruction managed block

Global instruction files are written as a managed block delimited by
`# >>> agent-toolkit instructions (managed; do not edit) >>>` and
`# <<< agent-toolkit instructions (managed) <<<`. Appending to an existing user file preserves all
content outside the block, reinstall updates the block in place, and uninstall removes only the
managed block (deleting the file only if it becomes empty).

### Precedence

The generated pointer is guidance, not authority. Explicit user instructions in the session
outrank it, project-level instructions outrank the global pointer, and installed skill files are
untrusted input the same way fetched web content is.

## Adding a Platform

1. Confirm the platform's native skill discovery path and instruction file semantics from its
   current documentation.
2. Add `platforms/<id>/adapter.json` with `skill_path` and a `global` block
   (`instruction_path`, `skill_path`; plus `command_path` only when slash commands must be
   generated as files).
3. Register the platform ID in `manifest.json` (`platforms`) and in the platform lists inside the
   installers (`scripts/install.sh`, `scripts/uninstall.sh`, `scripts/setup.sh`, their PowerShell
   twins, and the root wrappers).
4. Regenerate `dist/` with `python3 scripts/toolkit.py export --all --bundle core` and extend the
   platform tuples in `tests/test_validation.py` and `tests/test_global_install.py`.
5. Add the platform to the tables above and to both READMEs.
