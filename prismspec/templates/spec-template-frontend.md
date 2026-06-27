---
id: {spec-id}
title: {title}
status: drafted
template: frontend
execution_mode: {auto|plan|tdd}
mode_source: model-selected | project-default | user-override
owner: {owner}
created_at: {timestamp}
updated_at: {timestamp}
---

# Frontend Spec: {Title}

## 1. User Intent

{用户要完成什么任务？当前体验哪里阻塞？}

## 2. Scope

### In

- {页面、组件、状态、交互、文案、可视化或数据展示变化}

### Out

- {本次不做的后端、埋点、支付、账号、复杂设计系统改造等}

## 3. User Journey

| Step | User Action | System Response | State |
|------|-------------|-----------------|-------|
| 1 | | | default / loading / success / empty / error |

## 4. UI Contract

| Area / Component | Behavior | Data Needed | Responsive / A11y Notes |
|------------------|----------|-------------|--------------------------|
| | | | |

## 5. Acceptance Criteria

| # | Given | When | Then | Verification |
|---|-------|------|------|--------------|
| AC-1 | | | | component / e2e / visual / manual |

## 6. Edge States

| State | Expected Behavior | Verification |
|-------|-------------------|--------------|
| loading | | |
| empty | | |
| partial data | | |
| error | | |
| mobile / narrow viewport | | |

## 7. Design Decisions

| # | Decision | Rationale | Alternatives | Reversible? |
|---|----------|-----------|--------------|-------------|
| D-1 | | | | yes / no |

## 8. Execution Policy

- Mode: `{plan|tdd}`
- Reason: {低风险 UI / 核心转化链路 / 回归风险 / 状态复杂度}
- Source: model-selected | project-default | user-override

## 9. Verification Plan

| Check | Required? | Evidence |
|-------|-----------|----------|
| type-check | yes | |
| unit / component test | conditional | |
| e2e / browser check | conditional | |
| screenshot / visual review | conditional | |
| accessibility basics | conditional | |
