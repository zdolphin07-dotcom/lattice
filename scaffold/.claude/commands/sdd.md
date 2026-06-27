Run the guided Lattice SDD workflow.

Execute `prismspec/skills/sdd.md` when present; otherwise execute `lattice/skills/sdd.md`.

## Core behavior

1. Detect PrismSpec host mode: Lattice-hosted if `lattice/manifest.yaml` exists, standalone otherwise.
2. Resolve the spec id, execution mode, and next stage.
3. Resume from existing artifacts when possible.
4. Delegate to the stage skills in order:
   `brainstorm -> plan -> implement -> verify -> finish`.
5. After each stage, recompute artifact state and continue when the next action is clear.
6. Stop only on completion, retry exhaustion, or a material human decision.
7. Do not create extra stages, skip verification, or claim completion without evidence.

User input: $ARGUMENTS
