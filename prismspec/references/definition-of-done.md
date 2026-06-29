# PrismSpec Definition of Done

Use this reference during `verification` and optional `knowledge-capture`.

A PrismSpec run is done only when all applicable evidence exists:

- `spec.md` captures intent, scope, acceptance criteria, execution mode, risks, and verification plan.
- `plan.md` maps implementation tasks to AC identifiers.
- Code changes are scoped to the spec and plan, or scope changes are written back to the spec.
- Behavior changes have tests, or the no-test rationale is explicit and reviewable.
- Verification commands were actually run and recorded.
- TDD mode includes red and green evidence.
- Review findings are resolved, deferred with owner/reason, or marked `cannot_verify`.
- `verify.md` records changed files, command evidence, skipped checks, residual risks, follow-ups, and knowledge candidates.
- Reusable lessons are captured as draft knowledge only when they are durable and non-secret.

## Not Done

- "Looks good" without command output.
- Tests written only for the happy path when AC includes edge cases.
- Completion is claimed while verification failed.
- Spec drift is discovered but not written back.
- Transient review notes are treated as durable team knowledge without review.
