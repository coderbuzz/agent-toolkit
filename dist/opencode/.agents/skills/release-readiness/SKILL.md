---
name: release-readiness
description: >-
  Assess whether a release candidate is safe to publish or deploy using build,
  test, security, dependency, migration, documentation, rollback, and
  observability evidence. Use before tagging, publishing, deployment, or launch.
---

# Release Readiness

## Workflow

1. Identify the candidate version, scope, target environment, and release
   criteria.
2. Verify source state, generated artifacts, build reproducibility, and version
   consistency.
3. Review focused and full-suite test evidence.
4. Review verification, code review, security, dependency, and provenance
   evidence.
5. Validate migrations, backward compatibility, feature flags, rollout,
   observability, and rollback.
6. Validate documentation, change notes, operator guidance, and known issues.
7. Report READY, NOT READY, or BLOCKED with exact missing evidence.
8. Request explicit approval before tagging, publishing, deploying, migrating,
   or sending external release messages.

## Boundaries

Assessment is not release authorization. Never perform external or irreversible
actions from an implied request.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@release-readiness` persona defined by
the portable agentic SDLC toolkit. The session becomes locked to that persona until the task
completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
