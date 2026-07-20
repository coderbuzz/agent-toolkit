---
title: Portable Agentic SDLC Toolkit Discovery and Architecture Summary
status: COMPLETE (Phase 0)
date_analyzed: 2026-07-20
---

# Project Discovery Summary

## 1. Project Overview

The Portable Agentic SDLC Toolkit will be a refined, vendor-neutral
distribution of the SDLC agents, skills, instructions, standards, templates,
and quality gates proven in the reference repository. It will consolidate the
strongest existing material, remove duplication and conflicting directives,
and package the result as one clean source product.

The portable source will be authored and versioned once. Exporters and
installers will transform or copy that source into the native conventions of
agentic AI clients such as ChatGPT Codex, OpenCode, GitHub Copilot, Claude
Code, and other supported tools. Users must not need to maintain independent
handwritten copies of the same SDLC workflow for every client.

The project addresses two connected problems. First, the reference repository
contains valuable SDLC workflows but also has mirrored platform trees,
hard-coded paths, overlapping personas, and contradictory operational rules.
Second, agentic development tools expose similar concepts but use different
formats for custom agents, tool permissions, configuration, and project-level
instructions. Refinement must therefore happen in a portable core before
platform-specific packages are generated.

The intended users are software teams and individual developers who want an
explicit, traceable SDLC without rebuilding their agent instructions for every
AI client. The toolkit must support comprehensive feature development while
remaining practical for bug fixes, documentation-only work, and small surgical
changes.

### 1.1 Primary Outcomes

- Provide a portable SDLC workflow from discovery through release readiness.
- Refine and consolidate the existing agents and skills instead of rebuilding
  the SDLC workflow from scratch.
- Separate reusable procedures from agent personas and runtime permissions.
- Preserve traceability between requirements, specifications, plans, code,
  tests, reviews, and documentation.
- Export platform-native directory layouts and agent manifests without
  duplicating the procedural source content.
- Provide repeatable installation and update paths for each supported tool.
- Support risk-appropriate workflow lanes rather than forcing every change
  through the full feature lifecycle.

### 1.2 Non-Goals for the Initial Toolkit

- Reimplement an agentic AI runtime or orchestration engine.
- Standardize vendor-specific model names, pricing, or account entitlements.
- Preserve every existing instruction when it is redundant, contradictory, or
  tied to a single vendor's tool names.
- Provide application-framework-specific coding conventions in the core
  distribution.
- Replace deterministic controls such as CI checks, linters, test runners,
  permission systems, or deployment approvals with prompt instructions.

## 2. Technology Stack and Infrastructure

### 2.1 Portable Product Contents

The finished portable source distribution is expected to contain:

- Refined SDLC agent role definitions with explicit scope and capability
  boundaries.
- Refined Agent Skills containing reusable procedures, templates, references,
  and optional validation scripts.
- Concise global instructions shared by all supported agentic tools.
- Documentation standards for domain terminology, architectural decisions,
  traceability, and artifact quality.
- A platform capability map describing supported features and safe fallbacks.
- Exporters that render the portable definitions into tool-native layouts.
- Installers that deploy selected bundles into a repository or user-level
  configuration directory.
- Validators and compatibility tests that detect broken manifests, unresolved
  references, unsupported capabilities, and generated-output drift.

### 2.2 Portable Authoring Foundation

- **Reusable workflow format:** Open Agent Skills directories containing a
  required `SKILL.md` and optional `references/`, `scripts/`, and `assets/`.
- **Shared project guidance:** A concise root `AGENTS.md` for durable repository
  conventions, validation commands, and instruction routing.
- **Agent definitions:** Vendor-neutral source definitions transformed by
  exporters into platform-native agent manifests.
- **Artifact format:** Markdown for human-readable SDLC documents, with stable
  requirement and task identifiers for traceability.
- **Distribution:** Tool-specific exporters and installers generated from the
  portable source instead of manually maintained mirror trees.
- **Validation:** Static checks for skill metadata, internal links, manifest
  schemas, generated-file drift, and forbidden platform-specific references in
  portable content.

### 2.3 Reference Repository Inventory

The reference repository currently contains seven platform configuration
trees. The GitHub Copilot tree is the largest individual variant with 12 agent
profiles, 17 core skills, four instruction files, and two documentation
standards. The `.agents`, `.claude`, `.opencode`, `.omp`, and `.pi` variants
each contain the same 17 core skills and ten primary SDLC agent roles, with
mostly platform-path adaptations.

