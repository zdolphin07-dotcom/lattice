# Context 设计

## 定位

Lattice 的 Context 层不是知识库产品，也不是校验系统，而是给 Agent 的项目上下文供给层。

它的核心任务是：让 Agent 在写 `spec.md`、`plan.md` 和代码之前，知道这个项目的关键知识在哪里、哪些来源更可信、冲突时如何取舍，以及本次需求应该引用哪些最小上下文依据。

一句话：

> Context 不是 Agent 找到的所有材料，而是支撑本次 spec 决策的最小可信依据。

## 设计原则

| 原则 | 含义 |
|------|------|
| Agent-readable first | 优先给 Agent 一份可读的上下文地图，而不是先做机器配置。 |
| Less but relevant | 不追求加载更多 context，只保留影响本次决策的事实。 |
| Code remains truth | 当前代码、测试、schema、接口契约仍是真相源。 |
| Project over central | 项目内知识优先于中心知识，中心知识只作补充。 |
| Context before spec | Brainstorming 先形成 `context.md`，再写 `spec.md`。 |
| Tooling stays light | shell 只做同步、检索辅助和轻量 sanity check，不承载智能判断。 |

## 推荐结构

```text
lattice/
├── context/
│   ├── README.md              # Agent 必读的项目上下文地图
│   ├── external.md            # 项目外部关联知识、中心知识、第三方协议入口
│   ├── knowledge/
│   │   ├── architecture.md    # 项目架构、模块边界、关键流程
│   │   ├── rules.md           # 业务规则、技术规则、接口契约
│   │   ├── pitfalls.md        # 历史踩坑、事故教训、容易误用的点
│   │   ├── glossary.md        # 领域术语、缩写、命名约定
│   │   └── decisions/         # ADR / 历史决策
│   ├── drafts/                # 待确认的经验沉淀
│   └── sources.yaml           # 可选：给脚本/自动化消费的结构化来源声明
├── specs/
│   └── <spec-id>/
│       ├── context.md         # 本次 spec 的最小上下文依据
│       ├── spec.md
│       ├── plan.md
│       └── summary.md
└── state/
    └── context-runs/          # 可选：后续结构化记录命中与取舍
```

最重要的是 `lattice/context/README.md`。它不是普通说明文档，而是 Agent 的上下文地图。

## Context README

`lattice/context/README.md` 应该回答四个问题：

1. 这个项目是什么。
2. 需要某类上下文时应该读哪里。
3. 不同来源冲突时如何取舍。
4. 哪些内容不要直接塞进 prompt 或 spec。

推荐模板：

```markdown
# Project Context Map

## Project Snapshot
- 项目定位：
- 核心业务对象：
- 主要模块：
- 高风险链路：

## Where To Find Context
| Need | Read |
|------|------|
| 架构和模块边界 | `knowledge/architecture.md` |
| 业务规则和接口契约 | `knowledge/rules.md` |
| 历史踩坑和事故教训 | `knowledge/pitfalls.md` |
| 领域术语和命名 | `knowledge/glossary.md` |
| 历史决策 | `knowledge/decisions/` |
| 外部协议和中心知识 | `external.md` |
| 历史 specs | `../specs/` |

## Loading Policy
- 先读用户本次指令和当前代码、测试、schema。
- 再读项目知识。
- 中心知识和外部文档只作补充，不覆盖当前项目事实。
- 不把大段文档复制进 spec，只提炼影响本次决策的事实。

## Conflict Policy
1. 用户本次明确指令
2. 当前代码 / 测试 / schema / 接口契约
3. 项目知识
4. 历史 specs
5. 中心知识 / 外部文档
6. 模型先验
```

## 项目内知识

项目内知识是 repo-local 的长期记忆，适合存：

- 项目架构、模块职责、关键链路；
- 业务不变量和接口契约；
- 权限、安全、幂等、兼容性约束；
- 历史事故和踩坑；
- ADR、被拒绝方案和决策背景；
- 领域术语、命名规范、错误码约定。

不建议存：

- 大段源码；
- 临时会议碎片；
- 未确认的猜测；
- 与项目无关的通用 prompt 技巧；
- 密钥、token、生产原始数据或隐私数据。

## 外部关联知识

外部知识不应散落在 prompt 里，建议统一写到 `lattice/context/external.md`：

```markdown
# External Context

## Central Knowledge
- 团队规范：
- 公共组件文档：
- 跨项目踩坑：

## External Contracts
- 第三方 API：
- 协议文档：
- 设计系统：

## Usage Policy
- 外部知识只作参考。
- 与当前代码或项目知识冲突时，以项目事实为准。
- 需要联网或访问私有系统时，先确认权限和数据边界。
```

## `context.md`

`lattice/specs/<spec-id>/context.md` 是单次需求的上下文依据。它不是资料汇编，而是 Agent 从上下文地图中按需加载、筛选和压缩后的结果。

推荐模板：

