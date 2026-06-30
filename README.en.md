<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>Repo-local AI Coding control plane for teams</strong>
  </p>
  <p align="center">
    <a href="README.md">中文文档</a> ·
    <a href="docs/wiki/">Design Wiki</a> ·
    <a href="docs/adapters/">Agent Adapters</a> ·
    <a href="examples/go-gin-gorm/">Runnable Example</a> ·
    <a href="CHANGELOG.md">Changelog</a> ·
    <a href="SUPPORT.md">Support</a>
  </p>
  <p align="center">
    <a href="https://github.com/zdolphin07-dotcom/lattice/actions/workflows/shellcheck.yml"><img alt="Shellcheck" src="https://github.com/zdolphin07-dotcom/lattice/actions/workflows/shellcheck.yml/badge.svg"></a>
    <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
    <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
    <img alt="Runtime" src="https://img.shields.io/badge/runtime-Bash%203.2%2B-informational.svg">
  </p>
</p>

---

## What Is Lattice

Lattice is a repo-local AI Coding control plane for teams. It embeds PrismSpec: a risk-adaptive Spec Coding workflow that uses the minimum necessary contract to compress ambiguous intent into executable, reviewable, and verifiable engineering constraints, with two implementation modes: `plan` and `tdd`.

PrismSpec turns an AI coding task into `spec.md`, `plan.md`, `review.md`, and `verify.md`. Lattice adds project context, verification gates, evidence/eval, loop, and learn so individual productivity compounds into reusable team engineering capability.

| Capability Layer | Purpose |
|------------------|---------|
| Specification & Planning | Compresses ambiguous intent into executable specs, acceptance criteria, and task plans so AI coding starts with clear boundaries. |
| Context Engineering | Keeps project knowledge, historical lessons, external constraints, and team rules in the repository so individual judgment becomes reusable team context. |
| Delivery Verification | Uses build, lint, test, AC coverage, drift checks, and compliance gates to verify that code, specs, and project constraints stay aligned before delivery. |
| Evidence Intelligence | Aggregates command output, gate results, eval runs, history, and outcomes so completion status, quality risk, and improvement direction are traceable. |

In short: **PrismSpec provides the risk-adaptive Spec Coding contract; Lattice connects that contract to team-level context, verification, and evidence loops.**

## What Problem It Solves

Individual AI Coding can be fast, but team adoption often breaks down when:

- requirements, assumptions, and critical context stay inside chat;
- code changes lack reviewable specs, plans, and review evidence;
- "done" depends on a summary instead of fresh command output;
- project rules, lessons, and verification practices do not become shared assets.

Lattice turns those implicit individual workflows into versioned, reviewable, and verifiable engineering assets inside the repository.

## Why Not Plain AI Coding

| Plain AI Coding | Lattice |
|---|---|
| Requirements and assumptions stay in chat | `spec.md` records Context Basis, ACs, and risk boundaries. |
| The agent declares completion in prose | `verify.md` records commands, exit codes, results, and residual risks. |
| Each task rediscovers the project | `lattice/context/` keeps project maps, rules, pitfalls, and external constraints. |
| Review depends on one-off prompts | `review.md` records read-only verdicts, findings, and risk disposition. |
| Lessons are hard to reuse | Knowledge drafts and promotion turn reusable lessons into project knowledge. |

## What You Get

A Lattice-guided AI Coding task leaves a clear delivery chain in the repo:

| Artifact | Purpose |
|----------|---------|
| `spec.md` | Requirement, Context Basis, scope, ACs, risks, and verification plan. |
| `plan.md` | AC-traced tasks, file boundaries, and verification commands. |
| `review.md` | Read-only review verdicts, findings, and risk dispositions. |
| `verify.md` | Commands, exit codes, results, residual risks, and knowledge candidates. |
| `lattice/state/eval-runs/*.json` | Structured delivery evidence for queries, summaries, CI, and dashboards. |

Example verification summary:

```text
Spec: lattice/specs/create-item-api/spec.md
Review: pass
AC Coverage: 4/4
Drift: none
Command: lattice/kernel/delivery/pipeline.sh --json-out
Result: pass
Evidence: lattice/state/eval-runs/example.json
```

## Reliability / Safety

Lattice is designed as a repository-local engineering control plane, so it keeps these boundaries by default:

