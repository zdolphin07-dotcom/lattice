# PrismSpec

PrismSpec is a standalone, progressive Spec-Driven Development skill module for AI coding.

It keeps the workflow small:

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

## Positioning

PrismSpec can be used in two ways:

| Mode | What You Get | Required Host |
|------|--------------|---------------|
| Standalone | Persistent specs, plans, verification notes, summaries, and plan/tdd execution discipline | Any AI coding agent that can read files |
| Lattice-hosted | PrismSpec plus manifest, knowledge loading, delivery gates, AC coverage, drift checks, and compliance audit | Lattice |

PrismSpec does not depend on Lattice. Lattice embeds PrismSpec as its default spec-coding workflow.

## Artifacts

Standalone default:

```text
prismspec/
├── skills/
├── templates/
└── specs/
    └── {spec-id}/
        ├── spec.md
        ├── plan.md
        ├── verify.md
        └── summary.md

.prismspec/
└── runs/
    └── {spec-id}/
        └── {task-id}/
            ├── brief.md
            └── review-package.md
```

When `lattice/manifest.yaml` exists, PrismSpec uses the Lattice host paths:

```text
lattice/specs/{spec-id}/{spec.md,plan.md,summary.md}
.lattice/sdd/{spec-id}/{task-id}/
```

## Modes

PrismSpec supports exactly two implementation policies:

| Mode | Use When | Rule |
|------|----------|------|
| `plan` | Low-risk features, docs, scaffolding, straightforward refactors | Implement from a reviewed plan and add tests when behavior changes |
| `tdd` | Bug fixes, core flows, security/permission/money logic, state machines, migrations, concurrency, idempotency, regressions | Write red tests first, make them green, then refactor |

`auto` means the model chooses `plan` or `tdd` based on risk. `plan -> tdd` escalation is allowed when risk is discovered. `tdd -> plan` downgrade requires an explicit user override.

## Skills

| Skill | Purpose |
|-------|---------|
| `sdd.md` | Guided controller; resolves next stage and resumes from artifacts |
| `brainstorm.md` | Clarifies intent and writes `spec.md` |
| `plan.md` | Converts `spec.md` into AC-traced `plan.md` |
| `implement.md` | Executes plan or TDD policy |
| `verify.md` | Runs local verification and writes evidence |
| `finish.md` | Writes summary and durable follow-up notes |
| `learn.md` | Captures reusable lessons |

## Design Rule

PrismSpec adds a process step only when that step creates a durable artifact or prevents a real engineering failure. More stages mean more human cost; the default workflow stays intentionally restrained.
