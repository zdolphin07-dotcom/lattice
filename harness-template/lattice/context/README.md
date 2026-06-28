# 项目上下文地图

这是 AI Agent 在编写 spec 前应该先读的入口。它不承载全部知识，只告诉 Agent：关键知识在哪里、冲突时如何取舍、本次需求应该怎样形成最小可信上下文依据。

## 项目快照

- 项目定位：_初始化后补充_
- 核心业务对象：_初始化后补充_
- 主要模块：_初始化后补充_
- 高风险链路：_初始化后补充_

## 上下文入口

| Need | Read |
|------|------|
| 架构与模块边界 | `knowledge/architecture.md` |
| 业务规则与接口契约 | `knowledge/rules.md` |
| 历史踩坑与事故教训 | `knowledge/pitfalls.md` |
| 领域术语与命名约定 | `knowledge/glossary.md` |
| 架构决策 | `knowledge/decisions/` |
| 外部文档、中心知识、第三方协议 | `external.md` |
| 历史 spec | `../specs/` |

## 加载策略

- 先读用户本次需求，再查当前代码、测试、schema 和接口契约。
- 项目知识用于理解长期规则、历史决策和踩坑，不替代当前代码事实。
- 外部知识和中心知识只作补充，不覆盖项目内事实。
- 不把大段文档复制进 `spec.md`；只把影响 scope、AC、risk、interface、compatibility 或 verification 的事实写入 `lattice/specs/<spec-id>/context.md`。

## 冲突优先级

1. 用户本次明确指令。
2. 当前代码、测试、schema 和接口契约。
3. `lattice/context/knowledge/` 下的项目知识。
4. `lattice/specs/` 下的历史 spec。
5. `external.md` 和中心知识。
6. 模型先验。

有实质影响的冲突必须记录到 `lattice/specs/<spec-id>/context.md`。
