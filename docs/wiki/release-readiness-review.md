# Lattice 发布验收 Review

日期：2026-06-29

## 结论

Lattice 当前可以作为 **early preview / pilot** 对外发布，用于非关键仓库、新功能试点和团队内部流程验证；不建议明天直接以 “commercial-grade stable” 的口径发布。

核心原因不是主流程跑不通，而是公开下载入口、发布供应链、用户支持面和首日体验还没有达到成熟商业产品标准。

## 验收范围

本次验收覆盖：

- 本地源码仓库的脚本语法、ShellCheck、PrismSpec contract、smoke test 和 Go 示例。
- 远端 GitHub `main` 的 fresh clone 示例体验。
- README 中 remote install 命令的匿名访问体验。
- 文档一致性、CI 覆盖、支持文档和发布可信度检查。

未覆盖：

- Windows / WSL 环境。
- 未安装 `yq`、`git`、Bash 3.2+ 的新手机器。
- 真实业务仓库中的多语言大型项目、复杂 CI、多人并发 spec 管理。
- GitHub 仓库可见性切换后的匿名用户端到端复测。

## 自测结果

| 检查项 | 命令 / 路径 | 结果 |
|---|---|---|
| Bash 语法 | `bash -n init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')` | PASS |
| ShellCheck | `shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')` | PASS |
| PrismSpec contract | `bash prismspec/bin/lint.sh prismspec skillpack` | PASS |
| Smoke test | `bash tests/smoke-test.sh` | PASS，107 / 107 |
| Go 示例 | `bash examples/go-gin-gorm/try-it.sh` | PASS，完成 spec lint、AC coverage、drift check、review evidence、pipeline eval、eval summary/history |
| Release check | `bash tests/release-check.sh` | PASS，remote install 默认跳过；发布前可设置 `LATTICE_CHECK_REMOTE_INSTALL=1` |
| Whitespace | `git diff --check` | PASS |
| 远端 clone 示例 | `git clone --depth=1 https://github.com/zdolphin07-dotcom/lattice.git` 后运行 `examples/go-gin-gorm/try-it.sh` | PASS，但依赖本机已有 GitHub 凭证 |
| README remote install | `bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init` | FAIL，匿名 raw URL 返回 404 |

## P0 发布阻断

### 1. 公开下载入口当前不可用

README 推荐的安装命令：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh) --init
```

当前匿名访问返回 404。`https://github.com/zdolphin07-dotcom/lattice` 匿名访问也返回 404，但本机 `git clone` 可以成功，说明本地凭证可访问，不代表公开用户可访问。

影响：

- 新用户按 README 第一条命令会失败。
- Badge、clone URL、raw install URL 对外都不可验证。
- 任何宣传、文章或社群发布都会在第一步损害信任。

发布前必须完成：

- 确认 GitHub 仓库为 public，或切换 README 到真正公开的仓库地址。
- 用无凭证环境复测 GitHub 页面、raw install、fresh clone、示例运行。
- 复测后再发布安装命令。

### 2. 本地 HEAD 领先远端 main

当前分支 `github-push-main` 比 `github/main` 领先 1 个提交：`65a28c4 Polish PrismSpec release contract`。

影响：

- 本地验证的是最新代码，但远端用户拿到的是 `03e68b7`。
- 本地文档和远端发布内容不完全一致。

发布前必须完成：

- 决定是否把 `65a28c4` 推到 GitHub。
- 推送后重新跑远端 fresh clone 和 remote install。

## P1 商业化可信度 gap

### 1. 安全与支持入口已补齐，仍需建立私有披露渠道

本次已补齐：

- `SECURITY.md`
- `SUPPORT.md`
- GitHub issue templates
- PR template

仍需发布前确认：

- 是否有私有安全披露邮箱或 GitHub private vulnerability reporting。
- 是否把 `SUPPORT.md` 和 `SECURITY.md` 中的公开 URL 指向最终公开仓库。

### 2. CI 还没有覆盖公开用户入口

当前 GitHub Actions 已覆盖 Bash syntax、ShellCheck、PrismSpec skill frontmatter、YAML contract、smoke test、Go 示例和 release check，这是一个不错的底座。

仍有缺口：

- 未在 CI 验证 README remote install URL。
- 未做 macOS / Linux matrix。
- 未验证 tag/release 安装路径。

建议：

- 增加 install smoke job：从公开 raw URL 或 release tarball 安装到空目录并运行 doctor。
- 增加 `ubuntu-latest` + `macos-latest` matrix。

### 3. 供应链与版本发布策略不足

当前 README 使用 `main` 分支安装，适合快速试用，但商业化发布不够稳。

风险：

- `main` 变动会影响所有新安装。
- 没有 tag、release note、checksum 或版本化安装入口。
- 用户难以复现“我当时装的是哪一版”。

建议：

