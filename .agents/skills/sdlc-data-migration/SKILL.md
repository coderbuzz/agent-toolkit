---
name: sdlc-data-migration
description: >-
  Plan and verify safe schema, storage, configuration, or data migrations with
  compatibility, backfill, cutover, validation, and rollback controls. Use when
  changing persistent data or formats with meaningful recovery cost.
---

# Data Migration

## Workflow

1. Inventory source, target, ownership, volume, sensitivity, and invariants.
2. Define forward and backward compatibility across mixed-version operation.
3. Choose expand, migrate, verify, and contract phases when zero-downtime
   compatibility is required.
4. Design idempotent backfill, checkpointing, throttling, and restart behavior.
5. Define preflight checks, reconciliation queries, sampling, and acceptance
   thresholds.
6. Plan cutover, observability, abort criteria, rollback, and data restoration.
7. Test on representative data and failure injection before production use.
8. Require explicit approval for destructive transformation or production
   cutover.

## Boundaries

Never treat a backup as verified until restoration is tested. Never remove old
fields or formats before all supported readers and rollback windows permit it.
