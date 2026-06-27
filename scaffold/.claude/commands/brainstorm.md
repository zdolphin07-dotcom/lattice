Run Lattice Brainstorming and produce a persistent spec.

Execute `prismspec/skills/brainstorm.md` when present; otherwise execute `lattice/skills/brainstorm.md`.

## Core behavior

1. Detect PrismSpec host mode: Lattice-hosted if `lattice/manifest.yaml` exists, standalone otherwise.
2. Inspect relevant code, tests, schemas, and contracts.
3. Run targeted knowledge retrieval with `lattice/kernel/knowledge/loader.sh`.
4. Clarify only material uncertainties.
5. Write `lattice/specs/<spec-id>/spec.md`.

User input: $ARGUMENTS
