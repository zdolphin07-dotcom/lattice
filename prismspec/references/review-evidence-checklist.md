# Review Evidence Checklist

Use this reference during implementation review and closeout.

## Review Axes

| Axis | Question |
|------|----------|
| Spec compliance | Does the diff satisfy every touched AC without adding unapproved scope? |
| Code quality | Is the solution simple, maintainable, idiomatic, and rollback-friendly? |
| Test coverage | Do tests prove the important happy path, edge path, and regression risk? |
| Risk | Are security, permission, data, state, concurrency, and migration risks handled? |

## Verdicts

Use exactly one verdict:

- `pass`: enough evidence supports the claim.
- `fail`: a concrete blocker or regression exists.
- `cannot_verify`: evidence is insufficient; do not guess.

## Suggested Summary JSON

```json
{
  "verdict": "pass",
  "spec_compliance": "pass",
  "code_quality": "pass",
  "test_coverage": "pass",
  "findings": []
}
```

## Red Flags

- Reviewer repeats the implementation summary instead of checking ACs.
- Findings have no file, command, or evidence reference.
- Security or data-risk changes are reviewed only by the implementing agent.
- `cannot_verify` is treated as pass.
