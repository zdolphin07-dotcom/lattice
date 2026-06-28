---
name: prismspec-finish
description: Closes a PrismSpec run with summary.md, review evidence, residual risks, and reusable lessons. Use after verification passes or when a run needs an explicit closeout.
---

# PrismSpec Finish

## Overview

Close the loop. Preserve the useful delivery evidence and avoid turning transient details into permanent knowledge.

## Inputs

- `spec.md`
- `plan.md`
- `verify.md`
- Task evidence and review packages.
- Current git status and changed files.
- `prismspec/references/definition-of-done.md`
- `prismspec/references/review-evidence-checklist.md` when review evidence exists or risk is non-trivial.

## Workflow

1. Read spec, plan, verification evidence, and changed files.
2. Summarize what changed against ACs.
3. Record verification commands and outcomes.
4. Record review verdicts: `pass`, `fail`, or `cannot_verify`.
5. Write residual risks and deferred work with owners or next actions.
6. Write `summary.md` next to `spec.md`.
7. Capture reusable lessons through `prismspec-learn` only when durable.

## Outputs

- `summary.md`
- Optional knowledge draft.

## Stop Conditions

- Verification is missing and the user expects a completed run.
- A blocker remains but is being framed as done.
- Review verdict is `cannot_verify` and no residual risk is recorded.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The final answer is enough." | Future agents need file-backed closeout evidence. |
| "All lessons should go to knowledge." | Only durable, reusable, non-secret lessons belong there. |
| "Cannot verify is basically pass." | It is an explicit residual risk. |
| "Deferred work can be vague." | Vague follow-ups are lost work. |

## Red Flags

- `summary.md` omits failed or skipped checks.
- Follow-ups have no scope or trigger.
- Lessons duplicate existing knowledge.
- The summary claims AC completion without evidence.

## Verification

- [ ] `summary.md` exists.
- [ ] Verification result is explicit.
- [ ] Residual risks and deferred work are concrete.
- [ ] Reusable lessons are captured or intentionally skipped.