- It does not take over the IDE, replace coding agents, or bind teams to a model provider.
- It does not upload code or project knowledge; default assets stay in the current repository.
- It does not overwrite project-owned assets such as `manifest.yaml`, `context/`, and `specs/`.
- It does not replace test systems; it organizes evidence from build, lint, test, drift, and compliance checks.
- Framework code and project assets are separated: `kernel/` and PrismSpec can be upgraded while specs and knowledge remain reviewable.

## Quick Start

### Install Into A Target Project

> Release gate: the remote install command below is suitable for public launch material only after the GitHub repository and raw URL are anonymously accessible. For private repositories or preview work, use local clone installation.

```bash
# Run inside your application repository
cd /path/to/your-project
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# Or clone locally first, then install into the current repository
git clone https://github.com/zdolphin07-dotcom/lattice.git /tmp/lattice
/tmp/lattice/install.sh "$PWD" --init
```

Prerequisites: Bash 3.2+, `yq` 4.x, and `git`.

Installation adds `lattice/`, `prismspec/`, and agent entry files. On upgrade, framework code under `kernel/` and PrismSpec can be refreshed; project-owned assets such as `lattice/manifest.yaml`, `lattice/context/`, and `lattice/specs/` should not be overwritten.

Before a public launch, confirm the remote install URL is anonymously accessible:

```bash
curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh >/tmp/lattice-install.sh
```

If this returns `404`, the repository or raw URL is not public yet. Switch the repository visibility or publish from a public release/tag URL first. For commercial distribution, prefer a tag URL as the default install path and keep `main` as the development install path.

### Run The Example

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

The example demonstrates directory specs, embedded Context Basis in `spec.md`, spec lint, AC coverage, drift checks, eval JSON, and the context knowledge backend.

### 10-Minute Trial Path

```bash
# 1. Run the official example first to confirm local dependencies and evidence output.
bash examples/go-gin-gorm/try-it.sh

# 2. After installing into a non-critical repository, run health checks.
bash lattice/kernel/doctor.sh
bash prismspec/bin/doctor.sh

# 3. Create a small spec and inspect the next route.
bash prismspec/bin/new.sh checkout-flow --template=service --mode=plan
bash prismspec/bin/guide.sh --spec=checkout-flow --json

# 4. After editing spec.md, run the minimal contract check.
bash prismspec/bin/lint.sh lattice/specs/checkout-flow spec
```

## Adoption Path

1. Run `examples/go-gin-gorm/try-it.sh` to confirm local dependencies and evidence output.
2. Install Lattice into one non-critical repository and run `lattice/kernel/doctor.sh`.
3. Use PrismSpec for one small feature or bug fix, producing `spec.md`, `plan.md`, `review.md`, and `verify.md`.
4. Add the Lattice pipeline to CI, or start with `spec-lint`, `ac-coverage`, and `drift-check`.
5. Promote repeated rules, pitfalls, and verification lessons into `lattice/context/knowledge/`.

## Core Workflow

```text
Intent -> Clarify -> Spec -> Build -> Review -> Verify
```

`/prismspec` is the controller, not an extra phase. It routes from existing artifacts:

```bash
bash prismspec/bin/guide.sh --json
```

PrismSpec is not documentation ceremony, and it is not one rigid workflow for every task. It moves important AI coding decisions out of chat and into a resumable contract chain and evidence chain, then selects `plan` or `tdd` execution strength based on risk. The user-facing product blocks are backed by Agent Skills-compatible skill folders, command gates, and evidence:

| Block | Goal | Primary Artifacts |
|---|---|---|
| Clarify | Resolve intent, context basis, assumptions, conflicts, and blocking questions. | `spec.md#Context Basis` |
| Spec | Capture scope, non-goals, ACs, risks, mode, and verification plan. | `spec.md` |
| Build | Plan and implement AC-traced slices with Plan/TDD/debugging evidence. | `plan.md`, task evidence, TDD/debug evidence |
| Review | Independently inspect implementation evidence, diff, and quality risk. | `review.md` |
| Verify | Prove completion with fresh commands or the Lattice pipeline. | `verify.md` |

Machine-side evidence such as task briefs, review packages, `review-summary.json`, eval run JSON, and TDD/debug evidence feeds the pipeline and recovery flow. It is not the primary human-readable artifact contract.

`/capture` is a post-run command. It promotes only durable, reusable, non-secret lessons from `verify.md` or review evidence and is not a required stage in the default delivery chain.

