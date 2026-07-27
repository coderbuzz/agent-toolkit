# ⚡ Portable Agentic SDLC Toolkit

> **Supercharge your AI coding agents with vendor-neutral SDLC workflows, bounded roles, and reusable skills — installed in seconds with zero dependencies.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-brightgreen.svg)](#-quick-start)
[![Platform Support](https://img.shields.io/badge/Platforms-Claude%20%7C%20OpenCode%20%7C%20Codex%20%7C%20Copilot%20%7C%20Gemini%20%7C%20OMP-purple.svg)](#-supported-platforms--global-paths)

---

## Why Agentic SDLC Toolkit?

Building with AI coding assistants like Claude Code, OpenCode, GitHub Copilot, Codex, or Gemini? Without clear guardrails, AI agents can jump straight to unverified code, hallucinate dependencies, or overwrite critical files.

**Agentic SDLC Toolkit** gives your AI agents a structured, battle-tested software engineering process from discovery and PRDs to specifications, code review, and release readiness.

- 🚀 **Zero Dependencies**: Pure Shell & PowerShell installers. No Python or Node runtime needed to get started.
- 🎯 **Vendor-Neutral & Portable**: Write your SDLC rules once, deploy seamlessly across any platform.
- 🛡️ **Fail-Closed & Safe**: Preview every install with dry-runs first. Never silently overwrites your custom code or configuration.
- 🤖 **Multi-Platform Native**: Pre-built native packages for Claude Code, OpenCode, Codex, GitHub Copilot, Gemini/Antigravity, and OMP.

---

## 🚀 Quick Start

Run the 1-line installer below. It automatically launches an interactive wizard that guides you through platform and scope selection:

### 🐧 Linux / macOS / WSL
```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash
```

### 🪟 Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.ps1 | iex
```

> **Pro-Tip (Non-Interactive CI / Automation)**: Pass arguments directly to skip prompts and apply immediately:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/main/install.sh | bash -s -- --platform opencode --global --apply
> ```

---

## 🛠️ Local Usage & Interactive Setup

Working inside a local clone of this repository?

```bash
# Interactive setup wizard
./scripts/setup.sh

# Direct installation to a target project
./scripts/install.sh --platform opencode --target ../my-project --apply
```

---

## 🌐 Supported Platforms & Global Paths

Install once globally into your home directory (`$HOME`) so all your repos automatically inherit your AI agents and skills:

| Platform | Global Instructions | Global Agents | Global Skills |
| :--- | :--- | :--- | :--- |
| **Claude Code** | `~/.claude/CLAUDE.md` | `~/.claude/agents/*.md` | `~/.agents/skills/*` |
| **OpenCode** | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/agents/*.md` | `~/.agents/skills/*` |
| **Codex** | `~/.codex/AGENTS.md` | Managed block in `~/.codex/config.toml` | `~/.agents/skills/*` |
| **GitHub Copilot** | `~/.copilot/copilot-instructions.md` | `~/.copilot/agents/*.agent.md` | `~/.agents/skills/*` |
| **OMP** | `~/.omp/agent/AGENTS.md` | `~/.omp/agent/agents/*.md` | `~/.agents/skills/*` |
| **Gemini / Antigravity** | `~/.gemini/antigravity/AGENTS.md` | `~/.gemini/antigravity/agents/*.md` | `~/.agents/skills/*` |

---

## 📦 Skill Bundles

| Bundle | What's Included | Best For |
| :--- | :--- | :--- |
| **`core`** *(default)* | Lifecycle & cross-cutting SDLC skills | Everyday feature development & bug fixes |
| **`full`** | Core + specialist skills (data migration, incident response) | Full product lifecycle & ops |
| **`quality`** | Audit, security, threat modeling & verification | Quality overlays for mature repos |

---

## 💻 Contributor & Maintainer Guide

Developing or extending the toolkit itself? Maintainer tools require **Python 3.9+** (Standard Library only — no third-party pip dependencies required).

### Maintainer Commands

```bash
# Validate canonical skills, agent definitions, and manifests
python3 scripts/toolkit.py validate

# Run the complete test suite
python3 -m unittest discover -s tests -v

# Export generated platform packages into dist/
python3 scripts/toolkit.py export --all --bundle core

# Verify no drift between canonical sources and dist/
python3 scripts/toolkit.py check-drift --all --bundle core

# Run full POSIX validation sequence
./scripts/validate-all.sh
```

---

## 🏗️ Repository Architecture

```text
.
├── AGENTS.md                 # Portable core AI guidance
├── manifest.json             # Toolkit manifest & bundle definitions
├── agents/definitions.json   # Neutral agent role definitions
├── .agents/skills/           # Canonical reusable procedures
├── instructions/             # Shared communication and quality standards
├── standards/                # Architecture & traceability contracts
├── dist/                     # Pre-built packages for instant zero-dep installs
├── install.sh / install.ps1  # Zero-dependency terminal installer scripts
└── scripts/
    ├── install.sh            # Zero-dependency POSIX installer
    ├── install.ps1           # Zero-dependency PowerShell installer
    ├── setup.sh              # Interactive setup helper
    └── toolkit.py            # Maintainer CLI (validate, export, drift-check)
```

---

## 🌟 References & Inspiration

This project draws inspiration and architectural patterns from open-source community standards and official agentic platform specifications:

- **[awesome-copilot-id](https://github.com/GulajavaMinistudio/awesome-copilot-id)** by GulajavaMinistudio – Primary reference for prompt structures, skill format conventions, role definitions, and terminal installation workflows.
- **[OpenCode](https://opencode.ai)** – Agent role definitions and shared skill conventions.
- **[OpenAI Codex & Agent Specifications](https://github.com/openai)** – `AGENTS.md` format and fail-closed permission models.
- **[Anthropic Claude Code](https://docs.anthropic.com)** – `CLAUDE.md` guidelines and subagent patterns.
- **[GitHub Copilot Custom Instructions](https://docs.github.com/en/copilot)** – Custom agent prompt engineering patterns.
- **[Google Antigravity / Gemini CLI](https://cloud.google.com)** – Agentic workflow orchestration standards.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).


