# Skill: sdd — PrismSpec Guided Workflow (Lattice-hosted)

**Triggers**: `/sdd`, guided sdd, spec workflow, run lattice workflow

## Capability

Guide and resume the complete PrismSpec workflow inside a Lattice project by orchestrating the existing stage skills:

```text
Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing
```

This is a controller skill, not a new phase. Keep stage logic in the stage skills and delegate by reading the referenced skill file before executing that stage.

PrismSpec is standalone. In Lattice-hosted mode, it uses `lattice/manifest.yaml`, `lattice/specs/`, `.lattice/sdd/`, knowledge loading, and the Lattice delivery pipeline.

## Inputs

- User requirement, existing spec id, or continuation request.
- Optional spec selector: `spec=<spec-id>`.
- Optional mode override: `mode=auto|plan|tdd`.
- Optional resume hint: `from=brainstorm|plan|implement|verify|finish`.

## Required Context

Before routing:

1. Read `lattice/manifest.yaml`.
2. Read `specs.default_execution_mode` and `specs.allow_execution_mode_override`.
3. If `spec=<spec-id>` is provided, inspect `lattice/specs/<spec-id>/`.
4. If no spec id is provided, search recent specs only enough to avoid duplicating obvious in-progress work.

Do not paste large specs, plans, or diffs into the prompt. Use file paths and the existing task evidence helpers.

## Mode Selection

Determine execution mode once during Brainstorming and preserve it through the workflow:

1. If the user supplies `mode=plan|tdd` and overrides are allowed, record `Source: user-override`.
2. Else if `specs.default_execution_mode` is `plan` or `tdd`, record `Source: project-default`.
3. Else select intelligently and record `Source: model-selected`.

Use `tdd` for bug fixes, core behavior, money/security/permission logic, state machines, concurrency, idempotency, migrations, or regression-prone changes. Use `plan` for low-risk feature work, docs, scaffolding, and straightforward refactors.

If later stages discover TDD-level risk, upgrade `plan -> tdd` before continuing. Do not silently downgrade `tdd -> plan`; require an explicit user override.

## Routing

Resolve the next stage from artifacts, unless `from=<stage>` is explicitly provided:

| Current evidence | Next action |
|------------------|-------------|
| No matching `lattice/specs/<spec-id>/spec.md` | Run Brainstorming |
| `spec.md` exists but `plan.md` is missing | Run Planning |
| `plan.md` exists and tasks are incomplete | Run Implementation |
| Tasks appear complete but verification evidence is missing | Run Verification |
| Verification passed but `summary.md` is missing | Run Finishing |
| `summary.md` exists | Report current status and next optional action |

When evidence is ambiguous, inspect `spec.md`, `plan.md`, `.lattice/sdd/<spec-id>/`, and recent verification output. Ask only if the ambiguity affects scope, acceptance criteria, safety, or execution mode.

After a stage reaches its exit criteria, recompute routing from artifacts and continue automatically. Stop only when the workflow is complete, verification fails after the retry budget, or a material human decision is required.

## Stage Delegation

- **Brainstorming**: execute `lattice/skills/brainstorm.md`; output `lattice/specs/<spec-id>/spec.md`.
- **Planning**: execute `lattice/skills/plan.md`; output `lattice/specs/<spec-id>/plan.md`.
- **Implementation**: execute `lattice/skills/implement.md`; output task changes and `.lattice/sdd/<spec-id>/<task-id>/` evidence.
- **Verification**: execute `lattice/skills/verify.md`; run the manifest-driven delivery pipeline.
- **Finishing**: execute `lattice/skills/finish.md`; output `lattice/specs/<spec-id>/summary.md` and durable knowledge candidates.

## Operating Rules

- Prefer automatic continuation when the next action is clear.
- After each stage, report the created or updated artifact path before continuing.
- Keep human checkpoints valuable: ask only for material product, safety, or irreversible decisions.
- Never skip verification or claim completion before verification evidence exists.
- Keep specs persistent and evidence file-backed.
- Do not create extra process stages outside the five-stage SDD chain.
- Keep implementation scoped to the spec and plan; unrelated cleanup requires a new spec or explicit user approval.

## Completion Report

When the guided run stops, respond with:

- spec id and current status;
- artifacts created or updated;
- verification result;
- blocking decision or deferred work, if any;
- recommended next command only when the workflow is not finished.

## Exit Criteria

The guided workflow is complete only when:

- `spec.md`, `plan.md`, and `summary.md` exist for the spec;
- implementation tasks are complete or explicitly deferred;
- verification has passed or remaining failures are clearly escalated;
- durable lessons, if any, have been routed through `/learn`;
- the final response cites the spec id, changed files, verification result, and any deferred work.

User input: $ARGUMENTS
