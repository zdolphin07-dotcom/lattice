Run the full verification pipeline and record evidence.

Execute `prismspec/skills/verify/SKILL.md`.

## Core behavior

1. Execute `lattice/kernel/delivery/pipeline.sh --json-out` (manifest.yaml driven)
2. If harness not found, fallback to language defaults
3. Record exact commands, exit codes, output summaries, skipped checks, residual risks, and next actions in `verify.md`
4. Summarize: PASS / FAIL

## Important

- Actual command output required, no natural language assertions
