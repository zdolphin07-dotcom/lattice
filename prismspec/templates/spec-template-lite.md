---
id: {spec-id}
title: {title}
status: drafted
template: lite
execution_mode: plan
mode_source: model-selected | project-default | user-override
approval: explicit | inferred | skipped-with-reason
owner: {owner}
created_at: {timestamp}
updated_at: {timestamp}
---

# Lite Spec: {Title}

## Intent

{一句话说明要改什么，为什么要改。}

## Scope

### In

- {本次做什么}

### Out

- {本次不做什么}

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | | | |

## Execution Policy

- Mode: `plan`
- Reason: {低风险 / 文档 / 配置 / 简单重构 / 现有测试覆盖充分}
- Source: model-selected | project-default | user-override

## Risk Notes

- {低风险任务也要说明为什么风险可控；没有则写 N/A}

## Verification

| Check | Required? | Notes |
|-------|-----------|-------|
| build | yes / no | |
| lint / type-check | yes / no | |
| test | yes / no | |
| manual review | yes / no | |

## Approval

- Status: explicit / inferred / skipped-with-reason
- Source: user message / project default / reason
- Notes: {为什么可以进入 plan；没有则写 N/A}

## Notes

- {必要的实现约束或 reviewer 提醒；没有则写 N/A}
