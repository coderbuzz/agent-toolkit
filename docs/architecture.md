# Architecture

## Design Principles

The toolkit separates stable SDLC behavior from platform syntax:

- **Instructions** define always-on project behavior.
- **Standards** define durable artifact and traceability contracts.
- **Skills** define reusable procedures activated by task intent.
- **Agents** define bounded roles, upstream evidence, and capability intent.
- **Adapters** map neutral roles into platform-native files and permissions.
- **Runtime permissions** remain enforced by the host platform and user approval system.

This separation prevents platform-specific syntax from leaking into canonical workflows and
allows one refinement to benefit every supported tool.

## Source of Truth

`manifest.json` is the inventory and packaging contract. It identifies canonical paths,
supported platforms, all registered agents and skills, bundles, and installation policy.

Canonical content lives in:

- `AGENTS.md`
- `agents/definitions.json`
- `.agents/skills/`
- `instructions/`
- `standards/`
- `templates/`
- `platforms/*/adapter.json`

`dist/` is derived state. Never correct a generated file directly. Change canonical input,
run validation, regenerate the package, and check drift.

## Agent Contract

An agent definition contains:

- a stable identifier and user-facing name;
- a routing description;
- neutral capability intents;
- required upstream evidence;
- recommended skills; and
- an explicit operating boundary.

Capability intent is deliberately smaller than a platform tool schema:

| Capability | Meaning |
| --- | --- |
| `read_workspace` | Read and search repository files |
| `run_read_commands` | Run repository inspection commands |
| `write_documents` | Create or update documentation artifacts |
| `write_workspace` | Create or update source and test files |
| `run_tests` | Run deterministic checks and builds |
| `release_actions` | Perform explicitly approved external release actions |

Auditors, reviewers, and independent verification agents have no write capability. Commands
still require behavioral constraints because some platforms expose one general shell tool
rather than separate read-only and mutating command capabilities.

## Skill Contract

Each skill is a directory containing `SKILL.md` and `agents/openai.yaml`. Canonical skill
frontmatter contains only:

- `name`, equal to the directory name; and
- `description`, including both purpose and activation conditions.

Skill bodies use imperative procedures and define inputs, workflow, stop conditions, outputs,
and quality checks. They avoid platform paths, model identifiers, proprietary tool names, and
permission syntax. Resource references are relative to the skill directory and cannot escape
it.

## Adapter Contract

Each `platforms/<platform>/adapter.json` declares native paths, format, instruction strategy,
skill placement, and permission mapping. Renderer code consumes both the neutral definition
and adapter contract.

Adapters must:

- use native platform discovery paths;
- emit explicit least-privilege settings;
- fail closed for unknown or absent capabilities;
- omit model and MCP server identifiers;
- forbid known permission bypass modes;
- preserve canonical instructions; and
- add a deterministic generated marker and source digest.

## Export Pipeline

```text
Canonical sources
  -> canonical validation
  -> bundle resolution
  -> native agent rendering
  -> shared asset and skill copy
  -> package metadata
  -> platform contract validation
  -> atomic replacement in dist/<platform>
```

The source digest hashes relative path names and file contents in deterministic order. It
excludes generated output, tests, and documentation that do not alter installed behavior.
No timestamp is emitted, so unchanged inputs produce byte-identical packages.

Source symlinks are rejected. This prevents an export from unintentionally embedding content
outside the toolkit root.

## Installation Transaction

The installer performs these phases:

1. Validate or generate the source package.
2. Resolve every destination under the exact target root.
3. Reject traversal, case collisions, symlink escapes, non-regular destinations, and conflicts.
4. Classify actions as create, update, unchanged, remove stale, or preserve modified.
5. Print the complete plan and stop unless `--apply` is explicit.
6. Copy through temporary files and atomically replace each destination.
7. Write a hash ledger only after all file operations succeed.
8. Restore prior content and remove temporary output if any operation fails.

A differing file without matching ledger ownership is user-owned and blocks installation. A
managed file can be updated only if its current hash still matches the previously installed
hash. This avoids confusing toolkit ownership with broad permission to overwrite.

## Uninstallation

Uninstall reads the ledger and removes only files whose hash still matches the installed hash.
Missing files are harmless. Modified files and non-regular paths are preserved and reported.
The ledger is removed after an applied uninstall, transferring any preserved files fully back
to user ownership.

## Trust Boundaries

The following inputs are untrusted:

- manifest and adapter JSON;
- package metadata and ledger JSON;
- generated package paths;
- target repository files and symlinks;
- external artifact content consumed by agents; and
- host platform tool availability.

JSON parsing rejects duplicate keys and non-finite values. Path handling rejects absolute
paths, traversal components, backslashes, drive prefixes, NUL bytes, symlink escapes, and
case-insensitive collisions. Platform permissions are validated after generation.

## Extension Rules

Adding a platform requires an adapter descriptor, renderer, package validator, permission
tests, deterministic export test, and installation test. Adding a skill or agent requires
manifest registration and exact inventory validation. New behavior must remain canonical
unless it is genuinely specific to one host platform.
