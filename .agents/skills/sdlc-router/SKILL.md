---
name: sdlc-router
description: >-
  Classify software work into the smallest safe SDLC lane and identify required
  artifacts, gates, and escalation conditions. Use for new requests, mixed
  scopes, uncertain process, feature work, bugs, small changes, docs, or
  incidents.
---

# SDLC Router

## Workflow

1. Identify the requested outcome, affected behavior, and explicit exclusions.
2. Inspect available artifacts and repository evidence before asking questions.
3. Assess blast radius, reversibility, sensitive data, security boundaries,
   public contracts, migrations, and external side effects.
4. Select one lane:
   - Full feature for new scope, architecture, contracts, or broad changes.
   - Bug fix for stable intended behavior with a reproducible defect.
   - Small change for narrow, reversible, low-risk work.
   - Documentation for content-only changes.
   - Incident for active service or security impact.
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
