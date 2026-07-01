# Clarify / Spec / Build / Quality Gate

## 结论

Lattice 的产品工作台可以面向用户呈现为四个主要板块：

```text
Clarify -> Spec -> Build -> Quality Gate
```

这四个主要板块不是另起一套流程，而是 PrismSpec + Lattice 的产品化视图。底层仍由 Agent Skills-compatible skill folders、文件产物、命令 gates 和 evidence 组成。

参考 Google Agent Skills 的做法，每个板块必须满足四个条件：

1. **可发现**：在 `skillpack.yaml` 中有机器可读 block contract。
2. **可触发**：对应 skill 的 `description` 明确 Use when / Don't overlap。
3. **可恢复**：阶段状态来自文件和 `guide.sh --json`，不是对话记忆。
4. **可评估**：有 evals、lint、evidence 或命令输出支撑质量判断；skill 触发样本必须能被 `eval-skills.sh` 回归。

## Agent Skills 对齐原则

Google Agent Skills 示例的关键启示不是某个具体技能内容，而是 packaging discipline：

| Agent Skills 做法 | Lattice / PrismSpec 对应 |
|---|---|
| 一个能力一个 skill folder | `prismspec/skills/prismspec-*/` |
| `SKILL.md` 是核心指令 | 每个 stage 只有一个 canonical `SKILL.md` |
| 长文档放 `references/` | `prismspec/references/` |
| 复杂或确定性逻辑放 `scripts/` | `prismspec/bin/` 和 `lattice/kernel/` |
| 静态模板和资产独立管理 | `prismspec/templates/` |
| 技能需要清晰 trigger 和边界 | lint 检查 frontmatter、evals 和 stage contract；`eval-skills.sh` 检查 trigger fixtures 和相邻阶段碰撞 |

因此，四板块不应该变成四个大 prompt，而应该变成四个可组合、可验证、可发布的能力面。

## 四板块 Contract

| Block | 用户问题 | 主要 Skill | 关键产物 | 通过条件 |
|---|---|---|---|---|
| Clarify | 工程边界到底是什么？哪些问题会阻塞正式 spec？ | `prismspec-grilling`、`prismspec-specification` | `status: clarifying` 的 `spec.md`、Context Basis 中的 selected facts、constraints、conflicts、open questions | blocking questions 已解决或显式记录；上下文依据可追踪 |
| Spec | 做什么、不做什么、如何验收？ | `prismspec-specification` | `spec.md` | `scaffolded: false`；AC 可测试；risk/mode/verification plan 明确；approval 状态存在 |
| Build | 按什么任务顺序实现？每片如何证明？ | `prismspec-planning`、`prismspec-implementation`、`prismspec-debugging` | `plan.md`、task evidence、TDD evidence、debug evidence | task 可独立执行和 review；失败先定位根因；完成受 evidence gate 约束 |
| Quality Gate | 实现是否符合 spec、质量是否可接受、当前仓库是否被真实命令证明？ | `prismspec-review`、`prismspec-verification` | `review.md`、`verify.md`、review package、eval run JSON | 先 read-only review；review 通过后再 fresh command verification；`cannot_verify` 不当作 pass |

## Block 细化

### Clarify

Clarify 的目标是减少 Agent 猜测，不是写长 PRD。

必须回答：

- 用户目标和成功状态是什么；
- 需要读取哪些最小上下文；
- 哪些事实被采用、排除或发现冲突；
- 哪些问题会阻塞进入 Spec；
- 如果继续推进，哪些假设要写入 `spec.md` 的 Context Basis。

当前能力：

- `lattice/context/README.md` context map；
- `spec-template*.md` 的 Context Basis 区块；
- `/clarify` 入口和 `prismspec-grilling`，用于一问一答压实工程边界；
- `status: clarifying`，用于标记尚未收敛为正式合同的 spec draft；
- `prismspec/bin/lint.sh <spec-dir> spec`；
- knowledge backend；
- `prismspec-context-engineering` 用于选择影响 scope/AC/risk 的最小上下文；
- `prismspec-source-grounding` 用于验证外部 API/SDK/模型/平台事实。

主要 gap：

- open questions 还没有独立状态机；
- clarify lint 仍由 `spec-state-lint.sh` 的 `clarifying` 放宽合同承载，还没有独立 `clarify-lint`；
- clarify-focused evals 已覆盖基础触发，但高风险领域样本还可继续扩展。

### Spec

Spec 的目标是形成可执行契约。

