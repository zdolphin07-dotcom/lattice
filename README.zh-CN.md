<p align="center">
  <h1 align="center">Lattice</h1>
  <p align="center">
    <strong>面向团队的 AI Coding 工程框架</strong>
  </p>
  <p align="center">
    <a href="README.md">English</a> · <a href="CHANGELOG.md">更新日志</a> · <a href="docs/adapters/">Agent 适配器</a> · <a href="examples/go-gin-gorm/">示例</a>
  </p>
</p>

---

## 为什么需要 Lattice

AI Coding 已经能提升个人研发效率。更难的问题是：如何把个人实践沉淀为团队可复用的工程资产，让上下文、Spec、Agent 执行、验证证据和质量度量进入同一套研发工作流。

Lattice 是面向团队的 AI Coding 工程框架，以 Spec Coding 为主线，通过可插拔的 Context、Spec、Harness 与 Eval 组件，将个人 AI 编码实践沉淀为可复用、可治理、可度量的团队研发能力。

它围绕四个原则设计：

| 原则 | 含义 |
|------|------|
| **Spec 驱动** | 需求沉淀为显式契约，包含验收标准、接口/数据设计、风险和测试策略。 |
| **上下文工程** | 在编码前加载项目知识、命名规范、领域规则和历史决策，减少 Agent 猜测。 |
| **证据化交付** | 交付结论必须有 build/lint/test/gate 输出支撑，而不是 Agent 自我判断。 |
| **组件可插拔** | Context、Spec、Harness、Eval 可以单独使用，也可以组合成团队研发工作流。 |

## 问题

AI 编码 Agent 在两个边界上系统性失败，个人使用时这些问题常被速度收益掩盖：

**上下文边界** — 真实项目约束存在于代码库之外：领域规则、命名规范、历史决策、事故教训。模型能读你的代码，但无法推断它从未见过的东西。它不知道"余额"操作需要幂等键，不知道你的团队在 camelCase 还是 snake_case 上争论了一个月后达成了共识。没有这些上下文，它只能猜——而能编译通过的猜测是最危险的 bug。

**验证边界** — 当同一个模型既生成代码又评估代码是否正确，就是学生给自己批卷。Agent 会报告"所有测试通过"，因为它同时编写了代码和测试。结构性问题——缺失的边界场景、规约与代码的漂移、未覆盖的验收标准——无法被检测到，因为验证者和生成者共享同样的盲区。

## 解决方案

Lattice 安装到你的代码库中，在**两个边界提供外部支撑**：

| 边界 | 没有 Lattice | 有 Lattice |
|------|-----------------|----------------|
| **意图 → 代码** | Agent 猜测它看不到的约束 | Knowledge 层注入领域上下文；规约模板强制显式设计 |
| **代码 → 生产** | Agent 自我评估（"看起来没问题"） | Delivery 层运行独立卡口流水线；提供结构化验证与可复现证据 |

它**不是**工作流引擎、IDE 插件或云服务。它是一组可组合的项目文件、bash 脚本和 YAML 契约，存在于你的仓库中，由你正在使用的任何 AI Agent 调用。

---

## 组件模型

Lattice 采用组件化设计。每个组件都可以单独使用，同时通过统一的 `manifest.yaml` 和项目产物目录组合成团队研发工作流。

| 组件 | 作用 | 当前形态 |
|------|------|----------|
| **Context** | 加载项目知识、命名规范、领域约束和历史决策。 | `lattice/knowledge/`、`loader.sh`、`sync.sh` |
| **Spec** | 将需求标准化为可执行契约，包含 AC、设计决策、风险和测试策略。 | `spec-template.md`、`spec-lint.sh`、`lattice/specs/` |
| **Harness** | 在交付声明前运行独立于 Agent 的验证卡口。 | `pipeline.sh`、build/lint/test、AC coverage、drift check |
| **Eval** | 基于验收覆盖与漂移检查生成可复现的质量证据。 | 证据化 gate 输出；可通过 `drift.plugins[]` 扩展 |

---

## 快速开始

### 前置依赖

