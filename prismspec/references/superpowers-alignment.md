# Superpowers Alignment

PrismSpec is not a fork of Superpowers. When Superpowers already has a mature workflow discipline, PrismSpec should align to it and keep only the parts that are specific to PrismSpec or Lattice artifacts.

## Rule

Use Superpowers as the default behavioral reference for workflow discipline:

- `brainstorming` for intent discovery, alternatives, design approval, and written spec review.
- `writing-plans` for small reviewable tasks, global constraints, per-task interfaces, and plan pre-flight.
- `subagent-driven-development` or `executing-plans` for task execution discipline, file-backed handoffs, task review, and progress tracking.
- `test-driven-development` for red/green/refactor discipline.
- `verification-before-completion` for evidence before completion claims.
- `requesting-code-review` and `receiving-code-review` for review handling.
- `finishing-a-development-branch` only for explicit branch/worktree closeout. It is not a required PrismSpec main stage.

PrismSpec owns the artifact contract:

- `context.md`
- `spec.md`
- `plan.md`
- task evidence under `.prismspec/runs/` or `.lattice/sdd/`
- `review-summary.json`
- `verify.md`
- optional legacy `summary.md`
- Lattice context, verification, evidence, eval, and learn gates

Do not create a PrismSpec-only behavior when a Superpowers skill already covers the same workflow discipline. Add PrismSpec rules only when they are needed for durable artifacts, Lattice gates, context discovery, execution mode, AC traceability, or verification evidence.

## Mapping

| PrismSpec Stage | Superpowers Reference | PrismSpec Addition |
|---|---|---|
| `specification` | `brainstorming` | `context.md`, stable `AC-{n}`, execution mode, context discovery, Lattice context gates |
| `planning` | `writing-plans` | AC-traced `plan.md`, Lattice plan lint, task evidence paths |
| `implementation` | `subagent-driven-development`, `executing-plans`, `test-driven-development` | task status scripts, TDD evidence JSON, Lattice task evidence lint |
| `review` | Superpowers SDD task reviewer discipline, code review skills | `review-summary.json`, `pass/fail/cannot_verify`, AC/evidence grounding |
| `verification` | `verification-before-completion` | command-backed `verify.md`, Lattice delivery pipeline, AC coverage and drift gates |
| optional `knowledge-capture` | no required Superpowers main stage | durable, reusable, non-secret lessons from `verify.md` or review evidence |

## Brainstorming Compatibility

For non-trivial work, PrismSpec brainstorming should follow the Superpowers shape:

1. Explore project context before proposing design.
2. Ask one material question at a time.
3. Decompose oversized requests before writing a single spec.
4. Present 2-3 approaches with tradeoffs and a recommendation when design choices matter.
5. Present the selected design in readable sections.
6. Get approval before planning or implementation.
7. Write the approved design into PrismSpec artifacts instead of `docs/superpowers/specs/`.
8. Self-review the written spec for placeholders, contradictions, ambiguity, scope, and testability.
9. Ask for review when approval was not already explicit.

Tiny, low-risk changes may use a short design, but they still need a durable `spec.md` or an explicit documented skip reason.

## Precedence

If Superpowers and PrismSpec disagree:

1. Safety and user instructions win.
2. PrismSpec artifact locations and Lattice gates win for PrismSpec/Lattice projects.
3. Superpowers workflow discipline wins for human interaction, planning discipline, TDD discipline, review discipline, and completion discipline.
4. If the conflict changes product behavior, scope, execution mode, or risk, stop and ask.

## Anti-Wheel-Reinvention Check

Before adding or changing a PrismSpec skill rule, ask:

- Does a Superpowers skill already solve this workflow behavior?
- Is the PrismSpec change only about artifact shape, AC traceability, context discovery, or Lattice verification?
- Can this be expressed as a mapping to Superpowers plus a PrismSpec artifact override?

If the answer is yes, reference the Superpowers discipline instead of inventing a parallel one.
