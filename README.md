<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>面向团队的 repo-local AI Coding Control Plane</strong>
  </p>
  <p align="center">
    <a href="README.en.md">English</a> ·
    <a href="docs/wiki/">设计 Wiki</a> ·
    <a href="docs/adapters/">Agent 适配器</a> ·
    <a href="examples/go-gin-gorm/">可运行示例</a> ·
    <a href="CHANGELOG.md">更新日志</a>
  </p>
  <p align="center">
    <a href="https://github.com/zdolphin07-dotcom/lattice/actions/workflows/shellcheck.yml"><img alt="Shellcheck" src="https://github.com/zdolphin07-dotcom/lattice/actions/workflows/shellcheck.yml/badge.svg"></a>
    <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
    <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
    <img alt="Runtime" src="https://img.shields.io/badge/runtime-Bash%204%2B-informational.svg">
  </p>
</p>

---

## Lattice 是什么

Lattice 是面向团队的 repo-local AI Coding control plane。它把个人 AI Coding 中最容易停留在对话里的需求理解、项目上下文、执行策略、验证门禁和交付证据，沉淀为代码仓库内可复用的工程契约，让个人提效持续转化为团队提效。

| 能力层 | 作用 |
|--------|------|
| Specification & Planning | 将需求理解转化为可执行规格、验收标准和任务计划，让 AI Coding 从一开始就有清晰边界 |
| Context Engineering | 将项目知识、历史经验、外部约束和团队规则沉淀在仓库内，让个人判断变成团队可复用上下文 |
| Delivery Verification | 通过 build、lint、test、AC coverage、drift check 和 compliance gates，在交付前验证代码、规格和项目约束一致 |
| Evidence Intelligence | 汇总命令输出、gate 结果、eval run、历史趋势和 outcome，让完成状态、质量风险和改进方向可追踪 |

一句话：**Lattice 把一次次个人 AI Coding 提效，沉淀成团队可复用、可审查、可验证的工程能力。**

## 解决什么问题

个人使用 AI Coding 很容易提效，但团队落地时常见的问题是：

- 需求、假设和关键上下文停留在对话里，下一次任务难以恢复；
- Agent 写了代码，但缺少可审查的规格、计划和 review 证据；
- “完成了”依赖主观总结，而不是 fresh command output；
- 个人踩过的坑、项目规则和验证经验没有沉淀成团队资产。

Lattice 的目标是把这些隐性的个人过程，变成仓库内可版本化、可审查、可验证的工程资产。

## 为什么不是只用普通 AI Coding

| 普通 AI Coding | Lattice |
|---|---|
| 需求和假设留在对话里 | 写入 `spec.md`，包含 Context Basis、AC 和风险边界 |
| Agent 用总结声明完成 | `verify.md` 记录命令、退出码、结果和残留风险 |
| 每次任务重新理解项目 | `lattice/context/` 沉淀项目地图、规则、踩坑和外部约束 |
| Review 依赖临时提示词 | `review.md` 记录只读 verdict、发现项和风险处置 |
| 经验难复用 | knowledge draft / promotion 把可复用经验沉淀回项目 |

## 你会得到什么

一次 Lattice 驱动的 AI Coding 任务，会在仓库里留下清晰的交付链路：

| 产物 | 作用 |
|------|------|
| `spec.md` | 需求、Context Basis、Scope、AC、风险和验证计划 |
| `plan.md` | 按 AC 拆分的实现任务、文件边界和验证命令 |
| `review.md` | 只读 review verdict、发现项和风险处置 |
| `verify.md` | 命令、退出码、验证结果、残留风险和知识候选 |
| `lattice/state/eval-runs/*.json` | 可查询、可汇总、可用于 CI/dashboard 的结构化交付证据 |

示例验证摘要：

```text
Spec: lattice/specs/create-item-api/spec.md
Review: pass
AC Coverage: 4/4
Drift: none
Command: lattice/kernel/delivery/pipeline.sh --json-out
Result: pass
Evidence: lattice/state/eval-runs/example.json
```

## 可靠性与安全边界

Lattice 设计为安装在业务仓库内的工程控制面，因此默认遵守这些边界：

- 不接管 IDE、不替代 Coding Agent、不绑定模型供应商；
- 不上传代码或项目知识，默认资产留在当前仓库；
- 不覆盖项目资产：`manifest.yaml`、`context/`、`specs/` 由项目持有；
- 不替代测试系统，只组织 build、lint、test、drift、compliance 等验证证据；
- 框架代码和项目资产分离，`kernel/` 与 PrismSpec 可升级，业务规格和知识可审查。

## 快速开始

### 安装到目标项目

```bash
# 在你的业务仓库内执行
cd /path/to/your-project
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# 或先本地克隆，再安装到当前业务仓库
git clone https://github.com/zdolphin07-dotcom/lattice.git /tmp/lattice
/tmp/lattice/install.sh "$PWD" --init
```

