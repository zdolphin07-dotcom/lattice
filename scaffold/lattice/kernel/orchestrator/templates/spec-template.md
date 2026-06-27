---
id: {spec-id}
title: {title}
status: drafted
template: default
execution_mode: {auto|plan|tdd}
mode_source: model-selected | project-default | user-override
owner: {owner}
created_at: {timestamp}
updated_at: {timestamp}
---

# Spec: {Title}

## 1. Intent

{用 1-3 句话说明：这个变更要解决什么问题，为什么现在要做，成功后用户/系统会发生什么变化。}

## 2. Scope

### In

- {本次明确要交付的行为、模块、接口或用户可见结果}

### Out

- {本次明确不做的内容，避免 AI 或 reviewer 自动扩张范围}

## 3. Context

> 只放影响 Scope / AC / Risk / Execution Policy 的上下文，不复制完整代码或知识库。

| Source | Constraint / Fact | Impact |
|--------|-------------------|--------|
| user request | | |
| code / tests | | |
| docs / knowledge | | |

## 4. Acceptance Criteria

> AC 是 spec 的核心。每条 AC 都应该能被测试、人工验收或 gate 证明。

| # | Given | When | Then | Verification |
|---|-------|------|------|--------------|
| AC-1 | | | | unit / integration / e2e / manual / gate |

## 5. Contract Surface

> 只列本次会改变或依赖的外部契约。没有则写 N/A。

| Contract | Change | Compatibility |
|----------|--------|---------------|
| API / route | | |
| Schema / data | | |
| UI / component | | |
| Config / env | | |
| Events / jobs | | |

## 6. Design Decisions

> 只记录需要人审、不可轻易回滚、或会影响后续演进的决策。

| # | Decision | Rationale | Alternatives | Reversible? |
|---|----------|-----------|--------------|-------------|
| D-1 | | | | yes / no |

## 7. Risks And Invariants

> 高风险项必须明确不变量。低风险任务可以只写 N/A。

| Risk / Invariant | Mitigation | Verification |
|------------------|------------|--------------|
| idempotency / permission / data consistency / concurrency / regression | | |

## 8. Execution Policy

- Mode: `{plan|tdd}`
- Reason: {为什么选这个模式}
- Source: `model-selected | project-default | user-override`
- Escalation: `plan -> tdd` allowed if new risk is discovered; `tdd -> plan` requires explicit user override.

## 9. Verification Plan

| Gate / Test | Required? | Evidence |
|-------------|-----------|----------|
| build | yes / no | |
| lint / type-check | yes / no | |
| unit test | yes / no | |
| AC coverage | yes / no | |
| integration / e2e | conditional | |
| drift / contract check | conditional | |

## 10. Open Questions

> 只保留会阻塞 Scope、AC、Risk 或 Execution Policy 的问题。

- [ ] {question}
