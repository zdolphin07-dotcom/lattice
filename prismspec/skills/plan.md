# Skill: plan — PrismSpec Planning

**Triggers**: `/plan`, planning, write plan, decompose spec

## Capability

Convert `spec.md` into an execution plan with AC-traced tasks.

## Workflow

1. Read the target `spec.md`.
2. Inspect relevant files enough to identify implementation boundaries.
3. Validate execution mode:
   - If `plan` reveals TDD-level risk, update the spec to `tdd` before implementation.
   - Do not downgrade `tdd` without explicit user override.
4. Write `plan.md` next to `spec.md`.
5. Include:
   - source spec path and execution mode;
   - global constraints;
   - test-first tasks when mode is `tdd`;
   - implementation tasks with AC references;
   - interfaces: inputs, outputs, touched files/contracts, verification evidence.

## Exit Criteria

- `plan.md` exists.
- Every behavior task references at least one AC.
- TDD mode includes red-test-first tasks.
