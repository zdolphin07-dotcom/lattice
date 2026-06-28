## Lattice — Agent Behavior Rules

> Lattice injects project-level constraints into your AI coding agent via `CLAUDE.md` `@import`.
> Lattice hosts PrismSpec as its default spec-coding workflow and enhances it with project context loading and delivery verification.

---

### Routing

| Trigger | Path | When to use |
|---------|------|-------------|
| Describe a requirement (default) | **Brainstorming** | Clarify intent, load context, write persistent spec |
| `/init` | **Init Skill** | Set up harness, generate `lattice/manifest.yaml`, inject `CLAUDE.md` |
| `/sdd` | **PrismSpec Guided Skill** | Route or resume the full spec-coding workflow from artifacts |
| `/brainstorm` | **Brainstorm Skill** | Produce `lattice/specs/<id>/spec.md` |
| `/plan` | **Plan Skill** | Produce `lattice/specs/<id>/plan.md` |
| `/implement` | **Implement Skill** | Execute plan or tdd policy from the spec |
| `/verify` | **Verify Skill** | Run manifest-driven verification pipeline |
| `/finish` | **Finish Skill** | Close delivery, link evidence, extract durable knowledge |
| `/learn` | **Learn Skill** | Capture durable knowledge into project context |

---

### Phase Rules

> The following rules apply to each phase of development. If your workflow engine provides
> phases with different names, map them accordingly (see docs/adapters/ for engine-specific mappings).

#### Phase: Brainstorming — Spec format and context basis

- **Spec path**: `lattice/specs/{spec-id}/spec.md`
- **Context basis path**: `lattice/specs/{spec-id}/context.md`
- **Template**: read `specs.template` from `lattice/manifest.yaml`; default is `lattice/kernel/orchestrator/templates/spec-template.md`
- **Dual-audience principle**: diagrams for humans, DDL/AC/API examples for AI execution
- **AC numbering**: globally unique `AC-{nn}`, traced through spec -> test -> coverage
- **Execution policy**: read `specs.default_execution_mode`; `auto` means choose `plan` or `tdd` by risk
- **Active spec**: prefer `specs.active` when configured; do not infer from recently modified `plan.md` or `summary.md`

Before drafting the spec:
1. Read `lattice/manifest.yaml`
2. Read `lattice/context/README.md` as the project context map when present.
3. Follow the map to relevant project knowledge, external references, code, tests, schemas, interface contracts, and historical specs.
4. Write `lattice/specs/{spec-id}/context.md` with selected facts, constraints, conflicts, exclusions, and open questions.
5. Use `context.md` as the design basis; if context is insufficient, ask the user first.
6. Record whether the execution mode came from model selection, project default, or user override.

#### Phase: Planning — AC traceability

- Plan path: `lattice/specs/{spec-id}/plan.md`
- Each task must reference its associated AC number
- Plan must include `Global Constraints` for versions, dependencies, naming, security, data, compatibility, and out-of-scope limits
- Each task must declare interfaces: inputs, outputs, touched files/contracts, and verification evidence
- If `execution_mode: plan` but planning reveals bug-fix, money/security/permission/state-machine, concurrency, idempotency, or regression risk, upgrade to `tdd`
- If `execution_mode: tdd`, include test-first tasks; do not downgrade to `plan` without explicit user override
- If spec drift is discovered during coding, update the spec first, then continue implementation

#### Phase: Implementation — Plan/TDD policy

- Unit tests: `TestAC{nn}_{description}` (Go) / `test_ac{nn}_{description}` (Python) / `describe('AC-{nn}: ...')` (Node)
- Integration tests: `TestIntegration_{scenario}`
- Smoke tests: `TestSmoke_{API}`
- Plan mode: execute `plan.md`, add necessary tests for behavior changes
- TDD mode: write red tests first, implement green, then refactor; no red test, no implementation
- Before each task: resolve the next task with `bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json`, then generate a task brief with `bash lattice/kernel/orchestrator/sdd/task-brief.sh <spec-id> <task-id>`
- After each task: generate a review package with `bash lattice/kernel/orchestrator/sdd/review-package.sh <spec-id> <task-id>`
- Before marking implementation complete: run `bash lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>`
- Store transient evidence under `.lattice/sdd/{spec-id}/{task-id}/`; do not put execution scratch files in `.git/`

#### Review contract

- Review is read-only: reviewers must not modify the working tree
- Return both verdicts: spec compliance and code quality
- Valid verdicts: `pass`, `fail`, `cannot-verify`
- Use `cannot-verify` when the diff package lacks enough evidence; do not invent certainty

#### Phase: Verification — Delivery pipeline

Before declaring completion, run:

```bash
bash lattice/kernel/delivery/pipeline.sh
```

Rules:
- No completion claims without verification evidence
- On failure: fix -> re-run loop, default max 3 retries
- After retry budget exhausted: escalation, await human intervention

#### Phase: Finishing — Evidence closeout

Before merge/PR, confirm:
- `ac-coverage`: every AC has a corresponding test
- `drift-check`: DDL / routes / error codes match spec
- `compliance`: per-spec context, knowledge references, and clarification traces are auditable
- For multi-agent concurrent spec edits, use `spec-lock.sh`
- Write `lattice/specs/{spec-id}/summary.md`
- Link task briefs, review packages, and review verdicts
- Extract only durable knowledge via `/learn`; do not preserve one-off implementation details

---

### Available Skills

| Skill | Trigger | Capability |
|-------|---------|------------|
| `init` | `/init`, initialize Lattice | Generate manifest, copy harness-template, inject CLAUDE.md |
| `sdd` | `/sdd`, PrismSpec guided workflow | Route/resume Brainstorming -> Planning -> Implementation -> Verification -> Finishing |
| `brainstorm` | `/brainstorm`, draft spec | Clarify intent, load context, write persistent spec |
| `plan` | `/plan`, write plan | Decompose spec into AC-traced tasks |
| `implement` | `/implement`, tdd | Execute plan or tdd policy |
| `verify` | `/verify`, verify, run pipeline | Execute `lattice/kernel/delivery/pipeline.sh` |
| `finish` | `/finish`, close out | Write summary and extract durable knowledge |
| `learn` | `/learn`, capture, remember | Write to `lattice/context/knowledge/drafts` or `project` and update index |

### Artifact Layout

```text
lattice/
├── manifest.yaml
├── kernel/
│   ├── _lib.sh
│   ├── orchestrator/
│   │   ├── rules.md
│   │   ├── flow.yaml
│   │   └── templates/
│   ├── context/
│   └── delivery/
├── context/
│   ├── sources.yaml
│   └── knowledge/
│       ├── project/
│       ├── central/
│       └── drafts/
├── specs/
│   └── {spec-id}/
│       ├── context.md
│       ├── spec.md
│       ├── plan.md
│       └── summary.md
├── state/
└── skills/

prismspec/
├── skills/
└── templates/

.lattice/
└── sdd/
    └── {spec-id}/
        └── {task-id}/
            ├── brief.md
            └── review-package.md
```
