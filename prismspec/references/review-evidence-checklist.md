# Review Evidence Checklist

Use this reference during implementation review and final verification.

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

## Canonical Artifact

PrismSpec review should write a human-readable artifact to:

```text
lattice/specs/<spec-id>/review.md
```

`review.md` should include verdicts for all axes, concrete findings, disposition, and evidence checked. Task-scoped reviews use `.lattice/sdd/<spec-id>/<task-id>/review.md` when reviewing a task slice. Lattice-hosted projects generate `review-summary.json` as a machine sidecar for pipeline/eval collection.

Recommended helper:

```bash
bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> <task-id> \
  --spec-compliance=pass \
  --code-quality=pass \
  --test-coverage=pass \
  --risk=pass \
  --evidence="go test ./..."
```

The helper writes `review.md` and `review-summary.json`. The pipeline collects the JSON sidecar into `process_evidence.review_summaries[]`.

## JSON Sidecar Shape

```json
{
  "schema_version": "lattice.review-summary.v1",
  "kind": "review-summary",
  "verdict": "pass",
  "axes": {
    "spec_compliance": "pass",
    "code_quality": "pass",
    "test_coverage": "pass",
    "risk": "pass"
  },
  "findings": []
}
```

## Red Flags

- Reviewer repeats the implementation summary instead of checking ACs.
- Findings have no file, command, or evidence reference.
- Security or data-risk changes are reviewed only by the implementing agent.
- `cannot_verify` is treated as pass.
