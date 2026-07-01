# PrismSpec

> 中文版: [README.md](README.md)

PrismSpec is a risk-adaptive Spec Coding workflow and a standalone Agent Skills pack that can also be hosted by Lattice. It uses the minimum necessary contract to compress ambiguous intent into executable, reviewable, and verifiable engineering constraints, with two implementation modes: `plan` and `tdd`.

PrismSpec does not replace the coding agent, and it is not one rigid workflow for every task. It turns an AI coding task into a stable, resumable artifact chain:

```text
specification -> planning -> implementation(plan|tdd) -> review -> verification
```

`/prismspec` is the controller, not an extra phase. It reads current artifacts and routes to the next stage skill.

## One-Screen Model

The AI can implement freely, but it must move through reviewable artifacts:

| Layer | Question | Artifacts |
|-------|----------|-----------|
| Contract | What are we doing, based on what context, and how is it accepted? | `spec.md` |
| Plan | Who changes which files in what order, and how is each slice proven? | `plan.md` |
| Execution | How is each slice implemented, and does it need a red test? | code, tests, task evidence |
| Review | Does the implementation match the spec, and is the code acceptable? | `review.md` |
| Verification | What did the repository prove with real commands? | `verify.md` |

The philosophy is simple: **minimum necessary contract, risk-adaptive execution, stronger evidence. Reuse mature workflow discipline; put PrismSpec's value in artifacts, context, evidence, and resumability.**

