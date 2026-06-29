# PrismSpec

> 中文版: [README.md](README.md)

PrismSpec is a standalone, progressive Spec Coding skill pack. It turns an AI coding task into a resumable, reviewable, and verifiable artifact chain:

```text
specification -> planning -> implementation(plan|tdd) -> review -> verification
```

`/prismspec` is the controller, not an extra phase. It reads current artifacts and routes to the next stage skill. `/sdd` remains as a compatibility alias.

## Positioning

PrismSpec can run standalone or in Lattice-hosted mode.

| Mode | Best For | What You Get | Requires Lattice |
|------|----------|--------------|------------------|
| Standalone | Users who only want Spec Coding skills | Persistent specs, plans, review evidence, verification notes, and Plan/TDD execution discipline | No |
| Lattice-hosted | Teams that need a project-level harness | PrismSpec plus manifest, project context, verification gates, AC coverage, drift checks, Evidence / Eval, Loop / Learn | Yes |

PrismSpec does not depend on Lattice. Lattice embeds PrismSpec as its default Spec Coding workflow.

## Skill Pack Layout

```text
prismspec/
├── skillpack.yaml              # machine-readable skill-pack contract
├── skills/
│   ├── workflow/SKILL.md       # lifecycle controller
│   ├── specification/SKILL.md
│   ├── planning/SKILL.md
│   ├── implementation/SKILL.md
│   ├── review/SKILL.md
│   ├── verification/SKILL.md
│   ├── knowledge-capture/SKILL.md
│   └── branch-closeout/SKILL.md # optional legacy branch closeout helper
├── templates/                  # spec/context templates
├── references/                 # loaded on demand
├── agents/                     # task reviewer persona
├── commands/                   # slash-command entry points
└── bin/                        # deterministic new/guide/lint/doctor helpers
```

`skills/*/SKILL.md` is the only canonical skill source. Do not maintain parallel flat `skills/*.md` entries.

Each canonical skill includes `agents/openai.yaml` for UI, installer, or marketplace discovery: `display_name`, `short_description`, and a default invocation prompt. The root-level `agents/` directory contains the task reviewer persona; it has a different role.

`skillpack.yaml` is the distributable contract. It declares workflow stages, skills, templates, references, host modes, and quality gates. Agents, installers, and wrappers should prefer it over guessing the layout from the README.

## Artifact Layout

Standalone artifacts:

```text
prismspec/specs/<spec-id>/
├── context.md
├── spec.md
├── plan.md
└── verify.md

.prismspec/runs/<spec-id>/
├── branch/review-summary.json
└── <task-id>/
    ├── brief.md
    └── review-package.md
```

Lattice-hosted artifacts:

```text
lattice/specs/<spec-id>/
├── context.md
├── spec.md
├── plan.md
└── verify.md

.lattice/sdd/<spec-id>/<task-id>/
```

## Entry Point

First check the skill pack health:

```bash
bash prismspec/bin/doctor.sh
```

Create an initial spec directory:

```bash
bash prismspec/bin/new.sh checkout-flow --title="Checkout Flow" --template=service --mode=plan
```

Run the guide first. Route from current files, not conversation memory:

```bash
bash prismspec/bin/guide.sh --json
bash prismspec/bin/guide.sh --spec=checkout-flow --json
bash prismspec/bin/guide.sh --spec=checkout-flow --from=verification --json
```

`--json` is the recommended protocol for agent wrappers and slash commands. Important fields:

| Field | Meaning |
|-------|---------|
| `host` | `standalone` or `lattice` |
| `spec_id` | Current spec id |
| `scaffolded` | Whether the spec is still an unfilled `new.sh` scaffold |
| `stage` | Next stage: `specification`, `planning`, `implementation`, `review`, `verification`, or `done` |
| `mode` | `auto`, `plan`, or `tdd` |
| `skill` | `SKILL.md` file to read and execute |
| `spec_dir` | Current spec directory |
| `run_dir` | Current evidence directory |
| `verify_command` | Recommended verification command |

## Workflow

`new.sh` is an initialization helper, not a workflow stage. It creates `spec.md` with `scaffolded: true`. After Specification fills real context, scope, ACs, risk, and mode, set it to `scaffolded: false`; until then `guide.sh` keeps routing to Specification.

| Stage | Goal | Artifacts | Stop When |
|-------|------|-----------|-----------|
| Specification | Capture context basis, scope, ACs, risks, and mode. | `context.md`, `spec.md` | ACs are not testable, key decisions are missing, or risk mode cannot be confirmed. |
| Planning | Decompose the spec into AC-traced tasks. | `plan.md` | An AC cannot map to an implementation or verification path. |
| Implementation | Execute one planned slice at a time. | code, tests, task evidence | Scope drifts, red test is unreliable, or verification failure needs product judgment. |
| Review | Review implementation evidence, diff, and review package. | `review-summary.json` | Evidence is missing, a blocking finding exists, or the spec must change. |
| Verification | Run external commands and record final evidence. | `verify.md` | Credentials or services are missing, or the fix exceeds scope. |

`/capture` is an optional post-run command. It promotes only durable, reusable, non-secret lessons from `verify.md` or review evidence.

