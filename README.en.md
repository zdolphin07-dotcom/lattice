<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>Repo-local AI Coding harness for teams</strong>
  </p>
  <p align="center">
    <a href="README.md">中文文档</a> ·
    <a href="docs/wiki/">Design Wiki</a> ·
    <a href="docs/adapters/">Agent Adapters</a> ·
    <a href="examples/go-gin-gorm/">Runnable Example</a> ·
    <a href="CHANGELOG.md">Changelog</a>
  </p>
</p>

---

## What Is Lattice

Lattice is an AI Coding engineering framework installed into an application repository. It does not replace Claude Code, Cursor, Aider, Superpowers, or other agents. It gives them versioned, reviewable, and verifiable project contracts:

| Capability | Purpose |
|------------|---------|
| PrismSpec | Turns intent into `context.md`, `spec.md`, `plan.md`, `verify.md`, and `summary.md`. |
| Context | Provides an agent-readable context map, project knowledge, external references, and per-spec context basis. |
| Verification | Runs build, lint, test, AC coverage, drift checks, compliance, and other gates before delivery claims. |
| Evidence / Eval | Records command output, gate results, `eval-runs/*.json`, history, and outcomes to support "done" claims. |

In short: **Lattice turns individual AI Coding practice into reusable team engineering assets.**

## Quick Start

### Install Into A Target Project

```bash
# Remote install
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# Or install from a local clone
./install.sh /path/to/your-project --init
```

Prerequisites: Bash 4+, `yq` 4.x, and `git`.

### Run The Example

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

The example demonstrates directory specs, per-spec context, spec lint, AC coverage, drift checks, eval JSON, and the context knowledge backend.

## Installed Layout

```text
your-project/
├── CLAUDE.md
├── lattice/
│   ├── manifest.yaml
│   ├── config/
│   ├── kernel/
│   │   ├── orchestrator/
│   │   ├── context/
│   │   └── delivery/
│   ├── context/
│   │   ├── README.md
│   │   ├── external.md
│   │   ├── knowledge/
│   │   └── drafts/
│   ├── state/
│   │   ├── eval-runs/
│   │   ├── loops/
│   │   ├── outcomes/
│   │   ├── context-runs/
│   │   ├── learn-promotions/
│   │   └── knowledge-reviews/
│   └── specs/
│       └── <spec-id>/
│           ├── context.md
│           ├── spec.md
│           ├── plan.md
│           ├── verify.md
│           └── summary.md
└── prismspec/
    ├── skillpack.yaml
    ├── skills/
    ├── templates/
    ├── references/
    └── bin/
```

`kernel/` is upgradeable framework code. `manifest.yaml`, `context/`, and `specs/` are project-owned assets and should not be overwritten during upgrades.

## Core Workflow

```text
Intent -> Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing
```

`/sdd` is the controller, not an extra phase. It routes from existing artifacts:

```bash
bash prismspec/bin/guide.sh --json
```

| Stage | Goal | Artifacts |
|-------|------|-----------|
| Brainstorming | Capture context basis, scope, ACs, risks, and execution mode. | `context.md`, `spec.md` |
| Planning | Decompose the spec into AC-traced tasks. | `plan.md` |
| Implementation | Execute with Plan Mode or TDD Mode. | code, tests, task evidence |
| Verification | Run independent commands or the Lattice pipeline. | `verify.md` |
| Finishing | Summarize evidence, risk, and knowledge candidates. | `summary.md` |

Plan Mode and TDD Mode are implementation policies inside the same workflow:

| Mode | Use When | Evidence |
|------|----------|----------|
| `plan` | Docs, config, low-risk features, simple refactors, or changes already well covered by tests. | `plan.md`, relevant tests or no-test rationale, verification commands. |
| `tdd` | Bug fixes, permissions, security, state machines, concurrency, idempotency, migrations, or regressions. | Red test, green test, AC-to-test trace, and related verification. |

Projects can set the default mode in `lattice/manifest.yaml`. Users can override per spec. Risk discovered later may upgrade `plan -> tdd`; downgrading `tdd -> plan` requires explicit user override.

## Components

| Component | Responsibility | Key Paths |
|-----------|----------------|-----------|
| PrismSpec | Standalone Spec Coding skill pack. | `prismspec/skills/`, `prismspec/bin/`, `prismspec/templates/` |
| Orchestrator | Agent control plane for stage routing, status transitions, task selection, and evidence gating. | `lattice/kernel/orchestrator/` |
| Context | Context map, project knowledge, external references, optional retrieval backend, and per-spec context-run evidence. | `lattice/context/`, `lattice/kernel/context/` |
| Verification | Reproducible pipeline and gates. | `lattice/kernel/delivery/` |
| Evidence / Eval | Gate output, structured eval runs, Markdown summary/history, central sink, dashboard, queries, and outcomes. | `lattice/state/eval-runs/*.json`, `*.md`, `lattice/state/outcomes/` |

