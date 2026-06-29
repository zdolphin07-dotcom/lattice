Run the guided PrismSpec AI coding workflow.

Execute `prismspec/skills/workflow/SKILL.md`.

## Core behavior

1. Run `bash prismspec/bin/guide.sh $ARGUMENTS --json` to resolve host mode, spec id, execution mode, and next stage.
2. Resume from existing artifacts when possible.
3. Read the `skill` path returned by the guide, then delegate to stage skills in order:
   `specification -> planning -> implementation -> review -> verification`.
4. After each stage, recompute artifact state and continue when the next action is clear.
5. Stop only on verified completion, retry exhaustion, or a material human decision.
6. Follow mature Superpowers discipline where it exists; keep PrismSpec artifact paths and Lattice gates.
7. Do not create extra stages, skip review/verification, or claim completion without `verify.md` evidence.

User input: $ARGUMENTS
