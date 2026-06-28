# Gap 与 Roadmap

## 总体评估

Lattice 的技术路线可行，原因是它抓住了 AI coding 团队化落地中最稳定的两个痛点：

- 上下文边界：Agent 看不到业务规则、历史决策和团队约定。
- 验证边界：Agent 自己生成、自己验收，容易遗漏同一类盲点。

它选择的工程形态也合理：repo-local、bash + YAML、agent-agnostic、kernel/data 分离。这让它可以先在真实项目里低成本试点，而不是先做成大平台。

但当前实现还不能称为完整的团队级 AI coding platform，更准确的阶段判断是：

> 已具备最小可运行 harness，正在从方法论 scaffold 走向可度量工程系统。

## 已成立的部分

| 方向 | 当前证据 | 判断 |
|------|----------|------|
| SDD | Spec 模板、spec-lint、AC 编号、PrismSpec canonical skills、guide.sh、lint.sh、plan/tdd 执行策略、task brief、review package、review personas | 路线成立，下一步是把 review verdict 与 eval JSON 进一步结构化 |
| 知识库 | loader、sync、index、synonyms、learn 约定 | 最小可用，需补治理和元数据 |
| Eval | gate 输出、AC coverage、drift check、CI smoke test | 有雏形，需结构化数据 |
| Loop | retry budget、exit 2 escalation | 有半闭环，需状态落盘和 learn draft |
| 可插拔 | manifest steps、drift.plugins、adapter docs | 方向正确，需协议化和版本化 |

## 主要 gap

### P0：产品可用性 gap

| Gap | 影响 | 建议 |
|-----|------|------|
| GitHub 发布流程不显式 | 本地有多个 remote，容易推错目标 | 明确 release/push 流程 |
| `origin` 指向内部 remote，GitHub remote 是 `github` | 容易误 push 或文档与发布不一致 | 明确 release/push 流程 |
| install/init 还缺失败回滚 | 初始化中途失败可能留下半安装状态 | 增加 dry-run、rollback、idempotency 测试 |
| README 宣称 Eval，但 Eval 仍是 gate 文本 | 期望过高 | 在文档中标注 current vs planned |

### P1：SDD gap

| Gap | 影响 | 建议 |
|-----|------|------|
| Review verdict 仍偏文本 | 语义 review 难进入趋势分析和发布决策 | 将 reviewer 输出收敛为 `review-summary.json` |
| Spec 状态未被 gate 消费 | 不知道 drafted/planned/implemented/verified/finished 是否可信 | 让 `spec-lint` 校验 front matter |
| Execution policy 只做最小校验 | Plan Mode 和 TDD Mode 的证据强度还不能完全自动判断 | 强化 `prismspec/bin/lint.sh` 并联动 AC coverage |
| Plan lint 仍是轻量规则 | 能检查 AC/任务/验证，但不能理解复杂依赖 | 增加可选结构化 plan schema |
| TDD/review evidence 仍偏文本 | 无法自动确认 red-before-green、AC-to-test、review verdict | 增加 TDD/review evidence JSON |
| 产物目录分散 | review 一次需求时上下文不集中 | 改为 `lattice/specs/<id>/{spec,plan,verify,summary}.md` |

### P1：知识库 gap

| Gap | 影响 | 建议 |
|-----|------|------|
| 知识条目无 metadata | 难以治理来源和过期 | front matter schema |
| 无 stale/conflict 检测 | 旧知识误导 Agent | `knowledge-lint.sh` |
| learn 只是文档约定 | 失败经验沉淀不稳定 | escalation 生成 learn draft |
| 检索无 ranking | 命中质量不稳定 | exact/synonym/tag/fuzzy 分层 |

### P1：Eval gap

