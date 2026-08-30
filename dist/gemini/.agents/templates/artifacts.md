# Artifact Templates

Use stable IDs from `standards/TRACEABILITY-FORMAT.md`. Remove optional sections
that do not apply rather than filling them with placeholders.

## Discovery Draft

```md
---
title: [Project or feature discovery]
status: DRAFT | COMPLETE
date_analyzed: YYYY-MM-DD
---

# Project Discovery Summary

## Project Overview
## Goals and Non-Goals
## Users and Stakeholders
## Current System Evidence
## Workflows and Dependencies
## Strengths, Debt, and Risks
## Constraints and Open Questions
## Recommended Workflow Lane
## Product Requirements Handoff
```

## Product Requirements Document

```md
---
title: [Product requirements]
version: 0.1.0
status: DRAFT | APPROVED
---

# Product Requirements

## Context and Problem
## Users and Jobs
## Goals and Success Metrics
## Non-Goals
## User Journeys
## Requirements

### REQ-001 - [Requirement]

- Goal: GOAL-001
- Priority: Must | Should | Could
- Acceptance criteria: AC-001, AC-002

## Non-Functional Outcomes
## Privacy and Accessibility
## Dependencies and Risks
## Open Product Decisions
```

## Clarification Report

```md
# Clarification Report

## Target Artifact and Scope
## Resolved Ambiguities
## Edge Cases and Negative Paths
## Validated Assumptions
## Unresolved Decisions
## Glossary and ADR Actions
## Required Upstream Updates
```

## Technical Specification

```md
---
title: [Technical specification]
version: 0.1.0
status: DRAFT | APPROVED
---

# Technical Specification

## Scope and Requirement Mapping
## Current System Constraints
## Architecture and Boundaries
## Interfaces and Contracts
## Data Ownership and Lifecycle
## Error and Failure Behavior
## Security and Threat Model
## Observability
## Compatibility and Migration
## Test Strategy
## Rollout and Rollback
## ADR References
## Open Technical Decisions
```

## Implementation Plan

```md
---
title: [Implementation plan]
version: 0.1.0
status: DRAFT | APPROVED | COMPLETE
---

# Implementation Plan

## Scope and Constraints
## Dependency Order
## Implementation Tasks

### TASK-001 - [Task]

- References: DES-001, AC-001
- Target boundaries: [paths or stable symbols]
- Change: [bounded implementation action]
- Verification: TEST-001
- Risk and rollback: [when applicable]

## Parallel Work Safety
## Test and Verification Matrix
## Approval Gates
## Release and Documentation Tasks
```

## Traceability Audit

```md
# Traceability Audit

## Scope and Mode
## Executive Status
## Coverage Matrix
## Missing Coverage
## Orphaned Scope
## Contradictions
## Domain and ADR Compliance
## Corrective Actions and Owners
## Gate Recommendation
```

## Verification Report

```md
# Verification Report

## Candidate and Evidence Scope
## Acceptance Criteria Results
## Negative and Security Checks
## Regression Results
## Non-Functional Evidence
## Failed or Skipped Checks
## Status: PASS | FAIL | BLOCKED
```

## Code Review Report

```md
# Code Review Report

## Change and Intent
## Findings

### FIND-001 - [Severity] [Finding]

- Confidence: High | Medium | Low
- Location: [path and stable symbol or line evidence]
- Impact: [observable risk]
- Evidence: [why this is a defect]
- Remedy: [bounded correction]

## Specification Compliance
## Test Quality
## Residual Risk
```

## Release Readiness Report

```md
# Release Readiness Report

## Candidate Version and Scope
## Build and Test Evidence
## Security and Dependency Evidence
## Migration and Compatibility
## Documentation and Change Notes
## Observability and Rollback
## External Approval Required
## Status: READY | NOT READY | BLOCKED
```
