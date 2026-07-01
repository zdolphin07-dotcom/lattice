---
name: prismspec-review
description: Reviews PrismSpec implementation evidence, review-package.md files, reviewer findings, and task or branch diffs before verification. Use when planned implementation tasks are complete, when task review packages exist, when /review is invoked, when reviewer findings need disposition, or when /prismspec routes to review before final verification.
---

# PrismSpec Review

## Overview

Review is the independent quality gate between implementation and verification. Treat implementer reports as claims, inspect the diff and evidence, and record a verdict before the run claims verified completion.

This skill aligns with Superpowers task review discipline: use one skeptical read-only reviewer per task or run, return spec-compliance and code-quality verdicts, and do not tell the reviewer what to ignore. PrismSpec adds AC traceability, Lattice evidence paths, a human-readable `review.md`, and a machine sidecar `review-summary.json` for pipeline/eval ingestion.

## Inputs

- `spec.md`
- `plan.md`
- Task briefs, implementer reports, review packages, TDD evidence, and changed files.
- `prismspec/agents/task-reviewer.md`
- `prismspec/references/review-evidence-checklist.md`
- `prismspec/references/superpowers-alignment.md`

## Workflow

1. Confirm implementation tasks are complete or identify the incomplete task that blocks review.
2. Read the relevant `spec.md`, `plan.md`, task evidence, and review packages.
3. Use the smallest reviewer set that covers the risk:
   - `prismspec/agents/spec-reviewer.md` before planning or when scope, ACs, context, or mode changed.
   - `prismspec/agents/task-reviewer.md` for normal task-scoped implementation review.
   - `prismspec/agents/test-reviewer.md` when `execution_mode: tdd`, tests changed substantially, or AC-to-test trace is uncertain.
   - `prismspec/agents/risk-reviewer.md` when security, permission, money, data, migration, concurrency, idempotency, or irreversible behavior is touched.
4. Review as read-only. Do not mutate the working tree, index, HEAD, branch, or evidence files except for the final review artifact.
5. Return verdicts for spec compliance, code quality, test coverage, and risk: `pass`, `fail`, or `cannot_verify`.
6. Treat missing evidence as `cannot_verify`, not pass.
7. Write `review.md` as the canonical review artifact. User-facing headings and field labels should be Chinese. It must include front matter plus a professional verdict table for spec compliance, code quality, test coverage, and risk.
8. In Lattice-hosted mode, the helper can generate `review.md` plus `review-summary.json`:

```bash
bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> branch \
  --spec-compliance=pass|fail|cannot_verify \
  --code-quality=pass|fail|cannot_verify \
  --test-coverage=pass|fail|cannot_verify \
  --risk=pass|fail|cannot_verify
```

9. For task-scoped review, replace `branch` with the task id, for example `T1`.
10. Critical or important findings block verification. Minor findings may be recorded as residual risk or follow-up.
11. When receiving external review feedback, evaluate it technically before implementing it:
    - read the full feedback;
    - restate unclear items or ask before changing code;
    - verify the claim against code, spec, plan, tests, and evidence;
    - push back with technical reasoning when feedback conflicts with the project contract;
    - implement one accepted item at a time and test each fix.

## Outputs

- Branch review artifact: `lattice/specs/<spec-id>/review.md` or `prismspec/specs/<spec-id>/review.md`.
- Task review artifact when reviewing a task slice: `.lattice/sdd/<spec-id>/<task-id>/review.md`.
- Machine sidecar for pipeline/eval ingestion: `review-summary.json`.
- Findings with file/line references where possible.
- Disposition for received review feedback: accepted, rejected with reason, cannot_verify, or needs user decision.

## Review Artifact Shape

Use this human-readable structure for `review.md`:

```markdown
# 评审报告：<spec-id>

## 1. 评审结论

| 项 | 结论 |
|---|---|
| 评审范围 | 整体分支 / 任务 `<task-id>` |
| 总体结论 | `pass|fail|cannot_verify` |
| 是否允许进入验证 | <明确结论> |

## 2. 四轴评审

| 维度 | 结论 | 判断重点 |
|---|---|---|
| Spec 符合度 | `pass|fail|cannot_verify` | 是否满足相关 AC，且没有引入未批准范围。 |
| 代码质量 | `pass|fail|cannot_verify` | 是否简单、可维护、符合项目习惯，并具备可回滚性。 |
| 测试覆盖 | `pass|fail|cannot_verify` | 测试是否证明关键成功路径、失败路径和回归风险。 |
| 风险控制 | `pass|fail|cannot_verify` | 权限、数据、状态、并发、迁移等风险是否被约束。 |

## 3. 检查范围

## 4. 发现项

## 5. 已检查证据

## 6. 风险与处置

## 7. 机器侧证据
```

Keep stable machine values such as `pass`, `fail`, `cannot_verify`, file paths, commands, and JSON artifact names unchanged.

## Stop Conditions

- Required review packages, reports, or evidence are missing.
- The diff includes unplanned scope that needs spec or plan updates.
- A finding requires product, architecture, data, security, or permission decisions.
- Review feedback is unclear and could cause the wrong change.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The implementer said tests passed." | Reports are claims; review checks evidence. |
| "Verification will catch it." | Review checks intent, scope, and maintainability before broad commands run. |
| "Cannot verify is close enough." | It is a residual risk and must block or be explicitly accepted. |
| "Minor cleanup can be hidden in review." | Findings need concrete disposition. |
| "The reviewer said it, so implement it." | External review feedback must be verified against this codebase and spec. |
| "One reviewer can cover every risk." | Use extra reviewer personas only for the risk dimensions the task actually touches. |

## Red Flags

- Review prompt tells the reviewer what not to flag.
- review artifact has only prose and no verdict.
- `cannot_verify` is treated as pass.
- Review starts without `spec.md`, `plan.md`, or task evidence.
- Feedback is implemented before it is understood.
- Multiple review items are batched without focused verification.

## Verification

- [ ] Review evidence exists.
- [ ] Verdict axes include spec compliance, code quality, test coverage, and risk.
- [ ] Findings are grounded in diff, evidence, or missing evidence.
- [ ] Blocking findings are fixed before verification or recorded as explicit blockers.
- [ ] Accepted review feedback has focused verification evidence.
- [ ] Rejected review feedback has technical reasoning or a user decision.
