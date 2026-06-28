---
name: prismspec-implement
description: Executes PrismSpec plan.md one AC-traced slice at a time in plan or TDD mode. Use when /sdd routes to implementation, when code/tests must be changed under a PrismSpec execution policy, when task-next/task-complete evidence gating is available, or when TDD red/green evidence must be produced.
---

# PrismSpec Implement

## Overview

Implement one planned slice at a time. Keep scope narrow, produce evidence, and do not claim completion before verification.

## Inputs

- `spec.md`
- `plan.md`
- Current worktree status.
- Relevant task brief or review package helpers when available.
- `prismspec/references/tdd-evidence-checklist.md` for TDD mode.

## Workflow

1. Check worktree status and avoid mixing unrelated changes.
2. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json` and execute the returned `task_id`; otherwise pick the first incomplete task from `plan.md`.
3. If `task-next` returns `status=complete`, run task evidence lint and advance status instead of editing code.
4. Generate or write a task brief in the evidence directory.
5. Execute according to mode:
   - `plan`: implement the task, add tests for behavior changes or meaningful regression risk.
   - `tdd`: write and run the red test first, then implement green, then refactor.
6. Run focused verification for the task.
7. Generate a review package when helpers exist.
8. In TDD mode, write `tdd-evidence.json` when the helper exists.
9. In Lattice-hosted mode, mark the task complete with `lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> <task-id>`; otherwise update `plan.md` only after evidence exists.
10. In Lattice-hosted mode, re-run `task-next`; if another task is returned, stop or continue only when the user asked for multi-task execution.
11. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>` after completed implementation tasks are checked.
12. In Lattice-hosted mode, when all planned tasks are complete, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> implemented --from=planned`.

## Scope Rules

- Touch only files needed by the task.
- Record spec drift before implementing new scope.
- Prefer simple, boring code until tests prove the behavior.
- Separate unrelated refactors into follow-up tasks.

## Outputs

- Code and tests.
- Task evidence under `.prismspec/runs/<spec-id>/<task-id>/` or `.lattice/sdd/<spec-id>/<task-id>/`.
- For Lattice-hosted TDD tasks: `.lattice/sdd/<spec-id>/<task-id>/tdd-evidence.json`.
- Updated `plan.md` task status when appropriate.

## Stop Conditions

- Dirty worktree has unrelated user changes in files you must edit.
- Red test cannot be made to fail for the intended reason.
- Implementation needs scope not present in the spec.
- Verification failure requires product or architecture choice.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I will test after all tasks." | Bugs compound; each slice needs evidence. |
| "This small behavior change does not need tests." | Small behavior changes still need proof or a written no-test rationale. |
| "I can include this cleanup while here." | Mixed refactor and feature diffs are harder to review and revert. |
| "The red test failed, close enough." | Red must fail for the expected behavior, not setup noise. |

## Red Flags

- More than one planned slice is implemented before running tests.
- Implementation starts without resolving the next task from `task-next.sh` when available.
- `plan.md` is edited directly instead of using `task-complete.sh` when available.
- New abstractions appear before the third concrete need.
- `plan.md` remains unchecked even after evidence exists.
- Implementation changes unmentioned contracts without updating `spec.md`.

## Verification

- [ ] Focused task verification passed or blocker is explicit.
- [ ] TDD tasks include red and green evidence.
- [ ] Lattice task-evidence-lint passes for completed tasks.
- [ ] Lattice spec-status advances to `implemented` when all planned tasks are complete.
- [ ] Diff is scoped to the planned task.
- [ ] Broader relevant tests are ready for `verify`.
