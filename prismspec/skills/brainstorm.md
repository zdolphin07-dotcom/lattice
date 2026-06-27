# Skill: brainstorm — PrismSpec Spec Drafting

**Triggers**: `/brainstorm`, brainstorm, clarify requirement, draft spec

## Capability

Clarify a requirement just enough to write a persistent `spec.md`.

## Workflow

1. Detect host paths:
   - Lattice: `lattice/specs/<spec-id>/spec.md`
   - Standalone: `prismspec/specs/<spec-id>/spec.md`
2. Inspect only relevant code, tests, schemas, interfaces, docs, and known project rules.
3. Ask only material questions that affect scope, safety, acceptance criteria, or execution mode.
4. Select execution mode:
   - `plan` for low-risk work.
   - `tdd` for high-risk behavior or regression-prone work.
5. Write `spec.md` from the available template.
6. Keep the spec compact: intent, scope, context, ACs, design decisions, risks, execution policy, verification plan.

## Exit Criteria

- `spec.md` exists.
- Acceptance criteria use stable `AC-{n}` identifiers.
- Execution policy records mode, reason, and source.
