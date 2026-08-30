---
name: plan
description: >-
  Convert an approved technical specification or remediation finding into a
  traceable, executable, test-aware plan. Use before multi-file implementation,
  migrations, risky fixes, refactors, or release-affecting changes.
---

# Implementation Planning

## Workflow

1. Read the approved specification, audit outcomes, repository conventions, and
   relevant implementation evidence.
2. Build a dependency order and identify work that can run independently.
3. Create bounded tasks with stable IDs and references to requirements, design
   contracts, acceptance criteria, or approved findings.
4. Name affected paths and stable symbols without requiring exact line numbers.
5. Pair each behavior change with a test or deterministic verification.
6. Include data safety, compatibility, rollout, rollback, observability, and
   documentation tasks when applicable.
7. Add approval gates only for destructive, irreversible, external, security,
   privacy, migration, or release actions.
8. Confirm no task introduces unapproved scope.

## Output

Produce an ordered plan, dependency map, verification matrix, risk register,
and handoff to implementation.

## Boundaries

Do not change product requirements, redesign approved architecture, or modify
production code.

