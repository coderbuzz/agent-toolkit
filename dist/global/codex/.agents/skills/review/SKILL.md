---
name: review
description: >-
  Review changed code for correctness, security, simplicity, maintainability,
  tests, performance, and approved-spec compliance. Use for pull requests,
  diffs, implementation reviews, or security-focused code audits.
---

# Code Review

## Workflow

1. Identify the change set, stated intent, repository conventions, and available
   specification or plan.
2. Read affected tests before implementation details.
3. Evaluate correctness and security on every review.
4. Evaluate architecture and performance depth according to change risk.
5. Treat specification compliance as conditional when no approved spec exists;
   state the limitation.
6. Distinguish introduced findings from pre-existing observations.
7. Report only actionable findings with severity, confidence, location, impact,
   evidence, and remedy.
8. Summarize test quality, specification coverage, and residual risk.

## Severity

Use blocking severity for exploitable vulnerabilities, data loss, correctness
failures, or unmet required behavior. Use lower severity for maintainability or
clarity issues with credible impact.

## Boundaries

Do not edit reviewed code. Do not report subjective preferences as defects.
Make remediation planning a separate, explicit action.

