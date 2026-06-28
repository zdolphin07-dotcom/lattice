# PrismSpec

> English version: [README.en.md](README.en.md)

PrismSpec 是一套可独立使用的渐进式 Spec Coding skill pack。它把一次 AI Coding 任务收敛成可恢复、可审查、可验证的文件链路：

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

`/sdd` 是 controller，不是额外阶段。它读取当前产物，判断下一步应该调用哪个 stage skill。

## 定位

PrismSpec 可以单独使用，也可以被 Lattice 托管增强。

| 模式 | 适合谁 | 你会得到什么 | 是否依赖 Lattice |
|------|--------|--------------|------------------|
| Standalone | 只想要 Spec Coding skills 的用户 | 持久化 spec、plan、verify、summary，以及 Plan/TDD 两种执行纪律 | 否 |
| Lattice-hosted | 需要项目级 harness 的团队 | PrismSpec + manifest、项目 context、verification gates、AC coverage、drift check、Evidence / Eval、Loop / Learn | 是 |

PrismSpec 不依赖 Lattice。Lattice 内置 PrismSpec，并把它作为默认 Spec Coding workflow。

## Skill Pack 结构

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
└── bin/                        # deterministic new/guide/lint/doctor helpers
```

`skills/*/SKILL.md` 是唯一 canonical skill source。不要再维护 flat `skills/*.md` 入口，避免同一流程出现多个事实源。

每个 canonical skill 都带有 `agents/openai.yaml`，用于 UI、安装器或 marketplace 展示时读取 `display_name`、`short_description` 和默认调用提示。根目录 `agents/` 仍用于轻量 reviewer persona，两者职责不同。

`skillpack.yaml` 是可分发契约，声明 workflow stages、skills、templates、references、host modes 和质量门禁。Agent、安装器或 wrapper 应该优先读它，而不是从 README 猜目录结构。

## 产物结构

Standalone 默认产物：

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

Lattice-hosted 产物：

```text
lattice/specs/<spec-id>/
├── context.md
├── spec.md
├── plan.md
├── verify.md
└── summary.md

.lattice/sdd/<spec-id>/<task-id>/
```

## 使用入口

先检查 skill pack 是否健康：

```bash
bash prismspec/bin/doctor.sh
```

创建一个初始 spec 目录：

```bash
bash prismspec/bin/new.sh checkout-flow --title="Checkout Flow" --template=service --mode=plan
```

先运行 guide，永远从当前文件状态路由，不从对话记忆猜阶段：

```bash
bash prismspec/bin/guide.sh --json
bash prismspec/bin/guide.sh --spec=checkout-flow --json
bash prismspec/bin/guide.sh --spec=checkout-flow --from=verify --json
```

`--json` 是 Agent wrapper 和 slash command 的推荐协议。关键字段包括：

| 字段 | 含义 |
|------|------|
| `host` | `standalone` 或 `lattice` |
| `spec_id` | 当前 spec id |
| `scaffolded` | 是否仍是 `new.sh` 生成的待填写骨架 |
| `stage` | 下一阶段：`brainstorm`、`plan`、`implement`、`verify`、`finish`、`done` |
| `mode` | `auto`、`plan` 或 `tdd` |
| `skill` | 应读取并执行的 `SKILL.md` |
| `spec_dir` | 当前 spec 目录 |
| `run_dir` | 当前 evidence 目录 |
| `verify_command` | 推荐验证命令 |

## Workflow

`new.sh` 只是初始化 helper，不是 workflow 阶段。它创建的 `spec.md` 会带有 `scaffolded: true`。在 Brainstorming 阶段填完真实 context、scope、AC、risk 和 mode 后，才将其改为 `scaffolded: false`；在此之前 `guide.sh` 会继续路由到 Brainstorming。

| Stage | 目标 | 产物 | 何时停止 |
|-------|------|------|----------|
| Brainstorm | 固化 context basis、scope、AC、risk、mode | `context.md`、`spec.md` | AC 不可测试、关键决策缺失、风险模式无法确认 |
| Plan | 将 spec 拆成 AC-traced tasks | `plan.md` | AC 无法映射到任务或验证路径 |
| Implement | 一次执行一个 planned slice | code、tests、task evidence | 范围漂移、红灯测试不可信、验证失败需产品决策 |
| Verify | 运行外部命令并记录结果 | `verify.md` | 缺凭证、外部服务不可用、失败超出范围 |
| Finish | 汇总证据、风险和知识候选 | `summary.md` | 缺 verification evidence 或 blocker 被伪装成 done |

## 模板

| 模板 | 适用场景 | 重心 |
|------|----------|------|
| `spec-template.md` | 默认通用需求 | Intent、Scope、AC、关键契约、风险、验证 |
| `spec-template-lite.md` | 文档、配置、低风险 Plan Mode 改动 | AC-first，尽量少写设计 |
| `spec-template-service.md` | 后端服务、API、数据模型、状态流转 | API、DDL、错误码、幂等、补偿 |
| `spec-template-frontend.md` | 前端体验、产品主链路、交互改造 | 用户路径、状态、可访问性、视觉/交互验收 |
| `spec-template-tdd.md` | bug fix、核心链路、高风险改动 | 回归场景、红灯测试、不可破坏不变量 |

模板选择原则：能用 `lite` 就不要制造文档成本；涉及权限、安全、资金、幂等、迁移、并发、历史回归时优先 `tdd`；涉及 API、数据、状态时优先 `service`；涉及 UX 状态和可访问性时优先 `frontend`。

## 执行模式

PrismSpec 只支持两种 implementation policy：

| 模式 | 适用场景 | 必须产生 |
|------|----------|----------|
| `plan` | 低风险功能、文档、配置、简单重构、已有测试覆盖充分的改动 | AC-traced plan、相关测试或 no-test rationale、verification evidence |
| `tdd` | bug fix、权限、安全、资金、状态机、迁移、并发、幂等、历史回归 | red test、green test、AC-to-test trace、回归验证 |

`auto` 表示由模型按风险选择。发现风险后允许 `plan -> tdd` 升级；不允许静默 `tdd -> plan` 降级，除非用户显式覆盖并记录风险。

## Canonical Skills

| Skill | 触发场景 | Durable output |
|-------|----------|----------------|
| `skills/sdd/SKILL.md` | `/sdd`、恢复 spec、端到端引导 | 阶段路由 |
| `skills/brainstorm/SKILL.md` | 新需求、范围/AC/mode/context 不清 | `context.md`、`spec.md` |
| `skills/plan/SKILL.md` | spec 已有但任务和验证路径缺失 | `plan.md` |
| `skills/implement/SKILL.md` | 执行 AC-traced tasks | code、tests、task evidence |
| `skills/verify/SKILL.md` | 实现后运行外部验证 | `verify.md` |
| `skills/finish/SKILL.md` | 验证后收尾、风险和 outcome | `summary.md` |
| `skills/learn/SKILL.md` | 捕获可复用规则、决策、踩坑 | knowledge draft / project knowledge |

每个 canonical skill 都遵循高质量 skill 的基本结构：frontmatter 触发语义、工作流、输入输出、停机条件、常见跳步借口、红旗和验证清单。

## Lint

Closeout 前运行：

```bash
bash prismspec/bin/doctor.sh
bash prismspec/bin/lint.sh prismspec skillpack
bash prismspec/bin/lint.sh prismspec/specs/checkout-flow
bash prismspec/bin/lint.sh lattice/specs/checkout-flow
```

`doctor` 会检查 PrismSpec 在 standalone 或 Lattice-hosted 模式下是否可用，包括 skillpack contract、guide JSON 协议和宿主环境。

`skillpack` 会检查 PrismSpec 分发包自身：

- `skillpack.yaml` 的 entrypoints、workflow stages 和 quality gates；
- canonical `skills/*/SKILL.md` 的 frontmatter、触发描述、核心章节和 `agents/openai.yaml`；
- templates、references、command、guide/lint 脚本是否齐全；
- 是否误引入 flat skill wrappers。

artifact lint 会检查：

- `spec.md` 是否包含 AC、execution mode、risk、verification plan；
- `plan.md` 是否引用 AC、包含稳定任务 ID 和验证步骤；
- `verify.md` 或 `summary.md` 是否记录真实命令/结果证据；
- TDD 模式是否包含 red-test task。

## References 与 Reviewers

长规则放在 `references/`，按需加载，避免 `SKILL.md` 膨胀：

| Reference | 作用 |
|-----------|------|
| `mode-selection.md` | 判断 Plan/TDD 与升级规则 |
| `spec-quality-checklist.md` | 检查 spec 是否可审、可执行、可验证 |
| `tdd-evidence-checklist.md` | 约束 red/green evidence |
| `review-evidence-checklist.md` | 统一 pass/fail/cannot_verify |
| `definition-of-done.md` | closeout 完成标准 |

`agents/` 提供轻量 reviewer persona：spec compliance、code quality、test coverage。它们不绑定某个 Agent runtime。

## 设计原则

- Spec 是契约，不是长文档。
- 流程只在能产生持久产物或避免真实风险时才存在。
- Context 先给地图，再由 Agent 按需发现、筛选和压缩。
- Verification 必须由真实命令和 evidence 支撑。
- Plan Mode 和 TDD Mode 是同一流程内的执行策略，不是两套流程。
- 多一个流程就多一层人工损耗，默认保持克制。
