# Gap 与 Roadmap

## 总体判断

Lattice 当前已经达到“可试点的 repo-local AI Coding harness”阶段：安装、SDD 引导、目录化 spec、per-spec context、基础 gates 和 smoke test 都已形成闭环。

它还不是完整平台。现阶段应继续保持边界克制：先把可复现证据、真实示例和多语言扩展做扎实，再考虑 dashboard、协作平台或复杂治理。

## 已成立的能力

| 方向 | 当前证据 | 判断 |
|------|----------|------|
| PrismSpec | canonical skills、guide.sh、lint.sh、多模板、Plan/TDD policy | 主链路成立 |
| Spec contract | `context.md` + `spec.md` 目录化产物、context template、artifact lint | 可作为默认产物形态 |
| Context | context map、project knowledge、external entry、knowledge backend、sync | 最小可用 |
| Delivery | pipeline、spec-lint、PrismSpec lint、AC coverage、drift、compliance、spec-lock | 最小验证闭环成立 |
| AI 友好 | AGENTS.md、SKILL.md、slash commands、JSON guide | 入口清晰 |
| 安装验证 | install/init/smoke test/CI | 可持续迭代 |

## 主要 Gap

### P0：产品可信度

| Gap | 影响 | 建议 |
|-----|------|------|
| 示例项目仍偏小 | 用户难判断复杂业务价值 | 用 Lumi 等真实业务示例跑完整 spec 迭代 |
| README 与 wiki 需要持续同步 | 入口认知一旦过期会降低信任 | README 只讲当前可用能力；wiki 讲设计和路线 |
| Evidence 已有 pipeline/gate JSON、process evidence、Markdown summary 与 CI artifact 模板，但跨 run 趋势仍弱 | review/TDD/人工检查难做趋势分析 | 推进 PR comment 与 eval history aggregation |

### P1：Evidence 与 Loop

| Gap | 影响 | 建议 |
|-----|------|------|
| Review/TDD 只有单次 run 指标 | 难判断团队质量是否改善 | eval history aggregation |
| PR comment 未发布 | Step Summary 需要进入 CI run 页面查看 | 复用 eval markdown summary 发布 PR comment |
| retry 状态不落盘 | loop 不可审计 | loop state JSON |

### P1：Context 治理

| Gap | 影响 | 建议 |
|-----|------|------|
| 项目知识仍需要真实填充 | Agent 只能看到结构，缺少领域事实 | 在真实示例中填充 architecture/rules/pitfalls/glossary |
| central sync 仍是轻量文件同步 | 只能解决基础共享，不能解决治理 | 增加 metadata、owner、source、staleness |
| learn 仍靠人工确认 | 失败经验沉淀不稳定 | escalation 生成 learn draft，人工确认后入库 |
| context-runs 未落地 | 不知道哪些 context 真的被采用 | 记录采用事实、排除项和未解决问题 |

### P2：生态与扩展

| Gap | 影响 | 建议 |
|-----|------|------|
| drift 主要覆盖 Go/Gin/GORM | 多语言说服力不足 | Node/Express/Prisma 与 Python/FastAPI parser |
| 插件协议偏命令字符串 | 难治理输入输出和版本 | plugin manifest/schema/versioning |
| 多 Agent 协作较轻 | 只解决基础文件锁和规则导入 | owner + lease + state |
| shell 复杂度会增长 | 长期维护成本上升 | 保留 bash facade，复杂解析迁移到小工具 |

## Roadmap

### Milestone 1：真实示例闭环

目标：用一个真实业务项目跑通完整 PrismSpec + Lattice 流程。

任务：

- 选择 Lumi 作为真实业务示例。
- 从需求生成 `context.md`、`spec.md`、`plan.md`、`verify.md`、`summary.md`。
- 记录遇到的 Lattice gap。
- 更新 example README，展示真实业务链路。

验收：

- 用户能看到一次完整 AI Coding 迭代。
- 示例不是纯脚手架或假测试。
- context、spec、plan、verification、learn draft 都有真实内容。

### Milestone 2：Evidence 结构化

目标：让验证证据可被 CI、dashboard 和后续 Agent 消费。

任务：

- PR comment contract。
- eval history aggregation。
- review/TDD trend metrics。

验收：

- CI 能上传 eval artifact。
- eval run 包含 gate evidence 与 process evidence。
- `summary.md` 能引用 eval run。
- 每次交付能追踪 run id、spec hash、git sha 和 kernel version。

### Milestone 3：Context 治理

目标：让 Agent 稳定找到、筛选和压缩项目上下文，并知道哪些知识可信、过期或冲突。

任务：

- 在真实示例中填充 `lattice/context/README.md`、`external.md` 和项目知识文件。
- 为 context/knowledge 增加 front matter metadata。
- learn draft workflow。
- context-runs 记录采用事实、排除项和未解决问题。

验收：

- Agent 能按上下文地图找到项目知识。
- 每次 spec 能追踪采用了哪些事实、排除了哪些材料、还缺什么信息。
- 中心知识与项目知识冲突时有明确优先级。

### Milestone 4：插件化与多语言

目标：让团队可以扩展自己的 gates、drift parsers 和 context backends。

任务：

- plugin manifest schema。
- gate input/output contract。
- Node/Express/Prisma drift parser。
- Python/FastAPI/SQLAlchemy drift parser。
- adapter compatibility tests。

验收：

- 新 gate 不需要修改 pipeline 核心。
- 新语言 parser 有示例和测试。
- 插件输出能进入 evidence JSON。

## 推荐下一步

1. 用 Lumi 真实业务示例验证完整链路。
2. 做 PR comment contract，让 PR 能直接展示 eval run。
3. 给 context/knowledge 增加 metadata 和 context-runs。
4. 扩展 Node/Python drift parser 和插件协议。
5. 做 eval history aggregation 与 review/TDD trend metrics。
