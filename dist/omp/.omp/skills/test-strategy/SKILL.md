---
name: test-strategy
description: >-
  Design proportionate unit, integration, contract, end-to-end, security, and
  non-functional verification mapped to acceptance criteria and risk. Use
  during specification, planning, implementation, verification, or test audits.
---

# Test Strategy

## Workflow

1. Identify observable behavior, acceptance criteria, trust boundaries, failure
   modes, regressions, and non-functional requirements.
2. Select the lowest test level that verifies each behavior reliably.
3. Add integration or contract tests at real boundaries.
4. Add end-to-end tests only for critical cross-system journeys.
5. Define deterministic test data, isolation, cleanup, and environment needs.
6. Map every critical criterion and bug regression to a test identifier.
7. Define focused micro checks and the full macro completion suite.
8. Identify checks that require manual or environment-specific evidence.

## Quality Rules

Tests must be fast enough for their layer, independent, repeatable,
self-validating, behavior-focused, and capable of failing for the intended
defect. Avoid tests that only confirm mocks were called.

## Output

Produce a coverage map, commands or methods, data needs, expected evidence, and
known limitations.