The reusable SDLC coverage already includes discovery, product requirements,
clarification, technical specification, artifact consistency, implementation
planning, coding, code review, bug remediation, user documentation, memory,
UI design, and autonomous execution guidance. A separate supplementary
collection provides 23 additional framework, documentation, prompting, and
coding-style skills.

### 2.4 Verified Platform Baseline

- ChatGPT Codex provides built-in `default`, `worker`, and `explorer` agents,
  while project-specific agents use Codex-native TOML definitions.
- Codex, OpenCode, and GitHub Copilot recognize Agent Skills from
  `.agents/skills`, making that location the strongest candidate for the
  portable skill source.
- GitHub Copilot, OpenCode, Claude Code, and Codex use different custom-agent
  manifest formats and permission fields; custom agents therefore require
  generated platform adapters rather than direct file mirroring.
- The reference repository documents a `.codex` distribution, but the actual
  `.codex/` source tree is absent and must not be treated as an existing
  implementation baseline.

## 3. Current Architecture Assessment

### 3.1 Strengths to Preserve

- The repository separates agent personas from reusable procedural skills.
- The lifecycle covers discovery, requirements, design, planning,
  implementation, review, remediation, and user documentation.
- Mandatory upstream artifacts reduce context loss and unsupported
  implementation assumptions.
- Requirement IDs, acceptance criteria, task references, and consistency
  audits provide a strong traceability foundation.
- Clarification checkpoints explicitly search for ambiguity, missing edge
  cases, hidden dependencies, and inconsistent terminology.
- The Domain Glossary and Architecture Decision Record standards preserve
  business language and consequential architectural rationale.
- Testing is required both incrementally and before implementation phases are
  considered complete.
- Review guidance includes correctness, maintainability, security, and
  specification compliance.

### 3.2 Technical Debt and Portability Risks

- Seven platform trees duplicate nearly the same skills and agent content,
  making drift likely and reviews unnecessarily expensive.
- Portable skills reference platform-specific directories and tool names such
  as `.agents/rules`, `view_file`, `fetch_webpage`, and `send_to_user`.
- Several skills claim to override the system prompt or discard the host
  persona. Such claims are not portable, cannot supersede runtime policy, and
  resemble prompt-injection patterns.
- Mandatory activation prefixes and whole-session persona locks prevent valid
  orchestration and conflict with clients that use isolated subagents.
- `omni-dev` requires visible reasoning while `fable-protocol` forbids it.
- Autonomous execution guidance conflicts with mandatory approval after every
  implementation phase.
- Simplicity guidance conflicts with instructions to add speculative
  mitigations and broad refactoring.
- The artifact consistency checkpoint requires PRD, Spec, and Plan even when
  invoked at the earlier PRD or Spec checkpoint.
- The full sequential lifecycle is too heavy for surgical fixes, documentation
  changes, and low-risk maintenance unless users know a bypass phrase.
- No independent verification or release-readiness role owns macro validation
  after implementation.
- Security is strong during code review but insufficiently explicit during
  design, threat modeling, dependency review, and release preparation.
- Existing agent names such as `GodModeDev` and `BeastModeDev` communicate
  intensity rather than bounded responsibility and safe permissions.
- Installer documentation claims support for a missing `.codex` source tree.
- No automated compatibility suite proves that exported packages load and
  behave correctly on supported tools.

### 3.3 Agent Refinement Matrix

| Existing agent | Portable target | Decision |
| --- | --- | --- |
| Brainstorming Explorer Analyst | Discovery Explorer | Rewrite |
| Product Manager PRD | Product Manager | Rewrite |
| Clarification Analyst | Clarification Analyst | Rewrite |
| Specification Architect | Solution Architect | Rewrite |
| Artifact Consistency Checker | Traceability Auditor | Rewrite |
| Planner Architect | Implementation Planner | Rewrite |
| God Mode Dev | Implementation Engineer | Replace |
| Expert Code Reviewer | Code Reviewer | Rewrite |
| Bug Remediation Architect | Bug Remediation Analyst | Rewrite |
| Diataxis Documentation Architect | Documentation Architect | Rewrite |
| Beast Mode Dev | None | Retire |
| MiniBeast | None | Retire |

Shared refinement rules:

- Remove platform paths, tool names, persona hijacking, and visible-reasoning
  requirements.
