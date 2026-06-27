# PrismSpec Skills

These skills are self-contained instructions for an AI coding agent.

Use `sdd.md` as the main entry point. The stage skills are intentionally small and artifact-driven:

```text
sdd -> brainstorm -> plan -> implement -> verify -> finish
```

Host detection:

- If `lattice/manifest.yaml` exists, use Lattice paths and gates.
- Otherwise use `prismspec/specs/` for durable artifacts and `.prismspec/runs/` for transient evidence.

Templates:

- `prismspec/templates/spec-template.md` — default professional contract.
- `prismspec/templates/spec-template-lite.md` — lightweight AC-first Plan Mode.
- `prismspec/templates/spec-template-service.md` — backend/API/data/state work.
- `prismspec/templates/spec-template-frontend.md` — frontend UX and component work.
- `prismspec/templates/spec-template-tdd.md` — bug fixes and high-risk TDD work.
