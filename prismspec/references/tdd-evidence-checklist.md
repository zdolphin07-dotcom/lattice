# TDD Evidence Checklist

Use this reference for `execution_mode: tdd`.

## Required Evidence

For each TDD task, record:

- AC ids covered.
- Red test file and test name.
- Red command.
- Red failure output summary.
- Green command.
- Green pass output summary.
- Refactor notes, if any.

Recommended path:

```text
.prismspec/runs/<spec-id>/<task-id>/tdd-evidence.md
.lattice/sdd/<spec-id>/<task-id>/tdd-evidence.md
.lattice/sdd/<spec-id>/<task-id>/tdd-evidence.json
```

Lattice-hosted projects should also write structured evidence:

```bash
bash lattice/kernel/orchestrator/sdd/tdd-evidence.sh <spec-id> <task-id> \
  --ac=AC-1 \
  --test=TestAC1_CreateItem \
  --red-command="go test ./... -run TestAC1_CreateItem" \
  --red-exit=1 \
  --green-command="go test ./... -run TestAC1_CreateItem" \
  --green-exit=0
```

The pipeline collects this file into `process_evidence.tdd_evidence[]`.

## Minimal Format

```markdown
# TDD Evidence: <task-id>

## Coverage
- AC-1: <test name>

## Red
- Command: `<exact command>`
- Expected failure: <why this failure proves the behavior is missing>

## Green
- Command: `<exact command>`
- Result: pass

## Refactor
- <changes made after green, or "none">
```

## Red Flags

- Red test was not run.
- Red test failed for setup/import reasons unrelated to the intended behavior.
- Implementation existed before the failing test for a bug fix.
- Green evidence only runs the focused test and skips relevant regression checks.