必须包含：

- intent / scope / non-goals；
- stable `AC-{n}`；
- contracts 或接口边界；
- risks / invariants；
- execution mode 与 mode source；
- approval 状态；
- verification plan。

当前能力：

- 多模板；
- `new.sh`；
- `lint.sh spec`；
- `spec-state-lint.sh`；
- `spec-status.sh`；
- `prismspec-interface-design` 用于 API、schema、state、event、error、module boundary 契约；
- `prismspec-doubt-review` 用于高风险假设的反向审查。

主要 gap：

- spec lint 仍偏结构化，语义级 AC 质量判断不足；
- context 冲突是否影响 scope 仍依赖 reviewer；
- 缺少 dedicated spec review report。

### Build

Build 的目标不是“让 Agent 写代码”，而是让实现过程可分片、可恢复、可证明。

必须包含：

- AC-traced `plan.md`；
- global constraints 和 task interfaces；
- one task / one evidence cycle；
- TDD red/green evidence when required；
- failure -> debugging -> fix -> rerun；
- progress ledger 或状态推进证据。

当前能力：

- `plan-lint.sh`；
- `task-next.sh`；
- `task-brief.sh`；
- `task-complete.sh`；
- `task-evidence-lint.sh`；
- `tdd-evidence.sh`；
- `prismspec-debugging`。

主要 gap：

- 连续 build run 的 ledger 和 resume 体验还可加强；
- debug evidence 尚未独立结构化成 JSON；
- 多 Agent owner / lease 还未产品化。

### Quality Gate

Quality Gate 的目标是把用户可见流程缩短，但不压缩证据链。它是一个产品动作，内部包含两个 gate：

```text
Review Gate -> Verification Gate
```

Review 判断 intent、diff、实现证据、测试质量和风险是否允许进入最终验证。Verification 运行真实命令或 Lattice pipeline，证明当前仓库状态是否可交付。

#### Review Gate

Review 的目标是独立质量判断，不是实现者自评。

必须包含：

- read-only review；
- task 或 branch review package；
- implementer report 被视为 claims；
- spec compliance / code quality / test coverage / risk verdict；
- `cannot_verify` 不当作 pass；
- Critical/Important finding 阻塞进入 Verify。

当前能力：

- `review-package.sh`；
- `review-summary.sh`；
- `prismspec-review`；
- `prismspec/agents/task-reviewer.md`；
- `prismspec/agents/spec-reviewer.md`、`test-reviewer.md`、`risk-reviewer.md`；
- pipeline review metrics。

主要 gap：

- review dispatch 仍主要靠 Agent 执行，不是独立 runtime；
- final whole-branch review 的自动化程度不足；
- finding lifecycle 只有 review artifact，没有状态流转。

#### Verification Gate

Verify 的目标是用命令证明完成状态。

必须包含：

- fresh command output；
- exit code；
- pass/fail；
- skipped checks and reason；
- residual risks；
- eval run / history / outcome linkage。

当前能力：

- `pipeline.sh`；
- spec lint、AC coverage、drift、compliance；
- eval JSON、summary、history；
- central sink、dashboard、query；
- outcome link/report；
- loop state。

主要 gap：

- drift parser 主要覆盖 Go/Gin/GORM；
- dashboard 还是静态摘要，趋势和过滤不足；
- verification failure 到 build/debug 的闭环可更细。

## 推荐演进顺序

1. **Clarify P0**：把 blocking questions、assumptions、conflicts 做成 `spec.md` Context Basis 可 lint 的明确区块。
2. **Spec P0**：新增 spec review evidence，检查 AC 可测性、scope、risk、context contradiction。
3. **Quality Gate P0**：把 review package -> reviewer -> `review.md` -> verification -> `verify.md` 做成一个用户动作、两个证据产物的可执行闭环。
4. **Build P1**：补 progress ledger、debug evidence JSON、multi-agent lease。
5. **Verify P1**：扩展 Node/Python drift parser 和 dashboard trend。

## 发布标准

任一 block 对外宣称可用前，至少满足：

- `skillpack.yaml` 有 block entry；
- 对应 skill 有 `SKILL.md`、`agents/openai.yaml`、`evals/evals.json`；
- skill trigger fixtures 通过 `bash prismspec/bin/eval-skills.sh --all`；
- 关键产物可由 lint 或 gate 检查；
- smoke test 覆盖 happy path 和至少一个 failure path；
- README 只描述已经可运行或有明确 gap 的能力。
