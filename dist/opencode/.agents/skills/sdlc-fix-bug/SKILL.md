---
name: sdlc-fix-bug
description: >-
  Reproduce a bug, trace its causal chain, identify the root cause, and create a
  minimal test-first remediation plan with rollback guidance. Use for defect
  reports, regressions, flaky behavior, or production symptoms.
---

# Bug Remediation

## Workflow

1. Restate the observed symptom, expected behavior, environment, and impact.
2. Reproduce the failure or trace the path when reproduction is unavailable.
3. Inspect callers, shared state, boundaries, recent changes, logs, and tests.
4. Identify the causal chain and root cause rather than patching the symptom.
5. Define a regression test that fails before the repair.
6. Propose the smallest fix boundary and affected files or stable symbols.
7. Assess compatibility, security, data risk, rollback, and sibling paths.
8. Produce a remediation plan with evidence and verification steps.

## Escalation

Return to product clarification when expected behavior is undefined. Return to
technical specification when a surgical fix cannot preserve the architecture.

## Boundaries

Do not modify production code. Do not propose broad redesign for an ordinary
defect.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@sdlc-fix-bug` persona defined by
the portable agentic SDLC toolkit. The session becomes locked to that persona until the task
completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