## Templates

| Template | Use When | Focus |
|----------|----------|-------|
| `spec-template.md` | Default general-purpose work | Intent, scope, ACs, contracts, risks, verification |
| `spec-template-lite.md` | Docs, config, low-risk Plan Mode changes | AC-first, minimal design |
| `spec-template-service.md` | Backend services, APIs, data models, state transitions | API, DDL, error codes, idempotency, compensation |
| `spec-template-frontend.md` | Frontend UX, product flows, component changes | User journey, states, accessibility, UI acceptance |
| `spec-template-tdd.md` | Bug fixes, core flows, high-risk changes | Regression cases, red tests, invariants |

Template rule: use `lite` when possible; use `tdd` for permissions, security, money, idempotency, migrations, concurrency, and regressions; use `service` for API/data/state work; use `frontend` for UX states and accessibility.

## Execution Modes

PrismSpec supports two implementation policies:

| Mode | Use When | Must Produce |
|------|----------|--------------|
| `plan` | Low-risk features, docs, config, straightforward refactors, or behavior already covered by tests. | AC-traced plan, relevant tests or no-test rationale, verification evidence. |
| `tdd` | Bug fixes, permissions, security, money, state machines, migrations, concurrency, idempotency, or regressions. | Red test, green test, AC-to-test trace, regression verification. |

`auto` means the model chooses based on risk. `plan -> tdd` escalation is allowed when risk is discovered. `tdd -> plan` downgrade requires explicit user override and recorded risk.

## Canonical Skills

| Skill | Trigger | Durable Output |
|-------|---------|----------------|
| `skills/workflow/SKILL.md` | `/prismspec`, `/sdd`, spec resume, end-to-end guidance | stage routing |
| `skills/specification/SKILL.md` | `/spec`, new requirement, unclear scope/AC/mode/context | `context.md`, `spec.md` |
| `skills/planning/SKILL.md` | `/plan`, spec exists but tasks or verification paths are missing | `plan.md` |
| `skills/implementation/SKILL.md` | `/implement`, execute AC-traced tasks | code, tests, task evidence |
| `skills/review/SKILL.md` | `/review`, implementation evidence needs independent review | `review-summary.json` |
| `skills/verification/SKILL.md` | `/verify`, run external verification after implementation and review | `verify.md` |
| `skills/knowledge-capture/SKILL.md` | `/capture`, capture reusable rules, decisions, pitfalls | knowledge draft / project knowledge |
| `skills/branch-closeout/SKILL.md` | legacy `/finish`, only for explicit branch closeout | optional `summary.md` |

Every canonical skill follows the same quality bar: trigger-rich frontmatter, workflow, inputs/outputs, stop conditions, common rationalizations, red flags, and verification checklist.

## Lint

Run before completion:

```bash
bash prismspec/bin/doctor.sh
bash prismspec/bin/lint.sh prismspec skillpack
bash prismspec/bin/lint.sh prismspec/specs/checkout-flow
bash prismspec/bin/lint.sh lattice/specs/checkout-flow
```

`doctor` checks whether PrismSpec is usable in standalone or Lattice-hosted mode, including the skillpack contract, guide JSON protocol, and host environment.

`skillpack` checks the PrismSpec distribution itself:

- `skillpack.yaml` entrypoints, workflow stages, and quality gates;
- canonical `skills/*/SKILL.md` frontmatter, trigger descriptions, core sections, and `agents/openai.yaml`;
- templates, references, command, guide/lint scripts;
- absence of flat skill wrappers.

Artifact lint checks:

- `spec.md` has ACs, execution mode, risk notes, and verification plan;
- `plan.md` references ACs, has stable task ids, and includes verification;
- `verify.md` contains command/result evidence;
- TDD specs include red-test tasks.

## References And Reviewers

Long-form guidance lives in `references/` and is loaded on demand:

| Reference | Purpose |
|-----------|---------|
| `mode-selection.md` | Plan/TDD selection and escalation rules |
| `spec-quality-checklist.md` | Spec review and execution quality bar |
| `tdd-evidence-checklist.md` | Red/green evidence requirements |
| `review-evidence-checklist.md` | pass/fail/cannot_verify verdict rules |
| `definition-of-done.md` | verification completion standard |
| `superpowers-alignment.md` | Prefer proven Superpowers workflow discipline; PrismSpec adds artifact/context/evidence contracts |

`agents/` provides one task-scoped reviewer persona: `task-reviewer.md`. It returns both spec compliance and code quality verdicts, supports `cannot_verify`, and avoids multi-reviewer drift and duplicate review cost.

## Design Principles

- Spec is a contract, not a long document.
- Prefer mature Superpowers workflow discipline when it exists; do not invent parallel PrismSpec behavior for the same thing.
- A workflow node exists only when it creates a durable artifact or prevents real engineering risk.
- Context starts with a map, then the Agent discovers, selects, and compresses relevant facts.
- Verification must be backed by real commands and evidence.
- Plan Mode and TDD Mode are implementation policies inside one workflow, not separate workflows.
- Every extra phase adds human cost, so the default workflow stays small.