```markdown
# Context: <spec-id>

## Decision Frame
- Requirement type:
- Key decisions:
  - Scope:
  - AC:
  - Risk / Mode:
  - Interface:
  - Verification:

## Selected Facts
| Type | Source | Fact | Decision Impact |
|------|--------|------|-----------------|
| code | `src/order/service.ts` | 创建订单已有幂等 key 检查 | AC 需要覆盖重复提交 |
| test | `tests/order.test.ts` | 只有正常创建测试，没有重复提交测试 | 可能需要 TDD |
| schema | `schema.prisma` | `orderNo` 有唯一索引 | 需要覆盖唯一冲突 |
| knowledge | `rules.md#payment-idempotency` | 支付写操作必须幂等 | 影响风险和验证 |

## Constraints
| Type | Constraint | Source | Impact |
|------|------------|--------|--------|

## Conflicts / Ambiguities
| Issue | Sources | Required Decision |
|-------|---------|-------------------|

## Exclusions
| Source / Topic | Why excluded |
|----------------|--------------|

## Context Gaps
| Gap | Blocks planning? | Question |
|-----|------------------|----------|
```

## 模型与项目的边界

| 事项 | 责任方 | 说明 |
|------|--------|------|
| 判断本次需求需要哪些上下文 | Agent / Skill | 需要语义理解和取舍。 |
| 搜索相关代码、测试、schema、历史 spec | Agent / Skill | 模型根据需求主动查。 |
| 选择哪些事实进入 `context.md` | Agent / Skill | 只保留影响决策的事实。 |
| 提供上下文地图和知识资产 | Lattice / 项目 | 让 Agent 知道去哪里找。 |
| 提供模板和取舍规则 | Lattice / 项目 | 稳定输出结构，降低噪声。 |
| 同步中心知识 | Lattice tooling | Git/文件同步适合脚本。 |
| 轻量结构检查 | Lattice tooling | 只做 sanity check，不做重 gate。 |

Lattice 负责供给和约束，模型负责理解和选择。

## `sources.yaml` 的定位

`sources.yaml` 不是 Context 层的核心。它只有在脚本、CI 或中心化治理需要消费结构化配置时才有价值。

| 场景 | 是否需要 `sources.yaml` |
|------|-------------------------|
| 给 Agent 读项目上下文 | 不优先，Markdown 更自然 |
| 让脚本扫描 include/exclude | 有价值 |
| 中心知识同步策略 | 有价值 |
| 多项目统一治理 context 来源 | 有价值 |
| 当前只靠 Agent 使用 | 可以先作为可选扩展 |

因此推荐顺序是：

1. 先把 `README.md`、`knowledge/`、`external.md` 做好；
2. 再在需要自动化时补充 `sources.yaml`；
3. 不要让 `sources.yaml` 取代 Agent 可读的上下文地图。

## `loader.sh` 的定位

`loader.sh` 不应该是 Context 主流程。它最多是项目知识检索的辅助 backend。

专业心智应该是：

```text
Context Discovery = Agent 根据需求读上下文地图并主动查找、筛选、压缩
knowledge loader = 可选工具，用于检索 curated project knowledge
```

当前实现已将检索能力下沉为：

```text
lattice/kernel/context/backends/knowledge.sh
```

`loader.sh` 只保留为兼容包装，不应在 Brainstorming 里写成必做主入口。

## 与 PrismSpec 的关系

PrismSpec 负责 SDD 工作流；Context 负责提供更准确的项目上下文。

| 阶段 | Context 作用 | 产物 |
|------|--------------|------|
| Brainstorming | Agent 按上下文地图发现、筛选、压缩本次需求相关事实 | `context.md`、`spec.md` |
| Planning | 基于 `context.md` 和 `spec.md` 拆任务和验证证据 | `plan.md` |
| Implementation | 遵守 `context.md` 中的事实、约束和排除项 | 代码、测试、task evidence |
| Verification | 验证交付结果，不重新发明上下文 | gate output |
| Finishing | 将可复用经验写入 drafts，待确认后进入项目知识 | `summary.md`、knowledge draft |

## 当前 Gap

| Gap | 影响 | 优先级 |
|-----|------|--------|
| 默认 context map 仍是通用模板 | 需要项目初始化后补充真实模块、链路和风险 | P0 |
| 项目知识文件仍需人工填充 | Agent 只能看到结构，缺少真实领域知识 | P0 |
| `sources.yaml` 尚未被自动化消费 | 当前更多是未来扩展点 | P1 |
| `context.md` 质量依赖 Agent 自觉 | 需要更好的模板和少量 sanity check | P1 |

## 推荐演进

1. 在真实示例中填充 `lattice/context/README.md`、`external.md` 和项目知识文件。
2. 让 PrismSpec Brainstorm skill 更明确地要求先读 context map，再写 `context.md`。
3. 将 `sources.yaml` 保留为可选自动化配置，后续脚本真正消费后再提升权重。
4. 增加轻量 sanity check，避免空 `context.md`，但不要把 Context 做成重 gate。
5. 记录 context-runs，用于后续 Eval 分析哪些上下文真的有用。
