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

## What Ships

PrismSpec is packaged as a real skill pack:

```text
prismspec/
├── skills/*/SKILL.md      # canonical skills
├── references/            # loaded on demand
├── agents/                # lightweight reviewer personas
├── commands/              # slash-command entry points
├── bin/                   # deterministic guide/lint helpers
├── templates/             # spec templates
└── specs/                 # standalone durable artifacts
```

Legacy `skills/*.md` files are kept as compatibility entry points.

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

## Flow Guide

PrismSpec includes a small local guide script that detects the current stage and next skill:

```bash
bash prismspec/bin/guide.sh
bash prismspec/bin/guide.sh --spec=checkout-flow
bash prismspec/bin/guide.sh --spec=checkout-flow --json
```

The script only routes the workflow. It does not replace the agent's responsibility to write specs, plans, code, verification evidence, or summaries.

Use JSON output for command wrappers:

```bash
bash prismspec/bin/guide.sh --json
```

## Artifact Lint

Run lint before closeout:

```bash
bash prismspec/bin/lint.sh prismspec/specs/checkout-flow
bash prismspec/bin/lint.sh lattice/specs/checkout-flow
```

The lint checks that:

- `spec.md` has ACs, execution mode, risk notes, and verification plan;
- `plan.md` references ACs, has stable task ids, and includes verification;
- `verify.md` or `summary.md` contains command/result evidence;
- TDD specs include red-test tasks.

## Modes

| Mode | Use When | Rule |
|------|----------|------|
| `plan` | Low-risk features, docs, scaffolding, straightforward refactors | Implement from a reviewed plan and add tests when behavior changes |
| `tdd` | Bug fixes, core flows, security/permission/money logic, state machines, migrations, concurrency, idempotency, regressions | Write red tests first, make them green, then refactor |

`auto` means the model chooses `plan` or `tdd` based on risk. `plan -> tdd` escalation is allowed when risk is discovered. `tdd -> plan` downgrade requires an explicit user override.

## Skills

| Skill | Canonical File | Purpose |
|-------|----------------|---------|
| sdd | `skills/sdd/SKILL.md` | Workflow controller and resume router |
| brainstorm | `skills/brainstorm/SKILL.md` | Clarify requirements and write `spec.md` |
| plan | `skills/plan/SKILL.md` | Write AC-traced `plan.md` |
| implement | `skills/implement/SKILL.md` | Execute plan or TDD mode with evidence |
| verify | `skills/verify/SKILL.md` | Run verification and write `verify.md` |
| finish | `skills/finish/SKILL.md` | Write `summary.md` and capture residual risk |
| learn | `skills/learn/SKILL.md` | Capture durable project knowledge |

Each canonical skill includes frontmatter, workflow, inputs/outputs, stop conditions, common rationalizations, red flags, and verification criteria.

## References and Reviewers

`references/` contains mode selection, spec quality, TDD evidence, review evidence, and definition-of-done guidance. `agents/` contains lightweight reviewer personas for spec compliance, code quality, and test coverage.
