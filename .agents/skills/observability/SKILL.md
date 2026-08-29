---
name: observability
description: >-
  Design actionable logs, metrics, traces, events, service objectives, alerts,
  dashboards, and runbooks. Use during architecture, reliability planning,
  incident remediation, or before releasing operationally critical behavior.
---

# Observability Design

## Workflow

1. Identify user-visible outcomes, failure modes, dependencies, and operators.
2. Define service-level indicators and objectives where they drive decisions.
3. Specify structured events, metrics, traces, and correlation identifiers.
4. Minimize cardinality, noise, cost, and sensitive-data exposure.
5. Define alerts with owner, urgency, threshold rationale, and response action.
6. Design dashboards around diagnosis and decisions rather than vanity metrics.
7. Link alerts to concise runbooks and rollback or containment actions.
8. Test signal presence, absence, latency, and failure behavior before release.

## Boundaries

Do not log secrets, credentials, unnecessary personal data, or full untrusted
payloads. Avoid alerts that have no actionable response.
