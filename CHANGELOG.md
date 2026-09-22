# Changelog

## 3.2.0 (`main`, tag `v3.2.0`)

A new install surface: the toolkit is now installable as a Claude Code
plugin, alongside the existing prompt-driven install. No prompt-driven
install behavior changed, so a 3.1.0 install updates in place.

### Added

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, so
  Claude Code users can install every skill with `/plugin marketplace add
  coderbuzz/agent-toolkit` then `/plugin install agent-toolkit@agent-toolkit`,
  without touching the target repository. `plugin.json` points its `skills`
  field at the existing `.agents/skills/` directory, so this path and
  `AGENT-INSTALL.md` share one canonical source. It always installs the full
  31-skill set; there is no bundle parameter on this path.
- A credit for [ponytail](https://github.com/DietrichGebert/ponytail)
  (Dietrich Gebert) in `guardrails/SKILL.md` and both READMEs' Reference
  tables: its Decision Ladder shape was the direct inspiration for
  `guardrails`'s ladder. No text is copied.

### Changed

- Both READMEs' "Skill bundles" section grew from a three-row summary table
  into a full per-skill breakdown (name, invocation mode, purpose), and
  gained a "Claude Code: install via the plugin marketplace" subsection
  describing the new install path.

## 3.1.0 (`main`, tag `v3.1.0`)

Installing is one prompt and a parameter line. `AGENT-INSTALL.md` now states
its own invocation contract, so the READMEs stopped paraphrasing it, and both
were rewritten against the repository as it stands. No package contents or
install behavior changed, so a 3.0.0 install updates in place.

### Changed

- Installing is one prompt now, not three. `AGENT-INSTALL.md` section 0 gained
  the invocation contract: the four parameters a request may carry (`action`,
  `scope`, `bundle`, `ref`), their defaults, and the statement that no wording
  in a request waives the stop conditions, the write allowlist, or the preview.
  The README quick start had been restating that contract as numbered steps in
  three prompts across two languages, six copies free to drift from the
  protocol they paraphrased. They are now one prompt that names the protocol
  and a parameter line, with a table of variants that changes only that line.
  `tests/test_agent_protocol.py` holds it there: the defaults are asserted
  against `manifest.json`, and a quick start that grows a second prompt or a
  prompt longer than five lines fails.
- Pinning a version now pins what an agent actually reads. Section 5 clones
  `--branch <ref>` and the no-git fallback fetches from `<ref>` rather than a
  hardcoded `main`. `ref=v3.1.0` is the first tag whose protocol understands
  the parameter form; `v3.0.0` predates it and needs that tag's own prompt.
- Both READMEs rewritten against the repository as it stands. The English file
  goes from 510 lines to 417 without losing a section, because the same things
  had been said several times over: antislop had three entries (its own
  section, a duplicate table under Skills Reference, and Credits), the phase
  flow had five (a prose line, a best-practice list, an ASCII arrow chain, a
  Mermaid chart, and seven per-phase tables), and the platform list had five.
  Each now has one home: the antislop section, one lane diagram plus one
  skills-by-phase table, and the platforms table.
- Corrections the rewrite carried: the bundles section still said to name a
  bundle "in step 3 of the install prompt", which stopped existing when the
  prompt became one line; "188 KB of procedure" was measured at 167 KB;
  `/skills` was documented as listing 31 skills, which is the `full` count and
  not the default 27; and the phase tables listed `observability`, `incident`,
  `design-ui`, and `migrate` without marking them specialists absent from
  `core`. `docs/maintainer-guide.md`, `docs/platform-support.md`, and
  `llms.txt` existed but were linked from nowhere, and `docs/` was missing from
  the repository tree.
- The workflow diagram shows what prose cannot: the router branching into the
  five lanes, each with its own skill sequence. It replaced a Mermaid chart
  that redrew the linear chain the tables already carried, plus the ASCII arrow
  line that redrew it again.
- Credits' "Inspiration" list is now "Reference": a table of every external
  source this toolkit stands on, saying for each whether it ships code here, is
  an install target, or is an idea we learned from. antislop is the only row of
  the first kind.
- `README.id.md` is a Bahasa Indonesia README now, not an English one with a
  translated Quick Start. Around 17% of it had been translated, so the rest was
  a second English copy to keep in sync for no reader's benefit. Prose,
  headings, and tables are Indonesian; skill ids, parameters, paths, and the
  install prompt stay in English, because those are what the agent reads.
- The READMEs' "How loading works" now leads with the point it was making:
  skills load on demand, driven by your prompt. It had opened on what
  installing does not do, so the reader met the pointer file before the reason
  a pointer file exists.
- `review` now evaluates simplicity and maintainability as explicit workflow
  steps. Its description had promised both since 2.0.0, but the body carried no
  step or criteria for either, so an agent loading the skill was never told to
  look for them. Each new step is gated: a simplicity finding requires a named
  replacement, a maintainability finding requires the future change it puts at
  risk, so neither becomes a channel for taste. Severity guidance now states
  that both are non-blocking unless the shortcoming causes a correctness,
  security, or performance defect, and that dropping a test, a boundary
  validation, or error handling is never a simplification.
- The documentation lane has one name again. `start`'s description and
  `AGENTS.md` called it "Docs" while the skill's own routing step, the lane
  matrix, and the READMEs called it "Documentation", so an agent reading the
  description and then the body met two names for one lane. Both now say
  Documentation.
- `tests/test_agent_protocol.py` no longer finds the install prompt by
  splitting on an English heading, which the translated README would have
  broken. It looks for the fenced block carrying `action=install` instead, in
  either language.

## 3.0.0 (`main`, tag `v3.0.0`)

**Breaking: the shell installers are gone.** Installing is now something you ask
your coding agent to do. Paste a prompt, the agent reads
[`AGENT-INSTALL.md`](AGENT-INSTALL.md) and performs the install itself. See the
[README](README.md#-quick-start) for the prompts.

`dist/` is unchanged as the deploy source; only the front-end that copies a
package to a target was replaced.

### Added

- `AGENT-INSTALL.md`: the install, update, and uninstall protocol, written for
  agents. It claims authority over every other file in the repository, states
  explicit stop conditions, requires the agent to ask rather than guess its
  platform, bounds writes to an allowlist, and mandates a preview before it
  writes anything.
- `.agent-toolkit-files.json` in every generated package: each installable file
  with its `sha256` and a role of `regular`, `shared-skill`, `instruction-block`
  or `command`. Agents copy from this list rather than walking and hashing the
  package, and an agent without git can fetch exactly the files one package
  needs.
- Six antislop skills, vendored from
  [miqdadbadjuber/anti-slop](https://github.com/miqdadbadjuber/anti-slop) (MIT)
  and shipped in the `core` and `full` bundles: `antislop`, `antislop-ui`,
  `antislop-copywriting`, `antislop-code`, `antislop-human`,
  `antislop-layoutmobile`. See `NOTICE` and `vendor/anti-slop.json`.
- `llms.txt`, and `tests/test_agent_protocol.py`, which asserts every constant
  `AGENT-INSTALL.md` quotes against its definition in `scripts/toolkit.py`.

### Changed

- **Default scope is now `repository`, not `global`.** An install that omits a
  target is an error rather than a silent write into the home directory.
- `core` holds 27 skills (was 21), `full` 31 (was 25).

### Removed

- `install.sh`, `install.ps1`, `uninstall.sh`, `uninstall.ps1`,
  `scripts/install.*`, `scripts/uninstall.*`, `scripts/setup.sh`,
  `scripts/toolkit-lib.sh`. They remain available, and working, on the
  `release/2.0.0` branch.

### Upgrading from 2.0.0

The ledger format did not change, so a 2.0.0 install can be removed by either
route. Uninstall first, then install 3.0.0 with the prompt.

If you kept a 2.0.0 command, its URL points at `main` and no longer resolves.
The working one is:

```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/2.0.0/uninstall.sh | bash
```

## 2.0.0 (`release/2.0.0`, tag `v2.0.0`)

Frozen. Installs with a shell or PowerShell script. Zero-dependency installers,
pre-built global packages, shared skills at `~/.agents/skills`, and the ZCode
adapter. Global was the default scope.

## 1.0.0 (`release/1.0.0`, tag `v1.0.0`)

Frozen. The original shell installer, the agent roster, and `sdlc-`-prefixed
skill names. Published from the codebase that carried the internal version
`0.1.0`.
