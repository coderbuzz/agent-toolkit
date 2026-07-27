# Portable Agentic SDLC Toolkit

Vendor-neutral SDLC instructions, bounded agent roles, reusable skills, and deterministic
exporters for agentic coding tools.

This directory is a complete source package. Move its contents to a clean repository; do not
execute the discovery draft. The draft records design evidence, while `manifest.json`,
`agents/`, `.agents/skills/`, and `scripts/toolkit.py` are the implemented source of truth.

## Goals

- Provide one coherent SDLC from discovery through release and documentation.
- Keep canonical behavior independent from models, proprietary tool names, and permissions.
- Export native packages for Codex, OpenCode, GitHub Copilot, and Claude Code.
- Apply least privilege to every generated agent.
- Install without silently overwriting user-owned or user-modified files.
- Validate structure, traceability conventions, exports, installation, and drift without
  third-party runtime dependencies.

## Requirements

- Python 3.9 or newer
- A repository using at least one supported agentic coding platform

PyYAML is needed only for the optional upstream OpenAI skill validator. The toolkit's own
validator uses the Python standard library.

## Quick Start

### One-Line Terminal Installation (No Clone Required)

Install directly into any project or machine-wide (`--global`) without cloning the repository first:

**Linux / macOS**:
```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash
```

**Windows (PowerShell)**:
```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.ps1 | iex
```

Pass arguments directly to target specific platforms or apply changes automatically:
```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash -s -- --platform opencode --global --apply
```

### Local Repository Usage

Run all commands from this directory.

```bash
python3 scripts/toolkit.py validate
python3 -m unittest discover -s tests -v
python3 scripts/toolkit.py export --all --bundle core
python3 scripts/toolkit.py check-drift --all --bundle core
```

The full POSIX validation sequence is also available as:

```bash
./scripts/validate-all.sh
```

Windows users can run `scripts/validate-all.ps1` from PowerShell.

Preview an installation into another repository:

```bash
python3 scripts/toolkit.py install \
  --platform opencode \
  --bundle core \
  --target ../my-project
```

Apply the exact preflighted operation:

```bash
python3 scripts/toolkit.py install \
  --platform opencode \
  --bundle core \
  --target ../my-project \
  --apply
```

The thin wrappers `scripts/install.sh` and `scripts/install.ps1` accept the same arguments and
preserve the CLI's preview-first behavior. They add two conveniences:

- `--global` is a shorthand for `--scope global`.
- Omitting `--platform` (without `--all`/`--package`) prints a short usage hint with the
  valid platforms instead of a raw parser error.

For a guided first-time setup, run the interactive helper:

```bash
./scripts/setup.sh            # prompts for platform, scope, and target; previews, then asks to apply
```

`setup.sh` always previews first and applies only after you answer `y`. Windows users can run
`scripts/validate-all.ps1` from PowerShell for the validation pipeline.

### Global (machine-wide) installation

Install once into your home directory so every repository inherits the same skills, agents, and
guidance without per-repository duplication. Use `--scope global`; the target defaults to your
home directory.

```bash
python3 scripts/toolkit.py install --platform opencode --scope global
python3 scripts/toolkit.py install --platform opencode --scope global --apply
```

Global installs use each platform's home-relative configuration location, and all platforms share
a single copy of the skills under `~/.agents/skills` (read by OpenCode, Codex, Claude Code, and
GitHub Copilot). Shared skills are reference-counted, so uninstalling one platform never removes
skills another platform still uses.

