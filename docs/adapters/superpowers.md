# Superpowers Adapter — PrismSpec / Lattice Integration Guide

> This document describes how PrismSpec and Lattice map their AI Coding workflow to the [Superpowers](https://github.com/obra/superpowers) workflow engine.
> PrismSpec and Lattice do not depend on Superpowers. Superpowers is an optional execution adapter.

## Phase Mapping

PrismSpec keeps its own durable artifacts (`context.md`, `spec.md`, `plan.md`, review evidence, and `verify.md`) and maps its stages to Superpowers skills when Superpowers is present. Lattice-hosted mode stores these artifacts under `lattice/specs/` and adds gates:

| Lattice Stage | Superpowers Skill | Lattice Artifact / Constraint |
|---------------|-------------------|-------------------------------|
| **Specification** | `brainstorming` | Write persistent `context.md` and `spec.md`; load knowledge; select execution policy |
| **Planning** | `writing-plans` | Write `lattice/specs/<id>/plan.md`; include Global Constraints, task interfaces, Scope/AC refs |
| **Implementation: plan** | `executing-plans` | Execute reviewed plan with necessary tests; generate task brief and review package |
| **Implementation: tdd** | `test-driven-development` | Red test first; tests trace to ACs; record red/green evidence |
| **Review** | Superpowers SDD task reviewer discipline | Write `review-summary.json`; use `pass` / `fail` / `cannot_verify` |
| **Verification** | `verification-before-completion` | Run `lattice/kernel/delivery/pipeline.sh`; write `verify.md` |
| **Optional branch closeout** | `finishing-a-development-branch` | Use only when branch/worktree closeout is explicitly needed |

## Superpowers 6.0 Compatibility Notes

Lattice adopts the useful 6.0 ideas without depending on the Superpowers runtime:

- Mature Superpowers workflow discipline is preferred when available; PrismSpec should not invent parallel behavior for specification, planning, TDD, review, verification, or branch closeout.
- File-backed context: `task-brief.sh` and `review-package.sh` write compact artifacts under `.lattice/sdd/`.
- Read-only review: reviewers consume `review-package.md` and must not modify the working tree.
- Dual verdicts: review output separates spec compliance from code quality.
- `cannot_verify`: reviewers can say the diff package lacks enough evidence instead of guessing.
- Scratch isolation: transient SDD files live under `.lattice/sdd/`, not `.git/`, and should be ignored by git.

## How It Works

Lattice injects rules via `@import` in the project's `CLAUDE.md`:

```markdown
@import lattice/kernel/orchestrator/rules.md
```

When `rules.md` and a Superpowers skill definition conflict, `CLAUDE.md` content takes priority. Lattice rules override Superpowers defaults without modifying Superpowers source code.

The most important distinction:

- Superpowers owns workflow discipline.
- PrismSpec / Lattice own durable artifacts, execution policy, knowledge injection, and verification evidence.

## Why Not Modify Superpowers Directly

1. **Version independence**: Superpowers upgrades don't break Lattice artifacts or gates
2. **Portability**: Switching to another engine keeps the same `spec.md` / `plan.md` / `verify` contract
3. **Separation of concerns**: Superpowers manages workflow discipline; Lattice manages contracts and evidence
4. **Zero invasion**: Teams can adopt Lattice without replacing or forking Superpowers
