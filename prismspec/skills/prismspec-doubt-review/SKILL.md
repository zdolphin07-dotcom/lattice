---
name: prismspec-doubt-review
description: Performs an adversarial doubt review of high-risk PrismSpec assumptions, decisions, and completion claims before they become implementation or verification contracts. Use when work involves security, money, permissions, migrations, concurrency, irreversible actions, unfamiliar systems, or confident claims that are cheaper to challenge now than debug later.
---

# PrismSpec Doubt Review

## Overview

Challenge the decision before it becomes expensive. Doubt review is a bounded adversarial pass for high-risk claims; it is not a second implementation plan and not a reason to stall low-risk work.

Use the loop: claim, assumptions, doubts, reconciliation, stop or proceed.

## Inputs

- `spec.md`, `plan.md`, review findings, or verification claim.
- Risk notes, invariants, Context Basis, and external source facts.
- Related tests, contracts, migrations, security or data boundaries.

## Workflow

1. Extract the claim being relied on.
2. List the assumptions required for the claim to be true.
3. Challenge each assumption with the cheapest disconfirming check.
4. Check for missing actors, failure states, rollback paths, permissions, idempotency, and observability.
5. Reconcile: keep, revise, split, upgrade to TDD, or block.
6. Record the decision and unresolved doubts in `spec.md`, `plan.md`, `review.md`, or `verify.md`.
7. Stop once the risk is bounded; do not generate endless objections.

## Outputs

- Doubt review note with claim, assumptions, doubts, reconciliation, and decision.
- Required spec/plan/mode changes when risk changes.
- Blocking question when a safe decision requires user or owner input.

## Stop Conditions

- A doubt reveals unbounded data loss, security, permission, migration, or irreversible risk.
- Required evidence cannot be obtained locally.
- The review changes scope or mode and needs spec/plan update.
- The task is low risk and the doubt review is no longer producing decision-changing facts.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The model seems confident." | Confidence is not evidence; high-risk claims need disconfirming checks. |
| "Review will catch it later." | Late review is more expensive after code and tests encode the assumption. |
| "This is just a migration." | Migrations are irreversible enough to deserve doubt. |
| "The happy path is covered." | High-risk failures often live in rollback, permissions, idempotency, or concurrency. |
| "More objections means better quality." | Doubt review must stop after decision-changing risks are bounded. |

## Red Flags

- High-risk mode remains `plan` with no rationale.
- Spec has invariants but no negative or rollback verification.
- Review passes while `cannot_verify` risk remains unexplained.
- The same assumption appears in spec, tests, and code without independent evidence.
- Doubt review produces broad concerns but no decision.

## Verification

- [ ] The reviewed claim is explicit.
- [ ] Assumptions and doubts are listed.
- [ ] Each doubt has a check, disposition, or blocker.
- [ ] Result changes spec/plan/mode/evidence when needed.
- [ ] Remaining risk is recorded in the correct artifact.
