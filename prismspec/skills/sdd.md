# Skill: sdd — PrismSpec Guided Workflow

**Triggers**: `/sdd`, PrismSpec, guided sdd, spec workflow, spec coding

## Capability

Guide and resume the complete PrismSpec workflow:

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

This is a controller skill, not a new phase. Delegate stage behavior to the stage skills.

## Flow Guide

Before deciding manually, run the deterministic guide when available:

```bash
bash prismspec/bin/guide.sh [--spec=<spec-id>] [--from=<stage>] [--mode=auto|plan|tdd]
```

Use its output as the routing source of truth:

- `Stage` tells which stage skill to read next.
- `Skill` gives the stage skill file.
- `Spec dir` and `Evidence` give durable and transient artifact paths.
- `Template` gives the initial template hint for Brainstorming.

If `guide.sh` is unavailable, follow the Host Detection and Routing rules below.

## Host Detection

Before routing:

1. If `lattice/manifest.yaml` exists, run in Lattice-hosted mode:
   - specs: `lattice/specs/<spec-id>/`
   - transient evidence: `.lattice/sdd/<spec-id>/`
   - template: `lattice/kernel/orchestrator/templates/spec-template.md`
   - verification: `bash lattice/kernel/delivery/pipeline.sh`
2. Otherwise run in standalone mode:
   - specs: `prismspec/specs/<spec-id>/`
   - transient evidence: `.prismspec/runs/<spec-id>/`
   - template: `prismspec/templates/spec-template.md`
   - verification: detected local build/lint/test commands

## Inputs

- User requirement, existing spec id, or continuation request.
- Optional spec selector: `spec=<spec-id>`.
- Optional mode override: `mode=auto|plan|tdd`.
- Optional resume hint: `from=brainstorm|plan|implement|verify|finish`.

## Mode Selection

Determine execution mode once during Brainstorming and preserve it:

1. User override `mode=plan|tdd` wins when allowed.
2. Project default wins when configured.
3. Otherwise choose by risk and record `Source: model-selected`.

Use `tdd` for bug fixes, core behavior, money/security/permission logic, state machines, migrations, concurrency, idempotency, or regression-prone changes. Use `plan` for low-risk feature work, docs, scaffolding, and straightforward refactors.

If later stages discover TDD-level risk, upgrade `plan -> tdd`. Do not silently downgrade `tdd -> plan`.

## Routing

Resolve the next stage from artifacts unless `from=<stage>` is provided:

| Current evidence | Next action |
|------------------|-------------|
| no matching `spec.md` | Run Brainstorming |
| `spec.md` exists but `plan.md` is missing | Run Planning |
| `plan.md` exists and tasks are incomplete | Run Implementation |
| tasks appear complete but verification evidence is missing | Run Verification |
| verification passed but `summary.md` is missing | Run Finishing |
| `summary.md` exists | Report status and next optional action |

After each stage reaches exit criteria, recompute routing and continue automatically. Stop only on completion, retry exhaustion, or a material human decision.

## Completion

Complete only when:

- `spec.md`, `plan.md`, and `summary.md` exist;
- implementation tasks are complete or explicitly deferred;
- verification has passed or remaining failures are clearly escalated;
- durable lessons, if any, are captured through `learn.md`.
