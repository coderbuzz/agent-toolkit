# v2 Design — Best of Both

Snapshot sebelum refactor: branch `archive/main-20260829`, tag `archive-main-20260829`.

## Sources
- mattpocock/skills (principles): grilling, shared language (CONTEXT.md), TDD
  as core discipline, model-invoked skills, user-invoked vs model-invoked split.
- agent-toolkit v0.1 (process): lane routing, artifact gates, fail-closed
  installer, drift-check, vendor-neutral dist, bilingual docs.

## v2 Decisions
1. **AGENTS.md global = pointer only (<2KB).** Skills load on demand; the
   global file lists names + one-line triggers, never full procedures.
2. **Kill the 14-persona agent roster & session locking.** Each skill declares
   a compact `role:` in frontmatter. Fewer moving parts, same accountability.
3. **New skills from Matt:**
   - `grill` (user-invoked): two-way interview before any irreversible work.
     Merges and replaces `sdlc-clarify` as the default ambiguity tool.
   - `context` (model-invoked): owns CONTEXT.md — shared language, domain
     terms, project invariants. Promoted from support skill to core technique.
4. **TDD folded into `implement`:** red-green-refactor steps are part of the
   build skill; `test` stays as a utility (scaffolding suites), not a gate phase.
5. **Lanes stay, gates stay.** Routing (start) and approval gates are the
   strongest idea in v0.1; unchanged in spirit, simplified in wording.
6. **Frontmatter adds `invocation: user|model|both`** per Matt's taxonomy.
7. **Installer/drift-check unchanged** (they were already good).

## Skill Roster v2 (draft)
Core: start, grill, context, discover, define, design, plan, implement,
review, verify, fix, release, document
Utility: guardrails, memory, glossary (alias of context), decide, test,
threat, audit-deps, orchestrate
Specialists (full bundle): design-ui, incident, observability, migrate
