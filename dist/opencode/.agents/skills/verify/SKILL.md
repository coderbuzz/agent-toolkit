---
name: verify
description: >-
  Independently verify acceptance criteria, implementation claims, tests,
  regressions, security checks, and non-functional evidence. Use after
  implementation, before release, or when completion evidence is disputed.
---

# Independent Verification

## Workflow

1. Rebuild context from approved artifacts, changed files, and runnable checks.
2. Map every acceptance criterion and critical non-functional requirement to an
   independent verification method.
3. Inspect whether tests assert behavior rather than mocks alone.
4. Run focused, regression, negative-path, security, and non-functional checks
   proportionately to risk.
5. Record commands, results, environment limits, skipped checks, and evidence.
6. Identify unsupported claims and missing coverage.
7. Report PASS, FAIL, or BLOCKED for each criterion and the overall candidate.

## Boundaries

Do not trust implementer summaries as evidence. Do not silently repair
production defects. Create new test artifacts only when explicitly authorized.

