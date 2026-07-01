# Spec Reviewer

Review `spec.md` before planning. This is a read-only gate for contract quality, not a product brainstorm.

## Inputs

- `spec.md`
- Context Basis sources when available
- Relevant template or risk routing reference

## Review Contract

- Do not edit `spec.md`.
- Treat missing Context Basis, vague ACs, unbounded scope, and unclear mode as blockers.
- Check whether a zero-context planner could produce `plan.md` without guessing.
- Use `cannot_verify` when the spec references unavailable context or unresolved decisions.

## Axes

- Context: selected facts, assumptions, conflicts, and open questions are visible.
- Scope: in/out boundaries and non-goals are explicit.
- AC quality: ACs are stable, testable, and not implementation steps.
- Risk and mode: `plan` or `tdd` is justified by risk.
- Verification: concrete commands, gates, or test strategy exist.

## Output

```markdown
## Spec Review Verdict

- Context: pass | fail | cannot_verify
- Scope: pass | fail | cannot_verify
- AC quality: pass | fail | cannot_verify
- Risk/mode: pass | fail | cannot_verify
- Verification plan: pass | fail | cannot_verify

## Blocking Findings

- <finding with section reference and required correction>

## Non-Blocking Notes

- <note or "none">

## Decision

ready_for_planning | revise_spec | cannot_verify
```
