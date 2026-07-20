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
preserve the CLI's preview-first behavior.

The installer never replaces a differing user-owned file. If the target already has an
`AGENTS.md`, reconcile the portable guidance with that project file intentionally, then run
the preview again. Identical files are idempotent and managed files are updated only while
their installed hash remains unchanged.

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
```

Installation records hashes in `.portable-sdlc-install.json`. Uninstall removes only unchanged
managed files and preserves modified files with a warning.

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
