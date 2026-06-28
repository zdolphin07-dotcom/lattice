---
name: lattice
version: 1.0.0
description: >
  Lattice — team-native AI Coding framework for reusable, verifiable delivery.
  Provides Context / Spec / Harness / Evidence-oriented project harness;
  guide or resume the SDD workflow, brainstorm persistent specs, plan execution, implement with plan/tdd policies,
  generate task briefs and review packages, verify with gates, finish with evidence,
  and capture knowledge with /learn.
  Triggers: "initialize framework", "initialize harness", "lattice init", "configure dev environment".
  Triggers: "verify", "run pipeline" → execute lattice/kernel/delivery/pipeline.sh.
---

# Lattice Skill

> Project-level AI Coding framework: bridging the context gap and verification gap for teams.

## Installation

Install as a project-level dependency:

```bash
git clone <repo-url> .lattice/framework && rm -rf .lattice/framework/.git
```

Typical structure after installation:

```text
my-project/
├── .lattice/framework/
│   ├── README.md
│   ├── SKILL.md
│   ├── init.sh
│   └── harness-template/
├── lattice/
│   ├── manifest.yaml
│   ├── kernel/
│   │   ├── _lib.sh
│   │   ├── orchestrator/
│   │   ├── context/
│   │   └── delivery/
│   ├── context/
│   ├── specs/
│   ├── state/
│   └── skills/
└── CLAUDE.md
```

## Triggers

| Trigger | Action |
|---------|--------|
| `lattice init` / initialize framework | Run Init flow |
| `sdd` / guided workflow | Execute `prismspec/skills/sdd/SKILL.md`; route or resume the full SDD workflow from artifacts |
| `brainstorm` / draft spec | Run Brainstorming flow and write `lattice/specs/<id>/context.md` + `spec.md` |
| `plan` / write plan | Run Planning flow and write `lattice/specs/<id>/plan.md` |
| `implement` / tdd | Execute `plan` or `tdd` policy from the spec |
| `verify` / run pipeline | Execute `lattice/kernel/delivery/pipeline.sh` |
| `finish` / close out | Write delivery summary and extract durable knowledge |
| `learn` / capture / remember | Execute `prismspec/skills/learn/SKILL.md` flow |

## Init Flow

1. Locate harness-template (prefer `.lattice/framework/harness-template/`)
2. Detect language / framework / ORM / database / CI
3. Copy harness-template to project
4. Generate `lattice/manifest.yaml`
5. Inject `@import lattice/kernel/orchestrator/rules.md` into `CLAUDE.md`
6. Run `bash lattice/kernel/delivery/bootstrap.sh check`

## Key Constraints

- User assets never overwritten: `lattice/manifest.yaml`, `lattice/context/knowledge/`, `lattice/specs/`
- `manifest.yaml` is the single project configuration entry point
- Spec templates: `prismspec/templates/`
- Context template: `prismspec/templates/context-template.md`
- Guided SDD entry point: `prismspec/skills/sdd/SKILL.md`
- SDD evidence helpers: `lattice/kernel/orchestrator/sdd/task-brief.sh`, `lattice/kernel/orchestrator/sdd/review-package.sh`
- Verification entry point: `lattice/kernel/delivery/pipeline.sh`
- Explicit skills: `/init`, `/sdd`, `/brainstorm`, `/plan`, `/implement`, `/verify`, `/finish`, `/learn`
