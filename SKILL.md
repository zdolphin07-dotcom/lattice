---
name: lattice
version: 1.0.0
description: >
  Lattice — team-native AI Coding framework for reusable, verifiable delivery.
  Provides Context / Spec / Harness / Eval-oriented project scaffolding;
  init with /init, verify with /verify, capture knowledge with /learn.
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
│   └── scaffold/
├── lattice/
│   ├── manifest.yaml
│   ├── kernel/
│   │   ├── _lib.sh
│   │   ├── orchestrator/
│   │   ├── knowledge/
│   │   └── delivery/
│   ├── knowledge/
│   ├── requirements/
│   ├── specs/
│   ├── plans/
│   ├── state/
│   └── skills/
└── CLAUDE.md
```

## Triggers

| Trigger | Action |
|---------|--------|
| `lattice init` / initialize framework | Run Init flow |
| `verify` / run pipeline | Execute `lattice/kernel/delivery/pipeline.sh` |
| `learn` / capture / remember | Execute `lattice/skills/learn.md` flow |

## Init Flow

1. Locate scaffold (prefer `.lattice/framework/scaffold/`)
2. Detect language / framework / ORM / database / CI
3. Copy scaffold to project
4. Generate `lattice/manifest.yaml`
5. Inject `@import lattice/kernel/orchestrator/rules.md` into `CLAUDE.md`
6. Run `bash lattice/kernel/delivery/bootstrap.sh check`

## Key Constraints

- User assets never overwritten: `lattice/manifest.yaml`, `lattice/knowledge/`, `lattice/specs/`
- `manifest.yaml` is the single project configuration entry point
- Spec template: `lattice/kernel/orchestrator/templates/spec-template.md`
- Verification entry point: `lattice/kernel/delivery/pipeline.sh`
- Explicit skills: `/init`, `/verify`, `/learn` only
