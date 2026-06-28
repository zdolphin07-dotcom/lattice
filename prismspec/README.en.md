# PrismSpec

> 中文版: [README.md](README.md)

PrismSpec is a standalone, progressive Spec Coding skill pack. It turns an AI coding task into a resumable, reviewable, and verifiable artifact chain:

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

`/sdd` is the controller, not an extra phase. It reads current artifacts and routes to the next stage skill.

## Positioning

PrismSpec can run standalone or in Lattice-hosted mode.

| Mode | Best For | What You Get | Requires Lattice |
|------|----------|--------------|------------------|
| Standalone | Users who only want Spec Coding skills | Persistent specs, plans, verification notes, summaries, and Plan/TDD execution discipline | No |
| Lattice-hosted | Teams that need a project-level harness | PrismSpec plus manifest, project context, verification gates, AC coverage, drift checks, Evidence / Eval, Loop / Learn | Yes |

PrismSpec does not depend on Lattice. Lattice embeds PrismSpec as its default Spec Coding workflow.

## Skill Pack Layout

```text
prismspec/
├── skillpack.yaml              # machine-readable skill-pack contract
├── skills/
│   ├── sdd/SKILL.md            # lifecycle controller
│   ├── brainstorm/SKILL.md
│   ├── plan/SKILL.md
│   ├── implement/SKILL.md
│   ├── verify/SKILL.md
│   ├── finish/SKILL.md
│   └── learn/SKILL.md
├── templates/                  # spec/context templates
├── references/                 # loaded on demand
├── agents/                     # lightweight reviewer personas
├── commands/                   # slash-command entry points
└── bin/                        # deterministic guide/lint helpers
```

`skills/*/SKILL.md` is the only canonical skill source. Do not maintain parallel flat `skills/*.md` entries.

Each canonical skill includes `agents/openai.yaml` for UI, installer, or marketplace discovery: `display_name`, `short_description`, and a default invocation prompt. The root-level `agents/` directory still contains lightweight reviewer personas; it has a different role.

`skillpack.yaml` is the distributable contract. It declares workflow stages, skills, templates, references, host modes, and quality gates. Agents, installers, and wrappers should prefer it over guessing the layout from the README.

## Artifact Layout

Standalone artifacts:

```text
prismspec/specs/<spec-id>/
├── context.md
├── spec.md
├── plan.md
├── verify.md
└── summary.md

.prismspec/runs/<spec-id>/<task-id>/
├── brief.md
└── review-package.md
```

Lattice-hosted artifacts:

```text
lattice/specs/<spec-id>/
├── context.md
├── spec.md
├── plan.md
├── verify.md
└── summary.md

.lattice/sdd/<spec-id>/<task-id>/
```

## Entry Point

Run the guide first. Route from current files, not conversation memory:

```bash
bash prismspec/bin/guide.sh --json
bash prismspec/bin/guide.sh --spec=checkout-flow --json
bash prismspec/bin/guide.sh --spec=checkout-flow --from=verify --json
```

`--json` is the recommended protocol for agent wrappers and slash commands. Important fields:

| Field | Meaning |
|-------|---------|
| `host` | `standalone` or `lattice` |
| `spec_id` | Current spec id |
| `stage` | Next stage: `brainstorm`, `plan`, `implement`, `verify`, `finish`, or `done` |
| `mode` | `auto`, `plan`, or `tdd` |
| `skill` | `SKILL.md` file to read and execute |
| `spec_dir` | Current spec directory |
| `run_dir` | Current evidence directory |
| `verify_command` | Recommended verification command |

## Workflow

| Stage | Goal | Artifacts | Stop When |
|-------|------|-----------|-----------|
| Brainstorm | Capture context basis, scope, ACs, risks, and mode. | `context.md`, `spec.md` | ACs are not testable, key decisions are missing, or risk mode cannot be confirmed. |
| Plan | Decompose the spec into AC-traced tasks. | `plan.md` | An AC cannot map to an implementation or verification path. |
| Implement | Execute one planned slice at a time. | code, tests, task evidence | Scope drifts, red test is unreliable, or verification failure needs product judgment. |
| Verify | Run external commands and record results. | `verify.md` | Credentials or services are missing, or the fix exceeds scope. |
| Finish | Summarize evidence, risks, and knowledge candidates. | `summary.md` | Verification evidence is missing or blockers are being framed as done. |

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
| `skills/sdd/SKILL.md` | `/sdd`, spec resume, end-to-end guidance | stage routing |
| `skills/brainstorm/SKILL.md` | new requirement, unclear scope/AC/mode/context | `context.md`, `spec.md` |
| `skills/plan/SKILL.md` | spec exists but tasks or verification paths are missing | `plan.md` |
| `skills/implement/SKILL.md` | execute AC-traced tasks | code, tests, task evidence |
| `skills/verify/SKILL.md` | run external verification after implementation | `verify.md` |
| `skills/finish/SKILL.md` | closeout, risk, outcome, lessons | `summary.md` |
| `skills/learn/SKILL.md` | capture reusable rules, decisions, pitfalls | knowledge draft / project knowledge |

Every canonical skill follows the same quality bar: trigger-rich frontmatter, workflow, inputs/outputs, stop conditions, common rationalizations, red flags, and verification checklist.

## Lint

Run before closeout:

```bash
bash prismspec/bin/lint.sh prismspec skillpack
bash prismspec/bin/lint.sh prismspec/specs/checkout-flow
bash prismspec/bin/lint.sh lattice/specs/checkout-flow
```

`skillpack` checks the PrismSpec distribution itself:

- `skillpack.yaml` entrypoints, workflow stages, and quality gates;
- canonical `skills/*/SKILL.md` frontmatter, trigger descriptions, core sections, and `agents/openai.yaml`;
- templates, references, command, guide/lint scripts;
- absence of flat skill wrappers.

Artifact lint checks:

- `spec.md` has ACs, execution mode, risk notes, and verification plan;
- `plan.md` references ACs, has stable task ids, and includes verification;
- `verify.md` or `summary.md` contains command/result evidence;
- TDD specs include red-test tasks.

## References And Reviewers

Long-form guidance lives in `references/` and is loaded on demand:

| Reference | Purpose |
|-----------|---------|
| `mode-selection.md` | Plan/TDD selection and escalation rules |
| `spec-quality-checklist.md` | Spec review and execution quality bar |
| `tdd-evidence-checklist.md` | Red/green evidence requirements |
| `review-evidence-checklist.md` | pass/fail/cannot_verify verdict rules |
| `definition-of-done.md` | closeout standard |

`agents/` provides lightweight reviewer personas for spec compliance, code quality, and test coverage. They are not tied to a specific agent runtime.

## Design Principles

- Spec is a contract, not a long document.
- A workflow node exists only when it creates a durable artifact or prevents real engineering risk.
- Context starts with a map, then the Agent discovers, selects, and compresses relevant facts.
- Verification must be backed by real commands and evidence.
- Plan Mode and TDD Mode are implementation policies inside one workflow, not separate workflows.
- Every extra phase adds human cost, so the default workflow stays small.