| 工具 | 用途 | 安装 |
|------|------|------|
| **bash** ≥ 4.0 | 脚本运行时 | macOS: `brew install bash` · Linux: 内置 |
| **yq** ≥ 4.x | YAML 解析器 | `brew install yq` · [github.com/mikefarah/yq](https://github.com/mikefarah/yq) |
| **git** | 知识同步、漂移检测 | 通常已预装 |

### 安装

```bash
# 方式 A: 远程安装
bash <(curl -fsSL https://raw.githubusercontent.com/your-org/lattice/main/install.sh) --init

# 方式 B: 本地安装（已克隆仓库）
./install.sh /path/to/your-project --init

# 方式 C: Agent 驱动（在 Claude Code 中）
/init
```

`--init` 标志自动检测语言、框架和 ORM，然后生成 `manifest.yaml` 并将规则注入 Agent 配置。

### 试试示例

```bash
git clone https://github.com/your-org/lattice.git
cd lattice
bash examples/go-gin-gorm/try-it.sh
```

在示例 Go 项目上运行所有卡口——spec-lint、AC 覆盖率、漂移检查、知识检索——5 秒内完成，无需 Go 编译器。

---

## 架构

### 设计哲学

**引擎/数据分离。** `kernel/` 目录是可升级引擎——整体替换时项目配置不受影响。`specs/`、`knowledge/`、`plans/` 目录是项目自有数据——升级时保留，应纳入版本控制。

### 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│                      你的 AI Agent                          │
│  (Claude Code / Cursor / Aider / 任何支持 shell 的 Agent)    │
└──────────────┬──────────────────────────────┬───────────────┘
               │ @import rules.md             │ bash pipeline.sh
               ▼                              ▼
┌──────────────────────┐    ┌─────────────────────────────────┐
│    ORCHESTRATOR       │    │          DELIVERY                │
│    编排层              │    │          交付层                   │
│                       │    │                                  │
│  rules.md             │    │  pipeline.sh                     │
│  flow.yaml            │    │    ├── bootstrap.sh              │
│  spec-template.md     │    │    ├── spec-lint.sh              │
│                       │    │    ├── build / lint / test        │
│  定义每个开发阶段       │    │    ├── ac-coverage.sh            │
│  的行为规则            │    │    ├── drift-check.sh            │
│                       │    │    ├── compliance.sh             │
│                       │    │    └── spec-lock.sh              │
└──────────────────────┘    │                                  │
                             │  Exit 0 = 通过                   │
┌──────────────────────┐    │  Exit 1 = 失败（可重试）           │
│    KNOWLEDGE          │    │  Exit 2 = 升级（需人工介入）       │
│    知识层              │    └─────────────────────────────────┘
│                       │
│  loader.sh            │          ┌──────────────────┐
│  sync.sh              │          │  manifest.yaml    │
│  knowledge/index.md   │          │                   │
│  knowledge/*.md       │          │  单一项目配置源     │
│  synonyms.txt         │          └──────────────────┘
│                       │
│  按需检索领域上下文     │
└──────────────────────┘
```

| 层 | 角色 | 机制 | 形式 |
|----|------|------|------|
| **Orchestrator** | 控制面 | 定义 Agent 每阶段行为规则——规约格式、AC 编号、阶段转换 | 静态文件，`@import` 到 Agent 提示词 |
| **Knowledge** | 意图 → 代码 | 按关键词检索领域知识，注入 Agent 上下文 | CLI（`loader.sh`），Agent 调用 |
| **Delivery** | 代码 → 生产 | 运行 manifest 驱动的验证卡口流水线，独立于 Agent | CLI（`pipeline.sh`），Agent 调用 |

每层可通过 `manifest.yaml` 独立启用/禁用：

```yaml
kernel:
  layers:
    orchestrator: true   # 始终开启
    knowledge: true      # 无知识库时可禁用
    delivery: true       # 探索性工作时可禁用
```

### 安装后项目目录结构

```
your-project/
├── CLAUDE.md                          # 一行 @import 激活所有约束
├── lattice/
│   ├── manifest.yaml                  # 声明式项目配置
│   ├── kernel/                        # ★ 可升级引擎
│   │   ├── _lib.sh                    #   共享库（日志、YAML 查询）
│   │   ├── orchestrator/
│   │   │   ├── rules.md              #   阶段行为规则
│   │   │   ├── flow.yaml             #   阶段定义
│   │   │   └── templates/
│   │   │       └── spec-template.md  #   规约格式模板
│   │   ├── knowledge/
│   │   │   ├── loader.sh             #   关键词 → 知识检索
│   │   │   └── sync.sh              #   中央仓库同步
│   │   └── delivery/
│   │       ├── pipeline.sh           #   卡口编排器
│   │       ├── bootstrap.sh          #   环境检查
│   │       ├── deploy.sh             #   部署（可选，Docker+K8s 示例）
│   │       └── gates/
│   │           ├── spec-lint.sh      #   规约结构验证
│   │           ├── ac-coverage.sh    #   AC↔测试追踪
│   │           ├── drift-check.sh    #   规约↔代码漂移检测
│   │           ├── compliance.sh     #   行为合规审计
│   │           └── spec-lock.sh      #   多 Agent 写锁
│   ├── knowledge/                     # ★ 项目自有：领域知识库
│   │   ├── index.md                  #   关键词索引
│   │   └── *.md                      #   知识条目
│   ├── specs/                         # ★ 项目自有：冻结的规约合约
│   ├── plans/                         # ★ 项目自有：AC 追踪执行计划
│   └── requirements/                  # ★ 项目自有：需求输入
├── src/                               # 你的代码（Lattice 不侵入）
└── ...
```

---

## 工作原理

### 阶段一：设计 — 知识注入 + 规约编写

当你描述一个需求时，Agent 进入设计阶段：

```
你："添加一个优惠券核销 API"

Agent（已加载 Lattice 规则）：
  1. 读取 manifest.yaml 获取项目上下文
  2. 运行：bash lattice/kernel/knowledge/loader.sh coupon redemption payment
     → 找到：payment-idempotency.md, coupon-business-rules.md
  3. 评估："上下文是否充分？" 不够 → 向你提问
  4. 使用 spec-template.md 格式编写规约：
     - AC-1: 核销有效优惠券 → 200，余额扣减
     - AC-2: 核销过期优惠券 → 400，无副作用
     - AC-3: 并发核销 → 仅一个成功（幂等）
     ...
```

**HARD-GATE**：规约必须经人类审批后方可开始实现。这是整个工作流中唯一的强制人工检查点。

### 阶段二：实现 — AC 追踪的 TDD

实现阶段，Agent 遵循 `rules.md` 强制的命名规范：

```go
// 测试名称追溯到规约 AC 编号
func TestAC1_RedeemValidCoupon(t *testing.T) { ... }
func TestAC2_RedeemExpiredCoupon(t *testing.T) { ... }
func TestAC3_ConcurrentRedemption(t *testing.T) { ... }
```

```python
# Python 等价写法
def test_ac1_redeem_valid_coupon(): ...
def test_ac2_redeem_expired_coupon(): ...
```

```typescript
// Node 等价写法
describe('AC-1: Redeem valid coupon', () => { ... })
describe('AC-2: Redeem expired coupon', () => { ... })
```

### 阶段三：验证 — 独立卡口流水线

在宣布完成之前，Agent 运行流水线：

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

**失败时**，Agent 读取输出 → 修复问题 → 重跑，最多 3 次重试。重试耗尽后，退出码 `2` 触发升级：Agent 停止自修复，输出诊断报告请求人工介入。

---

## 卡口参考

### spec-lint — 规约结构验证

验证规约文档包含所有必需章节、AC 编号连续、JSON 格式正确、风险评审覆盖完整。

```bash
bash lattice/kernel/delivery/gates/spec-lint.sh [spec-file]
```

**可配置**，通过 `manifest.yaml`：

```yaml
specs:
  required_sections:
    - "Background & Goals"
    - "Naming Conventions"
    - "Technical Design"
    - "API Design"
    - "Data Model"
    - "Design Alternatives"
    - "Acceptance Criteria"
    - "Risk Review"
    - "Test Strategy"
    - "Release Checklist"
    - "Rollout & Rollback"
    - "Decision Log"
  risk_categories:
    - "Financial Safety"
    - "Technical Risk"
    - "Data Risk"
    - "Release Process"
```

执行的检查项：
- 必需章节存在性（可配置列表）
- AC 编号连续性（AC-1, AC-2, ... 不跳号）
- JSON 块中无 `//` 注释
- DDL 表计数
- Mermaid 图表计数（建议 ≥ 2）
- 决策日志完整性
- 风险评审分类覆盖
- 资金安全章节（检测到资产关键词时自动触发）

### ac-coverage — 验收标准追踪

将规约 AC 编号映射到测试函数名，生成覆盖率矩阵。

```bash
bash lattice/kernel/delivery/gates/ac-coverage.sh [spec-file] [search-dir]
bash lattice/kernel/delivery/gates/ac-coverage.sh --deep [spec-file] [search-dir]
```

| 语言 | 测试文件模式 | 函数正则 |
|------|------------|---------|
| Go | `*_test.go` | `func TestAC{nn}_` 或 `func Test_AC{nn}_` |
| Node/TS | `*.test.ts`, `*.spec.js` | `describe/it/test` 中包含 `AC-{nn}` |
| Python | `test_*.py` | `def test_ac{nn}_` |

输出：

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

**Deep 模式**（`--deep`）额外检测：
- 包含 `t.Skip` / `pytest.skip` 的测试（实际未运行）
- 零断言的测试（空测试体）

### drift-check — 规约↔代码漂移检测

检测规约文档与实际代码之间的偏移。

```bash
bash lattice/kernel/delivery/gates/drift-check.sh [spec-file] [project-root]
```

| 漂移类型 | 比较内容 | 支持的 ORM/框架 |
|---------|---------|----------------|
| **DDL 漂移** | 规约 `CREATE TABLE` 列 vs ORM 模型标签 | GORM（完整）· Prisma、Sequelize、SQLAlchemy（计划中） |
| **路由漂移** | 规约 API 表 vs 代码路由注册 | Gin、Echo、Chi（完整）· Express、FastAPI（计划中） |
| **错误码漂移** | 规约错误码表 vs 代码常量 | Go（完整） |
| **Seed SQL 漂移** | 规约 seed SQL vs `fixtures/seed.sql` | 所有语言 |
| **插件漂移** | 通过 `drift.plugins[]` 自定义检查 | 任意（用户定义） |

通过自定义插件扩展：

```yaml
drift:
  plugins:
    - name: proto-check
      run: "bash scripts/proto-drift.sh ${SPEC_FILE} ${PROJECT_ROOT}"
```

### compliance — 行为合规审计

软卡口，检查 Agent 在开发过程中是否遵循了 Lattice 行为规则。

```bash
bash lattice/kernel/delivery/gates/compliance.sh [spec-file]
bash lattice/kernel/delivery/gates/compliance.sh --strict [spec-file]
```

检查项：
- 规约是否引用了知识库条目？
- 近期提交是否包含知识相关活动？
- 规约是否包含澄清/确认记录？

默认为**软卡口**（仅警告，exit 0）。使用 `--strict` 将警告视为失败。

### spec-lock — 多 Agent 写锁

基于文件的锁，防止多 Agent 场景下的并发规约编辑。

```bash
bash lattice/kernel/delivery/gates/spec-lock.sh acquire <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh release <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh status <spec-file>
bash lattice/kernel/delivery/gates/spec-lock.sh clean    # 清理过期锁（>1h）
```

---

## 知识层

### 检索原理

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

1. **精确匹配**：在 `knowledge/index.md` 中搜索关键词
2. **同义词扩展**：无精确匹配时，`synonyms.txt` 映射相关术语（如 "payment" → "fund"、"charge"、"deduct"）
3. **输出**：匹配的知识文件内容打印供 Agent 消费

### 知识索引格式

```markdown
# Knowledge Index

- `payment-idempotency` | keywords: payment, idempotency, fund | 所有支付操作需要幂等键
- `naming-rules` | keywords: naming, convention, style | API 和代码命名标准
- `auth-flow` | keywords: auth, login, token | OAuth2 + JWT 刷新流程
```

### 中央知识同步

通过中央仓库跨项目共享知识：

```yaml
knowledge:
  local_dir: "lattice/knowledge"
  central:
    repo: "https://github.com/your-org/knowledge.git"
    mode: read-only        # read-only | read-write
    conflict: prefer-local  # prefer-local | prefer-remote | fail
```

```bash
bash lattice/kernel/knowledge/sync.sh pull    # 从中央拉取
bash lattice/kernel/knowledge/sync.sh push    # 推送本地变更
bash lattice/kernel/knowledge/sync.sh status   # 查看同步状态
```

---

## Agent Skills

Lattice 暴露 3 个 skill（Claude Code 中为斜杠命令；其他 Agent 中为自然语言）：

| Skill | 触发方式 | 功能 |
|-------|---------|------|
| **init** | `/init` | 交互式项目初始化：检测语言 → 生成 manifest → 复制脚手架 → 注入规则 |
| **verify** | `/verify` | 运行完整交付流水线 |
| **learn** | `/learn "经验"` | 将知识条目写入 `knowledge/`，更新索引 |

其他能力——知识加载、规约模板、AC 命名、漂移检测——通过 `rules.md` 行为注入自动激活。Agent 遵循规则是因为它们在提示词中，而非 Lattice 控制了 Agent。

---

## 语言支持矩阵

| 功能 | Go | Node/TS | Python | Rust | Java |
|------|:---:|:---:|:---:|:---:|:---:|
| 项目检测 | ✅ `go.mod` | ✅ `package.json` | ✅ `pyproject.toml` | ✅ `Cargo.toml` | ✅ `pom.xml` |
| 框架检测 | Gin, Echo, Chi | Express, NestJS, Koa, Fastify | FastAPI, Flask, Django | — | — |
| ORM 检测 | GORM, Ent | Sequelize, Prisma, TypeORM | SQLAlchemy | — | — |
| AC 覆盖率 | ✅ | ✅ | ✅ | — | — |
| DDL 漂移 | ✅ GORM | 计划中 | 计划中 | — | — |
| 路由漂移 | ✅ Gin/Echo/Chi | 计划中 | 计划中 | — | — |
| 错误码漂移 | ✅ | — | — | — | — |

---

## Agent 兼容性

Lattice 适用于任何能 (a) 读取规则文件并 (b) 执行 shell 命令的 AI 编码 Agent。

| Agent | 集成方式 | 文档 |
|-------|---------|------|
| **Claude Code** | `CLAUDE.md` `@import` + `.claude/commands/` | 内置（默认） |
| **Cursor** | `.cursorrules` `@file` 指令 | [docs/adapters/cursor.md](docs/adapters/cursor.md) |
| **Aider** | `--read` 标志或 `.aider.conf.yml` | [docs/adapters/aider.md](docs/adapters/aider.md) |
| **Superpowers** | 阶段覆写映射 | [docs/adapters/superpowers.md](docs/adapters/superpowers.md) |
| **其他** | 将 `rules.md` 加载到系统提示词；通过 shell 调用脚本 | [docs/adapters/README.md](docs/adapters/README.md) |

---

## CLI 参考

所有命令支持 `--help`。退出码：`0` 成功 · `1` 失败（可重试） · `2` 升级（需人工介入）。

### 流水线

```bash
# 运行完整流水线
bash lattice/kernel/delivery/pipeline.sh

# 仅运行指定步骤
bash lattice/kernel/delivery/pipeline.sh --only=build

# 指定规约文件
bash lattice/kernel/delivery/pipeline.sh --spec=lattice/specs/my-feature.md

# 跳过规约相关或集成测试步骤
bash lattice/kernel/delivery/pipeline.sh --skip-spec
bash lattice/kernel/delivery/pipeline.sh --skip-integration
```

### 单个卡口

```bash
# 规约检查
bash lattice/kernel/delivery/gates/spec-lint.sh <spec-file>

# AC 覆盖率
bash lattice/kernel/delivery/gates/ac-coverage.sh <spec-file> <search-dir>
bash lattice/kernel/delivery/gates/ac-coverage.sh --deep <spec-file> <search-dir>

# 漂移检查
bash lattice/kernel/delivery/gates/drift-check.sh <spec-file> <project-root>

# 合规审计
bash lattice/kernel/delivery/gates/compliance.sh <spec-file>
bash lattice/kernel/delivery/gates/compliance.sh --strict <spec-file>

# 规约锁
bash lattice/kernel/delivery/gates/spec-lock.sh acquire|release|status|clean <spec-file>
```

### 知识库

```bash
# 按关键词搜索
bash lattice/kernel/knowledge/loader.sh <关键词1> [关键词2] ...

# 列出所有条目
bash lattice/kernel/knowledge/loader.sh --list

# 输出所有知识
bash lattice/kernel/knowledge/loader.sh --all

# 与中央仓库同步
bash lattice/kernel/knowledge/sync.sh pull|push|status
```

### Bootstrap 与部署

```bash
# 检查环境就绪
bash lattice/kernel/delivery/bootstrap.sh check

# 启动本地服务（读取 manifest services.local）
bash lattice/kernel/delivery/bootstrap.sh local

# 部署到测试环境（可选，Docker+K8s 示例）
bash lattice/kernel/delivery/deploy.sh test|rollback|status
```

---

## 配置参考

Lattice 从单个 `manifest.yaml` 读取所有配置。完整参考：

<details>
<summary><strong>完整 manifest.yaml 参考（点击展开）</strong></summary>

```yaml
# ── 项目标识 ──
project:
  name: my-api
  language: go                          # go | node | python | rust | java
  version_constraint: ">=1.22"

# ── 层控制 ──
kernel:
  layers:
    orchestrator: true
    knowledge: true
    delivery: true

# ── 工具依赖 ──
tools:
  required:
    - { name: go, check: "go version" }
    - { name: yq, check: "yq --version" }
  optional:
    - { name: docker, check: "docker --version" }

# ── 服务依赖 ──
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

# ── 构建/测试命令 ──
commands:
  build: "go build ./..."
  lint: "go vet ./..."
  test: "go test ./... -short -count=1"
  integration_test: "go test ./tests/integration/... -tags=integration"
  smoke_test: "curl -sf http://localhost:8080/health"

# ── 规约配置 ──
specs:
  dir: "lattice/specs"
  template: "lattice/kernel/orchestrator/templates/spec-template.md"
  required_sections:                    # 覆盖默认值
    - "Background & Goals"
    - "Technical Design"
    - "Acceptance Criteria"
    # ...
  risk_categories:                      # 覆盖默认值
    - "Financial Safety"
    - "Technical Risk"
    - "Data Risk"
    - "Release Process"

# ── 测试策略 ──
testing:
  strategies:
    go:
      file_pattern: "*_test.go"
      func_regex: 'func Test(AC|_AC)([0-9]+)'

# ── 漂移检测 ──
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
  plugins: []                           # 自定义漂移检查

# ── 流水线步骤 ──
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

# ── 知识库 ──
knowledge:
  local_dir: "lattice/knowledge"
  central:
    repo: ""
    mode: read-only
    conflict: prefer-local

# ── 部署（可选）──
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

## 设计决策

| 决策 | 理由 | 取舍 |
|------|------|------|
| **注入 Agent，而非构建 Agent** | 编排是已解决的问题。Lattice 只增加上下文和验证。 | 依赖 Agent 遵循提示词指令的能力 |
| **纯 bash，零运行时依赖** | 零安装摩擦。任何 Unix 系统 + bash 4+ 和 yq 即可运行。 | 表达能力受限于 bash；无内置 UI |
| **flow.yaml 是行为指南，不是状态机** | Agent 接口差异太大，硬编码转换不可移植 | 规则合规依赖提示词工程 + 事后审计 |
| **关键词匹配，而非语义搜索** | 零外部依赖，离线可用，百条级别足够 | 对改述的召回率弱；需手动维护索引 |
| **卡口验证结构，不验语义** | 确定性标准，机械可执行，无误报 | 不替代人工 Code Review |
| **单一 manifest.yaml** | 一个文件理解项目的全部线束配置 | 文件随项目复杂度增长 |

## 已知限制

- **漂移检测基于正则**：不覆盖动态路由、嵌套 ORM 关系、gRPC protobuf。可通过 `drift.plugins[]` 扩展。
- **知识检索基于关键词**："余额扣减" vs "资金划扣"在没有同义词条目时无法匹配。支持同义词表，但需手动维护。
- **合规性是事后审计**：无法强制 Agent 加载知识；只能检测它没这么做。
- **语言覆盖不均**：完整漂移检测仅 Go（Gin/GORM）。Node 和 Python 支持计划中。
- **无 GUI**：Lattice 是纯 CLI。规约审查在编辑器中进行；流水线输出是终端文本。

---

## 升级

```bash
# 仅升级引擎（保留 manifest.yaml、knowledge/、specs/）
./install.sh /path/to/your-project --upgrade
```

升级替换 `lattice/kernel/`，保留所有项目自有数据（`manifest.yaml`、`knowledge/`、`specs/`、`plans/`）。如果项目内已有 kernel，会先移动到 `lattice/state/kernel-backups/` 再替换。

---

## 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可

MIT — 参见 [LICENSE](LICENSE)。
