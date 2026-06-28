# Project Context Map

## Project Snapshot

- Project purpose: small Go/Gin/GORM API example for Lattice gates.
- Core domain objects: item.
- Main modules: HTTP handler, GORM model, AC-traced tests.
- High-risk flows: naming drift between API JSON, Go structs, and database columns.

## Where To Find Context

| Need | Read |
|------|------|
| Architecture and module boundaries | `knowledge/architecture.md` |
| Rules and contracts | `knowledge/rules.md` |
| Historical pitfalls | `knowledge/pitfalls.md` |
| Naming conventions | `knowledge/glossary.md` |
| External references | `external.md` |

## Loading Policy

- Start from the sample spec and current code.
- Use project knowledge only when it affects AC coverage, drift checks, or naming decisions.
- Do not copy full files into specs; cite the relevant source and decision impact.
