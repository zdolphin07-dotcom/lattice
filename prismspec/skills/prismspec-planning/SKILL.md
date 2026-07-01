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
3. Write a Chinese `全局约束` block with the exact project-wide rules copied from the spec: version floors, dependency limits, naming/copy rules, data formats, platform requirements, and invariants.
4. Build dependency order and prefer thin vertical slices.
5. Right-size each task so it carries its own test cycle and reviewer gate.
6. Upgrade `plan -> tdd` when discovered risk requires red-test evidence.
7. Write `plan.md` next to `spec.md`.
8. Include mode, scope, interfaces, files/contracts, AC links, verification, evidence paths, and done conditions per task.
9. For implementation tasks, include concrete steps that a zero-context implementer can follow: exact file paths, code/test locations, focused command, expected result, and commit or evidence boundary.
10. For TDD tasks, include the red test intent, exact command, expected failure reason, green command, and regression command.
11. Run the self-review checklist below before implementation starts.
12. In Lattice-hosted mode, run `lattice/kernel/orchestrator/sdd/plan-lint.sh <spec-id>` before implementation starts.
13. In Lattice-hosted mode, advance status with `lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` after plan-lint passes.

## Plan Header

Every `plan.md` must start with:

```markdown
# 实施计划：<功能或技术主题>

**技术目标：** <一句话说明本轮实现要达成的工程结果>
**实现策略：** <2-3 句话说明架构路径、关键取舍和边界>
**执行模式：** plan | tdd

## 1. 来源

- 技术方案：`lattice/specs/<spec-id>/spec.md`
- 工作项：`<ticket-or-spec-id>`
- 执行模式：`plan|tdd`

## 2. 全局约束

- <binding requirement copied verbatim from spec/context>
- <exact value, format, version, invariant, or dependency constraint>

---
```

`全局约束` is the shared attention lens for implementers and reviewers. Do not place generic process rules there; copy only this spec's binding facts. User-facing headings and field labels in `plan.md` should be Chinese; keep stable IDs, commands, file paths, and code identifiers unchanged.

## Task Right-Sizing

A task is the smallest unit that can be implemented, tested, reviewed, and recovered independently.

- Fold setup, config, docs, or scaffolding into the task whose deliverable needs them.
- Split only where a reviewer could reject one task while approving the neighboring task.
- Prefer vertical slices over layer-by-layer work when the slice can be tested.
- Keep each task small enough for one focused evidence cycle.

## Task Shape

Use checkbox task rows so Lattice can track execution state. Every AC in `spec.md` must be referenced by at least one task.
Place task rows under `## 3. 任务拆解`.

```markdown
## 3. 任务拆解

- [ ] T1: <short implementation title>
  - 覆盖验收：AC-1, AC-2
  - 模式：plan | tdd
  - 范围：<一句话描述一个可独立实现、测试、评审的纵向切片>
  - 接口契约：
    - 输入：<request/event/file/config>
    - 输出：<response/state/artifact>
    - 依赖边界：<module/api/schema/ui/config>
  - 涉及文件：`<path>`, `<path>`
  - 验证方式：`<exact command, test name, or gate>`
  - 执行步骤：
    - [ ] 编写或更新 `<test path>`，覆盖 `<specific behavior>`。
    - [ ] 运行 `<focused command>`，预期 `<pass/fail reason>`。
    - [ ] 修改 `<implementation path>`，产出 `<exact output/state>`。
    - [ ] 重新运行 `<focused command>`，预期通过。
    - [ ] 运行 `<regression command>`，或记录无测试理由。
  - 证据：
    - 任务简报：`.lattice/sdd/<spec-id>/T1/brief.md`
    - 评审包：`.lattice/sdd/<spec-id>/T1/review-package.md`
    - 实施报告：`.lattice/sdd/<spec-id>/T1/report.md`
    - 评审记录：`.lattice/sdd/<spec-id>/T1/review.md`
  - 完成条件：
    - [ ] <observable condition>
```

For TDD tasks, list explicit `RED-{n}` tasks before implementation tasks:

```markdown
- [ ] RED-1: <short red-test title>
  - 覆盖验收：AC-1
  - 预期失败：<why this should fail before implementation>
  - 测试文件：`<path>`
  - 验证方式：`<exact command or test name>`
  - 预期命令结果：失败原因应为 `<missing behavior>`，不是环境、语法或导入错误。
  - 完成条件：
    - [ ] 预期失败已记录到对应任务证据。
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
- Steps that tell an implementer what to accomplish but not where to edit, what to run, or what result proves the step.

## Self-Review

Before reporting the plan ready, review it once as if you were the future task reviewer:

1. **Spec coverage:** every `AC-{n}` maps to at least one task and one verification path.
2. **Constraint propagation:** every binding global constraint reaches each task that depends on it.
3. **Placeholder scan:** no vague placeholders or "similar to" instructions remain.
4. **Type/interface consistency:** names and signatures match across neighboring tasks.
5. **Reviewer pre-flight:** if the plan mandates something a reviewer would flag as a defect, surface the conflict before implementation.
6. **Zero-context execution:** a fresh implementer with only one task, the global constraints, and relevant interfaces can complete the task without reading the whole plan.

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
- Plan omits `全局约束` or per-task `接口契约`.
- A task cannot be reviewed from its brief, report, review package, and evidence alone.
- TDD red task lacks the expected failure reason.

## Verification

- [ ] `plan.md` exists.
- [ ] Lattice plan-lint passes when running in Lattice-hosted mode.
- [ ] Lattice spec-status advances to `planned` when running in Lattice-hosted mode.
- [ ] Every behavior task references at least one AC.
- [ ] Global constraints and task interfaces are present and concrete.
- [ ] Every task has verification evidence requirements.
- [ ] Behavior tasks include concrete steps, focused commands, and expected results.
- [ ] No task is too large to complete and verify in one focused session.
