---
name: prismspec-workflow
description: Orchestrates the PrismSpec AI coding workflow from intent to verified evidence. Use when the user asks for PrismSpec, /prismspec, SDD, spec-driven development, guided spec workflow, resuming an existing spec, choosing plan vs TDD mode, or running an AI coding task through specification, planning, implementation, review, and verification.
---

# PrismSpec Workflow

## Overview

Act as the lifecycle controller for PrismSpec. Route work through the smallest complete chain:

```text
specification -> planning -> implementation(plan|tdd) -> review -> verification
```

This skill is a controller, not an extra phase. Delegate stage work to the stage skills.

Read `prismspec/references/superpowers-alignment.md` when workflow behavior is unclear. PrismSpec should not invent a parallel workflow when a mature Superpowers skill already covers the discipline; preserve PrismSpec artifact locations and Lattice gates as the override.

## Start Here

Run the deterministic guide before choosing a stage:

```bash
bash prismspec/bin/guide.sh --json
```

Pass through user selectors when present:

```bash
bash prismspec/bin/guide.sh --spec=<spec-id> --from=<stage> --mode=auto|plan|tdd --json
```

Use the JSON fields as the routing source of truth: `host`, `spec_id`, `stage`, `mode`, `skill`, `spec_dir`, `run_dir`, `verify_command`.

## Routing

| Stage | Delegate To | Durable Output |
|-------|-------------|----------------|
| `specification` | `prismspec-specification` | `context.md`, `spec.md` |
| `planning` | `prismspec-planning` | `plan.md` |
| `implementation` | `prismspec-implementation` | code, tests, task evidence |
| `review` | `prismspec-review` | `review-summary.json` |
| `verification` | `prismspec-verification` | `verify.md` |

After each completed stage, rerun `guide.sh --json` and continue when the next step is clear.

## Superpowers Alignment

When Superpowers is installed or explicitly requested, use its mature workflow skill as the behavioral reference for the stage, then write PrismSpec artifacts:

| PrismSpec Stage | Prefer Superpowers Discipline |
|---|---|
| `specification` | `superpowers:brainstorming` |
| `planning` | `superpowers:writing-plans` |
| `implementation` | `superpowers:subagent-driven-development`, `superpowers:executing-plans`, `superpowers:test-driven-development` |
| `review` | Superpowers SDD task reviewer discipline |
| `verification` | `superpowers:verification-before-completion` |

Use `superpowers:finishing-a-development-branch` only when branch/worktree closeout is explicitly in scope. PrismSpec's main workflow ends at command-backed verification; durable lessons move through `/capture`.

Do not copy Superpowers output paths blindly. For PrismSpec/Lattice work, write `context.md`, `spec.md`, `plan.md`, task evidence, `review-summary.json`, and `verify.md` in the routed PrismSpec locations.

## Host Modes

- Lattice-hosted: `lattice/manifest.yaml` exists; specs live under `lattice/specs/`, evidence under `.lattice/sdd/`, verification uses the Lattice pipeline.
- Standalone: specs live under `prismspec/specs/`, evidence under `.prismspec/runs/`, verification uses detected local commands.

## Stop Conditions

Stop and ask the user when:

- scope, safety, data, permission, or product behavior is materially ambiguous;
- mode downgrade from `tdd` to `plan` is requested or implied;
- the worktree has unrelated dirty changes that would be mixed into implementation;
- verification fails and the fix requires product or architecture choice;
- an irreversible action is required.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I can just start coding." | Non-trivial work needs a durable spec or the next agent cannot verify intent. |
| "The plan is obvious." | If it is obvious, it is cheap to write and useful for recovery. |
| "Verification can happen in the summary." | Summary records evidence; it does not replace running verification. |
| "This mode can be changed silently." | Mode is an execution contract and must be recorded. |

## Red Flags

- Stage is chosen from conversation memory instead of artifacts.
- `/prismspec` skips directly from `spec.md` to implementation without `plan.md`.
- Verification is described but no command output is recorded.
- Review evidence is missing but the run proceeds to verification.

## Verification

Before reporting completion:

- [ ] `guide.sh --json` reports `stage: done`, or remaining blockers are explicit.
- [ ] Required durable artifacts exist.
- [ ] Review evidence exists or a missing-review risk is explicit.
- [ ] Verification evidence is recorded in `verify.md`.
- [ ] Follow-ups are scoped and not hidden inside "done".
