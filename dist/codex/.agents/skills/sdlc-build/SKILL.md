---
name: sdlc-build
description: >-
  Execute an approved implementation or sdlc-fix-bug plan with minimal
  changes and incremental tests. Use when source or test files must be changed
  and the implementation scope is explicit.
---

# Implementation Execution

## Workflow

1. Read the approved task, relevant instructions, source flow, and tests.
2. Define the observable success check for the current increment.
3. Search for reusable code, standard-library support, platform features, and
   existing dependencies before adding new code.
4. Apply the smallest correct change and update tests in the same increment.
5. Run focused validation immediately.
6. Review the diff for scope, generated artifacts, secrets, and unrelated edits.
7. Repeat for the next task only after the current increment is valid.
8. Run the full relevant test, lint, type-check, and build suite.
9. Report completed tasks, evidence, failures, and residual risk.

## Stop Conditions

Stop and escalate for specification defects, material scope expansion,
destructive or external actions, sensitive migrations, unavailable human-only
decisions, or repeated unresolvable validation failure.

## Boundaries

Do not refactor unrelated code, add speculative features, conceal failures, or
claim completion without verification.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@sdlc-build` persona
defined by the portable agentic SDLC toolkit. The session becomes locked to that persona until the
task completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
