# Changelog

## 2.0.0

Published from the `release/2.0.0` branch. This branch is frozen; it is kept so
that installs made with 2.0.0 can still be updated or removed with the tooling
that created them.

The current version is 3.0.0 on `main`, which installs by pasting a prompt into
a coding agent instead of running a shell script.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/2.0.0/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/2.0.0/install.ps1 | iex
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/2.0.0/uninstall.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/coderbuzz/agent-toolkit/release/2.0.0/uninstall.ps1 | iex
```

### Changes on this branch

The 2.0.0 release itself is tagged `v2.0.0`. Beyond that release, this branch
carries one change: every self-reference is pinned to `release/2.0.0` so the
remote routes keep working after the default branch moved to 3.0.0.

- README install and uninstall commands, and the usage comments in `install.sh`
  and `install.ps1`, switch from
  `raw.githubusercontent.com/.../main/...` to `.../release/2.0.0/...`.
- `install.sh`, `install.ps1`, `uninstall.sh` and `uninstall.ps1` pass
  `--branch release/2.0.0` to `git clone`. Without it the wrapper cloned the
  repository's default branch, so a piped run downloaded the 2.0.0 wrapper and
  then fetched 3.0.0 — which no longer contains `scripts/install.sh`.
- A frozen-branch banner at the top of both READMEs.

### Known issues

`install.sh` and `uninstall.sh` use `${BASH_SOURCE[0]}`, which is not valid in a
strict POSIX shell. Running them with `sh` fails with `Bad substitution`; run
them with `bash`, as the documented `curl … | bash` commands do. This predates
this release and is left unchanged here.

## 1.0.0

See the `release/1.0.0` branch and the `v1.0.0` tag. Frozen; shell installer.
