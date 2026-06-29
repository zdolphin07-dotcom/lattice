---
name: prismspec-branch-closeout
description: Legacy branch-closeout helper for PrismSpec runs. Use when explicit branch or worktree closeout is needed after verification; otherwise use /verify as the workflow endpoint and /capture for durable knowledge.
---

# PrismSpec Branch Closeout

## Overview

Close branch/worktree-specific loose ends when explicitly needed. This is no longer a main PrismSpec workflow stage.

This skill aligns with Superpowers `finishing-a-development-branch` and review workflows when branch closeout is in scope. PrismSpec adds `summary.md`, residual risk, eval evidence, and learn candidates.

## Inputs

- `spec.md`
- `plan.md`
- `verify.md`
- Task evidence and review packages.
- Current git status and changed files.
- `prismspec/references/superpowers-alignment.md` when closeout discipline is unclear.
- `prismspec/references/definition-of-done.md`
- `prismspec/references/review-evidence-checklist.md` when review evidence exists or risk is non-trivial.

## Workflow

1. Read spec, plan, verification evidence, and changed files.
2. Summarize what changed against ACs.
3. Record verification commands and outcomes.
4. Record review verdicts: `pass`, `fail`, or `cannot_verify`; write `review-summary.json` when the helper exists.
5. Write residual risks and deferred work with owners or next actions.
6. In Lattice-hosted mode, generate a closeout draft with `lattice/kernel/orchestrator/sdd/summary-draft.sh <spec-id> [--eval-json=<file>]`, then edit only if human-readable context is missing.
7. Otherwise write `summary.md` next to `spec.md`.
8. If a post-run review finding, rework, escaped defect, incident, or success signal is already known in Lattice-hosted mode, record it with `outcome-link.sh` and refresh `outcome-report.sh` when useful.
9. Publish evidence with `eval-sink.sh publish` when the team uses a central eval sink, refresh `eval-dashboard.sh` when the team uses the static dashboard, and use `eval-query.sh` when a machine-readable central summary is needed.
10. Capture reusable lessons through `prismspec-knowledge-capture` only when durable.
11. In Lattice-hosted mode, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> finished --from=verified` after `summary.md` is written.

## Outputs

- `summary.md`
- Optional generated closeout draft from `summary-draft.sh`.
- Lattice-hosted review evidence: `.lattice/sdd/<spec-id>/<task-id>/review-summary.json` when review was performed.
- Optional Lattice outcome link: `lattice/state/outcomes/*.json`.
- Optional Lattice outcome report: `lattice/state/outcome-report.md`.
- Optional central eval sink publish, dashboard, and query output: `lattice/state/eval-sink/`.
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
- [ ] Known post-run outcome signals are linked to the eval run when applicable.
- [ ] Reusable lessons are captured or intentionally skipped.
- [ ] Lattice spec-status advances to `finished` when running in Lattice-hosted mode.