- Preserve upstream contracts, traceability, testing, security, and domain
  language controls.
- Use vendor-neutral identifiers and keep external issue creation optional.
- Make clarification, consistency audits, and approvals stage- and risk-aware.
- Keep model-specific execution profiles in platform settings.

### 3.4 Core Skill Refinement Matrix

| Existing skill | Decision | Portable target |
| --- | --- | --- |
| `brainstorming-explorer` | Rewrite | `project-discovery` |
| `product-manager-prd` | Rewrite | `product-requirements` |
| `clarification-analyst` | Rewrite | `artifact-clarification` |
| `specification-architect` | Rewrite | `technical-specification` |
| `artifact-consistency-checker` | Rewrite | `artifact-traceability-audit` |
| `planner-architect` | Rewrite | `implementation-planning` |
| `god-mode-dev` | Replace | `implementation-execution` |
| `expert-code-reviewer` | Rewrite | `code-review` |
| `bug-remediation-architect` | Rewrite | `bug-remediation` |
| `diataxis-documentation-architect` | Rewrite | `documentation-delivery` |
| `memory-manager` | Retain and simplify | `project-memory` |
| `karpathy-guidelines` | Merge | `engineering-guardrails` |
| `ponytail-lazy-senior-dev` | Merge | `engineering-guardrails` |
| `omni-dev` | Merge selective rules | `engineering-guardrails` |
| `grilling` | Merge | `artifact-clarification` |
| `fable-protocol` | Replace | `bounded-orchestration` |
| `ui-designer` | Rewrite as optional | `product-interface-design` |

The 23 supplementary skills should not be copied wholesale into the portable
core. They require a separate audit for duplication, vendor coupling, trigger
quality, and whether they belong in optional language, framework,
documentation, or migration packs.

## 4. Operational Workflow

### 4.1 Target Agent Catalog

The portable catalog should define roles by responsibility and permission
boundary. Platform exporters may map a role to a custom agent, subagent,
profile, or documented fallback depending on client capabilities.

| Target agent | Default capability boundary |
| --- | --- |
| Discovery Explorer | Read-only |
| Product Manager | Documentation write |
| Clarification Analyst | Documentation write with approval |
| Solution Architect | Documentation write |
| Traceability Auditor | Read-only |
| Implementation Planner | Documentation write |
| Implementation Engineer | Workspace write and local commands |
| Verification Engineer | Read and test commands |
| Code Reviewer | Read-only |
| Bug Remediation Analyst | Read and test commands |
| Documentation Architect | Documentation write |
| Release Engineer | Controlled commands and external approval |

Together, these agents own discovery, product definition, design, planning,
execution, verification, review, remediation, documentation, and release. Each
agent receives only the capabilities required by its responsibility.

`Product Interface Designer` may be distributed as an optional agent for
UI-heavy work. Security, testing, memory, and orchestration should primarily be
composable skills rather than additional personas unless a platform or team
needs a separately permissioned specialist.

### 4.2 Target Skill Catalog

#### Lifecycle Skills

- `sdlc-router`
- `project-discovery`
- `product-requirements`
- `artifact-clarification`
- `technical-specification`
- `artifact-traceability-audit`
- `implementation-planning`
- `implementation-execution`
- `independent-verification`
- `code-review`
- `bug-remediation`
- `release-readiness`
- `documentation-delivery`

#### Cross-Cutting Skills

- `engineering-guardrails`
- `project-memory`
- `domain-language-management`
- `architecture-decision-management`
- `test-strategy`
- `threat-modeling`
- `dependency-supply-chain-audit`
- `bounded-orchestration`

#### Optional Skills and Packs

- `product-interface-design`
- `incident-response`
- `observability-design`
- `data-migration`
- Language and framework convention packs.
- Tool-specific integration packs that require MCP servers or proprietary
  runtime features.

### 4.3 Workflow Lanes

The `sdlc-router` skill should recommend the smallest safe lane based on change
type, risk, reversibility, affected boundaries, and available upstream
artifacts. The user retains authority to select or override the lane.

#### Full Feature Lane

```text
Discovery
→ Product Requirements
→ Requirements Clarification
→ Interface or Experience Design, when applicable
→ Technical Specification
→ Threat Model and Test Strategy
→ Specification Clarification
→ Traceability Audit
→ Implementation Planning
→ Plan Clarification and Audit
→ Implementation
→ Independent Verification
→ Code and Security Review
→ Release Readiness
→ Documentation
```

