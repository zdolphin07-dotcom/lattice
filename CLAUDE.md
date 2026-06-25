# Lattice — Team-Native AI Coding Framework

## Project Identity

Lattice is a **project-level AI Coding framework** that installs into target projects, helping teams turn individual AI coding practices into reusable, verifiable engineering workflows.

- **This repo is the Lattice source repo**, not a project that uses Lattice
- Users install via `install.sh`, which copies `scaffold/` into their project
- `scaffold/` is the installation artifact template — the core deliverable

## Repository Structure

```
.
├── README.md              # User-facing product docs
├── SKILL.md               # Agent skill definition (triggers, init flow)
├── install.sh             # Remote/local install entry point
├── init.sh                # Project initialization (detect language → generate manifest)
├── scaffold/              # ★ Installation template — copied to target projects
│   ├── CLAUDE.ssd.md      #   CLAUDE.md append content for target projects
│   ├── .claude/commands/  #   Slash commands (/init /verify /learn)
│   └── lattice/
│       ├── kernel/        #   Framework engine (upgradable as a unit)
│       │   ├── _lib.sh                    # Shared CLI foundation
│       │   ├── orchestrator/              # Control plane: rules.md + flow.yaml + templates/
│       │   ├── knowledge/                 # Knowledge retrieval: loader.sh + sync.sh
│       │   └── delivery/                  # Delivery verification: pipeline.sh + gates/
│       ├── knowledge/     #   Knowledge base template (index.md + synonyms.txt)
│       ├── skills/        #   Agent capability declarations (init/verify/learn)
│       └── manifest.template.yaml  # Manifest generation template
├── docs/                  # Design docs and adapter guides
│   └── adapters/          # Engine-specific integration guides
├── examples/              # Example manifests for different language stacks
└── CHANGELOG.md           # Release history
```

## Development Rules

### What to Modify

- **Features** → modify scripts under `scaffold/lattice/kernel/`
- **Documentation** → modify `README.md` (user docs) or `SKILL.md` (agent interface)
- **Install flow** → modify `install.sh` or `init.sh`
- **Agent behavior rules** → modify `scaffold/lattice/kernel/orchestrator/rules.md`

### Path Conventions

All kernel scripts use `source` paths based on the target project layout, not this repo:

```bash
# scaffold/lattice/kernel/delivery/gates/*.sh:
source "$(dirname "$0")/../../_lib.sh"     # → kernel/_lib.sh

# scaffold/lattice/kernel/delivery/pipeline.sh:
source "$(dirname "$0")/../_lib.sh"        # → kernel/_lib.sh
```

### Testing

Verification approach:

```bash
# 1. Syntax check all scripts
bash -n init.sh install.sh $(find scaffold -name '*.sh')

# 2. Smoke test in a sandbox project
shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh $(find scaffold -name '*.sh')
bash tests/smoke-test.sh

# 3. Integration test in a sandbox project
mkdir /tmp/test-project && cd /tmp/test-project && git init
bash /path/to/lattice/install.sh --init
bash lattice/kernel/delivery/pipeline.sh
```

### Version Management

- `scaffold/lattice/kernel/VERSION` contains the version number
- Users upgrade via `install.sh --upgrade`
- `lattice/manifest.yaml` and `lattice/knowledge/` are user assets — never overwritten on upgrade

## Three-Layer Architecture

| Layer | Directory | Purpose |
|-------|-----------|---------|
| Orchestrator | `kernel/orchestrator/` | Inject agent behavior rules via rules.md @import |
| Knowledge | `kernel/knowledge/` | loader.sh retrieves project knowledge by keyword |
| Delivery | `kernel/delivery/` | pipeline.sh runs manifest-driven gate pipeline |

## Key Files

- `scaffold/lattice/kernel/delivery/pipeline.sh` — Core delivery pipeline, reads manifest step-by-step
- `scaffold/lattice/kernel/delivery/gates/` — 5 gates: spec-lint / ac-coverage / drift-check / compliance / spec-lock
- `scaffold/lattice/kernel/knowledge/loader.sh` — Knowledge retrieval engine with fuzzy match
- `scaffold/lattice/kernel/orchestrator/rules.md` — Agent behavior rules with generic phase names
- `scaffold/lattice/manifest.template.yaml` — Manifest generation template for init.sh
