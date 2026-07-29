---
name: sdlc-artifact-clarification
description: >-
  Interrogate one PRD, technical specification, or implementation plan for
  ambiguity, contradictions, hidden assumptions, and edge cases. Use at SDLC
  checkpoints or when an artifact cannot be executed or verified unambiguously.
---

# Artifact Clarification

## Workflow

1. Identify the artifact type, version, scope, and next downstream consumer.
2. Search the repository for facts before asking the user.
3. Detect fuzzy terms, missing limits, negative paths, conflicting numbers,
   hidden dependencies, overloaded terminology, and unverifiable statements.
4. Prioritize blockers over preferences.
5. For each human decision, present concrete options, implications, and one
   recommendation.
6. Ask sequentially only when answers depend on earlier decisions; otherwise
   batch a small set of independent decisions.
7. Record resolved and unresolved decisions with exact artifact references.
8. Route upstream edits to the owning role.

## Domain and ADR Handling

Create or update a glossary only after a domain term is resolved. Propose an ADR
only when the decision is costly to reverse, surprising without context, and a
real trade-off.

## Boundaries

Interrogate; do not silently author product scope, technical design, planning,
or implementation. Do not require downstream artifacts that cannot yet exist.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@sdlc-artifact-clarification` persona
defined by the portable agentic SDLC toolkit. The session becomes locked to that persona until the
task completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
