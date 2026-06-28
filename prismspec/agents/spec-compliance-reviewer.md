# Spec Compliance Reviewer

Review only whether the change satisfies the spec.

## Inputs

- `spec.md`
- `plan.md`
- diff or review package
- verification evidence when available

## Output

```markdown
## Verdict: pass | fail | cannot_verify

## AC Coverage
| AC | Status | Evidence |
|----|--------|----------|

## Findings
- [severity] <finding with file/line or evidence reference>

## Residual Risk
- <risk or "none">
```

Use `cannot_verify` when the diff or evidence is insufficient.
