<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>面向团队的 repo-local AI Coding Harness</strong>
  </p>
  <p align="center">
    <a href="README.en.md">English</a> ·
    <a href="docs/wiki/">设计 Wiki</a> ·
    <a href="docs/adapters/">Agent 适配器</a> ·
    <a href="examples/go-gin-gorm/">可运行示例</a> ·
    <a href="CHANGELOG.md">更新日志</a>
  </p>
</p>

---

## Lattice 是什么

Lattice 是安装到业务仓库里的 AI Coding 工程框架。它不替代 Claude Code、Cursor、Aider 或其他 Agent，而是给它们提供一组可版本化、可审查、可验证的项目契约：

| 能力 | 作用 |
|------|------|
| PrismSpec | 将需求沉淀为 `context.md`、`spec.md`、`plan.md`、`verify.md`、`summary.md` |
| Context | 给 Agent 提供项目上下文地图、项目知识、外部知识入口和 per-spec context |
| Delivery | 在交付前运行 build、lint、test、AC coverage、drift check、compliance 等 gates |
| Evidence | 用命令输出、gate 结果和 `eval-runs/*.json` 支撑“完成了”的结论 |

一句话：**Lattice 把个人 AI Coding 经验沉淀成团队可复用的工程资产。**

## 快速开始

### 安装到目标项目

```bash
# 远程安装
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init

# 或本地克隆后安装
./install.sh /path/to/your-project --init
```

前置依赖：Bash 4+、`yq` 4.x、`git`。

### 运行示例

```bash
git clone https://github.com/zdolphin07-dotcom/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

示例会演示目录化 spec、per-spec context、spec lint、AC coverage、drift check 和 context knowledge backend。

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
│   │   └── eval-runs/
│   └── specs/
│       └── <spec-id>/
│           ├── context.md
│           ├── spec.md
│           ├── plan.md
│           ├── verify.md
│           └── summary.md
└── prismspec/
    ├── skillpack.yaml
    ├── skills/
    ├── templates/
    ├── references/
    └── bin/
```

`kernel/` 是可升级的框架代码；`manifest.yaml`、`context/`、`specs/` 是项目资产，升级时不应覆盖。

## 核心工作流

```text
Intent -> Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing
```

`/sdd` 是引导入口，不是额外阶段。它根据已有产物自动路由：

```bash
bash prismspec/bin/guide.sh --json
```

| 阶段 | 目标 | 产物 |
|------|------|------|
| Brainstorming | 固化上下文依据、范围、AC、风险和执行模式 | `context.md`、`spec.md` |
| Planning | 将 spec 拆成 AC-traced tasks | `plan.md` |
| Implementation | 按 Plan Mode 或 TDD Mode 实现 | code、tests、task evidence |
| Verification | 运行独立验证命令或 Lattice pipeline | `verify.md` |
| Finishing | 汇总证据、风险和知识沉淀候选 | `summary.md` |

Plan Mode 和 TDD Mode 不是两套流程，只是 implementation 阶段的执行策略：

| 模式 | 适用场景 | 证据要求 |
|------|----------|----------|
| `plan` | 文档、配置、低风险功能、简单重构、已有测试覆盖充分的改动 | `plan.md`、必要测试、验证命令 |
| `tdd` | bug fix、权限、安全、状态机、并发、幂等、迁移、历史回归 | red test、green test、AC-to-test trace、完整相关验证 |

项目可在 `lattice/manifest.yaml` 设置默认模式；用户也可以对单次 spec 指定模式。发现风险时允许 `plan -> tdd` 升级；`tdd -> plan` 需要显式用户 override。

## 组件模型

| 组件 | 职责 | 关键路径 |
|------|------|----------|
| PrismSpec | 可独立使用的 Spec Coding skill pack | `prismspec/skills/`、`prismspec/bin/`、`prismspec/templates/` |
| Orchestrator | Agent 行为规则、阶段定义、模板入口 | `lattice/kernel/orchestrator/` |
| Context | 上下文地图、项目知识、外部知识入口、可选检索后端 | `lattice/context/`、`lattice/kernel/context/` |
| Delivery | 可复现验证 pipeline 与 gates | `lattice/kernel/delivery/` |
| Evidence | gate output、结构化 Eval run、Markdown summary 与 history report | `lattice/state/eval-runs/*.json`、`*.md`、AC coverage、drift diagnostics |

## 常用命令

```bash
# 初始化目标项目
bash .lattice/framework/init.sh

# 查看 SDD 下一步
bash prismspec/bin/guide.sh --json

# 校验 spec / plan / evidence
bash prismspec/bin/lint.sh lattice/specs/<spec-id>

# 检查安装健康度
bash lattice/kernel/doctor.sh

# 运行完整验证 pipeline
bash lattice/kernel/delivery/pipeline.sh

# 写出结构化 evidence
bash lattice/kernel/delivery/pipeline.sh --json-out

# 写出 review / TDD 语义 evidence
bash lattice/kernel/orchestrator/sdd/review-summary.sh <spec-id> <task-id> --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass
bash lattice/kernel/orchestrator/sdd/tdd-evidence.sh <spec-id> <task-id> --ac=AC-1 --test=TestAC1 --red-command="..." --red-exit=1 --green-command="..." --green-exit=0

# 将 eval JSON 渲染成人可读摘要
bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json

# 汇总多次 eval run 趋势
bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md

# 本地预览 PR comment 正文
bash lattice/kernel/delivery/pr-comment.sh lattice/state/eval-runs/<run-id>.md --dry-run

# GitHub Actions artifact 模板
cat .github/workflows/lattice-eval.yml

# 只运行某个 gate
bash lattice/kernel/delivery/pipeline.sh --only=spec-lint

# 阅读项目上下文地图
cat lattice/context/README.md

# 可选：检索项目内 curated knowledge
bash lattice/kernel/context/backends/knowledge.sh "payment idempotency"
```

## 当前状态

已具备：

- 安装、初始化、升级和 smoke test；
- PrismSpec 独立 skill pack manifest 与 Lattice-hosted 模式；
- 目录化 spec、per-spec context、模板和 artifact lint；
- doctor、spec lint、AC coverage、drift check、compliance、spec lock；
- `pipeline --json-out`、`lattice/state/eval-runs/*.json`、`lattice/state/loops/*.json`、`lattice/config/failure-categories.yaml`、`lattice/context/drafts/escalation-*.md`、eval markdown summary/history、AC/drift/compliance gate JSON、可配置 failure category、learn draft 和 review/TDD process evidence；
- GitHub Actions eval artifact、Step Summary 与 best-effort PR comment workflow 模板；
- Context map、knowledge backend、中心知识 sync 和基础 `/learn` 约定；
- Go/Gin/GORM 可运行示例与多 Agent adapter 文档。

仍在演进：

- failure category config lint 与 learn draft promotion workflow；
- context/knowledge metadata、过期检测和冲突治理；
- Node/Python 等更多 drift parser；
- 插件 manifest/schema/versioning 与多 Agent lease 模型。

## 文档导航

| 文档 | 内容 |
|------|------|
| [设计 Wiki](docs/wiki/) | 系统设计、SDD、Context、Eval、Loop、Roadmap |
| [PrismSpec README](prismspec/README.md) | 独立 Spec Coding skill pack |
| [Agent adapters](docs/adapters/) | Claude Code、Cursor、Aider、Superpowers 等适配说明 |
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
