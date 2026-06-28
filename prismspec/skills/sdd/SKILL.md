---
name: prismspec-sdd
description: Orchestrates the PrismSpec spec-coding workflow from intent to verified closeout. Use when the user asks for SDD, PrismSpec, spec-driven development, /sdd, guided spec workflow, resuming an existing spec, choosing plan vs TDD mode, or running an AI coding task through brainstorm, plan, implement, verify, and finish.
---

# PrismSpec SDD

## Overview

Act as the lifecycle controller for PrismSpec. Route work through the smallest complete chain:

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

This skill is a controller, not an extra phase. Delegate stage work to the stage skills.

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
| `brainstorm` | `prismspec-brainstorm` | `context.md`, `spec.md` |
| `plan` | `prismspec-plan` | `plan.md` |
| `implement` | `prismspec-implement` | code, tests, task evidence |
| `verify` | `prismspec-verify` | `verify.md` |
| `finish` | `prismspec-finish` | `summary.md`, optional learn draft |

After each completed stage, rerun `guide.sh --json` and continue when the next step is clear.

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
- `/sdd` skips directly from `spec.md` to implementation without `plan.md`.
- Verification is described but no command output is recorded.
- `summary.md` exists while tasks or failures are unresolved.

## Verification

Before reporting completion:

- [ ] `guide.sh --json` reports `stage: done`, or remaining blockers are explicit.
- [ ] Required durable artifacts exist.
- [ ] Verification evidence is linked from `summary.md`.
- [ ] Follow-ups are scoped and not hidden inside "done".
