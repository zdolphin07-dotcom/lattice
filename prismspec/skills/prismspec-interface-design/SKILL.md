---
name: prismspec-interface-design
description: Defines API, schema, module, state, and boundary contracts before PrismSpec planning or implementation. Use when a task changes public interfaces, request or response shapes, database schemas, events, error codes, state machines, module boundaries, or compatibility guarantees.
---

# PrismSpec Interface Design

## Overview

Stabilize the contract before implementation. Interface design keeps `spec.md` focused on externally visible behavior and prevents plans from encoding accidental implementation details.

Use this support skill for API, schema, event, state, and module boundary changes.

## Inputs

- User requirement and current `spec.md`.
- Existing routes, schemas, models, events, errors, tests, and clients.
- Compatibility requirements and migration constraints.

## Workflow

1. Identify the boundary: public API, internal module, schema, event, state transition, or error contract.
2. List consumers and compatibility constraints.
3. Define inputs, outputs, errors, state changes, and invariants.
4. Separate behavior contract from implementation choices.
5. Add migration, fallback, rollback, or versioning notes when compatibility can break.
6. Map each interface rule to ACs and verification.
7. Record the contract in `spec.md` and the concrete touched files/contracts in `plan.md`.

## Outputs

- Contract section in `spec.md`: inputs, outputs, errors, state, invariants, compatibility.
- ACs that verify the interface behavior.
- Planning notes for touched files, schemas, tests, or migration paths.

## Stop Conditions

- A consumer, compatibility rule, or rollback path is unknown.
- The requested interface conflicts with existing code, tests, schema, or API conventions.
- State transitions or error semantics are ambiguous.
- The contract would force a broad migration outside the approved scope.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The implementation will reveal the interface." | Accidental interfaces create drift and compatibility breaks. |
| "This is internal only." | Internal contracts still have consumers and Hyrum-style dependencies. |
| "We can add fields later." | Request, response, schema, and event changes need compatibility rules now. |
| "Tests are enough." | Tests prove examples; the spec must state the contract being protected. |
| "Error handling is obvious." | Error codes and failure semantics are part of the interface. |

## Red Flags

- Plan lists files before spec states the contract.
- API or schema changes have no compatibility or migration note.
- ACs only cover happy path.
- State machine changes do not list invalid transitions.
- Error codes, nullability, or idempotency are left to implementation.

## Verification

- [ ] Boundary and consumers are identified.
- [ ] Inputs, outputs, errors, state changes, and invariants are explicit.
- [ ] Compatibility, migration, or rollback is addressed or marked N/A.
- [ ] Interface rules map to ACs and verification.
- [ ] Implementation choices are not over-specified in the contract.
