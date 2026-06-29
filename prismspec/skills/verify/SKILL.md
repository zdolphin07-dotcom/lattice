---
name: prismspec-verify
description: Runs independent command-backed verification for a PrismSpec run and records durable verify.md evidence. Use when implementation and review are complete, after fixing failures, when Lattice pipeline gates should run, or whenever /prismspec routes to verification.
---

# PrismSpec Verification

## Overview

Run actual commands and record evidence. Verification is external proof, not a prose assertion.

This skill aligns with Superpowers `verification-before-completion`: no completion claim without command-backed evidence. PrismSpec adds durable `verify.md` and Lattice pipeline/eval gates. Verification is the main PrismSpec workflow endpoint; optional knowledge promotion happens through `/capture`.

## Inputs

- `spec.md`
- `plan.md`
- `review-summary.json` when review evidence is required.
- Current code and tests.
- Lattice pipeline when installed.
- `prismspec/references/superpowers-alignment.md` when completion discipline is unclear.
- `prismspec/references/definition-of-done.md`

## Workflow

1. Resolve verification command from `prismspec/bin/guide.sh --json`.
2. In Lattice-hosted mode, run:

```bash
bash lattice/kernel/delivery/pipeline.sh --json-out
```

3. In standalone mode, detect and run the smallest meaningful set:
   - Node: `npm run build`, `npm run lint`, `npm test` when present.
   - Python: `ruff check .`, `pytest` when present.
   - Go: `go test ./...`.
   - Rust: `cargo test`.
4. Record exact commands, exit codes, output summaries, AC completion, skipped checks, residual risks, next actions, and knowledge candidates in `verify.md`.
5. Fix retryable failures within the task scope, then rerun affected commands.
6. Escalate non-retryable failures with concrete next steps.
7. In Lattice-hosted mode, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> verified --from=implemented` only after verification passes.

## Outputs

- `verify.md` next to `spec.md`.

## Stop Conditions

- Verification requires external service or credentials not available.
- Failure points to ambiguous product behavior.
- Fix would exceed approved scope.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The tests should pass." | Only actual output is evidence. |
| "Focused tests passed, full verification is unnecessary." | Focused tests prove the slice; verification checks regressions. |
| "This failure is unrelated." | Record it with evidence and rationale, or fix it. |
| "I can summarize without writing verify.md." | Durable evidence is the completion record and future recovery point. |

## Red Flags

- Verification output is paraphrased with no command.
- `verify.md` says pass while commands failed.
- TDD evidence is missing for `execution_mode: tdd`.
- Manual checks are claimed without steps or observations.

## Verification

- [ ] `verify.md` exists.
- [ ] Commands and outcomes are recorded.
- [ ] AC completion, skipped checks, residual risks, and next actions are recorded.
- [ ] Failures are fixed or escalated.
- [ ] Evidence matches the selected execution mode.
- [ ] Lattice spec-status advances to `verified` only after passing evidence exists.
