---
name: sdlc-define-terms
description: >-
  Create and maintain a lazy Domain Glossary with canonical project terms and
  rejected synonyms. Use when terminology is ambiguous, overloaded,
  inconsistent across artifacts, or explicitly resolved during clarification.
---

# Domain Language Management

## Workflow

1. Check for a context map and route the term to its owning domain.
2. Confirm the concept is project-specific rather than generic engineering
   vocabulary.
3. Gather current uses and conflicting definitions from artifacts and code.
4. Select one canonical term and define what it is in one or two sentences.
5. Record rejected synonyms using the project's exact _Avoid_ syntax.
6. Create a glossary lazily only after the first term is resolved.
7. Validate downstream artifacts against the canonical term.

## Boundaries

Do not include implementation details, process notes, or history in the
glossary. Do not create duplicate entries for acronyms. Do not change domain
ownership silently.