## Common Commands

| Scenario | Command |
|----------|---------|
| Check installation health | `bash lattice/kernel/doctor.sh` |
| Route the next SDD step | `bash prismspec/bin/guide.sh --json` |
| Lint spec / plan / evidence | `bash prismspec/bin/lint.sh lattice/specs/<spec-id>` |
| Run the full verification pipeline | `bash lattice/kernel/delivery/pipeline.sh --json-out` |
| Run one gate | `bash lattice/kernel/delivery/pipeline.sh --only=spec-lint` |
| Resolve next task | `bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json` |
| Complete a task with evidence | `bash lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> T1 --json` |
| Check task evidence | `bash lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>` |
| Advance spec status | `bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` |
| Draft closeout summary | `bash lattice/kernel/orchestrator/sdd/summary-draft.sh <spec-id>` |
| Create learn draft from summary | `bash lattice/kernel/context/summary-learn-draft.sh <spec-id>` |
| Render eval summary | `bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json` |
| Aggregate eval history | `bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md` |
| Publish central eval sink | `bash lattice/kernel/delivery/eval-sink.sh publish --sink-dir=lattice/state/eval-sink` |
| Render static dashboard | `bash lattice/kernel/delivery/eval-dashboard.sh --sink-dir=lattice/state/eval-sink --out=lattice/state/eval-sink/dashboard.html` |
| Query central sink | `bash lattice/kernel/delivery/eval-query.sh summary --sink-dir=lattice/state/eval-sink` |
| Approve learn draft | `bash lattice/kernel/context/knowledge-review.sh approve lattice/context/drafts/<draft>.md --reviewer=<name> --reason=<reason> --conflicts-checked` |
| Promote learn draft | `bash lattice/kernel/context/learn-draft.sh promote lattice/context/drafts/<draft>.md --require-review --to=lattice/context/knowledge/pitfalls.md` |

See the [Design Wiki](docs/wiki/) and script `--help` output for the full command contracts.

## Current Status

Lattice currently provides a minimum trusted loop for repo-local AI Coding:

| Area | Available Capabilities |
|------|------------------------|
| Install and init | `install.sh`, `init.sh`, `doctor.sh`, smoke tests, GitHub Actions eval artifact template. |
| PrismSpec | Canonical skills, `guide.sh`, `lint.sh`, multiple templates, Plan/TDD policy, standalone and Lattice-hosted modes. |
| Spec lifecycle | `context.md`, `spec.md`, `plan.md`, `verify.md`, `summary.md`, status transitions, transition events/history. |
| Implementation evidence | `task-next.sh`, `task-complete.sh`, task brief, review package, review summary, TDD evidence, task evidence lint. |
| Verification / Evidence | Pipeline, spec lint, AC coverage, drift check, compliance, spec lock, structured eval JSON, Markdown summary/history. |
| Loop and outcome | Loop state, failure category, escalation draft, outcome link/report, central eval sink, static dashboard, eval query, PR comment dry run. |
| Context / Learn | Context map, external map, knowledge backend, context-lint, context-run, knowledge metadata/governance lint, knowledge review, learn draft promote/discard, summary-to-learn-draft. |
| Examples and adapters | Runnable Go/Gin/GORM example, Claude Code / Cursor / Aider / Superpowers adapter docs. |

Still evolving:

- dashboard trends and cross-project attribution;
- stronger semantic conflict governance;
- more drift parsers for Node, Python, and other stacks;
- plugin manifest/schema/versioning;
- multi-agent owner / lease model.

## Docs

| Document | Purpose |
|----------|---------|
| [Design Wiki](docs/wiki/) | System design, SDD, Context, Eval, Loop, Roadmap |
| [PrismSpec README](prismspec/README.md) | Standalone Spec Coding skill pack |
| [Agent adapters](docs/adapters/) | Claude Code, Cursor, Aider, Superpowers, and generic agents |
| [Runnable example](examples/go-gin-gorm/) | End-to-end Go/Gin/GORM sample |
| [Contributing](CONTRIBUTING.md) | Development, testing, and contribution guide |

## Design Principles

- Spec is a contract, not a long document.
- Current code, tests, schema, and command output remain the source of truth.
- Context starts with a map, then the Agent discovers, selects, and compresses relevant facts.
- Verification must be backed by external commands and evidence.
- PrismSpec can be used independently; Lattice adds project-level context, verification, evidence, loop, and learn.
- Extensions integrate through files, YAML, and command contracts.

## License

MIT
