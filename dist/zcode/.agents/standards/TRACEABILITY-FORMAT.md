# Traceability Format

## Identifier Namespaces

- `GOAL-NNN`: Product or business outcome.
- `REQ-NNN`: Functional requirement.
- `NFR-NNN`: Non-functional requirement.
- `AC-NNN`: Acceptance criterion.
- `DES-NNN`: Technical design contract.
- `ADR-NNNN`: Architecture decision record.
- `TASK-NNN`: Implementation task.
- `TEST-NNN`: Planned or implemented verification.
- `FIND-NNN`: Audit, verification, or review finding.
- `RISK-NNN`: Identified risk and mitigation.

Use zero-padded numbers and keep an identifier stable after publication. Mark
removed items as deprecated rather than silently reusing their IDs.

## Required Links

- Every `REQ` links to at least one `GOAL` and one `AC`.
- Every approved `REQ` or `NFR` links to a `DES`, unless no design change is
  required and the reason is documented.
- Every `TASK` links to a `DES`, `REQ`, or approved `FIND`.
- Every `AC`, security-critical `NFR`, and bug regression links to a `TEST`.
- Every release-blocking `FIND` links to corrective ownership and evidence.

## Audit Modes

- **Requirements mode:** Audit goals, requirements, criteria, terms, and scope.
- **Design mode:** Audit PRD-to-Spec coverage and contradictions.
- **Plan mode:** Audit full PRD-to-Spec-to-Plan coverage and orphan tasks.
- **Implementation mode:** Audit code, tests, verification, and review evidence.

Do not require downstream artifacts in an earlier audit mode.
