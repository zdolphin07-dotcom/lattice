# PrismSpec Risk Routing Card

Use this card during Specification or Planning to choose the minimum necessary execution strength. The goal is not to classify every task perfectly; the goal is to avoid using a weak workflow for work that can create real regressions.

## Default Rule

Start from `auto` unless the user or project manifest explicitly selects `plan` or `tdd`.

- Route to `plan` when the task is low risk and can be proven with ordinary verification.
- Route to `tdd` when a regression, invariant, or critical behavior must be protected before implementation.
- Upgrade `plan -> tdd` as soon as planning or implementation reveals TDD-level risk.
- Never silently downgrade `tdd -> plan`; user override must be explicit and recorded in `spec.md` and `verify.md`.

## Route To `plan`

Use `plan` when most of these are true:

- Documentation, examples, comments, or packaging metadata.
- Configuration changes with narrow blast radius.
- Small feature work with clear acceptance criteria and existing coverage.
- Simple refactor that preserves behavior and has a focused verification command.
- UI or copy changes where visual/interaction checks are sufficient.
- No permission, money, security, migration, concurrency, idempotency, or state-machine invariant is involved.

Required evidence:

- AC-traced `plan.md`.
- Focused test/build/lint command, or explicit no-test rationale.
- `review.md` for implementation review when code changed.
- `verify.md` with command, exit code, result, and residual risk.

## Route To `tdd`

Use `tdd` when any of these are true:

- Bug fix or historical regression.
- Permission, security, privacy, money, billing, quota, or audit behavior.
- State machine, workflow transition, retry, idempotency, concurrency, cache invalidation, or migration.
- Core product path where an escaped defect would be expensive.
- Ambiguous behavior that must be frozen before implementation.
- Existing tests are missing for the behavior being changed.

Required evidence:

- Regression scenario and invariant in `spec.md`.
- `RED-{n}` task before implementation tasks in `plan.md`.
- Failing test observed for the expected reason.
- Green test observed after the minimal fix.
- AC-to-test trace and final verification in `verify.md`.

## Escalation Signals

Escalate from `plan` to `tdd` if you discover:

- An AC cannot be verified without adding a new behavioral test.
- A change touches auth, payment, lifecycle state, data migration, background jobs, or retries.
- A failing command exposes a real product behavior gap.
- The implementation needs to change existing behavior to pass verification.
- Review finds missing regression coverage for a high-risk path.

## Recording Format

In `spec.md`, record:

```yaml
execution_mode: plan|tdd
mode_source: user|manifest|model-selected|escalated
```

In the Execution Policy section, include:

```text
- Mode: `plan|tdd`
- Reason: <risk signal or low-risk rationale>
- Escalation: `plan -> tdd` allowed if new risk is discovered; `tdd -> plan` requires explicit user override.
```
