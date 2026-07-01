# Agent Skills Adapter — PrismSpec Packaging Guide

PrismSpec uses Agent Skills as a packaging and quality standard. It does not treat Agent Skills as the SDD workflow itself.

## What Maps To Agent Skills

| Agent Skills Concept | PrismSpec Implementation |
|----------------------|--------------------------|
| Skill folder | `prismspec/skills/prismspec-*/` |
| Required instruction file | `SKILL.md` |
| Trigger metadata | YAML frontmatter `name` and `description` |
| UI metadata | `agents/openai.yaml` |
| Progressive disclosure | concise `SKILL.md` plus shared `prismspec/references/` |
| Skill evals | `evals/evals.json` with should-trigger, should-not-trigger, and assertions |
| Deterministic helpers | `prismspec/bin/` and Lattice kernel scripts |

## Product Blocks

Lattice presents the workflow as four primary product blocks while keeping Agent Skills-compatible folders underneath:

| Product Block | Primary Skill Folder | Durable Contract |
|---|---|---|
| Clarify | `prismspec-grilling/`, `prismspec-specification/` | `status: clarifying` `spec.md` and Context Basis: selected facts, assumptions, conflicts, open questions |
| Spec | `prismspec-specification/` | approved `spec.md` with ACs, risks, mode, verification plan |
| Build | `prismspec-planning/`, `prismspec-implementation/`, `prismspec-debugging/` | `plan.md`, task evidence, TDD/debug evidence |
| Quality Gate | `prismspec-review/`, `prismspec-verification/` | read-only `review.md`, command-backed `verify.md`, eval run JSON |

The mapping is declared in `prismspec/skillpack.yaml` under `product_blocks`. Hosts should read that machine-readable block list instead of inferring UI sections from directory names.

Each skill folder name matches its frontmatter `name`, for example:

```text
prismspec/skills/prismspec-planning/SKILL.md
name: prismspec-planning
```

## What Does Not Map

Agent Skills does not define an AI coding lifecycle. PrismSpec presents this user-facing lifecycle:

```text
specification -> planning -> implementation(plan|tdd) -> quality gate
```

Internally, Quality Gate still routes through `review -> verification` so `review.md` and `verify.md` remain separate evidence. Superpowers supplies the proven workflow discipline for brainstorming, planning, TDD, debugging, review, and verification. PrismSpec adds durable artifacts, AC traceability, host-aware routing, and evidence gates.

## Commercial Readiness Checklist

Before publishing PrismSpec skills:

- `skillpack.yaml` must expose `product_blocks` for Clarify, Spec, Build, and Quality Gate.
- Each skill directory name must match `SKILL.md` frontmatter `name`.
- Each description must say when to use the skill and avoid overlapping adjacent stages.
- Each skill must include `agents/openai.yaml`.
- Each skill must include `evals/evals.json`.
- `SKILL.md` must stay under 500 lines and link to references instead of embedding long background.
- `bash prismspec/bin/eval-skills.sh --all` must pass so trigger fixtures and adjacent-stage collisions are checked.
- `bash prismspec/bin/lint.sh prismspec skillpack` must pass.
- `bash tests/smoke-test.sh` must pass before release.

## Recommended Consumer Behavior

Agent hosts should:

1. Read `prismspec/skillpack.yaml` first.
2. Use `/prismspec` or `prismspec/bin/guide.sh --json` to route the current artifact state.
3. Read only the returned `SKILL.md`.
4. Load referenced files only when the selected skill asks for them.
5. Treat `verify.md` and command output as the source of truth for completion claims.
