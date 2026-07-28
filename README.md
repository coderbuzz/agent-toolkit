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

## 🔄 SDLC Workflows & Lanes

The toolkit classifies software development into **5 safety lanes** to ensure every change gets the right level of discipline without unnecessary overhead:

| Lane | Trigger & Scope | Required Workflow Steps |
| :--- | :--- | :--- |
| **Full-Feature** | New capabilities, architectural changes, public API/contract changes, sensitive data handling | Discovery → PRD → Spec → Plan → Execution → Verification → Code Review |
| **Bug-Fix** | Reproducible defects with clear intended behavior | Reproduce → Causal Chain Root Cause → Minimal Fix Plan → Test & Fix → Verify |
| **Small-Change** | Low-risk, reversible, narrowly scoped changes | Direct Minimal Fix → Unit/Integration Test Verification → Code Review |
| **Documentation** | Pure documentation or comment updates | Audit → Draft/Update → Verify Links & Clarity |
| **Incident** | Active production outage, security event, or data loss | Severity Assessment → Containment → Root Cause Review → Post-Mortem |

> 💡 **Automatic Routing**: If you're unsure which lane to use, just ask your agent: *"Use `sdlc-router` to determine the best workflow for [my task]"*.

---

## 🧰 Skills & Agent Roles

### Core Lifecycle Skills
- 🚦 **`sdlc-router`**: Classifies work into the appropriate SDLC lane and enforces step-by-step gates.
- 🔍 **`project-discovery`**: Researches repository architecture and requirements prior to planning.
- 📝 **`product-requirements`**: Generates or updates Product Requirements Documents (PRDs).
- 📐 **`technical-specification`**: Converts PRDs into detailed technical designs and data contracts.
- 📋 **`implementation-planning`**: Breaks down specs into traceable, step-by-step execution plans.
- 🛠️ **`implementation-execution`**: Executes implementation plans incrementally with test checks.
- ✅ **`independent-verification`**: Verifies acceptance criteria and runs full test suites.
- 🔍 **`code-review`**: Conducts multi-perspective code reviews (correctness, security, performance).
- 🐛 **`bug-remediation`**: Traces root causes, creates reproduction tests, and applies minimal fixes.
- 🚀 **`release-readiness`**: Audits security, dependencies, and docs before release tagging.

### Cross-Cutting & Governance Skills
- 🛡️ **`engineering-guardrails`**: Enforces evidence-first, minimal, and secure coding practices.
- 🏛️ **`architecture-decision-management`**: Evaluates and writes Architecture Decision Records (ADRs).
- 🧠 **`project-memory`**: Manages compact session memory and milestone tracking.
- 🔒 **`threat-modeling`**: Performs STRIDE threat modeling for security-sensitive changes.
- 📦 **`dependency-supply-chain-audit`**: Audits newly added or updated third-party dependencies.

---

## 💬 How to Use & Prompt Examples

Because skills are installed globally or at project level, you don't need special UI menus. Simply interact with your AI agent in natural language. Here are real-world prompt examples:

### 1. Starting a New Feature (Full-Feature Lane)
```text
"Saya ingin menambahkan fitur authentication dengan JWT dan OAuth2. Tolong gunakan sdlc-router untuk menentukan alur kerja dan buatkan PRD serta technical specification terlebih dahulu."
```
*or in English:*
```text
"Use sdlc-router to plan the implementation of user authentication. Generate a PRD and technical specification before writing code."
```

### 2. Fixing a Bug (Bug-Fix Lane)
```text
"User melaporkan error 500 saat checkout ketika cart kosong. Tolong gunakan skill bug-remediation untuk investigasi root cause, buat test reproduksi, dan perbaiki dengan minimal change."
```

### 3. Reviewing Code / PR (Code Review)
```text
"Tolong lakukan code review untuk perubahan di branch ini menggunakan skill code-review. Periksa aspek keamanan, performa, dan kesesuaian dengan spesifikasi."
```

### 4. Creating an Architecture Decision Record (ADR)
```text
"Kita perlu memilih antara Redis vs PostgreSQL untuk caching session. Gunakan skill architecture-decision-management untuk mengevaluasi trade-off dan buatkan ADR."
```

### 5. Running Pre-Release Check
```text
"Tolong audit repository ini menggunakan skill release-readiness sebelum kita melakukan release v1.0.0."
```

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


