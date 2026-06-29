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
| PrismSpec | 将需求沉淀为 `context.md`、`spec.md`、`plan.md`、review evidence 和 `verify.md` |
| Context | 给 Agent 提供项目上下文地图、项目知识、外部知识入口和 per-spec context |
| Verification | 在交付前运行 build、lint、test、AC coverage、drift check、compliance 等 gates |
| Evidence / Eval | 用命令输出、gate 结果、`eval-runs/*.json` 和 outcome 记录支撑“完成了”的结论 |

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
│   │   ├── eval-runs/
│   │   ├── loops/
│   │   ├── outcomes/
│   │   ├── context-runs/
│   │   ├── learn-promotions/
│   │   └── knowledge-reviews/
│   └── specs/
│       └── <spec-id>/
│           ├── context.md
│           ├── spec.md
│           ├── plan.md
│           └── verify.md
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
Intent -> Specification -> Planning -> Implementation(plan|tdd) -> Review -> Verification
```

`/prismspec` 是引导入口，不是额外阶段。它根据已有产物自动路由；`/sdd` 作为兼容别名保留：

```bash
bash prismspec/bin/guide.sh --json
```

| 阶段 | 目标 | 产物 |
|------|------|------|
| Specification | 固化上下文依据、范围、AC、风险和执行模式 | `context.md`、`spec.md` |
| Planning | 将 spec 拆成 AC-traced tasks | `plan.md` |
| Implementation | 按 Plan Mode 或 TDD Mode 实现 | code、tests、task evidence |
| Review | 审查实现证据、diff、review package | `review-summary.json` |
| Verification | 运行独立验证命令或 Lattice pipeline | `verify.md` |

`/capture` 是可选后处理，只把 `verify.md` 或 review evidence 中可复用、非敏感、可审计的经验沉淀到知识库。`/finish` 仅作为 legacy branch/worktree closeout 别名保留。

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
| 生成可选 summary | `bash lattice/kernel/orchestrator/sdd/summary-draft.sh <spec-id>` |
| 从知识候选生成 learn draft | `bash lattice/kernel/context/summary-learn-draft.sh <spec-id>` |
| 渲染 eval 摘要 | `bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/<run-id>.json` |
| 汇总 eval 历史 | `bash lattice/kernel/delivery/eval-history.sh --out=lattice/state/eval-runs/history.md` |
| 发布 central eval sink | `bash lattice/kernel/delivery/eval-sink.sh publish --sink-dir=lattice/state/eval-sink` |
| 生成静态 dashboard | `bash lattice/kernel/delivery/eval-dashboard.sh --sink-dir=lattice/state/eval-sink --out=lattice/state/eval-sink/dashboard.html` |
| 查询 central eval sink | `bash lattice/kernel/delivery/eval-query.sh summary --sink-dir=lattice/state/eval-sink` |
| Review learn draft | `bash lattice/kernel/context/knowledge-review.sh approve lattice/context/drafts/<draft>.md --reviewer=<name> --reason=<reason> --conflicts-checked` |
| Promote learn draft | `bash lattice/kernel/context/learn-draft.sh promote lattice/context/drafts/<draft>.md --require-review --to=lattice/context/knowledge/pitfalls.md` |

更完整的命令协议见 [设计 Wiki](docs/wiki/) 和各脚本的 `--help`。

## 当前状态

Lattice 当前已经具备 **repo-local AI Coding harness 的最小可信闭环**：

| 方向 | 已可用能力 |
|------|------------|
| 安装与初始化 | `install.sh`、`init.sh`、`doctor.sh` manifest/skillpack contract 检查、smoke test、GitHub Actions eval artifact 模板 |
| PrismSpec | canonical skills、`new.sh`、`doctor.sh`、`guide.sh`、skillpack/artifact `lint.sh`、多模板、Plan/TDD policy、standalone 与 Lattice-hosted 两种模式 |
| Spec lifecycle | `context.md`、`spec.md`、`plan.md`、review evidence、`verify.md`、状态推进、transition event/history |
| Implementation evidence | `task-next.sh`、`task-complete.sh`、task brief、review package、review summary、TDD evidence、task evidence lint |
| Verification / Evidence | pipeline、spec lint、AC coverage、drift check、compliance、spec lock、structured eval JSON、Markdown summary/history |
| Loop 与 outcome | loop state、failure category、escalation draft、outcome link/report、central eval sink、static dashboard、eval query、PR comment dry-run |
| Context / Learn | context map、external map、knowledge backend、context-lint、context-run、knowledge metadata/governance lint、knowledge review、learn draft promote/discard、summary-to-learn-draft |
| 示例与适配 | Go/Gin/GORM 可运行示例、Claude Code / Cursor / Aider / Superpowers adapter docs |

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
