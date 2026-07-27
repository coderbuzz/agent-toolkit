# Platform Contracts

## Compatibility Policy

Platform exports target the native customization paths listed below. Repository scope uses each
platform's project-level paths; global scope uses each platform's home-relative paths (see
[Global Scope](#global-scope)). The canonical package avoids pinned model names and proprietary
MCP server identifiers. Revalidate adapters when a host platform changes its agent schema.

| Platform | Agent format | Instruction strategy | Skill strategy |
| --- | --- | --- | --- |
| Codex | TOML | Root `AGENTS.md` | Canonical `.agents/skills` |
| OpenCode | Markdown with YAML frontmatter | Root `AGENTS.md` | Canonical `.agents/skills` |
| GitHub Copilot | Markdown with YAML frontmatter | Generated Copilot instructions | Canonical `.agents/skills` |
| Claude Code | Markdown with YAML frontmatter | `CLAUDE.md` imports `AGENTS.md` | Copy to `.claude/skills` |
| Gemini / Antigravity | Markdown with YAML frontmatter | Root `AGENTS.md` | Canonical `.agents/skills` |

## Codex

### Generated Layout

```text
AGENTS.md
.agents/skills/<skill>/...
.codex/agents/<agent>.toml
```

Each agent has `name`, `description`, `developer_instructions`, and `sandbox_mode`. Agents with
no write-oriented capability receive `read-only`. Documentation, implementation, and release
roles receive `workspace-write`; their instructions still approval-gate irreversible or
external actions. The exporter never emits `danger-full-access`.

Codex reads the canonical `.agents/skills` location directly, so no duplicate skill copy is
needed.

## OpenCode

### Generated Layout

```text
AGENTS.md
.agents/skills/<skill>/...
.opencode/agents/<agent>.md
```

Every generated agent uses `mode: subagent` and the singular `permission` map. Read access is
allowed, editing is denied unless the neutral role can write, external-directory access is
denied, and shell or task delegation is approval-gated when applicable.

OpenCode exposes general shell access rather than a portable read-only shell subset. Agent
instructions therefore restrict command behavior in addition to native permission mapping.

## GitHub Copilot

### Generated Layout

```text
AGENTS.md
.agents/skills/<skill>/...
.github/agents/<agent>.agent.md
.github/copilot-instructions.md
```

Each custom agent has an explicit `tools` allowlist. Omitting that field can broaden access, so
the exporter always emits read and search explicitly, then adds edit or execute only when the
neutral capabilities require them.

The generated Copilot instructions reproduce canonical `AGENTS.md` behavior and contain the
same source digest as the generated agents.

## Claude Code

### Generated Layout

```text
AGENTS.md
CLAUDE.md
.claude/agents/<agent>.md
.claude/skills/<skill>/...
```

Claude Code receives a native skill copy because its project skill discovery path differs from
the canonical location. `CLAUDE.md` imports `AGENTS.md`, keeping one instruction source inside
the package.

Read-only roles receive `Read`, `Grep`, and `Glob`, plus `Bash` only when command or test
capability is needed. Write-capable roles receive `Write` and `Edit`. Read-only roles use
`permissionMode: plan`; write-oriented roles use `default`. The exporter never emits
`bypassPermissions`.

## Shared Assets

Every package also places shared files under:

```text
.agents/instructions/
.agents/standards/
.agents/templates/
```

This layout follows the same portable customization root as canonical skills. Platform agents
refer to recommended skills by stable ID and do not require absolute paths.

## Global Scope

Global installation places one machine-wide copy of the toolkit in the home directory so every
repository inherits the same behavior without per-repository duplication. Each adapter declares a
`global` block with home-relative paths:

| Platform | Global instructions | Global agents | Global skills |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | Managed block in `~/.codex/config.toml` | `~/.agents/skills/<skill>` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/agents/<agent>.md` | `~/.agents/skills/<skill>` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/agents/<agent>.md` | `~/.agents/skills/<skill>` |
| GitHub Copilot | `~/.copilot/copilot-instructions.md` | `~/.copilot/agents/<agent>.agent.md` | `~/.agents/skills/<skill>` |
| OMP | `~/.omp/agent/AGENTS.md` | `~/.omp/agent/agents/<agent>.md` | `~/.agents/skills/<skill>` |
| Gemini / Antigravity | `~/.gemini/antigravity/AGENTS.md` | `~/.gemini/antigravity/agents/<agent>.md` | `~/.agents/skills/<skill>` |

### Shared skills

All platforms read skills from the shared `~/.agents/skills` location, so a single installed copy
serves every platform. A reference-counted ledger (`.portable-sdlc-shared-skills.json`) records
which platforms own each skill file. Uninstalling one platform releases its reference and removes
a skill only when no other platform still owns it. User-modified skill files are preserved.

### Dynamic Persona Activation

Skills are classified as **persona-bound** or **utility** in `manifest.json`
(`skill_metadata.<skill>.persona_bound`). Persona-bound skills (e.g. `code-review`,
`technical-specification`) carry a `## Dynamic Persona Activation` block in their `SKILL.md`.
This follows the convention used by ecosystems such as `awesome-copilot-id`: invoking a
persona-bound skill transforms the base assistant into that skill's persona and locks the session
to it, while utility skills (e.g. `project-memory`, `engineering-guardrails`) can be invoked at any
time without triggering a session lock. `validate_skills` enforces that every persona-bound skill
has the block and no utility skill does.

### Codex managed block

Codex does not read separate agent files from the home directory, so global agents are folded
into `~/.codex/config.toml` as `[agents.<id>]` tables inside a managed block delimited by
`# >>> portable-sdlc agents ... >>>` and `# <<< portable-sdlc agents <<<`. The merge preserves
all content outside the block, is idempotent, and uninstall removes only the managed block
(deleting the file only if it becomes empty).

### Instruction managed block

Global instruction files use the same managed-block pattern so an existing user file is never
overwritten. If the target instruction file already exists, the portable guidance is appended
inside a block delimited by `# >>> portable-sdlc instructions ... >>>` and
`# <<< portable-sdlc instructions <<<`, leaving the user's existing content intact. Uninstall
removes only that block (deleting the file only if nothing else remains). Claude Code's global
`~/.claude/CLAUDE.md` inlines the canonical `AGENTS.md` content rather than importing it, because
no `AGENTS.md` exists at the home level.

### Precedence

Global skills and agents are machine-wide defaults. A project-level install of the same skill or
agent name overrides the global one for that repository, matching each platform's native
precedence rules.

## Permission Caveats

Native tool access is necessary but not sufficient for safety:

- A general shell tool may run both read-only and mutating commands.
- Release tools may cause external side effects even in a workspace-only sandbox.
- Platform updates may change defaults when a field is omitted.
- Repository instructions cannot supersede host permission enforcement.

The toolkit therefore combines explicit native allowlists with behavioral approval gates. Host
administrators should keep platform runtime approvals enabled.

## Adding a Platform

1. Add the platform ID to `manifest.json`.
2. Create `platforms/<id>/adapter.json` with native project paths, a `global` block of
   home-relative paths, and fail-closed mappings.
3. Add a renderer to `scripts/toolkit.py`.
4. Extend `validate_exported_package` with schema and permission assertions.
5. Add export tests for native discovery paths and least privilege.
6. Add install and drift tests.
7. Generate twice and assert byte-identical packages.

Do not reuse the closest existing format without verifying the target platform's current
schema, instruction precedence, skill discovery path, and permission defaults.
