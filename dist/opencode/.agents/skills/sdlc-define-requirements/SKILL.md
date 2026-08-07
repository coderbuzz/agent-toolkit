---
name: sdlc-define-requirements
description: >-
  Create or revise a Product Requirements Document with outcomes, users, scope,
  measurable requirements, acceptance criteria, and metrics. Use after
  discovery or when an existing PRD needs product-level updates.
---

# Product Requirements

## Workflow

1. Read the approved discovery artifact or existing PRD.
2. Define the problem, target users, jobs, goals, non-goals, and constraints.
3. Describe primary journeys and failure outcomes from the user's perspective.
4. Assign stable vendor-neutral IDs to goals, requirements, and acceptance
   criteria.
5. Make every acceptance criterion observable, measurable, and testable.
6. Define outcome-level privacy, accessibility, reliability, and performance
   expectations without selecting implementation technologies.
7. Record dependencies, risks, open product decisions, and success metrics.
8. Validate that every requirement supports a stated goal and has criteria.

## Output

Produce a PRD using the repository's artifact template when available. Include
a traceability summary and a handoff to artifact clarification.

## Boundaries

Define why, who, and what. Do not choose protocols, libraries, database types,
payload schemas, or code structure. Keep issue-tracker creation optional.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@sdlc-define-requirements` persona defined
by the portable agentic SDLC toolkit. The session becomes locked to that persona until the task
completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
