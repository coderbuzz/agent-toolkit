# Platform Contracts

## Compatibility Policy

Platform exports target the native customization paths listed below. Repository scope uses each
platform's project-level paths; global scope uses each platform's home-relative paths (see
[Global Scope](#global-scope)). The canonical package avoids pinned model names and proprietary
MCP server identifiers. Revalidate adapters when a host platform changes its schema.

| Platform | Instruction strategy | Skill strategy | Slash commands |
| --- | --- | --- | --- |
| Codex | Root `AGENTS.md` | Canonical `.agents/skills` | n/a |
| OpenCode | Root `AGENTS.md` | Canonical `.agents/skills` | Generated `commands/<skill>.md` |
| GitHub Copilot | Generated Copilot instructions | Canonical `.agents/skills` | n/a |
| Claude Code | `CLAUDE.md` imports `AGENTS.md` | Copy to `.claude/skills` (repo) | n/a |
| Gemini / Antigravity | Root `AGENTS.md` | Canonical `.agents/skills` | n/a |
| OMP | Root `AGENTS.md` | Canonical `.agents/skills` | n/a |
| ZCode | Root `AGENTS.md` | Canonical `.agents/skills` | Native (every skill is `/<name>`) |

The toolkit ships skills only; there is no agent roster to render per platform. Each skill's
frontmatter (`name`, `description`, `invocation`, `role`) is the full contract.

## Platform Resolution by an Agent

Nothing detects the platform for the agent. `AGENT-INSTALL.md` gives it the table above as a
mapping from "which tool am I running as" to a platform id, and requires it to **ask the user**
rather than guess when it cannot decide. An agent that picks the closest match would write to the
wrong paths and record them in a ledger, so the protocol treats an unresolved platform as a stop
condition rather than something to infer.

## The Files Manifest

Every generated package carries `.agent-toolkit-files.json` alongside `.agent-toolkit-package.json`:

```json
{ "schema_version": 1,
  "files": [ { "path": ".agents/skills/start/SKILL.md", "role": "shared-skill", "sha256": "..." } ] }
```

`role` is one of `regular`, `shared-skill`, `instruction-block`, or `command`, and it decides how a
file is installed: `shared-skill` files are reference counted, `instruction-block` names the file
that receives the managed block, and everything else is copied and ledgered. Repository packages
contain only `regular` files.

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
`.agents/skills` directory (repository and `~/.agents/skills` global) with no extra wiring, so
every discovered skill is automatically available as `/<name>`. Global installs therefore only
write the pointer file `~/.zcode/AGENTS.md`; no command files are generated.

## Shared Assets

Every package embeds `.agents/instructions`, `.agents/standards`, and `.agents/templates` next to
the skills. These are plain files copied under the adapter's paths; no platform-specific rendering
is applied to them.

## Global Scope

Repository scope is the default. Global installation places one machine-wide copy of the toolkit in
the home directory so every repository inherits the same behavior without per-repository
duplication; it is used only when the user asks for it. Each adapter declares a
`global` block with home-relative paths:

| Platform | Global instructions | Global skills | Global commands |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | `~/.agents/skills/<skill>` | n/a |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/<skill>` | `~/.config/opencode/commands/<skill>.md` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.agents/skills/<skill>` | n/a |
| GitHub Copilot | `~/.copilot/copilot-instructions.md` | `~/.agents/skills/<skill>` | n/a |
| OMP | `~/.omp/agent/AGENTS.md` | `~/.agents/skills/<skill>` | n/a |
| Gemini / Antigravity | `~/.gemini/antigravity/AGENTS.md` | `~/.agents/skills/<skill>` | n/a |
| ZCode | `~/.zcode/AGENTS.md` | `~/.agents/skills/<skill>` | n/a (native `/<name>`) |

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
3. Register the platform ID in `manifest.json` (`platforms`).
4. Regenerate `dist/` with `python3 scripts/toolkit.py export --all --bundle core` and extend the
   platform tuples in `tests/test_validation.py` and `tests/test_global_install.py`.
5. Add the platform to the tables above, to the tables in `AGENT-INSTALL.md` sections 2 and 6, and
   to both READMEs. `tests/test_agent_protocol.py` fails until the protocol's tables match the
   manifest and the adapter, so an agent is never told a path the exporter does not produce.
