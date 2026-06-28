---
name: prismspec-verify
description: Runs independent verification for a PrismSpec run and records durable verify.md evidence. Use when implementation tasks appear complete, before finish, or whenever /sdd routes to verification.
---

# PrismSpec Verify

## Overview

Run actual commands and record evidence. Verification is external proof, not a prose assertion.

## Inputs

- `spec.md`
- `plan.md`
- Current code and tests.
- Lattice pipeline when installed.
- `prismspec/references/definition-of-done.md`

## Workflow

1. Resolve verification command from `prismspec/bin/guide.sh --json`.
2. In Lattice-hosted mode, run:

```bash
bash lattice/kernel/delivery/pipeline.sh
```

3. In standalone mode, detect and run the smallest meaningful set:
   - Node: `npm run build`, `npm run lint`, `npm test` when present.
   - Python: `ruff check .`, `pytest` when present.
   - Go: `go test ./...`.
   - Rust: `cargo test`.
4. Record exact commands, exit codes, and output summaries in `verify.md`.
5. Fix retryable failures within the task scope, then rerun affected commands.
6. Escalate non-retryable failures with concrete next steps.

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
| "I can summarize without writing verify.md." | Durable evidence is needed for finish and future recovery. |

## Red Flags

- Verification output is paraphrased with no command.
- `verify.md` says pass while commands failed.
- TDD evidence is missing for `execution_mode: tdd`.
- Manual checks are claimed without steps or observations.

## Verification

- [ ] `verify.md` exists.
- [ ] Commands and outcomes are recorded.
- [ ] Failures are fixed or escalated.
- [ ] Evidence matches the selected execution mode.
