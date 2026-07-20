# Refinement Map

## Purpose

This document records how the reference repository's strongest SDLC procedures were refined
into the portable toolkit. It is provenance, not a runtime dependency.

## Lifecycle Skill Refinements

| Portable skill | Reference source | Refinement |
| --- | --- | --- |
| `project-discovery` | `brainstorming-explorer` | Preserves evidence-first discovery; removes persona lock and host commands |
| `product-requirements` | `product-manager-prd` | Keeps measurable requirements and acceptance criteria; separates technical design |
| `artifact-clarification` | `clarification-analyst` | Generalizes recurring PRD, Spec, and Plan interrogation |
| `technical-specification` | `specification-architect` | Retains contracts, data, security, and observability; avoids production code |
| `artifact-traceability-audit` | `artifact-consistency-checker` | Adds checkpoint-aware modes so future artifacts are not required prematurely |
| `implementation-planning` | `planner-architect` | Produces executable, test-aware, dependency-ordered tasks with stable trace IDs |
| `implementation-execution` | `god-mode-dev` plus guardrail skills | Replaces unrestricted persona language with bounded execution and stop conditions |
| `independent-verification` | New gap coverage | Separates completion claims from independent acceptance evidence |
| `code-review` | `expert-code-reviewer` | Retains specification and engineering axes; adds severity and evidence discipline |
| `bug-remediation` | `bug-remediation-architect` | Preserves reproduce-root-cause-test-plan sequence and surgical scope |
| `release-readiness` | New gap coverage | Adds packaging, compatibility, rollback, and explicit external-action gates |
| `documentation-delivery` | `diataxis-documentation-architect` | Preserves Diataxis modes and adds command/example validation |
| `sdlc-router` | Workflow rules plus Phase 0 findings | Adds risk-based feature, bug, small-change, docs, incident, and migration lanes |

## Cross-Cutting Skill Refinements

| Portable skill | Reference source | Refinement |
| --- | --- | --- |
| `engineering-guardrails` | `karpathy-guidelines`, `ponytail-lazy-senior-dev`, `omni-dev` | Consolidates minimal change, reuse, assumptions, tests, and verification without persona overlap |
| `project-memory` | `memory-manager` | Preserves project-scoped durable context while excluding secrets and hidden prompts |
| `bounded-orchestration` | `fable-protocol` | Keeps decomposition, dependency ordering, progress evidence, and recovery; removes autonomy escalation |
| `domain-language-management` | Repository context standards | Makes glossary creation lazy and canonical terms explicit |
| `architecture-decision-management` | Repository ADR standards | Enforces the hard-to-reverse, surprising, real-trade-off triple gate |
| `test-strategy` | Distributed testing mandates | Centralizes test levels, negative paths, evidence, and completion criteria |
| `threat-modeling` | Security review guidance | Adds structured assets, boundaries, abuse cases, mitigations, and verification |
| `dependency-supply-chain-audit` | Review and release checks | Adds provenance, licensing, vulnerability, and lockfile evidence |

## Optional Specialist Coverage

| Portable skill | Reference source | Refinement |
| --- | --- | --- |
| `product-interface-design` | `ui-designer` | Preserves deliberate UX and accessibility without an identity-bound design persona |
| `incident-response` | New gap coverage | Adds containment-first operational response and recovery approvals |
| `observability-design` | Specification and release gaps | Adds signals, ownership, privacy, actionable alerts, and verification |
| `data-migration` | Specification and implementation gaps | Adds compatibility windows, rehearsal, integrity, rollback, and cleanup gates |

## Agent Model Refinements

The reference workflow used phase personas paired tightly to skills. The portable model uses
12 neutral roles and allows a host to select recommended skills independently:

- Discovery Explorer
- Product Manager
- Clarification Analyst
- Solution Architect
- Traceability Auditor
- Implementation Planner
- Implementation Engineer
- Verification Engineer
- Code Reviewer
- Bug Remediation Analyst
- Documentation Architect
- Release Engineer

Independent Verification and Release Engineering are explicit additions. They close the gaps
between implementation, review, deployment readiness, and evidence-backed completion.

## Directives Deliberately Removed

The following patterns were not carried into canonical content:

- dynamic persona or system-prompt override claims;
- session-wide persona locks;
- hard-coded platform paths and proprietary tool names;
- unrestricted autonomy or permission escalation language;
- mandatory full SDLC for every low-risk change;
- artificial per-file pauses that prevent approved autonomous completion;
- contradictory requirements to refuse work while also treating every request as absolute;
- premature requirements for downstream artifacts that cannot exist at a checkpoint; and
- claims that behavioral instructions can replace host runtime permissions.

Their useful intent was retained through bounded roles, risk-based lanes, explicit stop
conditions, project-scoped memory, evidence gates, and least-privilege platform adapters.

## New System-Level Capabilities

The toolkit adds capabilities that were not coherent as one portable product in the reference
repository:

- one manifest and exact inventory validation;
- deterministic multi-platform exports;
- native least-privilege agent rendering;
- safe preview-first installation and hash-ledger ownership;
- user-modification-preserving uninstall;
- path traversal, symlink, duplicate-key, and case-collision defenses;
- generated-source digest and drift checking; and
- a standard-library test matrix covering all platforms and bundles.
