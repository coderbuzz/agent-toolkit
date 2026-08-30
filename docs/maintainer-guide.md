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
- partial write rollback; and
- uninstall preservation.

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
- [ ] Documentation matches CLI help and platform output.
- [ ] Version and release notes reflect compatibility changes.
