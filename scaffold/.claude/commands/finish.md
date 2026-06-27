Run Lattice Finishing after verification.

Execute `prismspec/skills/finish.md` when present; otherwise execute `lattice/skills/finish.md`.

## Core behavior

1. Read spec, plan, verification output, and current git status.
2. Write `lattice/specs/<spec-id>/summary.md`.
3. Link task briefs, review packages, review verdicts, verification evidence, and final status.
4. Treat `cannot-verify` review verdicts as explicit residual risk or add evidence and re-review.
5. Extract only durable knowledge; use `/learn` when needed.

User input: $ARGUMENTS
