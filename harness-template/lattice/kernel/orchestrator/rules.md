## Lattice Agent Rules

> Lattice injects repo-local AI Coding constraints through `CLAUDE.md` `@import`.
> PrismSpec owns the Spec Coding workflow; Lattice adds project context, verification gates, evidence, loop, and learn.

### Operating Rule

Route from current artifacts, not conversation memory:

```bash
bash prismspec/bin/guide.sh --json
```

Use the returned `stage`, `mode`, `skill`, `spec_dir`, `run_dir`, and `verify_command` as the source of truth.

### Routing

| Trigger | Route | Output |
|---------|-------|--------|
| Requirement without spec | Brainstorm | `lattice/specs/<spec-id>/context.md`, `spec.md` |
| `/sdd` | PrismSpec controller | Next stage from `guide.sh --json` |
| `/brainstorm` | Brainstorm skill | context basis and spec |
| `/plan` | Plan skill | AC-traced `plan.md` |
| `/implement` | Implement skill | code, tests, task evidence |
| `/verify` | Verify skill | `verify.md`, eval JSON when available |
| `/finish` | Finish skill | `summary.md`, residual risk, outcome links |
| `/learn` | Learn skill | knowledge draft or promoted project knowledge |

### Source Of Truth

| Surface | Path |
|---------|------|
| Project declaration | `lattice/manifest.yaml` |
| Project context map | `lattice/context/README.md` |
| External context map | `lattice/context/external.md` |
| Durable project knowledge | `lattice/context/knowledge/` |
| Spec artifacts | `lattice/specs/<spec-id>/` |
| Task evidence | `.lattice/sdd/<spec-id>/<task-id>/` |
| Eval runs and loop state | `lattice/state/` |
| PrismSpec skills | `prismspec/skills/*/SKILL.md` |

Current code, tests, schemas, contracts, and command output override stale notes.

### Brainstorm

- Write both `context.md` and `spec.md`.
- Read `lattice/context/README.md` first when present.
- Load only context that changes scope, AC, risk, interface, compatibility, or verification.
- Optional curated knowledge search: `bash lattice/kernel/context/backends/knowledge.sh <keywords>`.
- Do not paste large knowledge files into the spec; record selected facts, constraints, conflicts, exclusions, and gaps in `context.md`.
- Record `execution_mode`, reason, and source: `model-selected`, `project-default`, or `user-override`.
- Use stable `AC-{n}` identifiers.

Run when available:

```bash
bash lattice/kernel/context/context-lint.sh <spec-id>
bash lattice/kernel/context/context-run.sh <spec-id> --strict
bash lattice/kernel/orchestrator/sdd/spec-state-lint.sh <spec-id>
```

### Plan

- Write `lattice/specs/<spec-id>/plan.md`.
- Every behavior task must reference at least one AC.
- Every task must name scope, touched files/contracts, verification command, evidence path, and done conditions.
- Use thin vertical slices when possible.
- Upgrade `plan -> tdd` when planning reveals bug-fix, permission, security, money, state-machine, migration, concurrency, idempotency, or regression risk.
- Do not silently downgrade `tdd -> plan`.

Run when available:

```bash
bash lattice/kernel/orchestrator/sdd/plan-lint.sh <spec-id>
bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted
```

### Implement

- Resolve the next task from artifacts:

```bash
bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json
```

- Implement one planned slice at a time.
- In Plan Mode, add tests for behavior changes or write an explicit no-test rationale.
- In TDD Mode, write the red test first, make it fail for the expected reason, then implement green and refactor.
- Generate task brief and review package when helpers exist.
- Mark tasks complete only through evidence-gated helper:

```bash
bash lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> <task-id> --json
```

- Do not mix unrelated refactors.
- If implementation needs scope not in the spec, update the spec first.

Before treating implementation as complete:

```bash
bash lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>
bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> implemented --from=planned
```

### Verify

Verification is command-backed proof, not a prose assertion.

Default Lattice-hosted verification:

```bash
bash lattice/kernel/delivery/pipeline.sh --json-out
```

Rules:

- No completion claim without command output or recorded evidence.
- Fix retryable failures within spec scope and rerun relevant commands.
- Escalate when the fix requires product, architecture, credential, data, or permission decisions.
- Record exact commands and outcomes in `verify.md`.

When verification passes:

```bash
bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> verified --from=implemented
```

### Finish

- Write `lattice/specs/<spec-id>/summary.md`.
- Summarize AC coverage, changed files, verification commands, evidence links, residual risk, and deferred work.
- Treat `cannot_verify` as residual risk, not pass.
- Link known post-run review findings, rework, escaped defects, incidents, or success signals with `outcome-link.sh` when available.
- Use `summary-draft.sh` as a draft generator when available; edit for human readability.

When summary exists and verification evidence is real:

```bash
bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> finished --from=verified
```

### Learn

Promote only durable, reusable, non-secret lessons.

- Prefer `lattice/kernel/context/summary-learn-draft.sh <spec-id>` when `summary.md` contains Knowledge Candidates.
- Store drafts under `lattice/context/drafts/`.
- Promote to `lattice/context/knowledge/` only after checking duplicates and conflicts.
- When governance is required, record reviewer evidence:

```bash
bash lattice/kernel/context/knowledge-review.sh approve lattice/context/drafts/<draft>.md --reviewer=<name> --reason=<reason> --conflicts-checked
bash lattice/kernel/context/learn-draft.sh promote lattice/context/drafts/<draft>.md --require-review --to=lattice/context/knowledge/pitfalls.md
```

### Review Contract

- Review is read-only.
- Valid verdicts: `pass`, `fail`, `cannot_verify`.
- Check spec compliance, code quality, test coverage, and risk.
- Do not treat missing evidence as pass.

### Artifact Layout

```text
lattice/
├── manifest.yaml
├── context/
│   ├── README.md
│   ├── external.md
│   ├── knowledge/
│   └── drafts/
├── specs/
│   └── <spec-id>/
│       ├── context.md
│       ├── spec.md
│       ├── plan.md
│       ├── verify.md
│       └── summary.md
└── state/
    ├── eval-runs/
    ├── loops/
    ├── outcomes/
    ├── context-runs/
    ├── learn-promotions/
    └── knowledge-reviews/

prismspec/
├── skillpack.yaml
├── skills/
├── templates/
├── references/
└── bin/

.lattice/sdd/<spec-id>/<task-id>/
├── brief.md
├── review-package.md
├── review-summary.json
└── tdd-evidence.json
```
