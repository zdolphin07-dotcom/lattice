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

## Relationship with PrismSpec Canonical Skills

PrismSpec now ships canonical skill folders such as `prismspec/skills/sdd/SKILL.md`. Prefer those files when present. The flat Markdown files in `lattice/skills/` and `prismspec/skills/*.md` remain compatibility entry points for older installs and simpler agents.

Canonical PrismSpec skills include frontmatter, workflow, inputs/outputs, stop conditions, common rationalizations, red flags, and verification criteria. Lattice adds manifest routing, knowledge, delivery gates, and evidence helpers around the same workflow.

## Relationship with `.claude/commands/`

`.claude/commands/` provides Claude Code slash command entry points that prefer `prismspec/skills/*/SKILL.md`, then fall back to compatibility files.
