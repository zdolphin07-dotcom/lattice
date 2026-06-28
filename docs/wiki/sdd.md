# PrismSpec / SDD 设计

## 结论

PrismSpec 是 Lattice 中独立出来的渐进式 Spec-Driven Development skill pack。它的目标不是增加流程仪式，而是给 AI Coding 提供一条可恢复、可审查、可验证的最小链路：

```text
Intent -> Brainstorming -> Planning -> Implementation(plan|tdd) -> Verification -> Finishing
```

`/sdd` 是 controller，不是第六个阶段。它读取现有产物，判断下一步应该执行哪个阶段 skill。

```bash
bash prismspec/bin/guide.sh --json
```

## Host 模式

PrismSpec 有两种运行形态：

| 模式 | 触发条件 | 产物路径 | 验证入口 |
|------|----------|----------|----------|
| Standalone | 无 `lattice/manifest.yaml` | `prismspec/specs/<id>/`、`.prismspec/runs/<id>/` | 检测本地 build/lint/test 命令 |
| Lattice-hosted | 存在 `lattice/manifest.yaml` | `lattice/specs/<id>/`、`.lattice/sdd/<id>/` | `bash lattice/kernel/delivery/pipeline.sh --json-out` |

Lattice-hosted 模式会额外使用 manifest、项目 context 地图、verification gates 和项目配置。Standalone 模式只保留 Spec Coding 主链路，适合只想使用 skill pack 的用户。

## 阶段与产物

| 阶段 | 目标 | 持久产物 | 临时证据 |
|------|------|----------|----------|
| Brainstorming | 明确 intent、scope、context、AC、risk、mode | `context.md`、`spec.md` | 需求澄清记录可写入 spec |
| Planning | 将 spec 拆成 AC-traced tasks | `plan.md` | 相关代码边界和任务验证说明 |
| Implementation | 执行 plan 或 TDD | code / tests | `brief.md`、`review-package.md` |
| Verification | 用外部命令证明结果 | `verify.md` | pipeline output、test output |
| Finishing | 关闭本次交付并提炼知识候选 | `summary.md` | review verdict、learn draft |

产物设计原则：

- `spec.md`、`plan.md`、`verify.md`、`summary.md` 是可版本化资产。
- `.lattice/sdd/` 与 `.prismspec/runs/` 是执行证据目录，默认不作为长期知识。
- review package 是审查输入，不等于 verification evidence。

## Brainstorming

Brainstorming 是第一阶段，产物是 `context.md` 和 `spec.md`。它不是随意头脑风暴，而是先固化上下文依据，再把需求压缩成可执行契约。

必须明确：

- 要解决的问题和成功状态；
- 本次做什么、不做什么；
- 可测试的 `AC-{n}`；
- 会影响实现和验证的上下文依据；
- 风险、不变量和执行模式；
- 验证计划。

### 为什么读取 `manifest.yaml`

在 Lattice-hosted 模式下，Brainstorming 需要读取 `lattice/manifest.yaml`，但目的不是把 manifest 当业务上下文，而是获取项目路由：

- spec 放在哪里；
- context 地图在哪里；
- 默认 execution mode 是什么；
- verification command 是什么；
- 项目启用了哪些 verification gates。

Brainstorming 不应该全量复制 manifest、代码或知识库到 spec。Agent 应先读取项目 context 地图，再按需查找相关代码、测试、schema、历史 spec、项目知识和外部知识。`context.md` 只记录被采用的事实、引用、冲突和开放问题；`spec.md` 只保留影响 Scope、AC、Risk、Execution Policy 的结论。

## Spec 模板策略

Spec 模板可以覆盖。默认模板位于：

```text
prismspec/templates/spec-template.md
```

项目可通过 `lattice/manifest.yaml` 指定：

```yaml
specs:
  template: "prismspec/templates/spec-template-service.md"
  default_execution_mode: "auto"
  allow_execution_mode_override: true
```

默认提供五类模板：

| 模板 | 场景 | 重点 |
|------|------|------|
| `spec-template.md` | 通用需求 | Intent、Scope、AC、Contract、Risk、Verification |
| `spec-template-lite.md` | 低风险文档、配置、简单重构 | AC-first，少写设计 |
| `spec-template-service.md` | 后端 API、数据、状态、幂等 | API、schema、state、rollback |
| `spec-template-frontend.md` | 前端体验和交互 | user journey、edge states、a11y、visual checks |
| `spec-template-tdd.md` | bug fix 和高风险链路 | regression boundary、invariants、red tests |

团队可以替换模板，但不建议删除这些语义：Intent、Scope、AC、Risk、Execution Policy、Verification Plan。

## Plan Mode 与 TDD Mode

Plan Mode 和 TDD Mode 是 execution policy，不是两套 workflow。

| 模式 | 使用场景 | 证据要求 |
|------|----------|----------|
| `plan` | 低风险功能、文档、配置、脚手架、简单重构、已有测试覆盖充分 | `plan.md` 任务、必要测试、验证命令 |
| `tdd` | bug fix、核心链路、权限、安全、资金、状态机、并发、幂等、迁移、历史回归 | red test、green test、AC-to-test trace、完整相关验证 |

选择顺序：

1. 用户单次 override 优先。
2. 项目默认 `specs.default_execution_mode` 次之。
3. 否则模型按风险选择，并记录 `mode_source: model-selected`。

模式变更规则：

- `plan -> tdd`：发现高风险或回归风险时允许升级。
- `tdd -> plan`：需要显式用户 override，不应静默降级。
- 模式选择必须写入 `spec.md` 的 front matter 和 Execution Policy。

## Planning

Planning 将 `spec.md` 转成 `plan.md`。好的 plan 不是任务清单堆砌，而是让 Agent 可以分片执行、reviewer 可以分片审查、gate 可以分片验证。

