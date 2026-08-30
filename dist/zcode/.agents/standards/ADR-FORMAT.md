# Architecture Decision Record Format

## Triple Gate

Create an ADR only when all conditions are true:

1. Reversing the decision has meaningful cost.
2. The choice is surprising or unclear without its context.
3. Distinct alternatives create a real trade-off.

Skip the ADR when any condition is false. Keep ordinary implementation choices
in the specification or plan.

## Storage and Numbering

- Store ADRs under `docs/adr/`.
- Scan existing records and increment the highest four-digit number.
- Name records `NNNN-short-decision-slug.md`.
- Use canonical terms from the applicable Domain Glossary.

## Template

```md
# NNNN - [Decision title]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNNN

## Context

[Why this decision is needed and which constraints matter.]

## Decision

[The selected direction and explicit boundary.]

## Consequences

[Accepted benefits, costs, limitations, and follow-up effects.]

## Considered Options

[Include only alternatives whose rejection is non-obvious.]
```

Omit `Considered Options` when it adds no durable explanatory value.
