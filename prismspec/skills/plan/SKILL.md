---
name: prismspec-plan
description: Converts an approved PrismSpec spec.md into an AC-traced plan.md. Use when a spec exists but implementation tasks, dependencies, verification steps, or TDD red-test tasks are missing.
---

# PrismSpec Plan

## Overview

Decompose `spec.md` into small, ordered, verifiable tasks. The plan is the implementation control surface.

## Inputs

- Target `spec.md`.
- Relevant code boundaries, tests, schemas, contracts, and project conventions.
- `prismspec/references/mode-selection.md` when risk changes.

## Workflow

1. Read `spec.md` and identify ACs, scope, risks, and execution mode.
2. Inspect enough code to locate implementation boundaries.
3. Build dependency order and prefer thin vertical slices.
4. Upgrade `plan -> tdd` when discovered risk requires red-test evidence.
5. Write `plan.md` next to `spec.md`.
6. Include interfaces, likely files, acceptance links, and verification per task.

## Task Shape

```markdown
## T1: <short task title>

- AC: AC-1, AC-2
- Mode: plan | tdd
- Scope: <one sentence>
- Files likely touched:
  - `<path>`
- Verification:
  - `<exact command or evidence>`
- Done when:
  - [ ] <observable condition>
```

For TDD tasks, add explicit red tasks before implementation tasks.

## Outputs

- `plan.md`
- Optional spec update when execution mode or scope changes.

## Stop Conditions

- An AC cannot map to any implementation or verification path.
- A task would touch unrelated subsystems and needs splitting.
- Planning reveals a product or architecture decision absent from the spec.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The implementation order is obvious." | Written order prevents context loss and tangled diffs. |
| "One big task is simpler." | Large tasks are harder for agents to verify and recover. |
| "Tests can be added wherever." | Tests must trace to ACs or they do not prove the spec. |
| "Risk can be handled during implementation." | Risk discovered in planning must update the execution policy. |

## Red Flags

- Tasks do not reference ACs.
- Plan is organized horizontally by layer when a vertical slice is possible.
- TDD mode has implementation tasks before red-test tasks.
- Verification says "run tests" without exact commands.

## Verification

- [ ] `plan.md` exists.
- [ ] Every behavior task references at least one AC.
- [ ] Every task has verification evidence requirements.
- [ ] No task is too large to complete and verify in one focused session.
