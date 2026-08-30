---
name: guardrails
description: >-
  Apply evidence-first, minimal, secure, and testable engineering behavior while
  writing, reviewing, refactoring, or fixing code. Use whenever implementation
  decisions risk overengineering, scope drift, unsafe assumptions, or weak
  verification.
---

# Engineering Guardrails

## Decision Ladder

1. Confirm the requested behavior and material assumptions.
2. Inspect the relevant flow and existing conventions.
3. Ask whether the change is needed at all.
4. Reuse an existing implementation when it is correct.
5. Prefer standard-library or native platform capabilities.
6. Prefer an already-approved dependency over adding another.
7. Write the smallest clear change that satisfies the requirement.

## Change Rules

- Trace every changed line to the request, requirement, repair, or its tests.
- Fix shared root causes instead of patching individual symptoms.
- Avoid unrelated refactoring, speculative flexibility, and premature
  abstractions.
- Match existing style unless an approved plan changes it.
- Validate untrusted input at boundaries and preserve data integrity.
- Remove only code made obsolete by the current change.

## Verification

Define an observable success check before editing. Add proportionate tests, run
focused checks after each increment, then run the full relevant suite. Report
failures and skipped checks exactly.
