---
name: design
description: >-
  Translate approved product requirements into testable technical contracts,
  boundaries, data behavior, security controls, and rollout design. Use after
  PRD clarification or when an existing specification needs approved updates.
---

# Technical Specification

## Workflow

1. Read the approved PRD, clarification outcomes, glossary, ADRs, and relevant
   current-system evidence.
2. Map every design contract to requirement and acceptance-criterion IDs.
3. Define architecture boundaries relative to the existing system.
4. Specify interfaces, data ownership, lifecycle, validation, errors, failure
   behavior, concurrency, and compatibility.
5. Define trust boundaries, threats, mitigations, privacy, and residual risk.
6. Define observability, test strategy, migration, rollout, and rollback.
7. Identify consequential decisions and apply the ADR creation gate.
8. Audit the specification for unresolved assumptions and orphaned design.

## Output

Produce an approved-spec candidate and requirement-to-design map. Use stable
symbols and contracts rather than brittle line numbers.

## Boundaries

Do not implement production code or change product scope. Escalate requirements
conflicts to the Product Manager.

