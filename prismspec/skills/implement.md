# Skill: implement — PrismSpec Implementation

**Triggers**: `/implement`, implement, execute plan, tdd

## Capability

Execute `plan.md` according to the spec execution policy.

## Plan Mode

1. Implement tasks in plan order.
2. Add tests for behavior changes or meaningful regression risk.
3. Keep changes scoped to the spec and task interfaces.
4. If new risk appears, escalate to TDD and update `spec.md` / `plan.md`.

## TDD Mode

1. Write the red tests listed in `plan.md`.
2. Run focused tests and confirm they fail for the expected reason.
3. Implement the minimal code to make them pass.
4. Re-run focused tests and confirm green.
5. Refactor only after green.

## Evidence

- Lattice-hosted: use `.lattice/sdd/<spec-id>/<task-id>/`.
- Standalone: use `.prismspec/runs/<spec-id>/<task-id>/`.

When helper scripts exist, generate task briefs and review packages. Otherwise create concise `brief.md` and `review-package.md` manually.

## Exit Criteria

- Planned tasks are complete or explicitly deferred.
- Focused tests pass.
- Broader relevant tests pass or failures are documented.
- No unresolved spec drift remains.
