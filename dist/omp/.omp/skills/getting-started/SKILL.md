---
name: getting-started
description: >-
  Start and navigate any software task with the Portable Agentic SDLC Toolkit.
  Classifies work into the smallest safe SDLC lane (Full-Feature, Bug-Fix, Small-Change,
  Docs, Incident) and guides the user through the step-by-step agent workflow.
  Alias for sdlc-router.
---

# Getting Started (SDLC Workflow Navigator)

Alias for `sdlc-router`.

## Workflow

1. Identify the requested outcome, affected behavior, and explicit exclusions.
2. Inspect available artifacts and repository evidence before asking questions.
3. Assess blast radius, reversibility, sensitive data, security boundaries,
   public contracts, migrations, and external side effects.
4. Select one lane:
   - **Full-Feature**: For new scope, architecture, contracts, or broad changes.
   - **Bug-Fix**: For stable intended behavior with a reproducible defect.
   - **Small-Change**: For narrow, reversible, low-risk work.
   - **Documentation**: For content-only changes.
   - **Incident**: For active service or security impact.
5. List required upstream artifacts, optional artifacts, validation, and
   approval gates for the selected lane.
6. Escalate to a stricter lane when new evidence increases risk or scope.

## Output

Report the selected lane, evidence, required inputs, gates, recommended agent role, and next steps.

## Dynamic Persona Activation

When this skill is invoked, the assistant adopts the `@sdlc-router` / `@getting-started` persona defined by the
portable agentic SDLC toolkit.
