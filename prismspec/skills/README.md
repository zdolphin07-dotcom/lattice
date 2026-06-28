# PrismSpec Skills

These skills are self-contained workflow instructions for AI coding agents.

Use `sdd/SKILL.md` as the canonical entry point. The legacy `*.md` files remain as compatibility wrappers.

```text
sdd -> brainstorm -> plan -> implement -> verify -> finish
```

Host detection:

- If `lattice/manifest.yaml` exists, use Lattice paths and gates.
- Otherwise use `prismspec/specs/` for durable artifacts and `.prismspec/runs/` for transient evidence.

Flow guide:

- Run `bash prismspec/bin/guide.sh` before manual routing when the script exists.
- Use `--json` when another script or agent wrapper needs structured output.
- Run `bash prismspec/bin/lint.sh <spec-dir>` before closeout when artifacts exist.

Canonical skills:

| Skill | Canonical file | Purpose |
|-------|----------------|---------|
| sdd | `sdd/SKILL.md` | Lifecycle controller and resume router |
| brainstorm | `brainstorm/SKILL.md` | Requirement clarification and `spec.md` authoring |
| plan | `plan/SKILL.md` | AC-traced task planning |
| implement | `implement/SKILL.md` | Plan/TDD execution with evidence |
| verify | `verify/SKILL.md` | Command-backed verification and `verify.md` |
| finish | `finish/SKILL.md` | `summary.md`, residual risks, learn candidates |
| learn | `learn/SKILL.md` | Durable knowledge capture |

Templates:

- `prismspec/templates/spec-template.md` — default professional contract.
- `prismspec/templates/spec-template-lite.md` — lightweight AC-first Plan Mode.
- `prismspec/templates/spec-template-service.md` — backend/API/data/state work.
- `prismspec/templates/spec-template-frontend.md` — frontend UX and component work.
- `prismspec/templates/spec-template-tdd.md` — bug fixes and high-risk TDD work.

References:

- `prismspec/references/mode-selection.md`
- `prismspec/references/spec-quality-checklist.md`
- `prismspec/references/tdd-evidence-checklist.md`
- `prismspec/references/review-evidence-checklist.md`
- `prismspec/references/definition-of-done.md`
