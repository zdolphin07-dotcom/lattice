# Lattice Skills — PrismSpec Host Interface

Skills are discoverable, invokable capability declarations for the AI agent.

Lattice embeds **PrismSpec** as its default progressive spec-coding workflow, then adds project manifest, knowledge loading, delivery gates, AC coverage, drift checks, and compliance audit.

PrismSpec can be used standalone from `prismspec/skills/`. The files in `lattice/skills/` remain as Lattice-hosted compatibility skills.

## Built-in Skills

| Skill | File | Trigger | Dependency Layer |
|-------|------|---------|-----------------|
| init | `init.md` | `/init`, initialize Lattice | Orchestrator + Delivery |
| sdd | `sdd.md` | `/sdd`, PrismSpec guided workflow | Orchestrator |
| brainstorm | `brainstorm.md` | `/brainstorm`, clarify, draft spec | Orchestrator + Knowledge |
| plan | `plan.md` | `/plan`, write plan | Orchestrator |
| implement | `implement.md` | `/implement`, execute plan, tdd | Orchestrator + Delivery |
| verify | `verify.md` | `/verify`, verify, run pipeline | Delivery |
| finish | `finish.md` | `/finish`, close out | Orchestrator + Knowledge |
| learn | `learn.md` | `/learn`, capture, remember | Knowledge |

Other capabilities (knowledge loading, spec templates, AC tracing, drift detection) are injected via `lattice/kernel/orchestrator/rules.md` and enforced by delivery gates.

## PrismSpec Relationship

| Layer | Responsibility |
|-------|----------------|
| `prismspec/skills/` | Standalone AI coding workflow: brainstorm, plan, implement, verify, finish |
| `lattice/skills/` | Lattice-hosted compatibility entry points |
| `lattice/kernel/` | Enhanced runtime: manifest, knowledge, gates, evidence helpers |

## Evidence Helpers

SDD helpers create file-backed context instead of pasting large briefs or diffs into the agent prompt:

| Helper | Purpose | Output |
|--------|---------|--------|
| `lattice/kernel/orchestrator/sdd/task-brief.sh` | Build a compact task brief from spec + plan | `.lattice/sdd/<spec-id>/<task-id>/brief.md` |
| `lattice/kernel/orchestrator/sdd/review-package.sh` | Build a read-only diff review package | `.lattice/sdd/<spec-id>/<task-id>/review-package.md` |

These files are transient execution evidence. They should be ignored by git and summarized in `/finish`, not promoted to long-term knowledge by default.

## Relationship with `.claude/commands/`

`.claude/commands/` provides Claude Code slash command entry points that reference `lattice/skills/*.md`.
