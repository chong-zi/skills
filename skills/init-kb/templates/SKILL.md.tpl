# kb — {{THEME}} 知识库

管理 `{{TARGET_DIR}}` 目录的知识库，支持查询和刷新。

## 触发条件

- `/kb` — 显示所有条目快速索引
- `/kb <名称>` — 查看指定条目的详细知识（5W1H + 示例 + 关联）
- `/kb refresh` — 重新生成全部知识条目
- `/kb refresh <名称>` — 重新生成指定条目

## 执行规则

收到 `/kb` 命令时：
1. 读取 `{{TARGET_DIR}}/.knowledge/index.md` 并展示
2. 如带名称参数，读取对应 `.knowledge/projects/<name>.md`
3. 如带 `refresh`，扫描目录并重新生成对应知识条目，更新 index.md

## 知识条目格式

```markdown
# <名称>

> 一句话摘要

## What — 是什么
## Why — 为什么用它
## Who — 适合谁用
## When — 什么场景下用
## Where — 源码 / 文档地址
## How — 怎么用（快速上手）

## 示例
## 与本目录其他条目的关联
```

生成知识条目时，通过读取条目目录下的 README、CLAUDE.md、package.json 等文件获取信息。
