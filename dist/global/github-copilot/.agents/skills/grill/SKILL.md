---
name: grill
description: >-
  Two-way interview before any ambiguous or irreversible work. Surfaces hidden
  assumptions, resolves conflicting requirements, and produces a written
  understanding the user confirms before execution begins.
invocation: user
role: ambiguity resolver
supersedes: clarify
---

# Grill (Understand Before Building)

## Purpose

Most agent failures are not coding failures — they are understanding
failures. This skill interviews the user before a single line of code is
written, for any task that is ambiguous, novel, or hard to reverse.

## Procedure

1. Read the request plus all available repo evidence first. Never ask a
   question the repository can already answer.
2. List what you believe the task means, in one short paragraph. Include
   explicit exclusions (what you will NOT do).
3. Ask the highest-leverage questions only — max 5, ordered by blast radius.
   Each question offers your best-guess answer so the user can just say
   "yes" instead of composing prose.
4. Capture decisions as they land: update CONTEXT.md (via the `context`
   skill) for durable domain facts; note one-off decisions in the task.
5. Write the confirmed understanding back as a compact spec summary and get
   an explicit "yes, go" before irreversible work starts.

## Boundaries

- Skip grilling for trivially reversible, narrowly scoped changes — route
  them through `start` to the Small-Change lane instead.
- Do not invent product decisions. If the user will not answer, state the
  assumption you will proceed under and mark it clearly.
