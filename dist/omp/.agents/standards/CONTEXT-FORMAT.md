# Domain Glossary Format

## Rules

- Create `CONTEXT.md` only after the first project-specific domain term is
  explicitly resolved.
- If `CONTEXT-MAP.md` exists, follow it to the owning bounded context.
- Define what a term is in one or two sentences; omit behavior and technical
  implementation.
- Select one canonical term and record rejected synonyms exactly as
  `_Avoid_: synonym-a, synonym-b`.
- Prefer a full name unless an acronym is universally recognized.
- Update a changed definition directly; do not keep history in the glossary.
- Exclude general engineering concepts that are not specific to the domain.

## Template

```md
# [Context Name]

[One sentence describing the bounded domain language.]

## Language

**[Canonical Term]**:
[One or two sentence definition.]
_Avoid_: [Rejected synonym], [Rejected synonym]
```

For multiple bounded contexts, create a root `CONTEXT-MAP.md` that links each
context glossary and states only relationships needed to route terminology.
