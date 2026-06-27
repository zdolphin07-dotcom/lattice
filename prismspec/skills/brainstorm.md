# Skill: brainstorm — PrismSpec Spec Drafting

**Triggers**: `/brainstorm`, brainstorm, clarify requirement, draft spec

## Capability

Clarify a requirement just enough to write a persistent `spec.md`.

## Workflow

1. Detect host paths:
   - Lattice: `lattice/specs/<spec-id>/spec.md`
   - Standalone: `prismspec/specs/<spec-id>/spec.md`
2. Select the smallest fitting template:
   - `spec-template-lite.md`: low-risk Plan Mode work, docs, config, simple refactors.
   - `spec-template-service.md`: backend API, data model, state transition, permission, idempotency, compensation.
   - `spec-template-frontend.md`: UI flow, component behavior, user-facing interaction, accessibility, visual states.
   - `spec-template-tdd.md`: bug fix, regression, core flow, security, permission, money, concurrency, idempotency.
   - `spec-template.md`: default when no specialized template clearly fits.
3. Inspect only relevant code, tests, schemas, interfaces, docs, and known project rules.
4. Ask only material questions that affect scope, safety, acceptance criteria, or execution mode.
5. Select execution mode:
   - `plan` for low-risk work.
   - `tdd` for high-risk behavior or regression-prone work.
6. Write `spec.md` from the selected template.
7. Keep the spec compact: intent, scope, context, ACs, design decisions, risks, execution policy, verification plan.

## Template Rule

Do not force every change into the default template. A good spec follows the reviewer and the risk shape:

- AC is mandatory in every template.
- Design is thin for low-risk work.
- API/schema/state details are explicit for service work.
- User journey and edge states are explicit for frontend work.
- Red tests and invariants are explicit for TDD work.

## Exit Criteria

- `spec.md` exists.
- Acceptance criteria use stable `AC-{n}` identifiers.
- Execution policy records mode, reason, and source.
