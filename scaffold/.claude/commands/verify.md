Run the full verification pipeline and paste evidence.

Execute `prismspec/skills/verify.md` when present; otherwise execute `lattice/skills/verify.md` verification flow.

## Core behavior

1. Execute `lattice/kernel/delivery/pipeline.sh` (manifest.yaml driven)
2. If harness not found, fallback to language defaults
3. Paste actual terminal output for each step
4. Summarize: ✅ PASS / ❌ FAIL

## Important

- Actual terminal output required, no natural language assertions
