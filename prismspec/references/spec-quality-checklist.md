# Spec Quality Checklist

Use this reference while drafting or reviewing `spec.md`.

## Required Sections

- Intent: the user problem, outcome, and success signal.
- Scope: explicit in/out boundaries.
- Context: only constraints that affect scope, AC, risk, or mode.
- Acceptance Criteria: stable `AC-{n}` identifiers.
- Design Decisions: one-way or reviewer-worthy decisions only.
- Risk Notes: security, permission, money, data, state, concurrency, migration, performance.
- Execution Policy: `plan` or `tdd`, reason, source.
- Verification Plan: commands, gates, manual checks, evidence location.

## Quality Bar

- ACs are testable and observable.
- Design detail is proportional to risk.
- The spec does not copy large knowledge-base content; it references the relevant rule.
- Open questions are limited to decisions that materially affect delivery.
- The spec can survive context compaction: a fresh agent can resume from it.

## Common Failure Patterns

- Vague AC: "works well", "fast enough", "good UX".
- Scope creep hidden in implementation notes.
- Template filling creates sections with no decision value.
- High-risk behavior has no TDD policy.
- Verification plan lists tools, not exact commands or evidence.
