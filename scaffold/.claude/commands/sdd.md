Run the guided Lattice SDD workflow.

Execute `prismspec/skills/sdd/SKILL.md` when present; otherwise execute `prismspec/skills/sdd.md` or `lattice/skills/sdd.md`.

## Core behavior

1. Run `bash prismspec/bin/guide.sh $ARGUMENTS --json` when present to resolve host mode, spec id, execution mode, and next stage.
2. If the guide script is absent, detect PrismSpec host mode manually: Lattice-hosted if `lattice/manifest.yaml` exists, standalone otherwise.
3. Resume from existing artifacts when possible.
4. Read the `skill` path returned by the guide, then delegate to stage skills in order:
   `brainstorm -> plan -> implement -> verify -> finish`.
5. After each stage, recompute artifact state and continue when the next action is clear.
6. Stop only on completion, retry exhaustion, or a material human decision.
7. Do not create extra stages, skip verification, or claim completion without evidence.

User input: $ARGUMENTS
