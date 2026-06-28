---
id: create-item-api
title: Create Item API
status: drafted
template: service
execution_mode: plan
mode_source: model-selected
owner: lattice-example
created_at: 2026-06-28T00:00:00Z
updated_at: 2026-06-28T00:00:00Z
---

# Spec: Create Item API

## Intent

Build a small CRUD API for item inventory and demonstrate how Lattice validates spec structure, AC-to-test traceability, route drift, schema drift, and context usage.

## Scope

### In

- Create an item.
- Get an item by ID.
- List items.
- Delete an item.
- Verify route, DDL, and AC traceability through Lattice gates.

### Out

- Authentication and authorization.
- Real database integration setup.
- Pagination, soft delete, and audit events.

## Context

| Source | Constraint / Fact | Impact |
|--------|-------------------|--------|
| `context.md` | Current example already has Gin routes, GORM model tags, and AC-named tests. | Use Plan Mode and verify with existing gates. |
| `lattice/context/knowledge/rules.md` | JSON, Go, and DB naming conventions must remain consistent. | Include naming rules and DDL/model drift checks. |

## Acceptance Criteria

| # | Given | When | Then | Verification |
|---|-------|------|------|--------------|
| AC-1 | API server is running | POST `/api/v1/items` with a valid body | Returns 201 with the created item | `TestAC1_CreateItem` |
| AC-2 | An item exists | GET `/api/v1/items/:id` | Returns 200 with the item | `TestAC2_GetItem` |
| AC-3 | No item exists for the requested ID | GET `/api/v1/items/:id` | Returns 404 | `TestAC3_GetItemNotFound` |
| AC-4 | An item exists | DELETE `/api/v1/items/:id` | Returns 204 and the item is no longer retrievable | `TestAC4_DeleteItem` |

## Contract Surface

### API Design

| API | Method | Path | Description | Auth |
|-----|--------|------|-------------|------|
| API-1 | POST | /api/v1/items | Create item | No |
| API-2 | GET | /api/v1/items/:id | Get item by ID | No |
| API-3 | GET | /api/v1/items | List items | No |
| API-4 | DELETE | /api/v1/items/:id | Delete item | No |

### Data Model

```sql
CREATE TABLE `items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `rarity` int NOT NULL DEFAULT 1,
  `price` int NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rarity` (`rarity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Design Decisions

| # | Decision | Rationale | Alternatives | Reversible? |
|---|----------|-----------|--------------|-------------|
| D-1 | Use auto-increment integer IDs. | Keeps the example small and easy to verify. | UUID | yes |
| D-2 | Use hard delete. | Demonstrates DELETE behavior without adding lifecycle complexity. | Soft delete | yes |

## Risks And Invariants

| Risk / Invariant | Mitigation | Verification |
|------------------|------------|--------------|
| Route/spec drift | Keep API rows and Gin registrations aligned. | `drift-check.sh` |
| DDL/model drift | Keep SQL columns and GORM tags aligned. | `drift-check.sh` |
| AC/test drift | Test names must include stable AC ids. | `ac-coverage.sh` |

## Execution Policy

- Mode: `plan`
- Reason: This is a low-risk example with existing AC-named tests and no high-risk state transitions.
- Source: `model-selected`
- Escalation: `plan -> tdd` allowed if a regression or high-risk invariant is introduced; `tdd -> plan` requires explicit user override.

## Verification Plan

| Gate / Test | Required? | Evidence |
|-------------|-----------|----------|
| spec-lint | yes | Directory layout, context basis, required sections |
| prismspec-lint | yes | PrismSpec spec contract |
| AC coverage | yes | AC-1 through AC-4 map to tests |
| drift check | yes | Route and DDL alignment |
| unit test | yes | `go test ./... -short -count=1` |

## Open Questions

- [x] None for the example.