前置依赖：Bash 4+、`yq` 4.x、`git`。

安装会新增 `lattice/`、`prismspec/` 和 Agent 入口文件。升级时 `kernel/` 与 PrismSpec 框架代码可刷新，`lattice/manifest.yaml`、`lattice/context/`、`lattice/specs/` 等项目资产不应被覆盖。

### 运行示例

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

示例会演示目录化 spec、`spec.md` 内嵌 Context Basis、spec lint、AC coverage、drift check 和 context knowledge backend。

## 推荐采用路径

1. 先运行 `examples/go-gin-gorm/try-it.sh`，确认本地依赖和验证输出。
2. 安装到一个非关键业务仓库，运行 `lattice/kernel/doctor.sh`。
3. 用 PrismSpec 跑一个小功能或 bug fix，生成 `spec.md`、`plan.md`、`review.md`、`verify.md`。
4. 在 CI 中接入 Lattice pipeline 或至少运行 `spec-lint` / `ac-coverage` / `drift-check`。
5. 把重复出现的规则、踩坑和验证经验提升到 `lattice/context/knowledge/`。

## 核心工作流

```text
Intent -> Clarify -> Spec -> Build -> Review -> Verify
```

`/prismspec` 是引导入口，不是额外阶段。它根据已有产物自动路由：

```bash
bash prismspec/bin/guide.sh --json
```

PrismSpec 的设计重点不是多一层文档，而是让 AI Coding 的关键决策离开对话窗口，进入可恢复的契约链和证据链。对用户呈现为五个产品板块，底层仍由 Agent Skills-compatible skill folders、命令 gates 和 evidence 驱动：

| Block | 目标 | 主要产物 |
|---|---|---|
| Clarify | 明确 intent、上下文依据、假设、冲突和阻塞问题 | `spec.md#Context Basis` |
| Spec | 固化 scope、non-goals、AC、risk、mode 和验证计划 | `spec.md` |
| Build | 拆 plan、执行 plan/TDD 切片、处理调试和任务证据 | `plan.md`、task evidence、TDD/debug evidence |
| Review | 独立审查实现证据、diff 和质量风险 | `review.md` |
| Verify | 运行真实命令或 Lattice pipeline 证明完成状态 | `verify.md` |

机器侧证据，例如 task brief、review package、`review-summary.json`、eval run JSON 和 TDD/debug evidence，属于 pipeline 与恢复机制的输入输出，不是人读主产物。

`/capture` 是后处理命令，只把 `verify.md` 或 review evidence 中可复用、非敏感、可审计的经验沉淀到知识库；不属于默认交付链路的必需阶段。

Plan Mode 和 TDD Mode 不是两套流程，只是 implementation 阶段的执行策略：

| 模式 | 适用场景 | 证据要求 |
|------|----------|----------|
| `plan` | 文档、配置、低风险功能、简单重构、已有测试覆盖充分的改动 | `plan.md`、必要测试、验证命令 |
| `tdd` | bug fix、权限、安全、状态机、并发、幂等、迁移、历史回归 | red test、green test、AC-to-test trace、完整相关验证 |

项目可在 `lattice/manifest.yaml` 设置默认模式；用户也可以对单次 spec 指定模式。发现风险时允许 `plan -> tdd` 升级；`tdd -> plan` 需要显式用户 override。

## 安装后的项目结构