#### Bug-Fix Lane

```text
Bug Intake
→ Reproduction Test
→ Root-Cause Analysis
→ Remediation Plan
→ Surgical Implementation
→ Regression Verification
→ Code Review
→ Release Readiness, when shipped externally
```

#### Small-Change Lane

```text
Scope and Risk Check
→ Surgical Implementation
→ Relevant Tests
→ Focused Review
```

#### Documentation Lane

```text
Source Audit
→ Documentation Classification
→ Draft or Update
→ Link, Example, and Format Validation
```

#### Incident Lane

```text
Triage
→ Containment
→ Evidence Preservation
→ Recovery
→ Root-Cause Review
→ Follow-Up Remediation
```

### 4.4 Quality Gates

- Clarification evaluates the currently available artifact and never requires
  downstream documents that do not yet exist.
- Traceability audit supports PRD-only, PRD-to-Spec, and complete
  PRD-to-Spec-to-Plan modes.
- Every implementation change has a proportionate runnable verification.
- The full relevant test suite must pass before implementation is complete.
- Independent verification checks acceptance criteria rather than trusting the
  implementation agent's completion statement.
- Security design occurs before code for trust boundaries, authentication,
  sensitive data, external integrations, and high-impact dependencies.
- Approval checkpoints are based on irreversibility, external side effects,
  data risk, and release impact rather than being inserted after every phase.
- Parallel agents are preferred for independent read-heavy analysis; writes to
  overlapping files remain serialized.

### 4.5 Portable Source and Export Shape

The following structure is a discovery-level proposal. Exact schemas and
generation rules require an approved Technical Specification.

```text
portable-sdlc-agent-toolkit/
├── AGENTS.md
├── manifest.yaml
├── .agents/
│   └── skills/
├── agents/
│   └── definitions/
├── instructions/
├── standards/
├── templates/
├── platforms/
│   ├── codex/
│   ├── opencode/
│   ├── github-copilot/
│   └── claude-code/
├── scripts/
│   ├── export/
│   ├── install/
│   └── validate/
├── tests/
├── docs/
└── dist/
```

The `.agents/skills` tree is the canonical portable skill source. Neutral agent
definitions contain role intent and capability requirements, while each
platform adapter maps those requirements to its supported manifest fields,
permission model, and fallback behavior. The `dist/` directory contains
generated output and must never become a second handwritten source of truth.

Installers should support selecting a platform and bundle, previewing changes,
preserving user-owned configuration, and applying idempotent updates. They must
not silently overwrite existing instructions, agent definitions, memory, or
credentials.

## 5. Handoff Notes for Product Manager

### 5.1 Discovery Recommendation

Build the toolkit as a refined portable core with generated platform adapters.
Do not select one existing vendor tree and continue maintaining manual mirrors.
The existing repository is a reference corpus and working area; the new folder
is the clean product boundary that can later become an independent repository.

The initial release should prioritize four platforms with documented custom
agent and Agent Skills support:

1. ChatGPT Codex.
2. OpenCode.
3. GitHub Copilot.
4. Claude Code.

Additional platforms should be added only after their manifest format,
instruction discovery, skill discovery, permission behavior, and installation
paths are verified from primary documentation.

### 5.2 Proposed Product Success Criteria

- One canonical copy exists for every portable skill and neutral agent role.
- Core skills contain no hard-coded platform paths, proprietary tool names,
  model names, or unsupported system-prompt override claims.
- Every skill has valid Agent Skills metadata, focused trigger language,
  explicit boundaries, and portable relative references.
- Every agent has a distinct responsibility, capability boundary, upstream
  context contract, output contract, and handoff condition.
- Exporters generate valid packages for the four initial target platforms.
- Generated packages pass schema, link, reference, and platform-layout checks.
- Installers support preview, repository scope, user scope when supported,
  idempotent updates, conflict detection, and safe removal.
- Installers never overwrite user-owned content without explicit approval.
- Full-feature, bug-fix, small-change, documentation, and incident lanes have
  unambiguous entry, exit, and escalation criteria.
- Requirements, specifications, plans, implementation tasks, verification,
  review findings, and documentation can be traced through stable IDs.
- No mandatory instruction pair produces contradictory execution behavior.
- Independent verification can reject an implementation that lacks evidence
  for its acceptance criteria.
