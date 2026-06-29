---
name: lattice
description: >
  Lattice — repo-local AI Coding harness for teams.
  Use when Codex needs to initialize Lattice in a target project, route PrismSpec workflow work,
  load project context, run verification gates, record command-backed evidence, or capture learnings.
  Triggers include "lattice init", "initialize harness", "prismspec", "sdd", "PrismSpec", "verify",
  "run pipeline", "eval", "context", and "learn".
---

# Lattice Skill

Lattice installs a project-level harness into a target repository. It does not replace the coding agent; it gives the agent stable project contracts for context, spec, verification, and evidence.

## Operating Rule

First determine whether you are in the Lattice source repository or an installed target project:

- Source repository: contains `install.sh`, `harness-template/`, and `prismspec/`.
- Installed target project: contains `lattice/manifest.yaml` and `lattice/kernel/`.

Use current files and command output as the source of truth. Do not route from conversation memory when `guide.sh`, `manifest.yaml`, or spec artifacts exist.

## Entry Points

| User Intent | Action |
|-------------|--------|
| initialize Lattice from source checkout | Run `./install.sh <target-project> --init` |
| initialize Lattice from remote installer | Run the documented `install.sh --init` command after confirming the target project path |
| inspect installed harness | Run `bash lattice/kernel/doctor.sh` |
| PrismSpec / guided workflow | Run `bash prismspec/bin/guide.sh --json`, then follow the routed PrismSpec stage skill |
| spec / draft specification | Write `lattice/specs/<spec-id>/context.md` and `spec.md` |
| plan | Write AC-traced `plan.md` |
| implement / tdd | Execute `plan` or `tdd` according to `spec.md` |
| review | Write or inspect `review-summary.json` evidence |
| verify / run pipeline | Run `bash lattice/kernel/delivery/pipeline.sh --json-out` when available |
| capture | Follow `prismspec/skills/knowledge-capture/SKILL.md` for durable knowledge capture |

## Contracts

- PrismSpec is the only SDD workflow source: `prismspec/skills/*/SKILL.md`.
- Default spec layout: `lattice/specs/<spec-id>/context.md` + `spec.md`.
- Templates live under `prismspec/templates/`.
- Do not recreate SDD workflow logic under `lattice/skills/`; Lattice hosts PrismSpec and adds repo-local harness contracts.
- User-owned assets are not overwritten on upgrade: `lattice/manifest.yaml`, `lattice/context/`, `lattice/specs/`.
- Context is agentic discovery first: read `lattice/context/README.md`, then select only facts that affect scope, AC, risk, interface, compatibility, or verification.
- Verification runs commands; Evidence / Eval records command-backed results, history, and outcomes.
- Learn entries must be durable, sourced, non-secret, and reviewable.

## Verification

```bash
bash prismspec/bin/guide.sh --json
bash prismspec/bin/lint.sh lattice/specs/<spec-id>
bash lattice/kernel/delivery/pipeline.sh --json-out
```

For source-repository maintenance, run the repository checks from `AGENTS.md` before reporting completion.
