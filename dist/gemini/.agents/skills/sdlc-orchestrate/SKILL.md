---
name: sdlc-orchestrate
description: >-
  Coordinate complex multi-step work with explicit scope, dependencies,
  capability-aware delegation, interval verification, progress updates, and
  stop conditions. Use for long-running tasks or work that can be safely
  decomposed.
---

# Bounded Orchestration

## Workflow

1. Define the objective, scope, success criteria, constraints, and action
   authority.
2. Build a dependency graph of bounded tasks.
3. Keep decisions, scope, and final integration in the main context.
4. Delegate independent read-heavy work when the host supports it.
5. Serialize overlapping writes and assign clear file ownership.
6. Establish verification intervals and collect concise evidence.
7. Retry only when a changed approach can resolve the failure.
8. Stop for destructive actions, external effects, severe scope expansion,
   missing human decisions, or repeated identical blockers.
9. Run an independent final verification when capabilities allow.
10. Report outcomes, failed checks, remaining risk, and unfinished work.

## Capability Fallback

When delegation, progress tools, goals, or background execution are unavailable,
continue with a local checklist and the same boundaries. Never reference a
specific host tool in the portable workflow.