```text
your-project/
├── CLAUDE.md
├── lattice/
│   ├── manifest.yaml
│   ├── config/
│   │   └── failure-categories.yaml
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

`kernel/` 是可升级的框架代码；`manifest.yaml`、`context/`、`specs/` 是项目资产，升级时不应覆盖。

## 组件模型

上面的能力层是用户视角；下面的组件模型是仓库内实现视角。

| 组件 | 职责 | 关键路径 |
|------|------|----------|
| PrismSpec | 可独立使用的 Spec Coding skill pack | `prismspec/skills/`、`prismspec/bin/`、`prismspec/templates/` |
| Orchestrator | Agent 行为规则、阶段定义、模板入口、状态推进 | `lattice/kernel/orchestrator/` |
| Context | 上下文地图、项目知识、外部知识入口、可选检索后端 | `lattice/context/`、`lattice/kernel/context/` |
| Verification | 可复现验证 pipeline 与 gates | `lattice/kernel/delivery/` |
| Evidence / Eval | gate output、结构化 eval run、Markdown summary、history report 与 outcome | `lattice/state/eval-runs/*.json`、`*.md`、AC coverage、drift diagnostics |

## 常用命令

| 场景 | 命令 |
|------|------|
| 检查安装健康度 | `bash lattice/kernel/doctor.sh` |
| 检查 PrismSpec standalone 健康度 | `bash prismspec/bin/doctor.sh` |
| 创建初始 spec 目录 | `bash prismspec/bin/new.sh checkout-flow --template=service --mode=plan` |
| 查看 PrismSpec 下一步 | `bash prismspec/bin/guide.sh --json` |
| 校验 PrismSpec skill pack | `bash prismspec/bin/lint.sh prismspec skillpack` |
| 校验 spec / plan / evidence | `bash prismspec/bin/lint.sh lattice/specs/<spec-id>` |
| 运行完整验证 pipeline | `bash lattice/kernel/delivery/pipeline.sh --json-out` |
| 只运行某个 gate | `bash lattice/kernel/delivery/pipeline.sh --only=spec-lint` |
| 查看下一项任务 | `bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json` |
| 受控完成任务 | `bash lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> T1 --json` |
| 检查任务证据 | `bash lattice/kernel/orchestrator/sdd/task-evidence-lint.sh <spec-id>` |
| 推进 spec 状态 | `bash lattice/kernel/orchestrator/sdd/spec-status.sh <spec-id> planned --from=drafted` |
| 写入 review verdict | `bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> branch --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass` |
| 从知识候选生成 knowledge draft | `bash lattice/kernel/context/summary-learn-draft.sh <spec-id>` |
| 渲染 eval 摘要 | `bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json` |
| 汇总 eval 历史 | `bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md` |
| 发布 central eval sink | `bash lattice/kernel/delivery/eval-sink.sh publish --sink-dir=lattice/state/eval-sink` |
| 生成静态 dashboard | `bash lattice/kernel/delivery/eval-dashboard.sh --sink-dir=lattice/state/eval-sink --out=lattice/state/eval-sink/dashboard.html` |
| 查询 central eval sink | `bash lattice/kernel/delivery/eval-query.sh summary --sink-dir=lattice/state/eval-sink` |
| Review knowledge draft | `bash lattice/kernel/context/knowledge-review.sh approve lattice/context/drafts/<draft>.md --reviewer=<name> --reason=<reason> --conflicts-checked` |
| Promote knowledge draft | `bash lattice/kernel/context/learn-draft.sh promote lattice/context/drafts/<draft>.md --require-review --to=lattice/context/knowledge/pitfalls.md` |

更完整的命令协议见 [设计 Wiki](docs/wiki/) 和各脚本的 `--help`。

## 当前状态

Lattice 当前已经具备 **repo-local AI Coding control plane 的最小可信闭环**：

> Lattice 仍处于早期迭代阶段。当前版本适合在非关键仓库、团队试点或新需求链路中逐步采用；不同技术栈、复杂 CI、多人协作和长期治理场景仍可能暴露边界问题。项目会持续根据真实使用反馈收敛契约、增强验证能力，并扩展更多语言和团队协作场景。

| 能力 | 状态 | 证据 |
|------|------|------|
| Repo-local install/init | Available | `install.sh --init`、`lattice/kernel/doctor.sh`、smoke test |
| Spec / Plan / Review / Verify artifacts | Available | `new.sh`、`guide.sh --json`、`lint.sh prismspec skillpack` |
| Delivery pipeline | Available | spec lint、AC coverage、drift check、compliance gates |
| Go/Gin/GORM drift parser | Available | `examples/go-gin-gorm/try-it.sh` |
| Evidence summary/history/outcome | Available | `eval-runs/*.json`、Markdown summary/history、outcome link/report |
| Dashboard trend analysis | Planned | static dashboard 已有，趋势分析仍在演进 |
| Node / Python drift parser | Planned | 作为后续多语言扩展 |
| Multi-agent owner / lease model | Planned | 作为团队协作扩展 |

仍在演进：

- dashboard 趋势增强和跨项目归因；
- 更强的语义冲突治理；
- Node/Python 等更多 drift parser；
- 插件 manifest/schema/versioning；
- 多 Agent owner / lease 模型。

## 文档导航

| 文档 | 内容 |
|------|------|
| [设计 Wiki](docs/wiki/) | 系统设计、SDD、Context、Eval、Loop、Roadmap |
| [五板块工作台](docs/wiki/workflow-blocks.md) | Clarify / Spec / Build / Review / Verify 的产品契约 |
| [PrismSpec README](prismspec/README.md) | 独立 Spec Coding skill pack |
| [Agent adapters](docs/adapters/) | Claude Code、Cursor、Aider、Superpowers、Agent Skills 等适配说明 |
| [示例项目](examples/go-gin-gorm/) | 可运行示例 |
| [贡献指南](CONTRIBUTING.md) | 开发、测试、贡献规范 |

## 设计原则

- Spec 是契约，不是长文档。
- 当前代码、测试、schema 和运行输出仍是真相源。
- Context 先给地图，再由 Agent 按需发现、筛选和压缩。
- 验证必须由外部命令和证据支撑。
- PrismSpec 可独立使用，Lattice 负责项目级增强。
- 所有扩展通过文件、YAML 和命令 contract 接入。

## License

MIT