The primary human-readable artifact contract is only `spec.md`, `plan.md`, `review.md`, and `verify.md`. `review-summary.json`, `review-package.md`, task briefs, TDD/debug evidence, and eval run JSON are machine-side or task-side evidence, not extra user-facing stages.

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
│   ├── prismspec-workflow/SKILL.md       # lifecycle controller
│   ├── prismspec-specification/SKILL.md
│   ├── prismspec-planning/SKILL.md
│   ├── prismspec-implementation/SKILL.md
│   ├── prismspec-review/SKILL.md
│   ├── prismspec-verification/SKILL.md
│   ├── prismspec-knowledge-capture/SKILL.md
│   ├── prismspec-debugging/SKILL.md
│   ├── prismspec-context-engineering/SKILL.md
│   ├── prismspec-source-grounding/SKILL.md
│   ├── prismspec-doubt-review/SKILL.md
│   └── prismspec-interface-design/SKILL.md
├── templates/                  # spec templates
├── references/                 # loaded on demand
├── agents/                     # task reviewer persona
├── commands/                   # slash-command entry points
└── bin/                        # deterministic new/guide/lint/doctor helpers
```

`skills/prismspec-*/SKILL.md` is the only canonical skill source. Each folder name matches the frontmatter `name`, following Agent Skills packaging conventions. Do not maintain parallel flat `skills/*.md` entries.

Each canonical skill includes:

- `agents/openai.yaml` for UI, installer, or marketplace discovery;
- `evals/evals.json` for should-trigger, should-not-trigger, and behavior assertions;
- `SKILL.md` for the core workflow needed after the skill triggers.

The root-level `agents/` directory contains the task reviewer persona; it has a different role.

`skillpack.yaml` is the distributable contract. It declares workflow stages, skills, templates, references, host modes, and quality gates. Agents, installers, and wrappers should prefer it over guessing the layout from the README.

## Artifact Layout

Standalone artifacts:

```text
prismspec/specs/<spec-id>/
├── spec.md
├── plan.md
├── review.md
└── verify.md

.prismspec/runs/<spec-id>/
└── <task-id>/
    ├── brief.md
    ├── review.md
    └── review-package.md
```

Lattice-hosted artifacts:

```text
lattice/specs/<spec-id>/
├── spec.md
├── plan.md
├── review.md
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

Check skill trigger fixtures, adjacent-stage collisions, and skill anatomy:

```bash
bash prismspec/bin/eval-skills.sh --all
```

See [RESOURCES.md](RESOURCES.md) for the full resource pack. For quick mode selection, use [risk-routing-card.md](references/risk-routing-card.md).

Commands have two layers:

| Command | Mental Model | Behavior |
|---------|--------------|----------|
| `/prismspec` | Resume the lifecycle from current artifacts. | Run `guide.sh --json`, then read the returned stage skill. |
| `/clarify` | Tighten engineering boundaries before formal spec. | Use grilling mode one question at a time, producing a `status: clarifying` `spec.md` draft. |
| `/build` | Move from an approved spec or plan into implementation. | Write `plan.md` if needed, then execute one AC-traced slice. |
| `/build auto` | Controlled multi-task execution after plan approval. | Continue across tasks, but keep evidence, TDD, review, and failure stops. |
| `/spec`, `/plan`, `/review`, `/verify` | Explicit stage entries. | Useful for advanced users and debugging. |

`/build auto` is not a bypass. It only removes manual stepping between tasks; it must stop on scope drift, unrelated dirty changes, missing evidence, unexplained failures, review blockers, or risky external actions.

`--json` is the recommended protocol for agent wrappers and slash commands. Important fields:

| Field | Meaning |
|-------|---------|
| `host` | `standalone` or `lattice` |
| `spec_id` | Current spec id |
| `scaffolded` | Whether the spec is still an unfilled `new.sh` scaffold |
| `stage` | Next stage: `specification`, `planning`, `implementation`, `review`, `verification`, or `done` |
| `mode` | `auto`, `plan`, or `tdd` |
| `skill` | `SKILL.md` file to read and execute |
| `automation_policy` | Automation boundary for the current stage |
| `stop_conditions` | Conditions that require pausing or escalation |
| `spec_dir` | Current spec directory |
| `run_dir` | Current evidence directory |
| `verify_command` | Recommended verification command |

## Workflow

`new.sh` is an initialization helper, not a workflow stage. It creates `spec.md` with `scaffolded: true`. After Specification fills real context, scope, ACs, risk, and mode, set it to `scaffolded: false`; until then `guide.sh` keeps routing to Specification.

| Stage | Goal | Artifacts | Stop When |
|-------|------|-----------|-----------|
| Specification | Capture context basis, scope, ACs, risks, and mode. | `spec.md` | ACs are not testable, key decisions are missing, or risk mode cannot be confirmed. |
| Planning | Decompose the spec into AC-traced tasks. | `plan.md` | An AC cannot map to an implementation or verification path. |
| Implementation | Execute one planned slice at a time. | code, tests, task evidence | Scope drifts, red test is unreliable, or verification failure needs product judgment. |
| Review | Review implementation evidence, diff, and review package. | `review.md` | Evidence is missing, a blocking finding exists, or the spec must change. |
| Verification | Run external commands and record final evidence. | `verify.md` | Credentials or services are missing, or the fix exceeds scope. |

`/capture` is a post-run command. It promotes only durable, reusable, non-secret lessons from `verify.md` or review evidence and is not a required stage in the default delivery chain.

## Alignment

PrismSpec aligns with two mature practices:

| Standard | How PrismSpec Uses It |
|----------|------------------------|
| Superpowers | Reuse proven coding workflow discipline: brainstorming, writing plans, TDD, task review, systematic debugging, and verification before completion. |
| Agent Skills | Follow distributable skill packaging: folder name = skill name, trigger-rich description, progressive disclosure, `agents/openai.yaml`, and `evals/evals.json`. |

PrismSpec does not reinvent brainstorming, TDD, or verification discipline. It anchors those disciplines in durable artifacts, project context, evidence, and Lattice gates.

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

PrismSpec intentionally exposes two stable execution modes instead of a complex continuum:

| Mode | Use When | Must Produce |
|------|----------|--------------|
| `plan` | Low-risk features, docs, config, straightforward refactors, or behavior already covered by tests. | AC-traced plan, relevant tests or no-test rationale, verification evidence. |
| `tdd` | Bug fixes, permissions, security, money, state machines, migrations, concurrency, idempotency, or regressions. | Red test, green test, AC-to-test trace, regression verification. |

`auto` means the model chooses `plan` or `tdd` based on risk. `plan -> tdd` escalation is allowed when risk is discovered. `tdd -> plan` downgrade requires explicit user override and recorded risk.

Quick rule:

- `plan` is the low-friction path for low-risk work that ordinary verification can prove.
- `tdd` is the risk-protection path for regressions and critical invariants.
- `auto` is not a third workflow; it routes to `plan` or `tdd`.

## Canonical Skills

| Skill | Trigger | Durable Output |
|-------|---------|----------------|
| `skills/prismspec-workflow/SKILL.md` | `/prismspec`, spec resume, end-to-end guidance | stage routing |
| `skills/prismspec-grilling/SKILL.md` | `/clarify`, vague engineering boundaries before spec | `status: clarifying` `spec.md` draft |
| `skills/prismspec-specification/SKILL.md` | `/spec`, new requirement, unclear scope/AC/mode/context | `spec.md` |
| `skills/prismspec-planning/SKILL.md` | `/plan`, spec exists but tasks or verification paths are missing | `plan.md` |
| `skills/prismspec-implementation/SKILL.md` | `/implement`, execute AC-traced tasks | code, tests, task evidence |
| `skills/prismspec-review/SKILL.md` | `/review`, implementation evidence needs independent review | `review.md` |
| `skills/prismspec-verification/SKILL.md` | `/verify`, run external verification after implementation and review | `verify.md` |
| `skills/prismspec-knowledge-capture/SKILL.md` | `/capture`, capture reusable rules, decisions, pitfalls | knowledge draft / project knowledge |
| `skills/prismspec-debugging/SKILL.md` | bugs, failing tests, build/pipeline failures, unexpected behavior | root cause, repro, fix evidence |
| `skills/prismspec-context-engineering/SKILL.md` | project knowledge, hidden constraints, historical decisions | Context Basis facts |
| `skills/prismspec-source-grounding/SKILL.md` | external APIs, SDKs, models, platforms, standards | sourced facts / unverified risk |
| `skills/prismspec-doubt-review/SKILL.md` | high-risk assumptions, irreversible decisions, security/data risk | doubt review note |
| `skills/prismspec-interface-design/SKILL.md` | API, schema, event, state, error, or module boundaries | interface contract |

Every canonical skill follows the same quality bar: trigger-rich frontmatter, workflow, inputs/outputs, stop conditions, common rationalizations, red flags, and verification checklist.

The last four are support skills, not workflow stages. They load only when the risk shape needs them, so low-risk work does not inherit extra ceremony.

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
- every skill's `evals/evals.json`;
- templates, references, command, guide/lint/eval scripts;
- absence of flat skill wrappers.

`eval-skills.sh` checks:

- whether `SKILL.md` follows the Agent Skills anatomy;
- whether trigger descriptions include clear `Use when` boundaries;
- whether `evals/evals.json` has enough should-trigger, should-not-trigger, and assertion fixtures;
- whether trigger prompts contain obvious duplicates or adjacent-stage collisions.

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
| `risk-routing-card.md` | Quick routing card for `plan` / `tdd` selection |
| `spec-quality-checklist.md` | Spec review and execution quality bar |
| `tdd-evidence-checklist.md` | Red/green evidence requirements |
| `review-evidence-checklist.md` | pass/fail/cannot_verify verdict rules |
| `definition-of-done.md` | verification completion standard |
| `superpowers-alignment.md` | Prefer proven Superpowers workflow discipline; PrismSpec adds artifact/context/evidence contracts |
| `agent-skills-alignment.md` | Agent Skills packaging, triggering, eval, and progressive disclosure standards |

`agents/` provides focused reviewer personas:

| Reviewer | Use When |
|----------|----------|
| `spec-reviewer.md` | Before planning, or when scope, ACs, context, risk, or mode changed. |
| `task-reviewer.md` | Default task or branch implementation review. |
| `test-reviewer.md` | TDD evidence, large test changes, or uncertain AC-to-test trace. |
| `risk-reviewer.md` | Security, permissions, money, data, migrations, concurrency, idempotency, or irreversible operations. |

Use the smallest reviewer set that covers the task. Personas do not call each other; the controller fan-outs selected reviews and merges verdicts into `review.md`.

## Design Principles

- Spec is a contract, not a long document.
- Plan and TDD are two risk tiers inside one workflow, not separate workflows.
- Prefer mature Superpowers workflow discipline when it exists; do not invent parallel PrismSpec behavior for the same thing.
- A workflow node exists only when it creates a durable artifact or prevents real engineering risk.
- Context starts with a map, then the Agent discovers, selects, and compresses relevant facts.
- Verification must be backed by real commands and evidence.
- Plan Mode and TDD Mode are implementation policies inside one workflow, not separate workflows.
- Every extra phase adds human cost, so the default workflow stays small.
