# Gap 与 Roadmap

## 总体判断

Lattice 当前已经达到“可试点的 repo-local AI Coding harness”阶段：安装、SDD 引导、目录化 spec、`spec.md` 内嵌 Context Basis、基础 gates 和 smoke test 都已形成闭环。

它还不是完整平台。现阶段应继续保持边界克制：先把可复现证据、真实示例、静态 dashboard 和多语言扩展做扎实，再考虑协作平台或复杂治理。

## 已成立的能力

| 方向 | 当前证据 | 判断 |
|------|----------|------|
| Product blocks | `skillpack.yaml` product_blocks、Clarify/Spec/Build/Review/Verify wiki、Agent Skills adapter | 产品面开始成型 |
| PrismSpec | canonical skills、new.sh、doctor.sh、guide.sh、skillpack/artifact lint.sh、spec-state-lint、spec-status、plan-lint、task-next、task-complete、task-evidence-lint、summary-draft、多模板、Plan/TDD policy | 主链路成立 |
| Spec contract | 自包含 `spec.md` 目录化产物、Context Basis、artifact lint | 可作为默认产物形态 |
| Context | context map、project knowledge、external entry、knowledge backend、summary-learn-draft、knowledge governance lint、knowledge review evidence、sync | 最小可用 |
| Verification / Evidence | pipeline、spec-lint、PrismSpec lint、AC coverage、drift、compliance、spec-lock、eval summary/history、outcome link/report | 最小验证闭环成立 |
| AI 友好 | AGENTS.md、SKILL.md、slash commands、JSON guide | 入口清晰 |
| 安装验证 | install/init/doctor manifest 与 skillpack contract check/smoke test/CI | 可持续迭代 |

## 主要 Gap

### P0：五板块产品面

| Gap | 影响 | 建议 |
|-----|------|------|
| Clarify lint 仍偏轻 | 已有 `/clarify`、`prismspec-grilling` 和 `status: clarifying`，但还没有独立 `clarify-lint` | 在 `spec-state-lint.sh` 之外补 clarify draft 语义检查与高风险 eval fixtures |
| Spec review 仍偏弱 | AC 可测性、scope 过大、risk 缺失仍依赖 Agent 自觉 | 增加 spec-review evidence 或 spec semantic checklist gate |
| Review runtime 不完整 | 已有 reviewer persona、`review.md` 和 JSON sidecar，但 dispatch/finding lifecycle 仍靠 Agent | 建 review package -> reviewer -> review.md -> blocking gate 的标准执行路径 |
| Superpowers worktree isolation 未产品化 | Superpowers 的发布工作流会在设计批准后进入隔离 workspace；Lattice 当前依赖宿主 Agent 或用户手工分支 | 在 adapter/host 层补 `worktree preflight`，不放进 PrismSpec 主产物契约 |
| Agent Skills 安装体验未封装 | Skill folder、metadata、eval 已齐，但还没有一键 link/install 到 `.agents/skills` 或目标 agent 的命令 | 增加 install/link helper 与 release packaging smoke |

### P0：产品可信度

| Gap | 影响 | 建议 |
|-----|------|------|
| 示例项目仍偏小 | 用户难判断复杂业务价值 | 用 Lumi 等真实业务示例跑完整 spec 迭代 |
| README 与 wiki 需要持续同步 | 入口认知一旦过期会降低信任 | README 只讲当前可用能力；wiki 讲设计和路线；机器侧 sidecar 不包装成用户阶段 |
| Evidence 已有 pipeline/gate JSON、spec-state-lint、spec-status、spec transition events/history、plan-lint、task-next、task-complete、task-evidence-lint、summary-draft、summary-learn-draft、loop state、outcome link/report、central eval sink、static dashboard、eval query、可配置 failure category、escalation learn draft、knowledge review event、promotion event、knowledge metadata/governance lint、process evidence、Markdown summary、history report、CI artifact 与 PR comment 模板 | 数据已经可汇总和查询，团队视角仍需要更强趋势分析 | dashboard trend |

### P1：Evidence / Eval 与 Loop

| Gap | 影响 | 建议 |
|-----|------|------|
| learn promotion 质量治理仍偏轻量 | 已有 metadata/source/placeholder/conflict/expiry lint 和 reviewer evidence，但缺少语义级冲突判断 | semantic conflict resolution |
| Dashboard 仍是静态文件 | central sink 已有文件协议、本地 HTML 和 CLI/JSON 查询，但缺少交互过滤与跨项目趋势视图 | dashboard trend |

### P1：Context 治理

| Gap | 影响 | 建议 |
|-----|------|------|
| 项目知识仍需要真实填充 | Agent 只能看到结构，缺少领域事实 | 在真实示例中填充 architecture/rules/pitfalls/glossary |
| central sync 仍是轻量文件同步 | 只能解决基础共享，不能解决治理 | 增加 source trust、staleness policy 和 review evidence sync |
| promotion 前质量判断仍需要 reviewer | lint 能发现结构风险，review event 能记录决策，但不能判断语义正确性 | semantic conflict resolution |

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
- 从需求生成 `spec.md`、`plan.md`、review evidence 和 `verify.md`。
- 记录遇到的 Lattice gap。
- 更新 example README，展示真实业务链路。

验收：

- 用户能看到一次完整 AI Coding 迭代。
- 示例不是纯脚手架或假测试。
- spec、plan、review、verification、learn draft 都有真实内容。

### Milestone 2：Evidence 结构化

目标：让验证证据可被 CI、dashboard 和后续 Agent 消费。

任务：

- cross-project outcome attribution。
- dashboard trend improvements。
- richer trend metrics。

验收：

- CI 能上传 eval artifact。
- eval run 包含 gate evidence 与 process evidence。
- eval run 包含 loop state。
- outcome event 能关联 eval run，并进入 summary/history/report。
- central eval sink 能汇总多项目 evidence。
- retry exhausted 时能生成 context learn draft。
- learn draft 可以被 review、promote 或 discard，并留下审计事件。
- promotion 后能运行 knowledge governance lint。
- 本地能生成 history report。
- `verify.md` 或可选 `summary.md` 能引用 eval run。
- 每次交付能追踪 run id、spec hash、git sha 和 kernel version。

### Milestone 3：Context 治理

目标：让 Agent 稳定找到、筛选和压缩项目上下文，并知道哪些知识可信、过期或冲突。

任务：

- 在真实示例中填充 `lattice/context/README.md`、`external.md` 和项目知识文件。
- 增加跨文件 semantic conflict resolution。
- outcome event 的跨项目归因分析。

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
2. 增加 cross-project outcome attribution。
3. 扩展跨文件 semantic conflict resolution。
4. 扩展 Node/Python drift parser 和插件协议。
5. 用 Lumi 真实业务示例继续压测完整链路。
