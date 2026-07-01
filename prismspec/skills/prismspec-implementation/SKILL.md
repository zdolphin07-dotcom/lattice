---
name: prismspec-implementation
description: Executes PrismSpec plan.md one AC-traced slice at a time in plan or TDD mode. Use when /prismspec routes to implementation, when code/tests must be changed under a PrismSpec execution policy, when an isolated implementer should execute a task package, when task-next/task-complete evidence gating is available, or when TDD red/green evidence must be produced.
---

# PrismSpec Implementation

## Overview

Implement one planned slice at a time. Keep scope narrow, produce evidence, and do not claim completion before verification.

This skill aligns with Superpowers `subagent-driven-development`, `executing-plans`, and `test-driven-development`: use file-backed handoffs, task-scoped review, strict TDD when required, and completion gates. PrismSpec adds routed task state, AC traceability, and Lattice evidence.

TDD mode is intentionally strict: write the test first, watch it fail for the expected reason, write the minimum code to pass, then refactor while staying green. If implementation code was written before the failing test, delete it or isolate it away from the final change and restart the task from the test.

## Inputs

- `spec.md`
- `plan.md`
- Current worktree status.
- Relevant task brief or review package helpers when available.
- `prismspec/references/superpowers-alignment.md` when choosing execution discipline.
- `prismspec/references/tdd-evidence-checklist.md` for TDD mode.
- `prismspec/agents/task-reviewer.md` when a task-scoped review is requested.

## Workflow

1. Check worktree status and avoid mixing unrelated changes.
2. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json` and execute the returned `task_id`; otherwise pick the first incomplete task from `plan.md`.
3. If `task-next` returns `status=complete`, run task evidence lint and advance status instead of editing code.
4. Generate or write a task brief in the evidence directory.
5. Execute according to mode:
   - `plan`: implement the task, add tests for behavior changes or meaningful regression risk.
   - `tdd`: write and run the red test first, confirm the expected failure, implement green, then refactor.
6. When subagents are available and tasks are independent, prefer the Subagent Execution Loop below.
7. Run focused verification for the task.
8. Write an implementer report in the task evidence directory with commit range, files changed, tests run, and concerns.
9. Generate a review package when helpers exist.
10. Generate review evidence for the review stage. When task-scoped review is requested, use one reviewer that returns both spec-compliance and code-quality verdicts.
11. In TDD mode, write `tdd-evidence.json` when the helper exists.
12. In Lattice-hosted mode, mark the task complete with `lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> <task-id>`; otherwise update `plan.md` only after evidence exists.
13. Update the progress ledger when available.
14. In Lattice-hosted mode, re-run `task-next`; if another task is returned, stop or continue only when the user asked for multi-task execution.
15. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>` after completed implementation tasks are checked.
16. In Lattice-hosted mode, when all planned tasks are complete, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> implemented --from=planned`.

## Subagent Execution Loop

Use this loop when subagents are available and the task can be isolated:

1. Create or read the progress ledger at `.lattice/sdd/<spec-id>/progress.md` or `.prismspec/runs/<spec-id>/progress.md`.
2. Record the base commit before dispatching the implementer.
3. Dispatch a fresh implementer with only the task brief, global constraints, relevant interfaces, output report path, and test/evidence contract.
4. Interpret implementer status:
   - `DONE`: proceed to review.
   - `DONE_WITH_CONCERNS`: read concerns and resolve correctness or scope concerns before review.
   - `NEEDS_CONTEXT`: provide missing context and re-dispatch.
   - `BLOCKED`: change context, model, task size, or escalate; do not retry unchanged.
5. Generate the review package from the recorded base commit to current HEAD.
6. Dispatch a read-only task reviewer with the task brief, implementer report, review package, and binding global constraints.
7. Fix Critical and Important findings before marking the task complete. Record Minor findings for final triage.
8. Append one ledger line: `Task <id>: complete (commits <base>..<head>, review <verdict>)`.
9. After all tasks, run a final whole-branch review before verification when the diff is non-trivial.

Do not paste full prior-task history into later dispatches. File paths and the current task brief are the handoff.

## TDD Cycle

Use this cycle for each TDD task:

1. **RED:** write one minimal test for one AC/risk.
2. **Verify RED:** run the exact focused command and confirm it fails because the behavior is missing, not because of setup noise.
3. **GREEN:** write the smallest production change that makes the focused test pass.
4. **Verify GREEN:** run the focused command and the relevant regression command.
5. **REFACTOR:** clean up only after green, then re-run the relevant command.
6. **Record evidence:** AC ids, test file/name, red command/exit/summary, green command/exit/summary, and refactor note.

Do not weaken, delete, or rewrite a valid red test to make the implementation easier.

## File Handoffs

Prefer file-backed handoffs over pasted context:

- `brief.md`: task requirements, AC refs, global constraints, and exact interfaces.
- `report.md`: implementer status, commits, files, test commands/results, TDD evidence summary, and concerns.
- `review-package.md`: read-only diff package for the reviewer.
- `review.md`: reviewer verdicts and findings.

Do not paste full diffs into prompts or summaries when a review package exists.

## Task Review

Task review is a gate, not a rewrite session.

- Use a single task-scoped reviewer that returns both spec-compliance and code-quality verdicts.
- The reviewer is read-only and must not mutate the working tree, index, HEAD, or branch.
- The reviewer must treat the implementer report as claims, not proof.
- The controller must not tell the reviewer what to ignore or pre-rate severity.
- Use `cannot_verify` when the review package or evidence is insufficient.
- Critical and Important findings block task completion; Minor findings may be recorded for final triage.

## Scope Rules

- Touch only files needed by the task.
- Record spec drift before implementing new scope.
- Prefer simple, boring code until tests prove the behavior.
- Separate unrelated refactors into follow-up tasks.
- If a command fails for an unexplained reason, switch to `prismspec-debugging` before fixing.

## Outputs

- Code and tests.
- Task evidence under `.prismspec/runs/<spec-id>/<task-id>/` or `.lattice/sdd/<spec-id>/<task-id>/`.
- For Lattice-hosted TDD tasks: `.lattice/sdd/<spec-id>/<task-id>/tdd-evidence.json`.
- Updated `plan.md` task status when appropriate.
- Progress ledger when subagent execution is used.

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
| "The reviewer can trust my report." | Reports are claims; review must be grounded in diff and evidence. |

## Red Flags

- More than one planned slice is implemented before running tests.
- Implementation starts without resolving the next task from `task-next.sh` when available.
- `plan.md` is edited directly instead of using `task-complete.sh` when available.
- New abstractions appear before the third concrete need.
- `plan.md` remains unchecked even after evidence exists.
- Implementation changes unmentioned contracts without updating `spec.md`.
- TDD task has green evidence without a captured red failure.
- Review prompt includes "do not flag", "ignore", "at most minor", or similar pre-judgment.
- Re-dispatches a blocked subagent without changing context, model, task size, or instructions.
- Relies on conversation todos alone for multi-task progress.

## Verification

- [ ] Focused task verification passed or blocker is explicit.
- [ ] TDD tasks include red and green evidence.
- [ ] Implementer report and review package exist when review is required.
- [ ] Task review has both spec-compliance and code-quality verdicts when review is required.
- [ ] Progress ledger is updated when subagent execution is used.
- [ ] Lattice task-evidence-lint passes for completed tasks.
- [ ] Lattice spec-status advances to `implemented` when all planned tasks are complete.
- [ ] Diff is scoped to the planned task.
- [ ] Broader relevant tests are ready for `review` and `verify`.
