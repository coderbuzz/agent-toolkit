# Maintainer Guide

## Development Baseline

Use Python 3.9 or newer. Runtime and tests rely only on the standard library. Work from
canonical sources and treat `dist/` as disposable generated state.

Before changing behavior:

1. Identify whether the change belongs to always-on instructions, a standard, a skill, or a
   platform adapter.
2. Preserve stable skill identifiers unless a breaking release is intentional.
3. Add or update tests with the change.
4. Keep platform names and permissions out of canonical skill bodies.

## Validation Loop

```bash
python3 scripts/toolkit.py validate
python3 -m unittest discover -s tests -v
python3 scripts/toolkit.py export --all --bundle core
python3 scripts/toolkit.py validate --dist dist --bundle core
python3 scripts/toolkit.py check-drift --all --bundle core
```

Also export `full` and `quality` when changing bundle resolution or optional skills.

`manifest.json` is part of the source digest, so any edit to it, including a
version bump, invalidates every generated package. Re-export before checking
drift, or the check will report a `source_sha256` mismatch that is really just a
stale `dist/`.

## How Installation Works Now

There is no installer in this repository. `dist/` is still the deploy source,
but the front-end that copies a package to a target is `AGENT-INSTALL.md`: a
protocol an agent reads and executes. Keep four things in mind.

1. **The protocol is prose executed by a language model.** A drifted sentence is
   a broken installer with no stack trace. `tests/test_agent_protocol.py`
   asserts every constant the document quotes (filenames, block markers,
   default scope, platform ids, bundle sizes, adapter paths) against its
   definition in `scripts/toolkit.py`. Change a constant and that test tells you
   which sentence to update.
2. **`toolkit.py install` and `uninstall` remain**, not as a supported user
   route but as the executable reference the protocol describes. When you change
   install behavior, change both, and re-check them against each other: install
   through the protocol by hand and through the CLI into two scratch
   directories, then diff. The trees and the ledger bytes must be identical.
3. **The prompt is parameters, and nothing else.** Section 0 of the protocol
   defines the invocation: `action`, `scope`, `bundle`, `ref`, and what each one
   defaults to. The README quick start carries a pointer to the protocol plus a
   parameter line, so instructions live in exactly one file. Do not answer a
   support question by adding steps back into the README prompt: the fix belongs
   in the protocol, where the agent actually reads it, and
   `tests/test_agent_protocol.py` fails a quick start that regrows them.
4. **The files manifest is what makes the protocol workable.** Every package
   ships `.agent-toolkit-files.json`, listing each installable file with its
   hash and role. An agent copies from that list rather than walking and hashing
   the package. If you add a file to a package, give it a role, or the agent
   will install it as a plain file, which for a shared skill silently breaks
   reference counting.

## Vendored Skills

The six `antislop` skills come from `miqdadbadjuber/anti-slop` under MIT. Do not
hand-edit them. To pull upstream changes:

```bash
git clone https://github.com/miqdadbadjuber/anti-slop ../anti-slop
python3 scripts/vendor-anti-slop.py ../anti-slop
```

The script re-applies every adaptation recorded in `vendor/anti-slop.json` and
prints, per skill, whether the rule text is still word-identical to upstream. It
fails if a rewrap changed a word, left a prose line over 120 characters, or if
upstream's wording moved out from under an adaptation. Update the pinned commit
in `vendor/anti-slop.json`, `NOTICE`, and the provenance block in
`scripts/vendor-anti-slop.py` after a re-sync.

Rules for changing a vendored skill:

1. **Never edit the vendored `SKILL.md` directly.** The next sync overwrites it.
   Add an adaptation function to `scripts/vendor-anti-slop.py` instead, and
   record it in `vendor/anti-slop.json`.
2. **Every adaptation asserts its input.** If upstream rewords the text an
   adaptation targets, the sync must fail loudly rather than silently skip the
   change. This has already caught one mistake.
3. **Packaging changes are ours; rule changes are not.** Adapt frontmatter, line
   width, cross-references, and paths freely. Changing what a rule *means* needs
   a reason recorded in `vendor/anti-slop.json` and, so far, has happened once:
   `r02-has-no-voice-override`. Prefer an upstream issue.
4. **Keep the README's adaptation table in step** with
   `vendor/anti-slop.json`. It is what a reader sees before the JSON.

## Adding or Updating a Skill

1. Choose a lowercase hyphenated ID that describes one reusable procedure.
2. Create `.agents/skills/<id>/SKILL.md`.
3. Limit frontmatter to `name`, `description`, `invocation` (user | model | both), `role`,
   and (for documented history only) `supersedes`.
4. Make the description state what the skill does and when it should activate.
5. Define inputs, workflow, stop conditions, outputs, and validation.
6. Keep detailed resources in the skill directory and reference them relatively.
7. Add `agents/openai.yaml` for clients that use optional presentation metadata.
8. Register the ID in one manifest skill group and the appropriate bundles.

The optional OpenAI quick validator requires PyYAML. When the upstream `skill-creator` scripts
are available, run its `quick_validate.py` against every skill in addition to this toolkit's
validator.

## Editing an Adapter

Platform schema changes are high-risk because a missing or renamed field may broaden access.
Verify current native documentation before modifying:

- project discovery paths;
- required frontmatter or TOML keys;
- tool allowlist behavior when omitted;
- instruction precedence; and
- native skill discovery paths.

Update the descriptor, renderer, package validator, documentation, and tests together.

## Installer Safety Tests

Changes to path handling or installation must cover:

- absolute and traversal paths;
- Windows drive and backslash forms;
- duplicate JSON keys and invalid hashes;
- case-insensitive path collisions;
- source and destination symlinks;
- existing user-owned files;
- user-modified managed files;
- idempotent reinstall;
- stale managed files;
- partial write rollback;
- uninstall preservation; and
- a ledger written by an older release still being readable.

Never add a force-overwrite option without a separate design and explicit recovery contract.

## Generated Output Policy

Exports contain no timestamps. A changed generated hash must be explainable by a changed
canonical input. Run `check-drift` in CI after export and fail when generated packages differ.

Generated instruction files include:

- toolkit version;
- canonical source SHA-256; and
- a do-not-edit marker.

The package metadata records the platform, bundle, version, digest, and included skills.

## Release Checklist

- [ ] Canonical validation passes.
- [ ] All unit and integration tests pass with zero failures.
- [ ] Core, full, and quality bundles export where affected.
- [ ] Every generated platform package passes contract validation.
- [ ] A second export is byte-identical.
- [ ] Drift check passes.
- [ ] Dry-run install reports expected actions in a clean repository.
- [ ] Conflict behavior is verified in a repository with existing instructions.
- [ ] Applied install is idempotent.
- [ ] Uninstall preserves a deliberately modified managed file.
- [ ] `AGENT-INSTALL.md` matches `scripts/toolkit.py`, proven by a by-hand run
      diffed against the CLI in both scopes.
- [ ] Documentation matches CLI help and platform output.
- [ ] Version and release notes reflect compatibility changes.
