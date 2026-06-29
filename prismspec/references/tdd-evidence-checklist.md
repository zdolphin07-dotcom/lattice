# TDD Evidence Checklist

Use this reference for `execution_mode: tdd`.

## Discipline

TDD means the failing test is written and observed before production code.

- RED: write one minimal behavior test.
- Verify RED: confirm it fails for the expected reason.
- GREEN: write the minimum production change.
- Verify GREEN: confirm the focused test and relevant regression checks pass.
- REFACTOR: clean up only after green, then keep the tests green.

If production code was written before the failing test, do not keep it as the final implementation. Restart the task from a failing test.

## Required Evidence

For each TDD task, record:

- AC ids covered.
- Red test file and test name.
- Red command.
- Red failure output summary.
- Green command.
- Green pass output summary.
- Refactor notes, if any.
- Relevant regression command after green.

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
- Test asserts mocks or implementation details instead of user-visible behavior or contract.
- Test output has warnings/noise that are ignored in the evidence.
- The test was weakened after RED instead of fixing production code.
