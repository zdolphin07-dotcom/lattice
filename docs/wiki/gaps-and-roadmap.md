# Gap 与 Roadmap

## 总体判断

Lattice 当前处于“可交付的最小工程框架”阶段，而不是完整平台阶段。

路线成立的原因：

- AI Coding 的核心痛点确实集中在上下文边界和验证边界。
- repo-local 形态降低了团队试点成本。
- Bash + YAML + Markdown 足够支撑早期 contract，不需要先做平台。
- PrismSpec 独立后，轻量用户可以只采用 SDD skills，团队用户再接入 Lattice gates。

主要风险：

- README/wiki 如果承诺过满，会让用户误以为 Eval、Loop、Knowledge governance 已完整产品化。
- 示例项目还不够真实，难证明框架能覆盖复杂业务。
- 多语言 drift 和插件协议还在雏形阶段。

## 已成立的能力

| 方向 | 当前证据 | 判断 |
|------|----------|------|
| PrismSpec | canonical skills、guide.sh、lint.sh、多模板、Plan/TDD policy | 主链路成立 |
| Harness | pipeline、spec-lint、AC coverage、drift、compliance、spec-lock | 最小验证闭环成立 |
| Knowledge | loader、sync、index、synonyms、learn 约定 | 最小可用 |
| AI 友好 | AGENTS.md、SKILL.md、commands、JSON guide | 入口比早期清晰 |
| 安装验证 | install/init/smoke test/CI | 可持续迭代 |

## 主要 gap

### P0：产品可信度

| Gap | 影响 | 建议 |
|-----|------|------|
| 示例项目偏 toy | 用户难判断真实价值 | 用 Lumi 等真实业务示例跑完整 spec 迭代 |
| README/wiki 曾偏长且旧 | 入口认知成本高 | 保持 README 产品化，wiki 设计化 |
| Eval 仍是文本证据 | 容易被理解为完整评估平台 | 明确 current vs planned，推进 JSON |

### P1：SDD 与 Evidence

| Gap | 影响 | 建议 |
|-----|------|------|
| Review verdict 未结构化 | 难进入 gate 和指标 | `review-summary.json` |
| TDD red/green 未结构化 | 难证明真实 TDD | `tdd-evidence.json` |
| Spec 状态机较弱 | drafted/planned/verified 不可强校验 | front matter schema + spec-lint |
| Plan lint 轻量 | 任务质量依赖 Agent 自觉 | plan schema 或 plan-lint |

### P1：Knowledge Governance

| Gap | 影响 | 建议 |
|-----|------|------|
| 无 metadata | 来源、owner、过期不可治理 | knowledge front matter |
| 无 stale/conflict | 旧规则误导 Agent | `knowledge-lint.sh` |
| learn 仍靠人工 | 失败经验沉淀不稳定 | escalation learn draft |
| 无命中记录 | 不知道知识是否有效 | loader output 写 eval run |

### P1：Eval 与 Loop

| Gap | 影响 | 建议 |
|-----|------|------|
| pipeline 无 JSON 输出 | 无趋势分析 | `--json-out` |
| 无 run id/spec hash/git sha | 难复盘 | eval run schema |
| retry 状态不落盘 | loop 不可审计 | loop state JSON |
| CI artifact 未固定 | 数据留存不稳定 | GitHub Actions 上传 eval runs |

### P2：生态与扩展

| Gap | 影响 | 建议 |
|-----|------|------|
| drift 主要覆盖 Go/Gin/GORM | 多语言说服力不足 | Node/Python parser examples |
| 插件协议偏命令字符串 | 难治理输入输出 | plugin manifest/schema/versioning |
| 多 Agent 协作较轻 | 只解决文件锁 | owner + lease + state |
| shell 复杂度增长 | 长期维护成本上升 | 保留 bash facade，复杂解析迁移到小工具 |

## Roadmap

### Milestone 1：真实示例闭环

目标：用一个真实业务项目跑通完整 PrismSpec + Lattice 流程。

任务：

- 选择 Lumi 作为示例项目。
- 从需求生成 `spec.md`、`plan.md`、`verify.md`、`summary.md`。
- 记录遇到的 Lattice gap。
- 更新 example README，展示真实业务链路。

验收：

- 用户能看到一次完整 AI Coding 迭代。
- 示例不是纯脚手架或假测试。

### Milestone 2：Evidence 结构化

目标：让验证证据可被 CI、dashboard 和后续 Agent 消费。

任务：

- `pipeline.sh --json-out`。
- eval run schema。
- AC coverage / drift findings 写入 JSON。
- review verdict JSON。
- TDD evidence JSON。

验收：

- CI 能上传 eval artifact。
- `summary.md` 能引用 eval run。

### Milestone 3：Knowledge 治理

目标：让知识库成为可审计资产。

任务：

- knowledge front matter schema。
- `knowledge-lint.sh`。
- stale/conflict detection。
- learn draft workflow。
- loader 命中记录进入 eval run。

验收：

- 过期知识能被发现。
- 每次 spec 能追踪使用了哪些知识。

### Milestone 4：插件化与多语言

目标：让团队可以扩展自己的 gates 和 drift parsers。

任务：

- plugin manifest schema。
- gate input/output contract。
- Node/Express/Prisma drift parser。
- Python/FastAPI/SQLAlchemy drift parser。
- adapter compatibility tests。

验收：

- 新 gate 不需要修改 pipeline 核心。
- 新语言 parser 有示例和测试。

## 推荐下一步

优先级建议：

1. 用 Lumi 真实业务示例验证框架。
2. 做 `pipeline --json-out` 和 eval run schema。
3. 做 knowledge front matter 与 `knowledge-lint.sh`。
4. 做 review/TDD evidence JSON。
5. 再扩展多语言 drift 和插件协议。