Plan Mode and TDD Mode are two risk tiers inside the same implementation workflow:

| Mode | Use When | Evidence |
|------|----------|----------|
| `plan` | Docs, config, low-risk features, simple refactors, or changes already well covered by tests. | `plan.md`, relevant tests or no-test rationale, verification commands. |
| `tdd` | Bug fixes, permissions, security, money, state machines, concurrency, idempotency, migrations, or regressions. | Red test, green test, AC-to-test trace, and related verification. |

Projects can set the default mode in `lattice/manifest.yaml`. Users can override per spec. Risk discovered later may upgrade `plan -> tdd`; downgrading `tdd -> plan` requires explicit user override.

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
│   │   ├── learn-promotions/
│   │   └── knowledge-reviews/
│   └── specs/
│       └── <spec-id>/
│           ├── spec.md
│           ├── plan.md
│           ├── review.md
│           └── verify.md
└── prismspec/
    ├── skillpack.yaml
    ├── skills/
    ├── templates/
    ├── references/
    └── bin/
```

`kernel/` is upgradeable framework code. `manifest.yaml`, `context/`, and `specs/` are project-owned assets and should not be overwritten during upgrades.

## Components

The capability layers above are the user-facing view; the component model below is the repository implementation view.

| Component | Responsibility | Key Paths |
|-----------|----------------|-----------|
| PrismSpec | Standalone Spec Coding skill pack. | `prismspec/skills/`, `prismspec/bin/`, `prismspec/templates/` |
| Orchestrator | Agent control plane for stage routing, status transitions, task selection, and evidence gating. | `lattice/kernel/orchestrator/` |
| Context | Context map, project knowledge, external references, and optional retrieval backend. | `lattice/context/`, `lattice/kernel/context/` |
| Verification | Reproducible pipeline and gates. | `lattice/kernel/delivery/` |
| Evidence / Eval | Gate output, structured eval runs, Markdown summary/history, central sink, dashboard, queries, and outcomes. | `lattice/state/eval-runs/*.json`, `*.md`, `lattice/state/outcomes/` |

## Support Matrix And Troubleshooting

| Item | Current Status |
|------|----------------|
| Operating systems | macOS / Linux; use WSL first for Windows |
| Shell | Bash 3.2+ |
| Required tools | `git`, `yq` 4.x |
| Validated example | Go / Gin / GORM |
| CI coverage | Bash syntax, ShellCheck, smoke test, Go example, release check |

| Symptom | Action |
|---------|--------|
| Remote install returns `404` | Confirm the GitHub repository and raw install URL are public; use local clone install for private repositories. |
| `yq` is missing | Install Mike Farah `yq` 4.x, for example `brew install yq` on macOS. |
| Shell version behaves unexpectedly | Use the system Bash first; if compatibility issues appear, install a newer Bash and rerun the checks. |
| `doctor.sh` fails | Inspect the missing file/tool, then run `bash prismspec/bin/doctor.sh` to isolate PrismSpec contract issues. |
| Pipeline skips most steps | Check project commands in `lattice/manifest.yaml` and whether an active spec exists. |

See [SUPPORT.md](SUPPORT.md) for support scope and troubleshooting details, and [SECURITY.md](SECURITY.md) for security boundaries and vulnerability reporting.

## Common Commands

| Scenario | Command |
|----------|---------|
| Preview install target before writing files | `bash install.sh /path/to/project --dry-run --init` |
| Print installer version metadata | `bash install.sh --version` |
| Check installation health | `bash lattice/kernel/doctor.sh` |
| Check PrismSpec standalone health | `bash prismspec/bin/doctor.sh` |
| Create an initial spec directory | `bash prismspec/bin/new.sh checkout-flow --template=service --mode=plan` |
| Route the next PrismSpec step | `bash prismspec/bin/guide.sh --json` |
| Lint the PrismSpec skill pack | `bash prismspec/bin/lint.sh prismspec skillpack` |
| Lint spec / plan / evidence | `bash prismspec/bin/lint.sh lattice/specs/<spec-id>` |
| Run the full verification pipeline | `bash lattice/kernel/delivery/pipeline.sh --json-out` |
| Run one gate | `bash lattice/kernel/delivery/pipeline.sh --only=spec-lint` |
| Resolve next task | `bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json` |
| Complete a task with evidence | `bash lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> T1 --json` |
| Check task evidence | `bash lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>` |
| Advance spec status | `bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` |
| Write review verdict | `bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> branch --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass` |
| Create knowledge draft from candidates | `bash lattice/kernel/context/summary-learn-draft.sh <spec-id>` |
| Render eval summary | `bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json` |
| Aggregate eval history | `bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md` |
| Publish central eval sink | `bash lattice/kernel/delivery/eval-sink.sh publish --sink-dir=lattice/state/eval-sink` |
| Render static dashboard | `bash lattice/kernel/delivery/eval-dashboard.sh --sink-dir=lattice/state/eval-sink --out=lattice/state/eval-sink/dashboard.html` |
| Query central sink | `bash lattice/kernel/delivery/eval-query.sh summary --sink-dir=lattice/state/eval-sink` |
| Approve knowledge draft | `bash lattice/kernel/context/knowledge-review.sh approve lattice/context/drafts/<draft>.md --reviewer=<name> --reason=<reason> --conflicts-checked` |
| Promote knowledge draft | `bash lattice/kernel/context/learn-draft.sh promote lattice/context/drafts/<draft>.md --require-review --to=lattice/context/knowledge/pitfalls.md` |

See the [Design Wiki](docs/wiki/) and script `--help` output for the full command contracts.

## Current Status

Lattice currently provides a minimum trusted loop for repo-local AI Coding. It is suitable for preview / pilot adoption in non-critical repositories, new feature workflows, and internal team process validation.

> A commercial stable claim requires additional release gates: anonymous public install, tag/release versioning, reproducible fresh-clone examples, clear security disclosure, and CI coverage for the public install path. Until those gates pass, avoid stable or production-SLA language.

| Capability | Status | Evidence |
|------------|--------|----------|
| Repo-local install/init | Available | `install.sh --init`, `lattice/kernel/doctor.sh`, smoke test. |
| Spec / Plan / Review / Verify artifacts | Available | `new.sh`, `guide.sh --json`, `lint.sh prismspec skillpack`. |
| Delivery pipeline | Available | spec lint, AC coverage, drift check, and compliance gates. |
| Go/Gin/GORM drift parser | Available | `examples/go-gin-gorm/try-it.sh`. |
| Evidence summary/history/outcome | Available | `eval-runs/*.json`, Markdown summary/history, outcome link/report. |
| Dashboard trend analysis | Planned | Static dashboard exists; trend analysis is still evolving. |
| Node / Python drift parser | Planned | Future multi-language expansion. |
| Multi-agent owner / lease model | Planned | Future team collaboration expansion. |

Still evolving:

- dashboard trends and cross-project attribution;
- stronger semantic conflict governance;
- more drift parsers for Node, Python, and other stacks;
- plugin manifest/schema/versioning;
- multi-agent owner / lease model.

## Release Validation

Maintainers should run at least:

```bash
bash tests/release-check.sh
LATTICE_CHECK_REMOTE_INSTALL=1 bash tests/release-check.sh
```

The first command validates the local repository loop. The second validates public raw install, initialization, doctor checks, and PrismSpec routing. See [Release Readiness Review](docs/wiki/release-readiness-review.md) for the full checklist.

## Docs

| Document | Purpose |
|----------|---------|
| [Design Wiki](docs/wiki/) | System design, SDD, Context, Eval, Loop, Roadmap |
| [Workflow Blocks](docs/wiki/workflow-blocks.md) | Clarify / Spec / Build / Review / Verify contracts |
| [PrismSpec README](prismspec/README.md) | Standalone Spec Coding skill pack |
| [Agent adapters](docs/adapters/) | Claude Code, Cursor, Aider, Superpowers, Agent Skills, and generic agents |
| [Runnable example](examples/go-gin-gorm/) | End-to-end Go/Gin/GORM sample |
| [Contributing](CONTRIBUTING.md) | Development, testing, and contribution guide |
| [Support](SUPPORT.md) | Support scope, troubleshooting, and issue context |
| [Security](SECURITY.md) | Security boundaries, vulnerability reporting, and release checks |

## Design Principles

- Spec is a contract, not a long document.
- Current code, tests, schema, and command output remain the source of truth.
- Context starts with a map, then the Agent discovers, selects, and compresses relevant facts.
- Verification must be backed by external commands and evidence.
- PrismSpec can be used independently; Lattice adds project-level context, verification, evidence, loop, and learn.
- Extensions integrate through files, YAML, and command contracts.

## License

MIT