- Compatibility tests detect platform changes before a release package is
  published.
- A clean checkout can export and validate every supported package using
  documented commands without manual file editing.

### 5.3 Primary Risks and Mitigations

- **Vendor formats change:** Exported packages stop loading. Isolate adapters,
  version compatibility data, and test fixtures.
- **Lowest-common-denominator design:** Advanced clients lose useful features.
  Define required behavior plus optional platform enhancements.
- **Prompt and context bloat:** Skills trigger poorly or agents miss rules.
  Keep skills focused and use progressive disclosure.
- **Instruction conflicts:** Agent behavior becomes unpredictable. Consolidate
  guardrails and validate incompatible directives.
- **Unsafe installer behavior:** Existing user configuration is damaged.
  Require preview, conflict policy, reversible changes, and overwrite approval.
- **Generated-source drift:** Manual edits diverge from the portable core. Mark
  output as generated and fail validation when drift is detected.
- **Untrusted skill content:** Installed packages unexpectedly expand agent
  privileges. Record provenance, audit scripts, declare dependencies, and
  minimize permissions.
- **Excessive SDLC ceremony:** Users bypass the toolkit. Route work through
  risk-appropriate lanes with explicit escalation rules.
- **Non-deterministic model behavior:** Identical instructions produce
  inconsistent outcomes. Use deterministic validators, templates, tests, and
  runtime permissions.
- **Framework scope expansion:** The core becomes unmaintainable. Keep language
  and framework guidance in separately versioned optional packs.

### 5.4 Candidate Architecture Decisions

The following proposals meet the Architecture Decision Record Triple Gate if
accepted. They are hard to reverse, surprising relative to the current mirrored
repository, and involve real portability and maintenance trade-offs:

- Use `.agents/skills` as the canonical skill source instead of `.opencode` or
  another vendor-specific tree.
- Maintain neutral agent definitions and generate native agent manifests rather
  than authoring each platform tree independently.
- Use risk-based workflow lanes instead of one mandatory sequence for every
  change type.

These remain proposed decisions. The clarification and specification phases
must confirm them before creating formal Architecture Decision Records.

### 5.5 Domain Terms Requiring Confirmation

- **Portable SDLC:** The complete refined source product, not merely shared
  prompt instructions or a generated platform package.
- **Portable Core:** The canonical agents, skills, instructions, standards,
  templates, and metadata from which exports are produced.
- **Platform Adapter:** The mapping from portable definitions to one agentic
  tool's native paths, manifest fields, permissions, and fallbacks.
- **Export Package:** Generated files ready to be installed for one target
  platform and toolkit version.
- **Workflow Lane:** A risk-appropriate SDLC path selected for a category of
  work such as a feature, bug fix, small change, documentation update, or
  incident.

If these terms are approved during clarification, they should seed the Domain
Glossary and include rejected synonyms under `_Avoid_`.

### 5.6 Required PRD Decisions

The Product Requirements phase must define:

- Initial target users and their primary installation scenarios.
- Supported platforms for the minimum viable release.
- Core, full, and optional bundle composition.
- Repository-level and user-level installation behavior.
- Conflict handling, update, rollback, and uninstall expectations.
- Versioning and compatibility-support policy.
- Whether exporters and installers are shell-based, runtime-based, or both,
  without prematurely selecting an implementation language in the PRD.
- Required offline behavior and network assumptions.
- Provenance, licensing, and third-party attribution requirements.
- Measurable activation, export, installation, and workflow-success metrics.
- Accessibility and localization requirements for user-facing documentation.
- Governance for accepting, deprecating, or replacing agents and skills.

The Product Manager should treat the current 17 skills, ten primary agents, two
bonus agents, and 23 supplementary skills as source material to evaluate, not
as a requirement to preserve every item in the finished product.

### 5.7 Phase Handoff

The next session should invoke the Product Manager with this completed
Discovery Draft as mandatory upstream context. The PRD must define product
behavior and acceptance criteria without committing to exporter schemas,
manifest field mappings, or implementation code.

Recommended handoff prompt:

```text
@ProductManagerPRD Create a PRD for the Portable Agentic SDLC Toolkit using
@docs/discovery-draft-20260720-1135-portable-agentic-sdlc-toolkit.md
as the approved Phase 0 discovery source. Focus on the refined portable core,
platform export packages, safe installation, lifecycle workflow lanes, and
measurable acceptance criteria.
```