| Gap | 影响 | 建议 |
|-----|------|------|
| 输出不可机器消费 | 无趋势、无对比 | `--json-out` |
| 无 run_id/spec_hash/git_sha | 无法复盘 | eval run schema |
| 无 review findings | 只有结构质量，没有语义质量 | review finding schema |
| 无 agent/kernel version | 无法比较工具或版本 | 记录 agent、model、kernel version |

### P2：扩展性 gap

| Gap | 影响 | 建议 |
|-----|------|------|
| drift 主要支持 Go/Gin/GORM | 多语言说服力不足 | plugin examples for Node/Python |
| 插件协议只有命令字符串 | 难治理输入输出和版本 | plugin manifest schema |
| 多 agent 锁较轻 | 只解决同 Spec 文件冲突 | spec state + owner + lease |
| Shell 脚本复杂度会增长 | 长期维护成本上升 | 保留 bash facade，复杂解析迁移到小工具 |

## Roadmap

### Milestone 1：可信最小闭环

目标：让一个真实项目可以稳定完成 Brainstorming -> Planning -> Implementation -> Verification -> Finishing。

建议任务：

- README 中真实 GitHub URL 替换占位。
- `pipeline.sh --json-out` 输出 eval run JSON。
- `spec-lint` 校验 front matter schema。
- 强化 `prismspec/bin/lint.sh` 的 plan/evidence checks。
- Smoke test 覆盖 canonical skills 安装、modern spec lint、PrismSpec lint、pipeline/eval JSON。

验收标准：

- 示例项目可以一键跑通。
- CI 产出 eval JSON artifact。
- 用户能从 wiki 理解 current vs planned。

### Milestone 2：知识治理闭环

目标：让知识库不是 prompt 杂货铺，而是可审计资产。

建议任务：

- 知识条目 front matter schema。
- `knowledge-lint.sh` 检查 source_ref、owner、expires_at、confidence。
- `loader.sh` 输出 matched entries 到 eval run。
- escalation 自动生成 learn draft。
- central knowledge read-only 模式跑通。

验收标准：

- 过期知识能被检测。
- 每次 Spec 生成可追踪用了哪些知识。
- 失败经验能进入 draft，而不是直接污染 verified knowledge。

### Milestone 3：Eval 与 Loop 数据化

目标：能回答“Lattice 是否真的提升质量”。

建议任务：

- `lattice/state/eval-runs/*.json`
- `lattice/state/loops/*.json`
- `lattice eval report` 汇总最近 N 次运行
- failure_category 分类
- review findings schema

验收标准：

- 能统计 first-pass pass rate、retry count、drift count、AC coverage。
- 能定位最常失败的 gate 和 failure category。
- 能把 review 问题纳入一次交付记录。

### Milestone 4：插件生态

目标：让语言/框架差异通过插件扩展，而不是堆进核心 bash。

建议任务：

- 定义 plugin manifest：

```yaml
name: fastapi-route-drift
type: drift
version: 0.1.0
inputs:
  - SPEC_FILE
  - PROJECT_ROOT
command: "python scripts/fastapi_route_drift.py ${SPEC_FILE} ${PROJECT_ROOT}"
outputs:
  format: json
exit_codes:
  pass: 0
  fail: 1
  escalation: 2
```

- 提供 Node/Express、Python/FastAPI、OpenAPI、protobuf 示例插件。
- CI 中跑插件契约测试。

验收标准：

- 新语言支持无需修改核心 pipeline。
- 插件输出可进入 eval JSON。
- 插件版本可记录和回放。

## 推荐优先级

最建议下一步做：

1. 修正文档和安装 URL 的占位问题。
2. 给 pipeline 增加 JSON evidence 输出。
3. 给 Spec/Knowledge 增加 front matter schema。
4. 强化 PrismSpec lint，并增加 knowledge-lint。
5. 做一个真实项目 dogfood 记录，把 loop 数据跑出来。

暂时不建议做：

- 大型 Web UI
- 自研 agent runtime
- 全量 RAG 平台
- 过度复杂的多 agent 调度
- 用 LLM 直接判定所有语义质量
