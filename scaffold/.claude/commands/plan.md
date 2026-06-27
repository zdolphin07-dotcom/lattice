Run Lattice Planning for an existing spec.

Execute `prismspec/skills/plan.md` when present; otherwise execute `lattice/skills/plan.md`.

## Core behavior

1. Read `lattice/specs/<spec-id>/spec.md`.
2. Create `lattice/specs/<spec-id>/plan.md`.
3. Add `Global Constraints` that every task must carry.
4. Ensure every task references Scope or ACs and declares interfaces.
5. If `execution_mode: tdd`, include test-first tasks.

User input: $ARGUMENTS
