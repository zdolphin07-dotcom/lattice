---
id: {spec-id}
status: drafted
execution_mode: {auto|plan|tdd}
owner: {owner}
created_at: {timestamp}
updated_at: {timestamp}
---

# Spec: {Title}

## Intent

{One sentence: what problem this change solves and why it matters.}

## Scope

### In

- {In-scope behavior / module / user impact}

### Out

- {Explicitly excluded behavior / module / follow-up}

## Context

| Source | Constraint | Why it matters |
|--------|------------|----------------|
| code / docs / knowledge | | |

## Acceptance Criteria

| # | When | Then | Verification |
|---|------|------|--------------|
| AC-1 | | | |

## Design Decisions

| # | Decision | Rationale | Reversible? |
|---|----------|-----------|-------------|
| D-1 | | | yes / no |

## Risk Notes

| Risk | Mitigation | Verification |
|------|------------|--------------|
| | | |

## Execution Policy

- Mode: `{plan|tdd}`
- Reason: {why this mode was selected}
- Source: model-selected | project-default | user-override

Use `plan` for low-risk changes where a reviewed plan plus normal tests is enough. Use `tdd` when behavior must be pinned by red tests first: bug fixes, core flows, money/security/permission/state-machine logic, concurrency, idempotency, migrations, or regression-prone changes.

## Verification Plan

| Gate / Test | Required? | Notes |
|-------------|-----------|-------|
| build | yes | |
| lint / type-check | yes | |
| unit test | yes | |
| AC coverage | tdd: yes / plan: conditional | |
| integration / smoke | conditional | |
