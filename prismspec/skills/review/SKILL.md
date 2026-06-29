---
name: prismspec-review
description: Reviews PrismSpec implementation evidence before verification. Use after planned implementation tasks are complete, when task review packages exist, when /review is invoked, or when /prismspec routes to review before final verification.
---

# PrismSpec Review

## Overview

Review is the independent quality gate between implementation and verification. Treat implementer reports as claims, inspect the diff and evidence, and record a verdict before the run claims verified completion.

This skill aligns with Superpowers 6.x task review discipline: use one skeptical read-only reviewer per task or run, return spec-compliance and code-quality verdicts, and do not tell the reviewer what to ignore. PrismSpec adds AC traceability, Lattice evidence paths, and `review-summary.json`.

## Inputs

- `spec.md`
- `plan.md`
- Task briefs, implementer reports, review packages, TDD evidence, and changed files.
- `prismspec/agents/task-reviewer.md`
- `prismspec/references/review-evidence-checklist.md`
- `prismspec/references/superpowers-alignment.md`

## Workflow

1. Confirm implementation tasks are complete or identify the incomplete task that blocks review.
2. Read the relevant `spec.md`, `plan.md`, task evidence, and review packages.
3. Use `prismspec/agents/task-reviewer.md` as the reviewer contract when task-scoped review is needed.
4. Review as read-only. Do not mutate the working tree, index, HEAD, branch, or evidence files except for the final review summary.
5. Return verdicts for spec compliance, code quality, test coverage, and risk: `pass`, `fail`, or `cannot_verify`.
6. Treat missing evidence as `cannot_verify`, not pass.
7. In Lattice-hosted mode, write structured evidence with:

```bash
bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> branch \
  --spec-compliance=pass|fail|cannot_verify \
  --code-quality=pass|fail|cannot_verify \
  --test-coverage=pass|fail|cannot_verify \
  --risk=pass|fail|cannot_verify
```

8. For task-scoped review, replace `branch` with the task id, for example `T1`.
9. Critical or important findings block verification. Minor findings may be recorded as residual risk or follow-up.

## Outputs

- Branch review summary: `.lattice/sdd/<spec-id>/branch/review-summary.json` or `.prismspec/runs/<spec-id>/branch/review-summary.json`.
- Optional task review summaries: `.lattice/sdd/<spec-id>/<task-id>/review-summary.json`.
- Findings with file/line references where possible.

## Stop Conditions

- Required review packages, reports, or evidence are missing.
- The diff includes unplanned scope that needs spec or plan updates.
- A finding requires product, architecture, data, security, or permission decisions.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The implementer said tests passed." | Reports are claims; review checks evidence. |
| "Verification will catch it." | Review checks intent, scope, and maintainability before broad commands run. |
| "Cannot verify is close enough." | It is a residual risk and must block or be explicitly accepted. |
| "Minor cleanup can be hidden in review." | Findings need concrete disposition. |

## Red Flags

- Review prompt tells the reviewer what not to flag.
- Review summary has only prose and no verdict.
- `cannot_verify` is treated as pass.
- Review starts without `spec.md`, `plan.md`, or task evidence.

## Verification

- [ ] Review evidence exists.
- [ ] Verdict axes include spec compliance, code quality, test coverage, and risk.
- [ ] Findings are grounded in diff, evidence, or missing evidence.
- [ ] Blocking findings are fixed before verification or recorded as explicit blockers.