- 发布 `v0.1.0` 或 `v1.0.0-preview.1` tag。
- README 默认使用 tag URL，保留 `main` 作为开发版入口。
- `install.sh --version` 和 `install.sh --dry-run` 已补齐；后续可继续补 `--uninstall` 或正式回滚文档。

## P1 产品体验 gap

### 1. 首日体验仍偏工程内核，不够“一条路径跑通”

README 已补 10 分钟体验路径、支持矩阵和 troubleshooting。新用户仍需要理解多个概念：PrismSpec、spec、plan、review、verify、pipeline、context、eval。

建议：

- 增加 `lattice/kernel/quickstart.sh` 或 `prismspec/bin/demo.sh`，让用户不用手写 spec 也能在空仓库中看到完整闭环。

### 2. 概念仍然偏多

README 的专业度已经提升，但对第一次接触的用户，`Evidence / Eval`、`Loop / Learn`、`central sink`、`dashboard`、`outcome` 同时出现，会让核心价值被稀释。

建议：

- 首屏只讲：Spec、Context、Verify、Evidence。
- Loop / Learn / central sink / dashboard 放到 “Advanced” 或 wiki。
- 商业化叙事优先围绕 “个人 AI Coding 经验如何变成团队工程资产”。

### 3. 安装前置依赖缺少自动诊断提示

README 和 `SUPPORT.md` 已补 Bash 3.2+、`yq`、`git`、remote install 404、Shell 版本异常等提示。

建议：

- `install.sh --init` 在调用 init 前检查并提示 `yq` 安装方式。
- doctor 输出 remediation hint，而不仅是缺失项。

## P2 工程与文档一致性 gap

### 1. `context.md` 迁移后仍有少量残留

本次已清理：

- `CHANGELOG.md` 中过期的 `context-lint.sh` / `context-run.sh` / `context.md` 描述。
- `init.sh` 中默认创建 `lattice/state/context-runs` 和 `context.runs_dir` 的残留。
- `init.sh` 中 “context-run evidence” 的注释。

仍建议后续继续检查：

- Wiki 中所有 Context 设计章节是否都明确：默认 per-spec context contract 是 `spec.md#Context Basis`。
- 旧版本升级场景中如果已有 `lattice/state/context-runs/`，是否需要迁移说明。

### 2. README 与 CHANGELOG 版本语义需要收敛

`CHANGELOG.md` 已有 `[1.0.0]`，但 README 又委婉表达 early iteration。商业上这会产生预期冲突。

建议：

- 如果明天是首次公开发布，考虑使用 `v0.1.0` / `preview` / `beta` 口径。
- 如果保留 `1.0.0`，需要补齐安全、支持、兼容性、版本化安装和公开下载。

### 3. 缺少商业化验收清单

建议把发布前门禁固化为：

```bash
bash -n init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')
shellcheck --severity=warning init.sh install.sh tests/smoke-test.sh $(find harness-template prismspec/bin -name '*.sh')
bash tests/smoke-test.sh
bash examples/go-gin-gorm/try-it.sh
bash prismspec/bin/lint.sh prismspec skillpack
bash tests/release-check.sh
git diff --check
```

同时增加远端验收：

```bash
curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh >/tmp/lattice-install.sh
tmp=$(mktemp -d)
mkdir -p "$tmp/target"
cd "$tmp/target"
bash /tmp/lattice-install.sh --init
bash lattice/kernel/doctor.sh
bash prismspec/bin/doctor.sh
bash prismspec/bin/guide.sh --json
```

## 明天发布建议

如果明天必须发：

1. 先解决 GitHub public/raw install 404。
2. 推送本地领先提交，并重新跑 fresh clone / remote install。
3. 发布口径使用 “early preview / pilot”，不要使用 “stable / commercial-grade”。
4. README 中保留当前 early iteration 说明。
5. 补一个最短 troubleshooting：安装 404、缺 yq、Bash 版本、doctor 失败。

如果可以延后 1-2 天：

1. 增加 `SECURITY.md`、`SUPPORT.md`、issue templates。
2. CI 增加 example demo、remote install 和 macOS matrix。
3. 做 tag-based preview release。
4. 增加 10 分钟 quickstart demo。

## 专家判断

当前项目的工程内核已经有可运行闭环，尤其是 smoke test、spec lint、AC coverage、drift check、review evidence、pipeline eval 和 history summary 这些能力，已经超过普通 prompt/文档型 AI Coding 模板。

距离成熟商业产品的主要差距不在“能不能跑”，而在：

- 公开可获取性和版本化发布；
- 首日用户体验的确定性；
- 安全、支持、兼容性和限制说明；
- 对外口径与当前 maturity 的一致性。

因此，推荐发布策略是：**先以 preview/pilot 发布，强调 repo-local、可审查、可验证的 AI Coding 工程契约；同时用明确 roadmap 承诺持续迭代。**
