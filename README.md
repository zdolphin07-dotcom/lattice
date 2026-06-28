<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>Team-native AI Coding Framework for reusable, verifiable software delivery</strong>
  </p>
  <p align="center">
    <a href="README.zh-CN.md">中文文档</a> · <a href="docs/wiki/">Design Wiki</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="docs/adapters/">Agent Adapters</a> · <a href="examples/go-gin-gorm/">Example</a>
  </p>
</p>

---

## Why Lattice

AI coding has already made individual engineers faster. The harder problem is making those wins reusable across a team: shared context, consistent specifications, repeatable verification, measurable quality, and a path for engineering practices to scale beyond one person's prompt history.

Lattice is a team-native AI Coding framework. It turns individual AI coding practices into reusable engineering assets by connecting project context, spec-driven work, agent execution rules, verification gates, and evaluation evidence.

It is designed around four principles:

| Principle | What it means |
|-----------|---------------|
| **Spec-driven** | Requirements become explicit contracts with acceptance criteria, API/data design, risks, and test strategy. |
| **Context-aware** | Project knowledge, naming conventions, domain rules, and past decisions are loaded before code is generated. |
| **Evidence-based** | Completion claims are backed by build/lint/test/gate output, not agent self-assessment. |
| **Composable** | Context, Spec, Harness, and Eval components can be used independently or combined as a workflow. |

## The Problem

AI coding agents fail at two boundaries that individual usage often hides:

**The Context Boundary** — Real project constraints live outside the codebase: domain rules, naming conventions, historical decisions, lessons learned from past incidents. The model can read your code, but it cannot infer what it has never seen. It doesn't know that "balance" operations require idempotency keys, or that your team settled on camelCase for API fields after a month-long debate. Without this context, it guesses — and guesses that compile are the most dangerous kind of bug.

**The Verification Boundary** — When the same model generates code and evaluates whether that code is correct, you get a student grading their own exam. The agent will report "all tests pass" because it wrote both the code and the tests to match. Structural issues — missing edge cases, spec-code drift, uncovered acceptance criteria — go undetected because the verifier shares the generator's blind spots.

## The Solution

Lattice installs into your codebase and provides **external support at both boundaries**:

| Boundary | Without Lattice | With Lattice |
|----------|-------------------|-----------------|
| **Intent → Code** | Agent guesses at constraints it can't see | Knowledge layer injects domain context; spec template forces explicit design |
| **Code → Production** | Agent self-evaluates ("looks good to me") | Delivery layer runs an independent gate pipeline for structural verification and repeatable evidence |

It is **not** a workflow engine, IDE plugin, or cloud service. It is a set of composable project files, bash scripts, and YAML contracts that live in your repo, invoked by whatever AI agent you already use.

---

## Component Model

Lattice is intentionally modular. Each component can be used on its own, while the shared `manifest.yaml` and artifact layout let them compose into a team workflow.

| Component | Role | Current form |
|-----------|------|--------------|
| **PrismSpec** | Standalone progressive spec-coding skill pack: guided `/sdd`, brainstorm, plan, implement, verify, finish, artifact lint, references, reviewer personas. | `prismspec/skills/*/SKILL.md`, `prismspec/bin/`, `prismspec/references/`, `prismspec/templates/` |
| **Context** | Load project knowledge, naming rules, domain constraints, and historical decisions. | `lattice/knowledge/`, `loader.sh`, `sync.sh` |
| **Spec** | Standardize requirements into executable contracts with ACs, design decisions, risks, and test strategy. | `spec-template.md`, `spec-lint.sh`, `lattice/specs/` |
| **Harness** | Run agent-independent verification gates before delivery claims. | `pipeline.sh`, build/lint/test, AC coverage, drift check |
| **Eval** | Produce repeatable quality evidence from acceptance coverage and drift checks. | Evidence-oriented gate output; extensible through `drift.plugins[]` |

PrismSpec can be used alone by users who only want the AI coding workflow. Lattice hosts PrismSpec and adds manifest routing, knowledge retrieval, gates, eval, and delivery loops.

