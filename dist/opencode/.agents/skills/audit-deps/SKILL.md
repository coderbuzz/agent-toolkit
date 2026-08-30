---
name: audit-deps
description: >-
  Assess whether a dependency is necessary, trustworthy, compatible,
  reproducible, maintained, licensed, and safe to install. Use before adding or
  upgrading packages, during security review, or before release.
invocation: model
role: dependency auditor
---

# Dependency Supply-Chain Audit

## Workflow

1. Confirm the capability is not already provided by project code, the standard
   library, the platform, or an approved dependency.
2. Use primary package and source documentation for current facts.
3. Verify package identity, publisher, repository, release history,
   maintenance, supported runtime, and license.
4. Review lockfile impact, transitive dependencies, install scripts, native
   code, network behavior, and required privileges.
5. Check relevant advisories and determine whether vulnerable paths are
   reachable in the intended use.
6. Assess compatibility, update policy, reproducibility, and removal cost.
7. Report approve, approve with constraints, reject, or blocked with evidence.

## Boundaries

Do not install, upgrade, or remove dependencies as part of an assessment unless
the implementation scope explicitly authorizes it.

