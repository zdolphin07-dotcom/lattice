# Project Context Map

This file is the first context entry for AI agents. Read it before drafting a spec.

## Project Snapshot

- Project purpose: _fill in after init_
- Core domain objects: _fill in after init_
- Main modules: _fill in after init_
- High-risk flows: _fill in after init_

## Where To Find Context

| Need | Read |
|------|------|
| Architecture and module boundaries | `knowledge/architecture.md` |
| Business rules and interface contracts | `knowledge/rules.md` |
| Historical pitfalls and incident lessons | `knowledge/pitfalls.md` |
| Domain terms and naming conventions | `knowledge/glossary.md` |
| Architecture decisions | `knowledge/decisions/` |
| External docs, central knowledge, third-party contracts | `external.md` |
| Historical specs | `../specs/` |

## Loading Policy

- Start with the current user request and current code, tests, schema, and contracts.
- Use project knowledge to understand durable rules and historical decisions.
- Use external or central knowledge as reference only; it must not override current project facts.
- Do not copy large documents into `spec.md`; summarize only facts that affect scope, ACs, risk, interface, compatibility, or verification.

## Conflict Policy

1. Current user instruction.
2. Current code, tests, schema, and interface contracts.
3. Project knowledge under `lattice/context/knowledge/`.
4. Historical specs under `lattice/specs/`.
5. External or central knowledge from `external.md`.
6. Model prior knowledge.

Record meaningful conflicts in `lattice/specs/<spec-id>/context.md`.
