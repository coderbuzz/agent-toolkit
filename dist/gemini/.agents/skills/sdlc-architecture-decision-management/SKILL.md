---
name: sdlc-architecture-decision-management
description: >-
  Evaluate, create, supersede, and validate Architecture Decision Records using
  a strict Triple Gate. Use when a technical choice is costly to reverse,
  surprising without context, and involves a real trade-off.
---

# Architecture Decision Management

## Triple Gate

Create an ADR only when all are true:

1. Reversing the choice has meaningful cost.
2. A future reader would not understand the choice from code alone.
3. Distinct alternatives create a real trade-off.

## Workflow

1. Inspect existing ADRs, specifications, constraints, and glossary terms.
2. Reject ADR creation if any gate is false.
3. Allocate the next project-defined identifier.
4. Record concise context, decision, and accepted consequences.
5. Include rejected options only when their rejection is non-obvious.
6. Link the ADR from affected specifications and plans.
7. Supersede records explicitly; do not rewrite accepted history silently.

## Boundaries

Do not use ADRs for ordinary library choices, reversible implementation details,
or decisions without alternatives.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@sdlc-architecture-decision-management`
persona defined by the portable agentic SDLC toolkit. The session becomes locked to that persona
until the task completes. Invoking a different persona-bound skill within the same session is
rejected to preserve focus and prevent context bleed.
