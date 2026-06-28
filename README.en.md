<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>Repo-local AI Coding harness for spec, context, verification, and evidence</strong>
  </p>
  <p align="center">
    <a href="README.md">中文文档</a> ·
    <a href="docs/wiki/">Design Wiki</a> ·
    <a href="docs/adapters/">Agent Adapters</a> ·
    <a href="examples/go-gin-gorm/">Example</a> ·
    <a href="CHANGELOG.md">Changelog</a>
  </p>
</p>

---

## What Is Lattice

Lattice is a repo-local AI Coding framework. It does not replace Claude Code, Cursor, Aider, or other agents. Instead, it gives them versioned project contracts:

- **PrismSpec** turns requirements into `context.md`, `spec.md`, `plan.md`, `verify.md`, and `summary.md`.
- **Context** loads project rules, decisions, code facts, and pitfalls before spec drafting.
- **Delivery Harness** runs build, lint, test, AC coverage, drift checks, and other gates before delivery claims.
- **Evidence** turns "the agent says it is done" into command-backed proof and structured `eval-runs/*.json`.

In short: **Lattice turns individual AI Coding practice into reusable team engineering assets.**

## Quick Start

```bash
# Remote install into a target project
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# Local install if you cloned this repo
./install.sh /path/to/your-project --init
```

Try the example:

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

## Workflow

Lattice uses PrismSpec as its progressive SDD workflow:

```text
Intent -> Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing
```

`/sdd` is the controller, not an extra phase. It routes from existing artifacts:

```bash
bash prismspec/bin/guide.sh --json
```

| Stage | Purpose | Artifact |
|-------|---------|----------|
| Brainstorming | Intent, scope, context basis, ACs, risks, execution mode | `context.md`, `spec.md` |
| Planning | AC-traced implementation tasks | `plan.md` |
| Implementation | Plan Mode or TDD Mode execution | code, tests, task evidence |
| Verification | Independent command-backed proof | `verify.md` |
| Finishing | Evidence, residual risks, knowledge candidates | `summary.md` |

## Components

| Component | Role | Key Paths |
|-----------|------|-----------|
| PrismSpec | Standalone spec-coding skill pack | `prismspec/skillpack.yaml`, `prismspec/skills/*/SKILL.md`, `prismspec/bin/`, `prismspec/templates/` |
| Orchestrator | Agent rules and phase definitions | `lattice/kernel/orchestrator/` |
| Context | Agent-readable context map, project knowledge assets, external context entry, and optional retrieval backend | `lattice/context/`, `lattice/kernel/context/` |
| Delivery | Independent verification pipeline and gates | `lattice/kernel/delivery/` |
| Evidence | Gate output, structured Eval runs, Markdown summaries, and history reports | `lattice/state/eval-runs/*.json`, `*.md`, AC coverage, drift diagnostics |

## Common Commands

```bash
bash lattice/kernel/delivery/pipeline.sh
bash lattice/kernel/delivery/pipeline.sh --json-out
bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> <task-id> --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass
bash lattice/kernel/orchestrator/sdd/tdd-evidence.sh <spec-id> <task-id> --ac=AC-1 --test=TestAC1 --red-command="..." --red-exit=1 --green-command="..." --green-exit=0
bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json
bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md
bash lattice/kernel/delivery/pr-comment.sh lattice/state/eval-runs/<run-id>.md --dry-run
bash lattice/kernel/delivery/pipeline.sh --only=spec-lint
bash lattice/kernel/doctor.sh
cat .github/workflows/lattice-eval.yml
bash prismspec/bin/guide.sh --json
bash prismspec/bin/lint.sh lattice/specs/<spec-id>
cat lattice/context/README.md
bash lattice/kernel/context/backends/knowledge.sh "payment idempotency"
```

## Current Status

Implemented:

- install/init/upgrade and smoke tests;
- standalone PrismSpec skill pack manifest and Lattice-hosted mode;
- doctor, `pipeline --json-out` structured eval runs, loop state JSON, Markdown summaries/history reports, AC/drift/compliance gate JSON, review/TDD process evidence, and GitHub Actions eval artifacts/Step Summary/best-effort PR comments;
- spec lint, AC coverage, drift check, compliance, spec lock;
- context map, knowledge backend, sync, and basic learn convention;
- Go/Gin/GORM example and adapter docs.

Planned:

- escalation learn draft automation;
- stronger context/knowledge metadata and stale/conflict checks;
- more drift parsers for Node/Python and other stacks;
- plugin manifest/schema/versioning;
- multi-agent state and lease model.

## Docs

| Document | Purpose |
|----------|---------|
| [Design Wiki](docs/wiki/) | System design, SDD, context, eval, loop, roadmap |
| [PrismSpec README](prismspec/README.md) | Standalone spec-coding skill pack |
| [Agent adapters](docs/adapters/) | Claude Code, Cursor, Aider, Superpowers, and generic agents |
| [Example](examples/go-gin-gorm/) | Runnable sample project |
| [Contributing](CONTRIBUTING.md) | Development and contribution guide |

## License

MIT
