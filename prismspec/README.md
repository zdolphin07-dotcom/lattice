# PrismSpec

> English version: [README.en.md](README.en.md)

PrismSpec 是一套可独立使用的渐进式 Spec-Driven Development skills，用于 AI Coding。

它只保留一条克制的主流程：

```text
brainstorm -> plan -> implement(plan|tdd) -> verify -> finish
```

## 定位

PrismSpec 可以独立使用，也可以被 Lattice 增强。

| 使用方式 | 你会得到什么 | 是否依赖 Lattice |
|----------|--------------|------------------|
| 独立模式 | 持久化 spec、plan、verify、summary，以及 plan/tdd 两种执行纪律 | 否 |
| Lattice-hosted | PrismSpec + manifest、知识库、交付 gate、AC coverage、drift check、compliance audit | 是 |

PrismSpec 不依赖 Lattice。Lattice 内置 PrismSpec，并把它作为默认的 spec-coding workflow。

## 核心观点

PrismSpec 对 spec 的理解来自三个判断：

1. Spec 不是厚文档，而是对可接受实现空间的最小、可验证编码。
2. Spec 不只有 Requirement，Intent → Code 中间所有显式约束都可以是 Spec，包括 Design 和 Plan。
3. 不存在一套模板适合所有需求。支付、后台 CRUD、前端体验、算法策略、基础设施的 spec 重心应该不同。

因此，PrismSpec 提供多种模板，而不是强制所有需求填同一张表。

## 产物结构

独立模式默认使用：

```text
prismspec/
├── skills/
│   ├── sdd/SKILL.md
│   ├── brainstorm/SKILL.md
│   └── ...
├── references/
├── agents/
├── commands/
├── bin/
├── templates/
└── specs/
    └── {spec-id}/
        ├── spec.md
        ├── plan.md
        ├── verify.md
        └── summary.md

.prismspec/
└── runs/
    └── {spec-id}/
        └── {task-id}/
            ├── brief.md
            └── review-package.md
```

如果项目存在 `lattice/manifest.yaml`，PrismSpec 会进入 Lattice-hosted 模式，并使用 Lattice 的宿主路径：

```text
lattice/specs/{spec-id}/{spec.md,plan.md,summary.md}
.lattice/sdd/{spec-id}/{task-id}/
```

## 流程引导

PrismSpec 提供一个轻量的本地引导脚本，用来判断当前 spec 处于哪个阶段、下一步应该执行哪个 skill：

```bash
bash prismspec/bin/guide.sh
bash prismspec/bin/guide.sh --spec=checkout-flow
bash prismspec/bin/guide.sh --spec=checkout-flow --json
```

它只负责路由和状态识别，不替代 agent 写 spec、plan、代码或验证结论。`--json` 输出是命令入口和 agent wrapper 的推荐协议。

## 质量门禁

PrismSpec 内置轻量 artifact lint，用来在 closeout 前检查 spec、plan 和证据是否满足最小契约：

```bash
bash prismspec/bin/lint.sh prismspec/specs/checkout-flow
bash prismspec/bin/lint.sh lattice/specs/checkout-flow
```

它会检查：

- `spec.md` 是否包含 AC、execution mode、risk、verification plan；
- `plan.md` 是否引用 AC、包含稳定任务 ID 和验证步骤；
- `verify.md` 或 `summary.md` 是否记录真实命令/结果证据；
- TDD 模式是否包含 red-test 任务。

## 模板

| 模板 | 适用场景 | 重心 |
|------|----------|------|
| `spec-template.md` | 默认通用模板 | Intent、Scope、AC、关键契约、风险、验证 |
| `spec-template-lite.md` | 中轻需求、Plan Mode、文档/配置/低风险改动 | AC-first，尽量少写设计 |
| `spec-template-service.md` | 后端服务、API、数据模型、状态流转 | API、DDL、错误码、幂等、补偿 |
| `spec-template-frontend.md` | 前端体验、产品主链路、交互改造 | 用户路径、状态、可访问性、视觉/交互验收 |
| `spec-template-tdd.md` | bug fix、核心链路、高风险改动 | 回归场景、红灯测试、不可破坏不变量 |

模板选择原则：

- 轻需求优先用 `lite`，不要为简单改动制造文档成本。
- 涉及 API、数据、状态、幂等、权限、资金、安全时用 `service` 或 `tdd`。
- 涉及用户体验、前端状态、组件和可访问性时用 `frontend`。
- 不确定时用默认模板，保持 AC 和风险清楚即可。

## 执行模式

PrismSpec 只支持两种实现策略：

| 模式 | 适用场景 | 规则 |
|------|----------|------|
| `plan` | 低风险功能、文档、脚手架、直接重构 | 从已审查的 plan 执行；行为变化需要补测试 |
| `tdd` | bug fix、核心链路、安全/权限/资金逻辑、状态机、迁移、并发、幂等、历史回归点 | 先写红灯测试，再实现绿灯，最后重构 |

`auto` 表示由模型按风险选择 `plan` 或 `tdd`。当后续发现风险高于预期时，允许从 `plan -> tdd` 升级；不允许静默从 `tdd -> plan` 降级，除非用户显式覆盖。

## Skills

| Skill | 作用 |
|-------|------|
| `skills/sdd/SKILL.md` | 引导式 controller，解析当前阶段并从产物恢复 |
| `skills/brainstorm/SKILL.md` | 澄清需求并生成 `spec.md` |
| `skills/plan/SKILL.md` | 把 `spec.md` 拆成可执行、可审查、可追踪 AC 的 `plan.md` |
| `skills/implement/SKILL.md` | 按 plan 或 TDD 策略执行 |
| `skills/verify/SKILL.md` | 运行本地验证并记录证据 |
| `skills/finish/SKILL.md` | 生成 summary，沉淀后续工作和可复用经验 |
| `skills/learn/SKILL.md` | 捕获可复用知识 |

每个 canonical skill 都包含 frontmatter、工作流、输入输出、停机条件、常见跳步借口、红旗和验证清单。旧的 `skills/*.md` 文件保留为兼容入口。

## References 与 Reviewer

PrismSpec 把长规则拆到 `references/`，按需加载：

| Reference | 作用 |
|-----------|------|
| `mode-selection.md` | 判断 plan / tdd 与升级规则 |
| `spec-quality-checklist.md` | 检查 spec 是否可审、可执行、可验证 |
| `tdd-evidence-checklist.md` | 约束 red / green 证据 |
| `review-evidence-checklist.md` | 统一 pass / fail / cannot_verify |
| `definition-of-done.md` | closeout 的完成标准 |

`agents/` 提供轻量 review persona：spec compliance、code quality、test coverage。它们不绑定某个 agent runtime，可以被 Claude Code、Codex 或其他 agent wrapper 使用。

## 设计原则

PrismSpec 只有在一个流程节点能产生持久产物，或能避免真实工程风险时，才引入这个节点。

多一个流程，就多一层人工损耗。因此默认 workflow 保持克制：不是把 AI Coding 变成审批流，而是让需求、计划、实现和验证之间有可追踪的证据链。
