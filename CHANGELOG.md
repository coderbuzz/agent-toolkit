# Changelog

## Unreleased

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
- The no-git fallback in `AGENT-INSTALL.md` section 5 now fetches from `<ref>`
  rather than a hardcoded `main`, so pinning a tag pins the files an agent
  without git downloads too.

- `review` now evaluates simplicity and maintainability as explicit workflow
  steps. Its description had promised both since 2.0.0, but the body carried no
  step or criteria for either, so an agent loading the skill was never told to
  look for them. Each new step is gated: a simplicity finding requires a named
  replacement, a maintainability finding requires the future change it puts at
  risk, so neither becomes a channel for taste. Severity guidance now states
  that both are non-blocking unless the shortcoming causes a correctness,
  security, or performance defect, and that dropping a test, a boundary
  validation, or error handling is never a simplification.

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
