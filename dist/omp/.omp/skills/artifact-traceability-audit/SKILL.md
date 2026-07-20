---
name: artifact-traceability-audit
description: >-
  Audit available SDLC artifacts for coverage, scope creep, contradictions,
  terminology drift, ADR compliance, and codebase reality. Use after PRD, Spec,
  Plan, implementation, or whenever traceability is uncertain.
---

# Artifact Traceability Audit

## Select the Audit Mode

- Requirements mode: goals, requirements, criteria, terms, and scope.
- Design mode: PRD-to-Spec coverage and contradictions.
- Plan mode: PRD-to-Spec-to-Plan coverage and orphan tasks.
- Implementation mode: plans, code, tests, verification, and review evidence.

## Workflow

1. Read only artifacts available at the selected checkpoint.
2. Map upstream items to downstream coverage.
3. Trace downstream items back to approved intent.
4. Compare numbers, constraints, contracts, terminology, and decisions.
5. Check Domain Glossary and ADR rules without requiring lazily created files.
6. Compare claims with repository reality when source evidence is in scope.
7. Classify findings by impact and identify the owning role.
8. Report PASS, PASS WITH WARNINGS, or FAIL with exact evidence.

## Boundaries

Do not rewrite audited artifacts or choose which conflicting artifact wins.
Recommend a gate; runtime policy and the user retain authority.
