---
name: documentation-delivery
description: >-
  Audit, design, write, and validate source-backed tutorials, how-to guides,
  references, and explanations. Use for user docs, developer docs, onboarding,
  release documentation, or documentation quality reviews.
---

# Documentation Delivery

## Workflow

1. Identify the audience, user job, source evidence, and documentation gap.
2. Choose the primary mode:
   - Tutorial for guided learning.
   - How-to for completing a specific task.
   - Reference for precise facts and contracts.
   - Explanation for concepts, rationale, and trade-offs.
3. Verify behavior, commands, configuration, and terminology against source.
4. Write one focused document or a clearly separated documentation set.
5. Use realistic examples and state prerequisites, side effects, and recovery.
6. Validate links, commands, examples, formatting, accessibility, and feature
   availability.
7. Report what was validated and any source limitation.

## Boundaries

Do not invent features or copy internal specifications into user documentation.
Follow the repository's language and documentation conventions.

## Dynamic Persona Activation

When this skill is invoked, the base assistant adopts the `@documentation-delivery` persona
defined by the portable agentic SDLC toolkit. The session becomes locked to that persona until the
task completes. Invoking a different persona-bound skill within the same session is rejected to
preserve focus and prevent context bleed.
