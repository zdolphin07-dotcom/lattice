# Context Layer

Context 层负责给 AI Agent 提供可靠的项目上下文。主入口是 `lattice/context/README.md`，不是 shell 命令。

## Agent Flow

1. 读取 `lattice/context/README.md`。
2. 根据上下文地图查找相关项目知识、外部引用、代码、测试、schema、接口契约和历史 spec。
3. 只选择会影响 scope、AC、risk、interface、compatibility 或 verification 的事实。
4. 将本次采用的上下文依据写入 `lattice/specs/<spec-id>/context.md`。
5. 基于 `context.md` 编写 `spec.md`。

## Directory Contract

```text
lattice/context/
  README.md                    # Agent-readable context map
  external.md                  # 外部知识和中心知识入口
  knowledge/
    architecture.md
    rules.md
    pitfalls.md
    glossary.md
    decisions/
  drafts/                      # 待确认的知识沉淀
  sources.yaml                 # 可选：给脚本/自动化消费
lattice/specs/<spec-id>/
  context.md                   # 本次 spec 的最小上下文依据
```

## Optional Tooling

```bash
# 检索 curated project knowledge
lattice/kernel/context/backends/knowledge.sh auth rate-limit idempotency

# 兼容旧入口
lattice/kernel/context/loader.sh auth rate-limit idempotency

# 同步可选中心知识缓存
lattice/kernel/context/sync.sh pull
lattice/kernel/context/sync.sh push
lattice/kernel/context/sync.sh status
```

这些脚本是确定性辅助工具，不替代 Agent 主导的 Context Discovery。

## Manifest

```yaml
kernel:
  layers:
    context: true

context:
  root: lattice/context
  map_file: lattice/context/README.md
  external_file: lattice/context/external.md
  sources_file: lattice/context/sources.yaml
  knowledge:
    dir: lattice/context/knowledge
    drafts_dir: lattice/context/drafts
  central:
    repo: ""
    cache_dir: lattice/context/.central
    mode: read-only
    conflict: project-wins
```