### Spec Template Policy

PrismSpec templates are intentionally scenario-specific. The default template is compact: lock intent, scope, acceptance criteria, one-way decisions, risks, and verification; leave regenerable implementation detail to the model.

| Template | Use When |
|----------|----------|
| `prismspec/templates/spec-template.md` | Default professional contract |
| `prismspec/templates/spec-template-lite.md` | Lightweight Plan Mode, docs, config, low-risk changes |
| `prismspec/templates/spec-template-service.md` | Backend APIs, data, state, idempotency, compensation |
| `prismspec/templates/spec-template-frontend.md` | Frontend UX, component behavior, visual/interaction states |
| `prismspec/templates/spec-template-tdd.md` | Bug fixes, regressions, high-risk TDD work |

Teams can override the template per project in `lattice/manifest.yaml`:

```yaml
specs:
  active: ""                         # optional: spec id or path
  template: "lattice/kernel/orchestrator/templates/spec-template.md"
  # or: "prismspec/templates/spec-template-service.md"
  default_execution_mode: "auto"   # auto | plan | tdd
  allow_execution_mode_override: true
```

`auto` lets the model choose `plan` or `tdd` by risk. A project may force a default, and a user can override the mode for a single spec. Plan mode may escalate to TDD when planning or implementation discovers higher risk; TDD should not be downgraded silently.

---

