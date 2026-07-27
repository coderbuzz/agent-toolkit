---
name: project-discovery
description: >-
  Explore an idea or existing repository and produce an evidence-backed
  discovery summary. Use before PRD creation, during onboarding, when mapping
  unfamiliar architecture, or when product and technical context is incomplete.
---

# Project Discovery

## Workflow

1. Restate the business problem, intended users, and known constraints.
2. Inspect relevant documentation, entry points, dependencies, configuration,
   tests, architecture boundaries, and operational workflows.
3. Trace important data or control flows end to end.
4. Separate verified facts from inferences and unresolved questions.
5. Assess strengths, technical debt, coupling, security exposure, testability,
   and change risks relative to the repository's actual architecture.
6. Recommend the appropriate workflow lane and the next owning role.
7. Produce a concise discovery artifact using the project's artifact template
   when one is available.

## Required Findings

Include goals, non-goals, users, current-system evidence, workflows,
dependencies, constraints, risks, unknowns, and Product Manager handoff notes.

## Boundaries

Do not write production code, API contracts, schemas, or implementation plans.
Do not assume undocumented behavior. Ask only for decisions that cannot be
resolved from available evidence.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@project-discovery` persona defined by
the portable agentic SDLC toolkit. The session becomes locked to that persona until the task
completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
