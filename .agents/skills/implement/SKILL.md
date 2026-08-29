---
name: implement
description: >-
  Build with TDD as the default discipline: red-green-refactor folded into
  the build loop instead of a separate gate phase. Includes proportionate
  testing, minimal-diff rules, and dependency audit hooks.
invocation: both
role: implementation engineer
replaces: sdlc-implement, sdlc-test (as gate)
---

# Implement (Build with Discipline)

## Purpose

Turn an approved plan (or a routed small change) into the smallest correct
change, with tests as the feedback loop — not as ceremony.

## Procedure

1. Read the plan or lane routing from `start`. Confirm upstream artifacts
   exist for the lane; if not, stop and route back.
2. For behavior changes, default to TDD:
   - **Red**: write the smallest failing test that captures the intended
     behavior. Run it; confirm it fails for the expected reason.
   - **Green**: write the minimal production code to pass. No extras.
   - **Refactor**: clean up with tests green; keep diffs reviewable.
3. Non-testable work (docs, config, pure plumbing): state how correctness
   will be checked instead, then check it.
4. Respect guardrails at every step:
   - Smallest correct diff; no unrelated cleanup, reformatting, or renames.
   - Reuse existing patterns and standard-library features first.
   - Validate inputs at trust boundaries.
5. New dependency? Run the `audit-deps` check before adding it.
6. Finish with: focused checks during work, full relevant suite before
   declaring done. Report skipped or failed checks exactly as they are.

## Boundaries

- Never claim completion without evidence (test output, build result).
- Never expand scope mid-task; route new discoveries back through `start`.
- Destructive, external, or credential-touching actions require explicit
  user approval regardless of lane.
