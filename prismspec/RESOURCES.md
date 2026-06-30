# PrismSpec 资源包

PrismSpec 的公开资源包只保留三类内容：可安装 skills、可执行模板、风险路由卡。它们共同服务一个目标：用最小必要契约，把一次 AI Coding 任务落到可恢复、可审查、可验证的工程产物。

## 资源清单

| 资源 | 路径 | 用途 |
|------|------|------|
| Skill pack contract | `prismspec/skillpack.yaml` | 机器可读的分发、入口、workflow、模板和 gate 契约 |
| Canonical skills | `prismspec/skills/*/SKILL.md` | Specification、Planning、Implementation、Review、Verification 等阶段行为 |
| Slash commands | `prismspec/commands/` | `/prismspec`、`/spec`、`/plan`、`/implement`、`/review`、`/verify`、`/capture` 入口 |
| Spec templates | `prismspec/templates/` | 通用、lite、service、frontend、tdd 五类规格模板 |
| Risk routing card | `prismspec/references/risk-routing-card.md` | 判断 `plan` / `tdd` 执行强度和证据要求 |
| Alignment references | `prismspec/references/` | Superpowers、Agent Skills、DoD、review、TDD evidence 等对齐规则 |

## 推荐使用路径

1. 先运行 `bash prismspec/bin/doctor.sh`，确认 skill pack 可用。
2. 用 `bash prismspec/bin/new.sh <spec-id> --template=<type> --mode=auto` 创建 spec。
3. 运行 `bash prismspec/bin/guide.sh --spec=<spec-id> --json`，按当前产物路由下一步。
4. 需要判断执行强度时，读取 `prismspec/references/risk-routing-card.md`。
5. 完成后运行 `bash prismspec/bin/lint.sh <spec-dir>`，确认 artifact contract 可恢复。

## 公开口径

PrismSpec 不是 Superpowers 的替代品。Superpowers 已经做好的 brainstorming、planning、TDD、debugging、review、verification discipline，应优先复用。

PrismSpec 的改良点只放在工程契约层：

- 固定人读主产物：`spec.md`、`plan.md`、`review.md`、`verify.md`；
- 固定 Context Basis 在 `spec.md` 内，而不是新增必需 `context.md`；
- 固定 `plan` / `tdd` 两种风险档位；
- 固定机器侧证据是 sidecar，不包装成新的用户阶段；
- 允许 Lattice 托管后接入 context、gates、evidence/eval、loop/learn。