| Platform | Global instructions | Global agents | Global skills |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | managed block in `~/.codex/config.toml` | `~/.agents/skills/*` |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/agents/*.md` | `~/.agents/skills/*` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/agents/*.md` | `~/.agents/skills/*` |
| GitHub Copilot | `~/.copilot/copilot-instructions.md` | `~/.copilot/agents/*.agent.md` | `~/.agents/skills/*` |
| OMP | `~/.omp/agent/AGENTS.md` | `~/.omp/agent/agents/*.md` | `~/.agents/skills/*` |
| Gemini / Antigravity | `~/.gemini/antigravity/AGENTS.md` | `~/.gemini/antigravity/agents/*.md` | `~/.agents/skills/*` |

Codex agents are folded into `~/.codex/config.toml` inside a managed block delimited by
`# >>> portable-sdlc agents ... >>>` and `# <<< portable-sdlc agents <<<`. Content outside the
block is never touched, the merge is idempotent, and uninstall removes only the managed block.
Global instruction files (`~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`,
`~/.claude/CLAUDE.md`, `~/.copilot/copilot-instructions.md`, `~/.omp/agent/AGENTS.md`) use the same managed-block approach:
if you already have that file, the portable guidance is appended inside a
`# >>> portable-sdlc instructions ... >>>` block and your existing content is left untouched.
Uninstall removes only that managed block. (Claude Code's global `CLAUDE.md` inlines the
canonical `AGENTS.md` content rather than importing it, because no `AGENTS.md` exists at the
home level.)
Global skills and agents act as machine-wide defaults; a project-level install still overrides
them for that repository.

Uninstall one platform's global footprint (requires `--platform`):

```bash
python3 scripts/toolkit.py uninstall --platform opencode --scope global
python3 scripts/toolkit.py uninstall --platform opencode --scope global --apply
```

The installer never replaces a differing user-owned file outside a managed block. If a target
instruction file already exists and is not owned by the toolkit, its content is preserved and
the portable guidance is added as a managed block. If you edit inside a managed block, the
next install reports a conflict so you can reconcile it intentionally. Identical managed blocks
are idempotent; uninstall removes only the managed block and leaves the rest of your file intact.

## Toolkit Layout

```text
.
├── AGENTS.md                 # Portable always-on behavior
├── manifest.json             # Inventory, bundles, platforms, and policy
├── agents/definitions.json   # Neutral roles and capability intents
├── .agents/skills/           # Canonical reusable procedures
├── instructions/             # Shared communication and quality rules
├── standards/                # Glossary, ADR, and traceability contracts
├── templates/                # SDLC artifact templates
├── platforms/                # Native format and permission mappings
├── scripts/toolkit.py        # Validator, exporter, installer, and drift checker
├── tests/                    # Standard-library test suite
├── docs/                     # Architecture, platform, and operating guides
└── dist/                     # Generated packages; never edit directly
```

## SDLC Flow

The router chooses the smallest safe lane. The complete feature lane is:

```text
Discovery
  -> Product Requirements
  -> Clarification
  -> Technical Specification
  -> Clarification
  -> Traceability Audit
  -> Implementation Plan
  -> Clarification
  -> Traceability Audit
  -> Implementation
  -> Independent Verification
  -> Code Review
  -> Release Readiness
  -> Documentation Delivery
```

Bug fixes, small changes, documentation, incidents, and migrations use narrower lanes while
preserving evidence, tests, independent checks, and approval gates proportional to risk.

## Bundles

| Bundle | Contents | Intended use |
| --- | --- | --- |
| `core` | Lifecycle and cross-cutting skills | Default development workflow |
| `full` | Core plus optional specialist skills | Broad product and operations coverage |
| `quality` | Audit, testing, security, verification, and review | Quality overlay for an existing setup |

All 12 agent definitions are exported. Recommended skills are advisory, so an agent remains
usable when a narrow bundle omits a specialist procedure.

## Platform Support

| Platform | Native agents | Skills | Project instructions |
| --- | --- | --- | --- |
| Codex | `.codex/agents/*.toml` | `.agents/skills/*` | `AGENTS.md` |
| OpenCode | `.opencode/agents/*.md` | `.agents/skills/*` | `AGENTS.md` |
| GitHub Copilot | `.github/agents/*.agent.md` | `.agents/skills/*` | `.github/copilot-instructions.md` |
| Claude Code | `.claude/agents/*.md` | `.claude/skills/*` | `CLAUDE.md` importing `AGENTS.md` |
| Gemini / Antigravity | `.gemini/agents/*.md` | `.agents/skills/*` | `AGENTS.md` |

Generated agents receive explicit, fail-closed permission mappings. The canonical agents use
capability intent rather than platform tool names.

## Command Reference

### Validate

```bash
python3 scripts/toolkit.py validate
python3 scripts/toolkit.py validate --dist dist --bundle core
```

### Export

```bash
python3 scripts/toolkit.py export --platform codex --bundle core
python3 scripts/toolkit.py export --all --bundle full --output dist
python3 scripts/toolkit.py export --all --bundle core --check
```

Exports are deterministic. Each platform directory is generated through a staging directory,
validated, and atomically replaced. A source digest allows drift detection without timestamps.

### Install and Uninstall

Both commands default to preview mode. Add `--apply` only after reviewing the listed actions.

```bash
python3 scripts/toolkit.py install --platform claude-code --target ../my-project
python3 scripts/toolkit.py install --package dist/claude-code --target ../my-project --apply
python3 scripts/toolkit.py uninstall --target ../my-project
python3 scripts/toolkit.py uninstall --target ../my-project --apply
python3 scripts/toolkit.py install --platform claude-code --scope global --apply
python3 scripts/toolkit.py uninstall --platform claude-code --scope global --apply
```

Add `--scope global` to install or uninstall into the home directory instead of a repository.
Repository installs record hashes in `.portable-sdlc-install.json`. Global installs use a
per-platform ledger (`.portable-sdlc-install-<platform>.json`) plus a shared, reference-counted
skills ledger (`.portable-sdlc-shared-skills.json`). Uninstall removes only unchanged managed
files and preserves modified files with a warning.

### Drift Check

```bash
python3 scripts/toolkit.py check-drift --all --bundle core --output dist
```

The command fails when a generated file is missing, changed, or unexpected.

## Extending the Toolkit

1. Add or refine canonical behavior first.
2. Register new skills, agents, platforms, or bundles in `manifest.json`.
3. Keep platform syntax under `platforms/` and renderer code under `scripts/`.
4. Add tests for validation, native output, permissions, installation, and drift.
5. Run canonical validation, the full suite, a fresh export, package validation, and drift check.

See [Architecture](docs/architecture.md), [Platform Contracts](docs/platform-support.md),
[Refinement Map](docs/refinement-map.md), and [Maintainer Guide](docs/maintainer-guide.md) for
the detailed contracts.

## References & Inspiration

This project draws inspiration and architectural patterns from open-source community standards and official agentic platform specifications:

- **[awesome-copilot-id](https://github.com/GulajavaMinistudio/awesome-copilot-id)** by GulajavaMinistudio – Primary reference and inspiration for prompt structures, skill format conventions, role definitions, and terminal installation workflows.
- **[OpenCode](https://opencode.ai)** – Agent role definitions, configuration layout, and shared skill conventions.
- **[OpenAI Codex & Agent Specifications](https://github.com/openai)** – `AGENTS.md` format, fail-closed permission models, and instruction blocks.
- **[Anthropic Claude Code](https://docs.anthropic.com)** – `CLAUDE.md` guidelines, subagent definition patterns, and skill structures.
- **[GitHub Copilot Custom Instructions](https://docs.github.com/en/copilot)** – Custom agent instructions and prompt engineering patterns.
- **[Google Antigravity / Gemini CLI](https://cloud.google.com)** – Gemini/Antigravity integration and agentic workflow orchestration standards.

