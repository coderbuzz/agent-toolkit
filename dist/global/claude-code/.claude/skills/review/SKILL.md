---
name: review
description: >-
  Review changed code for correctness, security, simplicity, maintainability,
  tests, performance, and approved-spec compliance. Use for pull requests,
  diffs, implementation reviews, or security-focused code audits.
invocation: both
role: code reviewer
---

# Code Review

## Workflow

1. Identify the change set, stated intent, repository conventions, and available
   specification or plan.
2. Read affected tests before implementation details.
3. Evaluate correctness and security on every review.
4. Evaluate architecture and performance depth according to change risk.
5. Evaluate simplicity on every review: complexity the change adds that its
   stated intent does not require.
6. Evaluate maintainability on every review: what the change costs the next
   person who has to modify it.
7. Treat specification compliance as conditional when no approved spec exists;
   state the limitation.
8. Distinguish introduced findings from pre-existing observations.
9. Report only actionable findings with severity, confidence, location, impact,
   evidence, and remedy.
10. Summarize test quality, specification coverage, and residual risk.

## Simplicity

Report a simplicity finding only when a concrete replacement exists and you can
name it. Without a named replacement it is a preference, not a finding.

Look for:

- an abstraction with one implementation, one caller, or one product;
- a dependency covering what the standard library or platform already provides;
- configuration, flags, or extension points nothing sets;
- code reimplementing something the repository already has;
- structure built for requirements that do not exist yet.

The `guardrails` decision ladder states the same preference order for authoring
code. This step applies it to a diff already written.

## Maintainability

Report a maintainability finding only when you can name the future change it
puts at risk, or the specific wrong conclusion a reader would draw. "Hard to
read" on its own is a preference, not a finding.

Look for:

- logic duplicated into places that must now be changed together;
- names, types, or signatures that describe something other than what the code
  does;
- coupling or ordering requirements a caller cannot see from the interface;
- failures that discard the context needed to diagnose them;
- code this change leaves behind with no remaining caller.

Simplicity asks whether the code should exist in this form. Maintainability
assumes it should, and asks what the next change to it will cost.

## Severity

Use blocking severity for exploitable vulnerabilities, data loss, correctness
failures, or unmet required behavior. Use lower severity for maintainability or
clarity issues with credible impact.

Simplicity and maintainability findings are non-blocking unless the shortcoming
itself causes a correctness, security, or performance defect. Removing a test, a
boundary validation, or error handling is never a simplification.

## Boundaries

Do not edit reviewed code. Do not report subjective preferences as defects.
Make remediation planning a separate, explicit action.

