# PrismSpec Mode Selection

Use this reference when choosing or revising `execution_mode`.

## Decision Rule

Choose the lowest ceremony mode that still protects correctness.

| Mode | Use When | Must Produce |
|------|----------|--------------|
| `plan` | Low-risk feature work, docs, config, scaffolding, straightforward refactors, existing tests already cover the behavior | AC-traced plan, relevant tests or explicit no-test rationale, verification evidence |
| `tdd` | Bug fixes, core product behavior, auth/permission/security, money, state machines, migrations, concurrency, idempotency, historical regressions | Red test evidence, green evidence, AC-to-test trace, regression verification |

## Override Order

1. User single-run override: record `Source: user-override`.
2. Project default in `lattice/manifest.yaml`: record `Source: project-default`.
3. Model risk choice: record `Source: model-selected`.

## Escalation

- Upgrade `plan -> tdd` when planning or implementation discovers TDD-level risk.
- Do not silently downgrade `tdd -> plan`.
- If the user downgrades a TDD-worthy task, record the risk and verification compromise in `spec.md` and `summary.md`.

## Red Flags

- A bug fix uses `plan` and has no failing reproduction test.
- A payment, permission, migration, or concurrency change uses `plan` without a written rationale.
- The mode is mentioned in conversation but missing from `spec.md`.
- Verification evidence does not match the selected mode.
