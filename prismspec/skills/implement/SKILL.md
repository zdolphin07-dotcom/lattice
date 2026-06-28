---
name: prismspec-implement
description: Executes PrismSpec plan.md in plan or TDD mode. Use when /sdd routes to implementation, when implementing AC-traced tasks, or when code/tests must be changed under a PrismSpec execution policy.
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
2. Pick the next incomplete task from `plan.md`.
3. Generate or write a task brief in the evidence directory.
4. Execute according to mode:
   - `plan`: implement the task, add tests for behavior changes or meaningful regression risk.
   - `tdd`: write and run the red test first, then implement green, then refactor.
5. Run focused verification for the task.
6. Generate a review package when helpers exist.
7. Mark the task complete only when evidence exists.

## Scope Rules

- Touch only files needed by the task.
- Record spec drift before implementing new scope.
- Prefer simple, boring code until tests prove the behavior.
- Separate unrelated refactors into follow-up tasks.

## Outputs

- Code and tests.
- Task evidence under `.prismspec/runs/<spec-id>/<task-id>/` or `.lattice/sdd/<spec-id>/<task-id>/`.
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
- New abstractions appear before the third concrete need.
- `plan.md` remains unchecked even after evidence exists.
- Implementation changes unmentioned contracts without updating `spec.md`.

## Verification

- [ ] Focused task verification passed or blocker is explicit.
- [ ] TDD tasks include red and green evidence.
- [ ] Diff is scoped to the planned task.
- [ ] Broader relevant tests are ready for `verify`.
