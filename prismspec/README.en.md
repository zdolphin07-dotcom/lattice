# PrismSpec

> 中文版: [README.md](README.md)

PrismSpec is a standalone, progressive Spec-Driven Development skill module for AI coding.

It keeps the workflow intentionally small:

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

## Positioning

PrismSpec can run standalone, or in Lattice-hosted mode.

| Mode | What You Get | Requires Lattice |
|------|--------------|------------------|
| Standalone | Persistent specs, plans, verification notes, summaries, and plan/tdd execution discipline | No |
| Lattice-hosted | PrismSpec plus manifest routing, knowledge loading, delivery gates, AC coverage, drift checks, and compliance audit | Yes |

PrismSpec does not depend on Lattice. Lattice embeds PrismSpec as its default spec-coding workflow.

## Core Beliefs

1. A spec is not a thick document. It is the smallest verifiable encoding of the acceptable implementation space.
2. A spec is not only requirements. Any explicit constraint between Intent and Code can be part of the spec, including design and plan.
3. There is no universal spec template. Payment flows, CRUD backends, frontend UX, algorithms, and infrastructure need different spec shapes.

## Templates

| Template | Use When | Focus |
|----------|----------|-------|
| `spec-template.md` | Default general-purpose work | Intent, scope, ACs, contracts, risks, verification |
| `spec-template-lite.md` | Lightweight Plan Mode tasks, docs, config, low-risk changes | AC-first, minimal design |
| `spec-template-service.md` | Backend services, APIs, data models, state transitions | API, DDL, error codes, idempotency, compensation |
| `spec-template-frontend.md` | Frontend UX, product flows, component changes | User journey, states, accessibility, UI acceptance |
| `spec-template-tdd.md` | Bug fixes, core flows, high-risk changes | Regression cases, red tests, invariants |

## Modes

| Mode | Use When | Rule |
|------|----------|------|
| `plan` | Low-risk features, docs, scaffolding, straightforward refactors | Implement from a reviewed plan and add tests when behavior changes |
| `tdd` | Bug fixes, core flows, security/permission/money logic, state machines, migrations, concurrency, idempotency, regressions | Write red tests first, make them green, then refactor |

`auto` means the model chooses `plan` or `tdd` based on risk. `plan -> tdd` escalation is allowed when risk is discovered. `tdd -> plan` downgrade requires an explicit user override.
