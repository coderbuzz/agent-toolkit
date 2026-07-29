---
description: Instruction prompt to review and sync new skills/agents from awesome-copilot-id
apply_to: maintainers-and-agents
---

# Upstream Sync & Evolution: `awesome-copilot-id`

This document defines the procedure for reviewing "what's new" in [GulajavaMinistudio/awesome-copilot-id](https://github.com/GulajavaMinistudio/awesome-copilot-id) and updating `agent-toolkit` skills and agents.

> **Principle**: `awesome-copilot-id` is used solely as a reference and inspiration source. Upstream content MUST NOT be blindly copied. All changes must respect `agent-toolkit`'s vendor-neutral portability standards, prevent duplication/overlap, and maintain least-privilege role boundaries.

---

## Workflow Steps

### Step 1: Upstream Clone & Fetch
1. Check if a local copy of `awesome-copilot-id` exists in `/tmp/awesome-copilot-id`.
2. If it does not exist, clone it:
   ```bash
   git clone https://github.com/GulajavaMinistudio/awesome-copilot-id.git /tmp/awesome-copilot-id
   ```
3. If it already exists, pull the latest changes:
   ```bash
   git -C /tmp/awesome-copilot-id pull
   ```

### Step 2: Inventory Analysis ("What's New")
1. **Upstream Inventory**:
   - List upstream skills in `/tmp/awesome-copilot-id/.agents/skills/*`
   - List upstream agents in `/tmp/awesome-copilot-id/.github/agents/*`, `.claude/agents/*`, `.codex/agents/*`, or `AGENTS.md`.
2. **Local Toolkit Inventory**:
   - Inspect `.agents/skills/*`
   - Inspect `agents/definitions.json`
   - Inspect `manifest.json`
3. **Classification & Audit Matrix**:
   Evaluate every upstream skill and agent against local inventory and classify into one of 4 categories:
   - **`[SKIP]` Duplicate / Equivalent**: Functionality already exists in `agent-toolkit` under the same or different name. No change needed.
   - **`[ENHANCE]` Overlap / Refinement**: Upstream provides useful ideas, steps, or edge cases that complement an existing `agent-toolkit` skill/agent. Update existing files without introducing vendor lock-in or breaking existing contracts.
   - **`[NEW]` Novel & Valuable**: High-value skill or agent role missing from `agent-toolkit`. Adapt and convert into canonical `agent-toolkit` format.
   - **`[REJECT]` Irrelevant / Vendor-Locked / Out-of-Scope**: Tied to proprietary platform features, model-specific prompts, or non-SDLC tasks. Record rejection rationale.

### Step 3: Adaptation & Conversion Rules

#### A. Skill Conversion (`.agents/skills/<skill-id>/SKILL.md`)
- **Location**: `.agents/skills/<skill-id>/SKILL.md`
- **Frontmatter**: MUST contain ONLY `name` and `description` in YAML frontmatter.
- **Vendor Neutrality**: Remove vendor-specific tool names, model names, or proprietary permission syntax. Use capability intent (e.g. `read_file`, `grep_search`, `run_command`).
- **Structure**:
  - `## Description` / Overview
  - `## Workflow / Procedure`
  - `## Inputs & Outputs`
  - `## Verification & Stop Conditions`
- **Registration**: Add new skill ID to `manifest.json` in the appropriate category (`lifecycle`, `cross_cutting`, or `optional`) and relevant bundle (`core`, `full`, or `quality`).

#### B. Agent Conversion (`agents/definitions.json`)
- **Location**: `agents/definitions.json`
- **Schema Compliance**:
  - `id`: Lowercase hyphenated unique ID
  - `name`: Neutral title
  - `description`: Scope and role definition
  - `capabilities`: Explicit list from capability registry
  - `recommended_skills`: List of registered skill IDs
  - `handoffs` & `constraints`: Clear boundaries and forbidden actions
- **Least Privilege**: Maintain read-only boundaries for audit, review, and verification roles.
- **Registration**: Add agent ID to `manifest.json`.

### Step 4: Verification & Integrity Pipeline
Always run the complete verification suite after making changes:

```bash
# 1. Validate canonical source files and manifest integrity
python3 scripts/toolkit.py validate

# 2. Run unit and integration tests
python3 -m unittest discover -s tests -v

# 3. Export generated packages for all supported platforms
python3 scripts/toolkit.py export --all --bundle core
python3 scripts/toolkit.py export --all --bundle full

# 4. Validate generated packages and verify drift
python3 scripts/toolkit.py check-drift --all --bundle core
```

### Step 5: Sync Audit & Summary Report
Produce a summary report detailing:
- **Upstream Revision / Commit**: SHA or date checked.
- **Added Skills / Agents**: List of new items with IDs.
- **Enhanced Skills / Agents**: List of updated items with changes made.
- **Skipped / Rejected Items**: Table of items with classification and rationale.
- **Verification Results**: Status of validation script, unittest suite, export, and drift checks.
