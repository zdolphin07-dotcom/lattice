---
name: prismspec-planning
description: Converts an approved PrismSpec spec.md into an AC-traced plan.md. Use when a spec exists but implementation tasks, dependency order, touched files/contracts, verification steps, task evidence requirements, or TDD red-test tasks are missing; or when /prismspec routes to planning.
---

# PrismSpec Planning

## Overview

Decompose `spec.md` into small, ordered, verifiable tasks. The plan is the implementation control surface.

This skill aligns with Superpowers `writing-plans`: global constraints, concrete task interfaces, right-sized independently reviewable tasks, and a pre-flight plan review are preferred over PrismSpec-specific reinvention. PrismSpec adds AC traceability, execution mode, and Lattice evidence paths.

## Inputs

- Target `spec.md`.
- Relevant code boundaries, tests, schemas, contracts, and project conventions.
- `prismspec/references/superpowers-alignment.md` when deciding whether to follow Superpowers `writing-plans` discipline.
- `prismspec/references/mode-selection.md` when risk changes.

## Workflow

1. Read `spec.md` and identify ACs, scope, risks, and execution mode.
2. Inspect enough code to locate implementation boundaries.
3. Write a `Global Constraints` block with the exact project-wide rules copied from the spec: version floors, dependency limits, naming/copy rules, data formats, platform requirements, and invariants.
4. Build dependency order and prefer thin vertical slices.
5. Right-size each task so it carries its own test cycle and reviewer gate.
6. Upgrade `plan -> tdd` when discovered risk requires red-test evidence.
7. Write `plan.md` next to `spec.md`.
8. Include mode, scope, interfaces, files/contracts, AC links, verification, evidence paths, and done conditions per task.
9. Run the self-review checklist below before implementation starts.
10. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/plan-lint.sh <spec-id>` before implementation starts.
11. In Lattice-hosted mode, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` after plan-lint passes.

## Plan Header

Every `plan.md` must start with:

```markdown
# <Feature Name> Implementation Plan

**Goal:** <one-sentence outcome>
**Architecture:** <2-3 sentences about the approach>
**Execution mode:** plan | tdd

## Global Constraints

- <binding requirement copied verbatim from spec/context>
- <exact value, format, version, invariant, or dependency constraint>

---
```

`Global Constraints` is the shared attention lens for implementers and reviewers. Do not place generic process rules there; copy only this spec's binding facts.

## Task Right-Sizing

A task is the smallest unit that can be implemented, tested, reviewed, and recovered independently.

- Fold setup, config, docs, or scaffolding into the task whose deliverable needs them.
- Split only where a reviewer could reject one task while approving the neighboring task.
- Prefer vertical slices over layer-by-layer work when the slice can be tested.
- Keep each task small enough for one focused evidence cycle.

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
    - Implementer report: `.lattice/sdd/<spec-id>/T1/report.md`
    - Review summary: `.lattice/sdd/<spec-id>/T1/review-summary.json`
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

## Interfaces

Each task's `Interfaces` block must be concrete enough for an implementer who sees only that task:

- `Inputs`: exact request/event/file/config/function/type names consumed.
- `Outputs`: exact response/state/artifact/function/type names produced.
- `Touched files/contracts`: exact files, APIs, schemas, routes, UI states, or config keys.
- `Neighbor dependency`: any value or signature a later task relies on.

## No Placeholders

These are plan failures:

- `TBD`, `TODO`, `implement later`, `fill in details`, or equivalent.
- "Add validation/error handling/tests" without concrete cases.
- "Similar to Task N" instead of repeating the exact requirement.
- Verification that says only "run tests" without a command, test name, expected result, or gate.
- Type, method, field, route, config, or artifact names that are used before they are defined.

## Self-Review

Before reporting the plan ready, review it once as if you were the future task reviewer:

1. **Spec coverage:** every `AC-{n}` maps to at least one task and one verification path.
2. **Constraint propagation:** every binding global constraint reaches each task that depends on it.
3. **Placeholder scan:** no vague placeholders or "similar to" instructions remain.
4. **Type/interface consistency:** names and signatures match across neighboring tasks.
5. **Reviewer pre-flight:** if the plan mandates something a reviewer would flag as a defect, surface the conflict before implementation.

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
- Plan omits `Global Constraints` or per-task `Interfaces`.
- A task cannot be reviewed from its brief, report, review package, and evidence alone.

## Verification

- [ ] `plan.md` exists.
- [ ] Lattice plan-lint passes when running in Lattice-hosted mode.
- [ ] Lattice spec-status advances to `planned` when running in Lattice-hosted mode.
- [ ] Every behavior task references at least one AC.
- [ ] Global constraints and task interfaces are present and concrete.
- [ ] Every task has verification evidence requirements.
- [ ] No task is too large to complete and verify in one focused session.
