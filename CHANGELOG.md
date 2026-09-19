# Changelog

## 1.0.0

Published from the `release/1.0.0` branch. This is the codebase previously
carried on `main` under the internal version `0.1.0`, released under a stable
version number as part of the project's version ladder.

This branch is frozen. It is kept so that installs made with this version can
still be uninstalled with the tooling that created them.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/1.0.0/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/1.0.0/install.ps1 | iex
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/1.0.0/uninstall.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/1.0.0/uninstall.ps1 | iex
```

### Changes in this release

- `manifest.json` version set to `1.0.0` (was `0.1.0`); `dist/` regenerated so
  every generated package declares `1.0.0` and a matching `source_sha256`.
- All self-referencing URLs pinned to this branch instead of `main`, so the
  remote install and uninstall routes keep working after `main` moves on:
  - README install/uninstall commands and the usage comments in `install.sh`
    and `install.ps1`;
  - the `git clone` inside `install.sh`, `install.ps1`, `uninstall.sh`, and
    `uninstall.ps1`, which previously cloned the repository's default branch and
    would otherwise fetch a newer, incompatible version.

### Known issues

`install.sh` and `uninstall.sh` use `${BASH_SOURCE[0]}`, which is not valid in a
strict POSIX shell. Running them with `sh` fails with `Bad substitution`; run
them with `bash`, as the documented `curl … | bash` commands do. This predates
this release and is left unchanged here.
