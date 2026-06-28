Run Lattice Brainstorming and produce a persistent spec.

Execute `prismspec/skills/brainstorm/SKILL.md`.

## Core behavior

1. Detect PrismSpec host mode: Lattice-hosted if `lattice/manifest.yaml` exists, standalone otherwise.
2. Inspect relevant code, tests, schemas, and contracts.
3. Read `lattice/context/README.md` when present, then load only context that changes scope, AC, risk, interface, compatibility, or verification.
4. Optionally query curated project knowledge with `lattice/kernel/context/backends/knowledge.sh <keywords>`.
5. Clarify only material uncertainties.
6. Write `lattice/specs/<spec-id>/context.md` and `spec.md`.

User input: $ARGUMENTS
