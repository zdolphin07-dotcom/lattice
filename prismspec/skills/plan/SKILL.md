---
name: prismspec-plan
description: Converts an approved PrismSpec spec.md into an AC-traced plan.md. Use when a spec exists but implementation tasks, dependency order, touched files/contracts, verification steps, task evidence requirements, or TDD red-test tasks are missing; or when /sdd routes to plan.
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
6. Include mode, scope, interfaces, files/contracts, AC links, verification, evidence paths, and done conditions per task.
7. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/plan-lint.sh <spec-id>` before implementation starts.
8. In Lattice-hosted mode, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` after plan-lint passes.

## Task Shape

Use checkbox task rows so Lattice can track execution state. Every AC in `spec.md` must be referenced by at least one task.

```markdown
- [ ] T1: <short implementation title>
  - Ref: AC-1, AC-2
  - Mode: plan | tdd
  - Scope: <one sentence; one thin vertical slice>
  - Interfaces:
    - Inputs: <request/event/file/config>
    - Outputs: <response/state/artifact>
    - Touched files/contracts: <module/api/schema/ui/config>
  - Files: `<path>`, `<path>`
  - Verification: `<exact command, test name, or gate>`
  - Evidence:
    - Brief: `.lattice/sdd/<spec-id>/T1/brief.md`
    - Review package: `.lattice/sdd/<spec-id>/T1/review-package.md`
  - Done when:
    - [ ] <observable condition>
```

For TDD tasks, list explicit `RED-{n}` tasks before implementation tasks:

```markdown
- [ ] RED-1: <short red-test title>
  - Ref: AC-1
  - Expected failure: <why this should fail before implementation>
  - Test file: `<path>`
  - Verification: `<exact command or test name>`
  - Done when:
    - [ ] Expected failure is captured in the related task evidence.
```

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
- [ ] Lattice plan-lint passes when running in Lattice-hosted mode.
- [ ] Lattice spec-status advances to `planned` when running in Lattice-hosted mode.
- [ ] Every behavior task references at least one AC.
- [ ] Every task has verification evidence requirements.
- [ ] No task is too large to complete and verify in one focused session.
