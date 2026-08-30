---
name: start
description: >-
  Start and navigate any software task with the Agent Toolkit. Classifies
  work into the smallest safe lane (Full-Feature, Bug-Fix, Small-Change,
  Docs, Incident) and guides the selected lane step by step.
invocation: both
role: workflow navigator
---

# SDLC Start (Workflow Navigator)

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

Report the lane, evidence, required inputs, gates, next role, and escalation
conditions. The user may override the recommendation within runtime safety and
permission boundaries.

## Boundaries

Do not invent missing product decisions. Do not force the full lifecycle on
low-risk work. Require approval for destructive, irreversible, external, or
sensitive-data actions.