每个任务应该包含：

- stable task id，如 `T1`、`RED-1`；
- 对应的 `AC-{n}`；
- `Mode` 和一句话 `Scope`，避免执行时重新解释任务边界；
- 触达文件或契约；
- 输入、输出和约束；
- 明确的验证命令、测试名或 gate；
- task brief、review package 等 evidence 路径；
- done condition。

`plan.md` 必须覆盖 `spec.md` 中的每个 AC。TDD mode 必须先生成 `RED-{n}` red-test tasks，再生成 `T{n}` implementation tasks；red task 记录预期失败、测试文件和验证命令，implementation task 记录对应的 evidence 位置。

## Implementation

Implementation 只执行 `plan.md` 中的下一片任务。

在 Lattice-hosted mode 中，Implementation 应先运行：

```bash
bash lattice/kernel/orchestrator/sdd/task-next.sh <spec-id> --json
```

它返回下一项未完成任务或 `status=complete`。Agent 不应该凭最近修改时间或自然语言猜测下一项任务。

任务完成后，应使用 `task-complete.sh` 勾选对应 task，而不是直接编辑 checkbox：

```bash
bash lattice/kernel/orchestrator/sdd/task-complete.sh <spec-id> <task-id> --json
```

该命令会先检查 task brief、review package 和 TDD evidence（当适用），证据不足时拒绝勾选。

Plan Mode：

1. 读取下一项任务。
2. 生成或维护 task brief。
3. 实现最小变更。
4. 对行为变化补测试或写明无需测试的理由。
5. 运行 focused verification。
6. 生成 review package。
7. 需要 review 时写出 `review-summary.json`。

TDD Mode：

1. 写红灯测试。
2. 确认红灯因预期行为失败。
3. 实现最小代码到绿灯。
4. 绿灯后再重构。
5. 记录 red/green evidence，并写出 `tdd-evidence.json`。

Implementation 不应该：

- 暗中扩大 scope；
- 为了通过测试而弱化测试；
- 把 unrelated refactor 混进同一任务；
- 用 review package 替代 verification。

## Verification

Verification 是独立证明阶段。它必须运行实际命令，并把结果写入 `verify.md`。

Lattice-hosted 模式：

```bash
bash lattice/kernel/delivery/pipeline.sh --json-out
```

Standalone 模式按项目检测：

- Node：`npm run build`、`npm run lint`、`npm test`
- Python：`ruff check .`、`pytest`
- Go：`go test ./...`
- Rust：`cargo test`

`verify.md` 至少记录：

- command；
- exit code；
- pass/fail；
- failure summary；
- rerun result；
- remaining risk。

## Finishing

Finishing 关闭本次 spec run。它不是重复写一遍需求，而是留下未来可恢复的证据：

- spec id 和状态；
- AC 完成情况；
- 变更摘要；
- verification evidence；
- review verdict / `review-summary.json`；
- residual risks；
- deferred work；
- knowledge candidates。

Lattice-hosted mode 应先生成 closeout 草稿：

```bash
bash lattice/kernel/orchestrator/sdd/summary-draft.sh <spec-id> --eval-json=<eval-json>
```

草稿来自 `spec.md`、`plan.md`、`verify.md`、task evidence 和可选 eval JSON。Agent 可以补充业务上下文，但不应删除失败、跳过、`cannot_verify` 或 residual risk 证据。

如果 `summary.md` 中存在 Knowledge Candidates，先生成可审查 draft：

```bash
bash lattice/kernel/context/summary-learn-draft.sh <spec-id>
```

只有 durable、可复用、非敏感的经验才进入 knowledge。一次性的实现细节留在 `summary.md`；候选经验必须先经过 review / promote，而不是直接写入项目知识库。

## Skills 设计

canonical skills 位于：

```text
prismspec/skills/
├── sdd/SKILL.md
├── brainstorm/SKILL.md
├── plan/SKILL.md
├── implement/SKILL.md
├── verify/SKILL.md
├── finish/SKILL.md
└── learn/SKILL.md
```

PrismSpec 不再维护 flat Markdown wrapper。主入口只读取 canonical `SKILL.md`，避免同一流程出现多个事实源。

## 当前实现边界

已实现：

- `new.sh` 初始 `context.md` / `spec.md` 目录化产物创建，并用 `scaffolded: true` 标记未完成骨架。
- `guide.sh` artifact-based routing；当 spec 仍是 scaffolded 时继续路由到 Brainstorming。
- `doctor.sh` standalone / Lattice-hosted skill pack 健康检查。
- `lint.sh` skillpack / spec / plan / evidence contract 校验。
- canonical skill folders。
- canonical skill `agents/openai.yaml` UI/发现元数据。
- 多模板策略。
- Lattice-hosted 与 standalone 路径分流。
- task brief / review package / review summary / TDD evidence helper。
- learn draft promotion/discard workflow。
- summary knowledge candidate to learn draft helper。
- knowledge governance lint。
- knowledge metadata lint。
- context-run evidence。
- knowledge review evidence。
- outcome link evidence。
- outcome attribution report。
- central eval sink。
- static eval dashboard。
- eval query。
- context-lint。
- plan-lint。
- task-evidence-lint。
- spec-state-lint。
- spec-status guarded transition helper。
- spec transition JSON events。
- spec-history Markdown report。

尚未完成：

- transition event dashboard 趋势视图。
- 更强结构化 plan schema。
- dashboard 趋势增强。

## 演进优先级

1. 增强 spec transition event dashboard 趋势视图。
2. 增强 plan schema 和任务完成证据的结构化归因。
3. 增强 dashboard 过滤和趋势视图。
4. 增加跨项目 outcome attribution 分析。
5. 用真实项目迭代模板和 mode 选择策略。
