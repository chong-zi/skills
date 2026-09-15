---
name: skill-wiki
description: 扫描 ~/.claude/skills/ 下外部安装的 skill，增量更新 Obsidian wiki。支持增量扫描（默认）和全量重建（rebuild 参数）。
---

# Skill Wiki

维护 `agent skills/安装/` 目录下的 skill wiki，追踪所有外部安装的 skill。

> **wiki 根目录**：默认为当前目录（首次使用会提示你指定；或设环境变量 `SKILL_WIKI_DIR`）。下文路径中的 `安装/` 一律指该 wiki 根目录。

## 触发

- `/skill-wiki` — 增量扫描（只处理变化的 skill）
- `/skill-wiki rebuild` — 全量重建（清空状态，重新处理所有 skill）

## 执行步骤

### 准备

1. 读取 AGENTS.md 了解 wiki 规范：`$SKILL_WIKI_DIR/AGENTS.md`
2. 读取当前状态：`$SKILL_WIKI_DIR/_sources.json`（不存在则视为空对象 `{}`）
3. 若参数为 `rebuild`：将 `_sources.json` 视为空对象，删除 `安装/skills/` 下所有 `.md` 文件

### 扫描

运行以下命令获取所有外部安装的 skill：

```bash
for f in ~/.claude/skills/*/; do
  name=$(basename "$f")
  target=$(readlink "$f")
  if echo "$target" | grep -q "/.agents/skills/"; then
    echo "$name"
  fi
done
```

### 处理每个 skill

对每个外部 skill：

1. 计算哈希：`sha256sum ~/.agents/skills/<name>/SKILL.md | awk '{print $1}'`
2. 对比 `_sources.json` 中的哈希：
   - **新增或变更**：读取 `~/.agents/skills/<name>/SKILL.md`，生成/更新 `安装/skills/<name>.md`
   - **消失**（json 中有但扫描中没有）：将 `安装/skills/<name>.md` 的 frontmatter `status` 改为 `deleted`
   - **无变化**：跳过

### 生成 skill 页面

从 SKILL.md 提取：
- `description` 字段 → 页面引用块
- `When to Use` / 触发条件章节 → 触发条件
- `capabilities` 字段 → 主要能力列表
- `related_skills` 字段 + 同 category skill → 相关 Skills（`[[name]]` 格式）
- `category` 字段 → 按 AGENTS.md 分类规则归类

页面格式严格遵循 AGENTS.md 中的模板。

### 更新 _sources.json

将所有处理过的 skill 写入 `_sources.json`，消失的 skill 的 status 改为 `deleted`。

### 重建 index.md

按 AGENTS.md 的分类规则，将所有 active skill 按分类排列，deleted skill 单独列在末尾。
格式遵循 AGENTS.md 中的 index.md 模板。

## 文件路径

| 文件 | 路径 |
|------|------|
| wiki 根目录 | `$SKILL_WIKI_DIR`（默认当前目录） |
| 外部 skill 源 | `~/.agents/skills/<name>/SKILL.md` |
| 状态文件 | `安装/_sources.json` |
| skill 页面 | `安装/skills/<name>.md` |
| 总览 | `安装/index.md` |
