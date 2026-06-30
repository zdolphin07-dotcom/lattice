# Lattice 发布验收 Review

日期：2026-06-30

## 结论

Lattice 的本地工程闭环已经达到 **commercially credible preview / pilot** 标准：安装、PrismSpec contract、spec/plan/review/verify artifact、delivery gates、eval evidence、Go 示例和 release check 都有可运行证据。

但当前还不应以 **commercial-grade stable** 口径发布。唯一 P0 阻断是公开分发入口：README 默认 remote install URL 在匿名环境下仍返回 `404`。在这个问题解决前，外部用户第一步安装会失败。

## 发布分级

| 发布口径 | 是否建议 | 条件 |
|----------|----------|------|
| 内部试点 / demo | 可以 | 本地 clone、示例、smoke test 和 PrismSpec lint 通过 |
| Public preview / pilot | 可以，但需说明限制 | 公开仓库或 release 可访问，README 安装路径可复现 |
| Commercial stable | 暂不建议 | 需要 tag/release、公开安装 CI、兼容性矩阵、安全披露和支持承诺 |

## 当前验收状态

| 检查项 | 命令 / 路径 | 当前结论 |
|---|---|---|
| Bash 语法 | `bash -n init.sh install.sh tests/smoke-test.sh tests/release-check.sh $(find harness-template prismspec/bin -name '*.sh')` | PASS |
| ShellCheck | `shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh tests/release-check.sh $(find harness-template prismspec/bin -name '*.sh')` | PASS |
| PrismSpec contract | `bash prismspec/bin/lint.sh prismspec skillpack` | PASS |
| Smoke test | `bash tests/smoke-test.sh` | PASS，107 / 107 |
| Go 示例 | `bash examples/go-gin-gorm/try-it.sh` | PASS，spec lint、AC coverage、drift check、review evidence、pipeline eval、eval summary/history 均通过 |
| Release check | `bash tests/release-check.sh` | PASS，remote install 默认跳过 |
| Whitespace | `git diff --check` | PASS |
| Remote install | `curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh` | **FAIL：匿名访问 404** |

## P0 发布阻断

### 公开安装入口不可用

README 推荐的安装命令依赖：

```bash
https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh
```

当前匿名访问返回 `404`。这通常意味着仓库不是 public，或 raw URL 不在公开分发路径上。

发布前必须完成：

- 确认 GitHub 仓库为 public，或创建公开 release/tag 分发地址。
- 在无凭证环境复测 GitHub 页面、raw install、fresh clone 和示例运行。
- 将 README 默认安装路径切到稳定 tag URL；`main` 只保留为开发版入口。
- 设置 `LATTICE_CHECK_REMOTE_INSTALL=1` 跑完整 release check。

## P1 商业化可信度

### 版本化发布

当前 `prismspec/skillpack.yaml` 使用 `0.1.0`，`CHANGELOG.md` 仍保留历史 `[1.0.0]` 段落。公开发布时建议选择一个明确口径：

- preview：发布 `v0.1.0` 或 `v0.1.0-preview.1`；
- stable：只有在公开安装、安全披露、兼容性矩阵和支持流程都通过后再使用 `v1.0.0`。

### CI 覆盖

已有 GitHub Actions 覆盖 Bash syntax、ShellCheck、smoke test、Go 示例和 release check。建议补强：

- macOS + Ubuntu matrix；
- tag/release install smoke；
- `LATTICE_CHECK_REMOTE_INSTALL=1` 的公开路径定时或 release job；
- README 命令 copy-paste smoke。

### 首日体验

README 已经给出 10 分钟体验路径。为了进一步降低试用摩擦，后续可以增加：

- `prismspec/bin/demo.sh` 或 `lattice/kernel/quickstart.sh`；
- 一个空仓库最小闭环 demo；
- 安装失败时更具体的 `yq` / shell / URL remediation hint。

## PrismSpec 与文章资源承诺对齐

当前项目已具备：

- PrismSpec skills：`prismspec/skills/*/SKILL.md`；
- 轻量 Spec 模板：`prismspec/templates/spec-template-lite.md`；
- TDD 模板：`prismspec/templates/spec-template-tdd.md`；
- Superpowers 对齐说明：`prismspec/references/superpowers-alignment.md`；
- 资源包入口：`prismspec/RESOURCES.md`；
- 需求风险分级卡片：`prismspec/references/risk-routing-card.md`。

对外文章应同步当前实现口径：

- 不再使用 `brainstorm -> plan -> implement -> verify -> finish` 作为 PrismSpec 官方流程；
- 使用 `Clarify -> Spec -> Build -> Review -> Verify` 作为产品板块；
- 内部阶段写作 `specification -> planning -> implementation(plan|tdd) -> review -> verification`；
- 人读主产物是 `spec.md`、`plan.md`、`review.md`、`verify.md`；
- `review-summary.json` 是机器侧 sidecar，不是 review 的主产物；
- 不承诺必需 `context.md`；Context Basis 写入 `spec.md`。

## 发布前命令

本地发布检查：

```bash
bash -n init.sh install.sh tests/smoke-test.sh tests/release-check.sh $(find harness-template prismspec/bin -name '*.sh')
shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh tests/release-check.sh $(find harness-template prismspec/bin -name '*.sh')
bash prismspec/bin/lint.sh prismspec skillpack
bash tests/smoke-test.sh
bash examples/go-gin-gorm/try-it.sh
bash tests/release-check.sh
git diff --check
```

公开安装检查：

```bash
LATTICE_CHECK_REMOTE_INSTALL=1 bash tests/release-check.sh
```

只有两组都通过，README 默认安装命令才适合进入对外发布材料。

## 专家判断

项目真正有价值的部分已经成立：PrismSpec 把模糊意图压缩成工程契约，Lattice 把契约接入 repo-local context、verification 和 evidence loop。这比单纯 prompt 模板更接近团队可采用的工程产品。

当前最后一公里不是再增加概念，而是完成发布供应链：公开可获取、版本可复现、首日路径可跑通、支持边界清楚。解决 P0 后，可以用 **risk-adaptive Spec Coding workflow + repo-local AI Coding control plane** 的口径发布 preview；等版本化安装和支持面补齐后，再升级 stable 口径。
