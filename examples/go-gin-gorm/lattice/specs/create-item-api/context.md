# Context: create-item-api

## Decision Frame

| Item | Value |
|------|-------|
| Requirement type | feature |
| Execution mode impact | plan |
| Main affected surface | API / schema / tests |
| Verification focus | spec-lint / prismspec-lint / AC coverage / drift check |

## Selected Facts

| Type | Source | Fact | Decision Impact |
|------|--------|------|-----------------|
| user | example scenario | Build a CRUD API for item inventory. | Scope includes create, get, list, and delete item endpoints. |
| code | `internal/handler/item.go` | Routes are registered with Gin-style `POST/GET/DELETE`. | Drift check can compare spec API rows with route registrations. |
| code | `internal/model/item.go` | GORM model uses snake_case column tags. | Spec DDL must match model columns. |
| test | `tests/item_test.go` | Tests are named with `TestAC{n}_...`. | AC coverage can map AC-1 through AC-4 to tests. |
| knowledge | `lattice/context/knowledge/rules.md` | API JSON, Go struct, and DB column naming styles must remain consistent. | Spec records naming and drift verification. |

## Constraints

| Type | Constraint | Source | Impact |
|------|------------|--------|--------|
| compatibility | Keep route paths under `/api/v1/items`. | example contract | Tests and drift check rely on stable routes. |
| data | `id`, `name`, `rarity`, `price`, `created_at`, `updated_at` must match DDL and GORM tags. | code / spec | Drift check must pass. |

## Conflicts / Ambiguities

| Issue | Sources | Required Decision |
|-------|---------|-------------------|
| None | current example | N/A |

## Exclusions

| Source / Topic | Why excluded |
|----------------|--------------|
| Authentication | Not needed for this minimal gate demonstration. |
| Integration DB setup | Out of scope for this smoke example. |

## Context Gaps

| Gap | Blocks planning? | Question / Next action |
|-----|------------------|------------------------|
| None | no | N/A |