## Quick Start

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| **bash** ≥ 4.0 | Script runtime | macOS: `brew install bash` · Linux: built-in |
| **yq** ≥ 4.x | YAML parser | `brew install yq` · [github.com/mikefarah/yq](https://github.com/mikefarah/yq) |
| **git** | Knowledge sync, drift detection | Usually pre-installed |

### Install

```bash
# Option A: Remote install
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# Option B: Local install (if you cloned the repo)
./install.sh /path/to/your-project --init

# Option C: Agent-driven (inside Claude Code)
/init
```

The `--init` flag auto-detects your language, framework, and ORM, then generates `manifest.yaml` and injects rules into your agent's config.

### Try the Example

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

This runs all gates on a sample Go project — spec-lint, AC coverage, drift check, knowledge retrieval — in under 5 seconds, no Go compiler needed.

---

## Architecture

### Design Philosophy

**Engine/data separation.** The `kernel/` directory is an upgradable engine — replace it as a unit and project config stays untouched. The `specs/`, `knowledge/`, and `plans/` directories are project-owned data — they survive upgrades and belong in version control.

### Three Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      Your AI Agent                          │
│  (Claude Code / Cursor / Aider / any agent with shell)      │
└──────────────┬──────────────────────────────┬───────────────┘
               │ @import rules.md             │ bash pipeline.sh
               ▼                              ▼
┌──────────────────────┐    ┌─────────────────────────────────┐
│    ORCHESTRATOR       │    │          DELIVERY                │
│                       │    │                                  │
│  rules.md             │    │  pipeline.sh                     │
│  flow.yaml            │    │    ├── bootstrap.sh              │
│  spec-template.md     │    │    ├── spec-lint.sh              │
│                       │    │    ├── build / lint / test        │
│  Defines behavior     │    │    ├── ac-coverage.sh            │
│  per development      │    │    ├── drift-check.sh            │
│  phase                │    │    ├── compliance.sh             │
│                       │    │    └── spec-lock.sh              │
└──────────────────────┘    │                                  │
                             │  Exit 0 = pass                   │
┌──────────────────────┐    │  Exit 1 = fail (retryable)       │
│    KNOWLEDGE          │    │  Exit 2 = escalation (human)     │
│                       │    └─────────────────────────────────┘
│  loader.sh            │
│  sync.sh              │          ┌──────────────────┐
│  knowledge/index.md   │          │  manifest.yaml    │
│  knowledge/*.md       │          │                   │
│  synonyms.txt         │          │  Single source of │
│                       │          │  project config   │
│  Retrieves domain     │          └──────────────────┘
│  context on demand    │
└──────────────────────┘
```

| Layer | Role | Mechanism | Form |
|-------|------|-----------|------|
| **Orchestrator** | Control plane | Defines agent behavior rules per phase — spec format, AC numbering, phase transitions | Static files, `@import` into agent prompt |
| **Knowledge** | Intent → Code | Retrieves domain knowledge by keyword, injects into agent context | CLI (`loader.sh`), called by agent |
| **Delivery** | Code → Production | Runs manifest-driven verification gate pipeline, independent of agent | CLI (`pipeline.sh`), called by agent |

Each layer can be independently enabled/disabled via `manifest.yaml`:

```yaml
kernel:
  layers:
    orchestrator: true   # Always on
    knowledge: true      # Disable if no knowledge base yet
    delivery: true       # Disable for exploratory work
```

### Project Directory After Installation

```
your-project/
├── CLAUDE.md                          # One @import activates all constraints
├── lattice/
│   ├── manifest.yaml                  # Declarative project config
│   ├── kernel/                        # ★ Upgradable engine
│   │   ├── _lib.sh                    #   Shared library (logging, YAML queries)
│   │   ├── orchestrator/
│   │   │   ├── rules.md              #   Phase behavior rules
│   │   │   ├── flow.yaml             #   Phase definitions
│   │   │   └── templates/
│   │   │       └── spec-template.md  #   Spec format template
│   │   ├── knowledge/
│   │   │   ├── loader.sh             #   Keyword → knowledge retrieval
│   │   │   └── sync.sh              #   Central repo sync
│   │   └── delivery/
│   │       ├── pipeline.sh           #   Gate orchestrator
│   │       ├── bootstrap.sh          #   Environment check
│   │       ├── deploy.sh             #   Deploy (optional, Docker+K8s example)
│   │       └── gates/
│   │           ├── spec-lint.sh      #   Spec structure validation
│   │           ├── ac-coverage.sh    #   AC↔Test traceability
│   │           ├── drift-check.sh    #   Spec↔Code drift detection
│   │           ├── compliance.sh     #   Behavioral compliance audit
│   │           └── spec-lock.sh      #   Multi-agent write lock
│   ├── knowledge/                     # ★ Project-owned: domain knowledge base
│   │   ├── index.md                  #   Keyword index
│   │   └── *.md                      #   Knowledge entries
│   ├── specs/                         # ★ Project-owned: frozen spec contracts
│   ├── plans/                         # ★ Project-owned: AC-traced execution plans
│   └── requirements/                  # ★ Project-owned: requirement inputs
├── src/                               # Your code (Lattice never touches this)
└── ...
```

---

## How It Works

### Phase 1: Brainstorming — Knowledge Injection + Spec Authoring

When you describe a requirement, the agent enters the brainstorming phase:

```
You: "Add a coupon redemption API"

Agent (with Lattice rules):
  1. Reads manifest.yaml for spec/knowledge/verification routing
  2. Runs: bash lattice/kernel/knowledge/loader.sh coupon redemption payment
     → Finds: payment-idempotency.md, coupon-business-rules.md
  3. Evaluates: "Is this context sufficient?" If not → asks you
  4. Writes lattice/specs/coupon-redemption/spec.md:
     - AC-1: Redeem valid coupon → 200, balance deducted
     - AC-2: Redeem expired coupon → 400, no side effects
     - AC-3: Concurrent redemption → only one succeeds (idempotency)
     - execution_mode: tdd  # model-selected | project-default | user-override
     ...
```

The durable output is a compact `spec.md` with Intent, Scope, Context, Acceptance Criteria, Design Decisions, Risk Notes, Execution Policy, and Verification Plan.

### Phase 2: Planning — AC-Traced Tasks

The agent turns the spec into `lattice/specs/<id>/plan.md`. Every task references Scope or `AC-{n}`. If the spec uses `execution_mode: tdd`, the plan must include red-test-first tasks before implementation tasks.

### Phase 3: Implementation — Plan or TDD Policy

Implementation follows the execution policy declared in the spec:

- `plan`: implement from the reviewed plan with necessary tests.
- `tdd`: write failing AC-traced tests first, then implementation, then refactor.

In both modes, tests can trace back to spec AC numbers:

```go
// Test names trace back to spec AC numbers
func TestAC1_RedeemValidCoupon(t *testing.T) { ... }
func TestAC2_RedeemExpiredCoupon(t *testing.T) { ... }
func TestAC3_ConcurrentRedemption(t *testing.T) { ... }
```

```python
# Python equivalent
def test_ac1_redeem_valid_coupon(): ...
def test_ac2_redeem_expired_coupon(): ...
```

```typescript
// Node equivalent
describe('AC-1: Redeem valid coupon', () => { ... })
describe('AC-2: Redeem expired coupon', () => { ... })
```

### Phase 4: Verification — Independent Gate Pipeline

Before declaring completion, the agent runs the pipeline:

```
$ bash lattice/kernel/delivery/pipeline.sh

══════════════════════════════════
Lattice — Delivery Pipeline
Project: my-api (go)
══════════════════════════════════

🔄 [1] bootstrap            → lattice/kernel/delivery/bootstrap.sh check
✅ [1] bootstrap            PASS

🔄 [2] spec-lint            → lattice/kernel/delivery/gates/spec-lint.sh
✅ [2] spec-lint            PASS

🔄 [3] build                → go build ./...
✅ [3] build                PASS

🔄 [4] lint                 → go vet ./...
✅ [4] lint                 PASS

🔄 [5] unit-test            → go test ./... -short -count=1
✅ [5] unit-test            PASS

🔄 [6] ac-coverage          → lattice/kernel/delivery/gates/ac-coverage.sh
📋 AC Coverage: 3/3 (100%)
✅ [6] ac-coverage          PASS

🔄 [7] drift-check          → lattice/kernel/delivery/gates/drift-check.sh
✅ [7] drift-check          PASS

══════════════════════════════════
📊 Pipeline: ✅ 7  ❌ 0  ⏭️  0 / 7 total steps
✅ ALL PASS
```

**On failure**, the agent reads the output, fixes the issue, and re-runs — up to 3 retries. After exhausting retries, exit code `2` triggers escalation: the agent stops self-repairing and outputs a diagnostic report for human intervention.

### Phase 5: Finishing — Evidence and Knowledge

After verification passes, the agent writes `lattice/specs/<id>/summary.md`, links commands and gate evidence, records deferred work, and extracts only reusable lessons through `/learn`.

---

## Gate Reference

### spec-lint — Spec Structure Validation

Validates that the spec document contains all required sections, has sequential AC numbering, proper JSON formatting, and risk review coverage.

```bash
bash lattice/kernel/delivery/gates/spec-lint.sh [spec-file]
```

**Configurable** via `manifest.yaml`:

```yaml
specs:
  required_sections:
    - "Intent"
    - "Scope"
    - "Context"
    - "Acceptance Criteria"
    - "Design Decisions"
    - "Execution Policy"
    - "Verification Plan"
  risk_categories:
    - "Financial Safety"
    - "Technical Risk"
    - "Data Risk"
    - "Release Process"
```

Checks performed:
- Required section presence (configurable list)
- AC numbering continuity (AC-1, AC-2, ... no gaps)
- No `//` comments in JSON blocks
- DDL table count
- Mermaid diagram count (recommends ≥ 2)
- Decision log completeness
- Risk review category coverage
- Financial safety section (auto-triggered when asset keywords detected)

### ac-coverage — Acceptance Criteria Traceability

Maps spec AC numbers to test function names, producing a coverage matrix.

```bash
bash lattice/kernel/delivery/gates/ac-coverage.sh [spec-file] [search-dir]
bash lattice/kernel/delivery/gates/ac-coverage.sh --deep [spec-file] [search-dir]
```

| Language | Test File Pattern | Function Regex |
|----------|------------------|----------------|
| Go | `*_test.go` | `func TestAC{nn}_` or `func Test_AC{nn}_` |
| Node/TS | `*.test.ts`, `*.spec.js` | `describe/it/test` containing `AC-{nn}` |
| Python | `test_*.py` | `def test_ac{nn}_` |

Output:

```
📋 AC Coverage Matrix:

| AC | Spec Description | Test Function | Status |
|----|------------------|---------------|--------|
| AC-1 | Create item      | TestAC1_CreateItem | ✅ |
| AC-2 | Get item         | TestAC2_GetItem    | ✅ |
| AC-3 | Item not found   | —                  | ❌ Uncovered |

📊 AC Coverage: 2/3 (66%)
❌ FAIL — uncovered: AC-3
```

**Deep mode** (`--deep`) additionally detects:
- Tests containing `t.Skip` / `pytest.skip` (not actually running)
- Tests with zero assertions (empty test bodies)

### drift-check — Spec↔Code Drift Detection

Detects divergence between the spec document and the actual codebase.

```bash
bash lattice/kernel/delivery/gates/drift-check.sh [spec-file] [project-root]
```

| Drift Type | What It Compares | Supported ORMs/Frameworks |
|-----------|-----------------|--------------------------|
| **DDL drift** | Spec `CREATE TABLE` columns vs ORM model tags | GORM (full) · Prisma, Sequelize, SQLAlchemy (planned) |
| **Route drift** | Spec API table vs code route registrations | Gin, Echo, Chi (full) · Express, FastAPI (planned) |
| **Error code drift** | Spec error code table vs code constants | Go (full) |
| **Seed SQL drift** | Spec seed SQL vs `fixtures/seed.sql` | All languages |
| **Plugin drift** | Custom checks via `drift.plugins[]` | Any (user-defined) |

Extend with custom plugins:

```yaml
drift:
  plugins:
    - name: proto-check
      run: "bash scripts/proto-drift.sh ${SPEC_FILE} ${PROJECT_ROOT}"
```

### compliance — Behavioral Compliance Audit

Soft gate that checks whether the agent followed Lattice behavioral rules during development.

```bash
bash lattice/kernel/delivery/gates/compliance.sh [spec-file]
bash lattice/kernel/delivery/gates/compliance.sh --strict [spec-file]
```

Checks:
- Does the spec reference knowledge base entries?
- Do recent commits show knowledge-related activity?
- Does the spec contain clarification/confirmation records?

Default is a **soft gate** (warnings only, exit 0). Use `--strict` to treat warnings as failures.

### spec-lock — Multi-Agent Write Lock

File-based lock preventing concurrent spec edits in multi-agent setups.

```bash
bash lattice/kernel/delivery/gates/spec-lock.sh acquire <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh release <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh status <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh clean    # Remove expired locks (>1h)
```

---

## Knowledge Layer

### How Retrieval Works

```bash
$ bash lattice/kernel/knowledge/loader.sh payment concurrency

🔍 Searching keywords: payment concurrency

────────────────────────────────
📄 payment-idempotency.md (matched keyword: payment)
────────────────────────────────
# Payment Idempotency Rules
- All payment mutations require an idempotency key...

📊 Loaded 1 knowledge entries
```

1. **Exact match**: Keyword is searched in `knowledge/index.md`
2. **Synonym expansion**: If no exact match, `synonyms.txt` maps related terms (e.g., "payment" → "fund", "charge", "deduct")
3. **Output**: Matching knowledge file contents are printed for the agent to consume

### Knowledge Index Format

```markdown
# Knowledge Index

- `payment-idempotency` | keywords: payment, idempotency, fund | All payment ops need idempotency keys
- `naming-rules` | keywords: naming, convention, style | API and code naming standards
- `auth-flow` | keywords: auth, login, token | OAuth2 + JWT refresh flow
```

### Central Knowledge Sync

Share knowledge across projects via a central repository:

```yaml
knowledge:
  local_dir: "lattice/knowledge"
  central:
    repo: "https://github.com/your-org/knowledge.git"
    mode: read-only        # read-only | read-write
    conflict: prefer-local  # prefer-local | prefer-remote | fail
```

```bash
bash lattice/kernel/knowledge/sync.sh pull    # Pull from central
bash lattice/kernel/knowledge/sync.sh push    # Push local changes
bash lattice/kernel/knowledge/sync.sh status   # View sync status
```

---

## Agent Skills

Lattice exposes PrismSpec as a small AI Coding skill chain (slash commands in Claude Code; natural language in other agents):

| Skill | Trigger | What It Does |
|-------|---------|-------------|
| **init** | `/init` | Interactive project setup: detect language → generate manifest → copy scaffold → inject rules |
| **sdd** | `/sdd "requirement"` | Guide or resume the full PrismSpec workflow from existing artifacts |
| **brainstorm** | `/brainstorm` | Clarify intent, load knowledge, and write persistent `spec.md` |
| **plan** | `/plan` | Decompose `spec.md` into AC-traced `plan.md` |
| **implement** | `/implement` | Execute `plan` or `tdd` policy from the spec |
| **verify** | `/verify` | Run the full delivery pipeline |
| **finish** | `/finish` | Close delivery, link evidence, and extract durable knowledge |
| **learn** | `/learn "lesson"` | Write a knowledge entry to `knowledge/`, update index |

The core chain is `Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing`. `/sdd` is the guided entry point for that chain: it resolves the spec, mode, and next stage, then delegates to the stage skills. In standalone PrismSpec, artifacts live under `prismspec/specs/`; in Lattice-hosted mode, knowledge loading, spec templates, AC naming, drift detection, and delivery gates are activated via `rules.md` and the skill files.

Implementation can also generate file-backed evidence under `.lattice/sdd/` with `task-brief.sh` and `review-package.sh`, so agents/reviewers read compact files instead of pasted briefs or diffs.

---

## Language Support Matrix

| Feature | Go | Node/TS | Python | Rust | Java |
|---------|:---:|:---:|:---:|:---:|:---:|
| Project detection | ✅ `go.mod` | ✅ `package.json` | ✅ `pyproject.toml` | ✅ `Cargo.toml` | ✅ `pom.xml` |
| Framework detection | Gin, Echo, Chi | Express, NestJS, Koa, Fastify | FastAPI, Flask, Django | — | — |
| ORM detection | GORM, Ent | Sequelize, Prisma, TypeORM | SQLAlchemy | — | — |
| AC coverage | ✅ | ✅ | ✅ | — | — |
| DDL drift | ✅ GORM | Planned | Planned | — | — |
| Route drift | ✅ Gin/Echo/Chi | Planned | Planned | — | — |
| Error code drift | ✅ | — | — | — | — |

---

## Agent Compatibility

Lattice works with any AI coding agent that can (a) read a rules file and (b) execute shell commands.

| Agent | Integration | Docs |
|-------|------------|------|
| **Claude Code** | `CLAUDE.md` `@import` + `.claude/commands/` | Built-in (default) |
| **Cursor** | `.cursorrules` `@file` directive | [docs/adapters/cursor.md](docs/adapters/cursor.md) |
| **Aider** | `--read` flag or `.aider.conf.yml` | [docs/adapters/aider.md](docs/adapters/aider.md) |
| **Superpowers** | Phase override mapping | [docs/adapters/superpowers.md](docs/adapters/superpowers.md) |
| **Any other** | Load `rules.md` into system prompt; invoke scripts via shell | [docs/adapters/README.md](docs/adapters/README.md) |

---

## CLI Reference

All commands support `--help`. Exit codes: `0` success · `1` failure (retryable) · `2` escalation (needs human).

### Pipeline

```bash
# Run full pipeline
bash lattice/kernel/delivery/pipeline.sh

# Run specific step only
bash lattice/kernel/delivery/pipeline.sh --only=build

# Specify spec file
bash lattice/kernel/delivery/pipeline.sh --spec=lattice/specs/my-feature.md

# Skip spec-related or integration steps
bash lattice/kernel/delivery/pipeline.sh --skip-spec
bash lattice/kernel/delivery/pipeline.sh --skip-integration
```

### Individual Gates

```bash
# Spec lint
bash lattice/kernel/delivery/gates/spec-lint.sh <spec-file>

# AC coverage
bash lattice/kernel/delivery/gates/ac-coverage.sh <spec-file> <search-dir>
bash lattice/kernel/delivery/gates/ac-coverage.sh --deep <spec-file> <search-dir>

# Drift check
bash lattice/kernel/delivery/gates/drift-check.sh <spec-file> <project-root>

# Compliance audit
bash lattice/kernel/delivery/gates/compliance.sh <spec-file>
bash lattice/kernel/delivery/gates/compliance.sh --strict <spec-file>

# Spec lock
bash lattice/kernel/delivery/gates/spec-lock.sh acquire|release|status|clean <spec-file>
```

### Knowledge

```bash
# Search by keyword
bash lattice/kernel/knowledge/loader.sh <keyword1> [keyword2] ...

# List all entries
bash lattice/kernel/knowledge/loader.sh --list

# Output all knowledge
bash lattice/kernel/knowledge/loader.sh --all

# Sync with central repo
bash lattice/kernel/knowledge/sync.sh pull|push|status
```

### Bootstrap & Deploy

```bash
# Check environment readiness
bash lattice/kernel/delivery/bootstrap.sh check

# Start local services (reads manifest services.local)
bash lattice/kernel/delivery/bootstrap.sh local

# Deploy to test (optional, Docker+K8s example)
bash lattice/kernel/delivery/deploy.sh test|rollback|status
```

---

## Configuration Reference

Lattice reads all configuration from a single `manifest.yaml`. Here's a complete reference:

<details>
<summary><strong>Full manifest.yaml reference (click to expand)</strong></summary>

```yaml
# ── Project identity ──
project:
  name: my-api
  language: go                          # go | node | python | rust | java
  version_constraint: ">=1.22"

# ── Layer control ──
kernel:
  layers:
    orchestrator: true
    knowledge: true
    delivery: true

# ── Tool requirements ──
tools:
  required:
    - { name: go, check: "go version" }
    - { name: yq, check: "yq --version" }
  optional:
    - { name: docker, check: "docker --version" }

# ── Service dependencies ──
services:
  local:
    - name: mysql
      health: "mysqladmin ping -h127.0.0.1 -uroot --silent"
      start: "docker compose up -d mysql"
      post_start:
        - "mysql -h127.0.0.1 -uroot -e 'CREATE DATABASE IF NOT EXISTS mydb'"
  test:
    - name: mysql
      health: "mysqladmin ping -htest-mysql.example.com --silent"

# ── Build/test commands ──
commands:
  build: "go build ./..."
  lint: "go vet ./..."
  test: "go test ./... -short -count=1"
  integration_test: "go test ./tests/integration/... -tags=integration"
  smoke_test: "curl -sf http://localhost:8080/health"

# ── Spec configuration ──
specs:
  dir: "lattice/specs"
  active: ""                            # optional: spec id under specs.dir or a direct path
  template: "lattice/kernel/orchestrator/templates/spec-template.md"
  default_execution_mode: "auto"        # auto | plan | tdd
  allow_execution_mode_override: true
  required_sections:                    # Override defaults
    - "Intent"
    - "Scope"
    - "Context"
    - "Acceptance Criteria"
    - "Design Decisions"
    - "Execution Policy"
    - "Verification Plan"
  risk_categories:                      # Override defaults
    - "Financial Safety"
    - "Technical Risk"
    - "Data Risk"
    - "Release Process"

# ── Test strategy ──
testing:
  strategies:
    go:
      file_pattern: "*_test.go"
      func_regex: 'func Test(AC|_AC)([0-9]+)'

# ── Drift detection ──
drift:
  ddl:
    orm: gorm                           # gorm | sequelize | prisma | sqlalchemy
    model_tag: "column:"
    model_dirs: ["internal/model"]
  routes:
    framework: gin                      # gin | echo | chi | express | fastapi
    router_pattern: '\.(GET|POST|PUT|DELETE|PATCH)\("([^"]+)"'
  error_codes:
    const_pattern: '(Code|Err)[A-Za-z]+ *= *[0-9]+'
  plugins: []                           # Custom drift checks

# ── Pipeline steps ──
pipeline:
  steps:
    - { name: bootstrap,        run: "lattice/kernel/delivery/bootstrap.sh check",              skip_when: never }
    - { name: spec-lint,        run: "lattice/kernel/delivery/gates/spec-lint.sh ${SPEC_FILE}",      skip_when: no_spec }
    - { name: build,            run: "${commands.build}",                                   skip_when: no_code }
    - { name: lint,             run: "${commands.lint}",                                    skip_when: no_code }
    - { name: unit-test,        run: "${commands.test}",                                    skip_when: no_code }
    - { name: ac-coverage,      run: "lattice/kernel/delivery/gates/ac-coverage.sh ${SPEC_FILE} .",  skip_when: no_spec }
    - { name: integration-test, run: "${commands.integration_test}",                        skip_when: no_integration }
    - { name: drift-check,      run: "lattice/kernel/delivery/gates/drift-check.sh ${SPEC_FILE} .",  skip_when: no_spec }
    - { name: compliance,       run: "lattice/kernel/delivery/gates/compliance.sh ${SPEC_FILE}",     skip_when: no_spec }

# ── Knowledge base ──
knowledge:
  local_dir: "lattice/knowledge"
  central:
    repo: ""
    mode: read-only
    conflict: prefer-local

# ── Deploy (optional) ──
deploy:
  docker:
    builder_image: "golang:1.22-alpine"
    runner_image: "alpine:3.19"
    dockerfile: "deploy/Dockerfile"
  environments:
    test:
      namespace: "my-api-test"
      manifests: "deploy/k8s/"
      rollback: auto
      smoke_after_deploy: true
```

</details>

---

## Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Inject into agents, don't build one** | Orchestration is a solved problem. Lattice only adds context and verification. | Depends on agent's ability to follow prompt instructions |
| **Pure bash, no runtime dependencies** | Zero install friction. Works on any Unix system with bash 4+ and yq. | Limited to what bash can express; no built-in UI |
| **flow.yaml is a guide, not a state machine** | Agent interfaces vary too widely for hardcoded transitions | Rule compliance relies on prompt engineering + post-hoc audit |
| **Keyword matching, not semantic search** | Zero external dependencies, works offline, sufficient at hundreds of entries | Weak recall for paraphrases; requires manual index maintenance |
| **Gates verify structure, not semantics** | Deterministic criteria, mechanically executable, no false positives | Does not replace human code review |
| **Single manifest.yaml** | One file to understand a project's entire harness config | File grows with project complexity |

## Known Limitations

- **Drift detection is regex-based**: Does not cover dynamic routes, nested ORM relationships, or gRPC protobuf. Extensible via `drift.plugins[]`.
- **Knowledge retrieval is keyword-based**: "balance deduction" vs "fund charge" won't match without synonym entries. Synonym table is supported but requires manual maintenance.
- **Compliance is post-hoc**: Cannot force the agent to load knowledge; can only detect that it didn't.
- **Language coverage is uneven**: Full drift detection only for Go (Gin/GORM). Node and Python support is planned.
- **No GUI**: Lattice is CLI-only. Spec review happens in your editor; pipeline output is terminal text.

---

## Upgrading

```bash
# Upgrade kernel only (preserves manifest.yaml, knowledge/, specs/)
./install.sh /path/to/your-project --upgrade
```

The upgrade replaces `lattice/kernel/` and preserves all project-owned data (`manifest.yaml`, `knowledge/`, `specs/`, `plans/`). If an existing kernel is present, it is moved to `lattice/state/kernel-backups/` before replacement.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and PR guidelines.

## License

MIT — see [LICENSE](LICENSE).
