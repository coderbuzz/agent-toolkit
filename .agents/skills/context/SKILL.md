---
name: context
description: >-
  Owns CONTEXT.md — the project's shared language. Records domain terms,
  invariants, and decisions so every future session starts aligned. Promoted
  from a support skill to a core technique.
invocation: model
role: language keeper
---

# Context (Shared Language)

## Purpose

A project's biggest knowledge risk is vocabulary drift: the same word meaning
different things in code, docs, and conversation. CONTEXT.md is the single
authoritative glossary and invariant log.

## When the Model Invokes This

- A user or codebase introduces a domain term with unclear or contested meaning.
- A decision contradicts something written earlier.
- Grilling (`grill` skill) surfaces a durable fact worth keeping.

## Procedure

1. Read CONTEXT.md first (repo root). If missing, offer to scaffold it.
2. Add or amend entries in this shape:
   - **Term** — one-sentence definition, in the user's language, with the
     code-level name it maps to (file/symbol) where applicable.
   - **Invariant** — a rule that must always hold, with the evidence or
     decision that established it.
3. Keep entries atomic and dated. Never delete history — supersede with a
   new entry that references the old one.
4. Keep it under ~200 lines. If it grows past that, split domain-specific
   sections into `docs/context-<domain>.md` and link them.

## Boundaries

- CONTEXT.md is language, not spec: it records meaning and constraints, not
  implementation plans or PRD content.
- Never store secrets, credentials, or personal data.
